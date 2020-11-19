#Dockerfile that extracts the memcached unikernel based on a local image containing rumprun
FROM myrumprun AS builder
#get the packages
RUN git clone https://github.com/cloudkernels/rumprun-packages
WORKDIR /rumprun-packages
#set config for x86_64 arch
RUN cp config.mk.dist config.mk
#build memcached
WORKDIR /rumprun-packages/memcached
#make
RUN make
#bake the memcached binary with solo5 as the middleware interface
RUN rumprun-bake solo5-hvt build/memcached.hvt build/memcached

#extract the .hvt produced
FROM scratch as artifact
COPY --from=builder /rumprun-packages/memcached/build/memcached.hvt ./
