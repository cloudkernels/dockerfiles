FROM ubuntu:20.04 AS builder
ARG DEBIAN_FRONTEND=noninteractive
ARG TOKEN
RUN apt-get -y update && apt -y install git
RUN git clone https://${TOKEN}:x-oauth-basic@github.com/cloudkernels/kvmm
#copy the two patches from build context
COPY /kvmm/linux-patches/0001-KVMM-export-needed-symbols.patch /
COPY /kvmm/linux-patches/0002-KVMM-Memory-and-interface-related-changes.patch /
#grab 5.7 kernel from Linus's tree to apply patches
RUN git clone https://github.com/torvalds/linux -b v5.7 --depth 1
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

#extract the bzImage to use with qemu
FROM scratch AS artifact
COPY --from=builder /linux/arch/x86/boot/bzImage .
COPY --from=builder /linux/modules ./modules/
COPY --from=builder /kvmm/kvmm.ko /kvmm.ko
