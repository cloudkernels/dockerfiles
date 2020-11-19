#Dockerfile that extracts the redis-server unikernel based on a local image containing rumprun
FROM myrumprun AS builder
#get the packages
RUN git clone https://github.com/cloudkernels/rumprun-packages
WORKDIR /rumprun-packages
#set config for x86_64 arch
RUN cp config.mk.dist config.mk
#build redis
WORKDIR /rumprun-packages/redis
#make without persistence
RUN make cache
#bake the redis-server binary with solo5 as the middleware interface
RUN rumprun-bake solo5-hvt bin/redis-server.hvt bin/redis-server

#extract the .hvt, the .iso and .img produced
FROM scratch as artifact
COPY --from=builder /rumprun-packages/redis/bin/redis-server.hvt ./
COPY --from=builder /rumprun-packages/redis/images/data.iso ./
#without persistence there is no .img product
#COPY --from=builder /rumprun-packages/redis/images/datapers.img ./
