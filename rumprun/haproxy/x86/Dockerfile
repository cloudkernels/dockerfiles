#Dockerfile that extracts the haproxy unikernel based on a local image containing rumprun
FROM myrumprun AS builder
#get the packages
RUN git clone https://github.com/cloudkernels/rumprun-packages
WORKDIR /rumprun-packages
#set config for x86_64 arch
RUN cp config.mk.dist config.mk

#apply patch so that pcre library building no longer hangs (haproxy can't compile without it)
COPY /0001-ftp-mirror-no-longer-hanging.patch /
WORKDIR /rumprun-packages/pcre
RUN git config user.name "CI Bot"
RUN git config user.email "ci-bot@nubis-pc.eu"
RUN git am /0001-ftp-mirror-no-longer-hanging.patch

#build/compile haproxy
WORKDIR /rumprun-packages/haproxy
#make
RUN make
#bake the server binary with solo5 as the middleware interface
RUN rumprun-bake solo5-hvt build/haproxy.hvt build/haproxy

#extract the .hvt and .iso produced
FROM scratch as artifact
COPY --from=builder /rumprun-packages/haproxy/build/haproxy.hvt ./
