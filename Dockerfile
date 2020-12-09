#base building stage, will contain the most utilities needed
FROM ubuntu:20.04 AS builder
ARG DEBIAN_FRONTEND=noninteractive
ARG GITHUB_OAUTH_TOKEN
RUN apt-get -y update && apt -y install git && apt-get -y install build-essential && apt -y install wget && apt -y install curl


#start with building the linux kernel
FROM builder AS linux-builder
ARG DEBIAN_FRONTEND
ARG GITHUB_OAUTH_TOKEN
COPY /0001-KVMM-export-needed-symbols.patch /
COPY /0002-KVMM-Memory-and-interface-related-changes.patch /
#grab 5.7 kernel from Linus's tree to apply patches
RUN git clone https://github.com/torvalds/linux -b v5.7 --depth 1
RUN git clone https://${GITHUB_OAUTH_TOKEN}:x-oauth-basic@github.com/cloudkernels/kvmm
WORKDIR /linux/
#apply patches sequentially
RUN git config user.name "CI Bot"
RUN git config user.email "ci-bot@nubis-pc.eu"
RUN git am /*.patch
#install necessary packages to build linux
RUN apt-get -y install build-essential libncurses-dev bc bison flex libssl-dev libelf-dev
#use a custom config
RUN apt-get -y install wget
RUN wget -O arch/x86/configs/kvmm.config https://gist.githubusercontent.com/ananos/4749c77111a560503bd9725409d82800/raw/3e65dec157a7a19d965675054ef85ce8bc06c74b/basic%2520kernel%2520config
RUN touch .config
RUN make kvmm.config
#compile it using parallel and install modules
RUN make -j $(nproc)
RUN make INSTALL_MOD_PATH=/linux/modules modules_install
WORKDIR /kvmm/
RUN KDIR=/linux make


#build qemu
FROM builder AS qemu-builder
ARG DEBIAN_FRONTEND
ARG GITHUB_OAUTH_TOKEN
#we need a few dependencies to build qemu
RUN apt-get -y install libglib2.0-dev libfdt-dev libpixman-1-dev zlib1g-dev
#we also need python3 tools or else configure is not going to work
RUN apt-get -y install python3-setuptools && apt-get -y install python3-pip && pip3 install Ninja
#cloning the repo results in a /qemu folder
RUN git clone git://git.qemu-project.org/qemu.git --depth 1
#browse the source code dir
WORKDIR /qemu/
RUN git submodule update --init
#Prepare a native build (out of tree)
#configure and build for x86 and aarch64
RUN ./configure --target-list=x86_64-softmmu,aarch64-softmmu --static --prefix=/qemu_install && make -j $(nproc) LDFLAGS="-static"
RUN make install


#build solo5 (for unikernel testing)
FROM builder AS solo5-builder
RUN apt install -y pkg-config && apt-get install -y libseccomp-dev
RUN git clone https://github.com/Solo5/solo5.git -b v0.4.1
WORKDIR /solo5/
RUN ./configure.sh
#disable genode
RUN sed -i 's/BUILD_GENODE=yes/BUILD_GENODE=no/g' Makeconf
RUN make -j $(nproc) LDFLAGS="-static"


#-----------APP BUILDERS----------------
#redis
#build the app static binary we want to test
FROM builder AS redis-builder
ARG DEBIAN_FRONTEND
#we will need wget to get the redis source code as well as tcl
RUN apt-get -y update && apt -y install tcl && apt-get -y install pkg-config
#download redis stable in this directory
RUN wget http://download.redis.io/redis-stable.tar.gz -P .
RUN tar xvfz redis*
WORKDIR /redis-stable/
RUN make LDFLAGS="-static" -j $(nproc)


#nginx, may need revision (normal build)
FROM ubuntu:16.04 AS nginx-builder
RUN apt-get -y update && apt-get -y install wget
RUN apt-get -y install libpcre3 libpcre3-dev && apt -y install build-essential
#need to build zlib
RUN wget http://zlib.net/zlib-1.2.11.tar.gz && tar xvzf zlib* && rm -r zlib*.gz
WORKDIR /zlib-1.2.11/
RUN ./configure && make && make install
#now need to install openssl
WORKDIR /
RUN wget http://www.openssl.org/source/openssl-1.1.1g.tar.gz && tar xvzf openss* && rm -r opens*.gz
WORKDIR /openssl-1.1.1g/
RUN ./Configure linux-x86_64 --prefix=/usr && make -j $(nproc) && make install
#back to nginx building
WORKDIR /
RUN wget https://nginx.org/download/nginx-1.19.0.tar.gz && tar xvzf ngin* && rm -r ngin*.gz
WORKDIR /nginx-1.19.0/
RUN ./configure --prefix=/mynginx --with-http_ssl_module --with-stream --with-mail=dynamic --with-openssl=/openssl-1.1.1g
RUN make LDFLAGS="-static" -j $(nproc)
RUN make install
RUN touch /mynginx/logs/access.log


#---------SOLO5 UNIKERNELS FOR EACH APP--------
#redis unikernel
FROM rumprun-toolstack:latest AS redis-uni-builder
#get the packages
RUN git clone https://github.com/cloudkernels/rumprun-packages
WORKDIR /rumprun-packages
#set config for x86_64 arch
RUN cp config.mk.dist config.mk
#build redis
WORKDIR /rumprun-packages/redis
#make without persistence
RUN make cache -j $(nproc)
#bake the redis-server binary with solo5 as the middleware interface
RUN rumprun-bake solo5-hvt bin/redis-server.hvt bin/redis-server


#nginx unikernel
FROM rumprun-toolstack:latest AS nginx-uni-builder
#get the packages
RUN git clone https://github.com/cloudkernels/rumprun-packages
WORKDIR /rumprun-packages
#set config for x86_64 arch
RUN cp config.mk.dist config.mk
#apply patch so that pcre library building no longer hangs (nginx can't compile without it)
COPY /0001-ftp-mirror-no-longer-hanging.patch /
WORKDIR /rumprun-packages/pcre
RUN git config user.name "CI Bot"
RUN git config user.email "ci-bot@nubis-pc.eu"
RUN git am /0001-ftp-mirror-no-longer-hanging.patch
#build/compile nginx
WORKDIR /rumprun-packages/nginx
#make
RUN make -j $(nproc)
#bake the server binary with solo5 as the middleware interface
RUN rumprun-bake solo5-hvt bin/nginx.hvt bin/nginx

#---------INITRAMFS FOR EACH APP----------
#redis initramfs
#build the initramfs we will use with qemu
FROM builder AS redis-initramfs
#prevent stdin hangs
ARG DEBIAN_FRONTEND
ARG GITHUB_OAUTH_TOKEN
RUN apt-get -y update && apt -y install git && apt -y install wget
#get fetch to grab ramdisk image
RUN wget -O /fetch  https://github.com/gruntwork-io/fetch/releases/download/v0.3.11/fetch_linux_amd64
RUN chmod +x /fetch && mkdir -p /ramdisk
RUN /fetch --repo="https://github.com/cloudkernels/kvmm" --tag="v0.0.1" --release-asset="initramfs.cpio.gz" /ramdisk
#add selected binary to the ramdisk
WORKDIR /ramdisk/build/
RUN apt-get -y install cpio
RUN zcat ../initramfs.cpio.gz | cpio -idv
#lets add the binary & scripts to the ramdisk
COPY --from=redis-builder /redis-stable/src/redis-server ./usr/bin/
COPY --from=linux-builder /linux/modules/* ./lib/modules/
#pass the template script from context
COPY /template_script.sh /
#produce the actual init.d script from the template we copied + make it executable
RUN cat /template_script.sh | sed 's/APP/redis-server --protected-mode no/g' > ./etc/init.d/S91myscript && chmod +x ./etc/init.d/S91myscript
RUN find . | cpio -H newc -o | gzip -9 > ../initramfs.cpio.gz


#nginx initramfs
#build the initramfs we will use with qemu
FROM builder AS nginx-initramfs
#prevent stdin hangs
ARG DEBIAN_FRONTEND
ARG GITHUB_OAUTH_TOKEN
RUN apt-get -y update && apt -y install git && apt -y install wget
#get fetch to grab ramdisk image
RUN wget -O /fetch  https://github.com/gruntwork-io/fetch/releases/download/v0.3.11/fetch_linux_amd64
RUN chmod +x /fetch && mkdir -p /ramdisk
RUN /fetch --repo="https://github.com/cloudkernels/kvmm" --tag="v0.0.1" --release-asset="initramfs.cpio.gz" /ramdisk
#add selected binary to the ramdisk
WORKDIR /ramdisk/build/
RUN apt-get -y install cpio
RUN zcat ../initramfs.cpio.gz | cpio -idv
#lets add the binary & scripts to the ramdisk
RUN mkdir mynginx
COPY --from=nginx-builder /mynginx/sbin/nginx ./usr/bin/
COPY --from=nginx-builder /mynginx/conf ./mynginx/conf
COPY --from=nginx-builder /mynginx/logs ./mynginx/logs
COPY --from=linux-builder /linux/modules/* ./lib/modules/
#pass the template script from context
COPY /template_script.sh /
#produce the actual init.d script from the template we copied + make it executable
RUN cat /template_script.sh | sed 's/APP/nginx/g' > ./etc/init.d/S91myscript && chmod +x ./etc/init.d/S91myscript
RUN find . | cpio -H newc -o | gzip -9 > ../initramfs.cpio.gz


#--------TARGET ARTIFACTS----------
#now these used as target stages will determine what will be built and kept in the final artifact
FROM scratch AS nginx-qemu
COPY --from=linux-builder /linux/arch/x86/boot/bzImage .
COPY --from=qemu-builder /qemu_install ./qemu/
COPY --from=nginx-initramfs /ramdisk/initramfs.cpio.gz .

FROM scratch AS redis-qemu
COPY --from=linux-builder /linux/arch/x86/boot/bzImage .
COPY --from=qemu-builder /qemu_install ./qemu/
COPY --from=redis-initramfs /ramdisk/initramfs.cpio.gz .

#HVT unikernels targets
FROM scratch AS redis-solo5
COPY --from=redis-uni-builder /rumprun-packages/redis/bin/redis-server.hvt .
COPY --from=redis-uni-builder /rumprun-packages/redis/images/data.iso .
COPY --from=solo5-builder /solo5/tenders/hvt/solo5-hvt .


FROM scratch AS nginx-solo5
COPY --from=nginx-uni-builder /rumprun-packages/nginx/bin/nginx.hvt .
COPY --from=nginx-uni-builder /rumprun-packages/nginx/images/data.iso .
COPY --from=solo5-builder /solo5/tenders/hvt/solo5-hvt .
