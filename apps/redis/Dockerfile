FROM ubuntu AS builder
ARG DEBIAN_FRONTEND=noninteractive
#we will need wget to get the redis source code as well as tcl & make
RUN apt-get -y update && apt -y install wget && apt -y install tcl && apt-get -y install build-essential && apt-get -y install pkg-config
#download redis stable in this directory
RUN wget http://download.redis.io/redis-stable.tar.gz -P .
RUN tar xvfz redis*
WORKDIR /redis-stable/
RUN make CFLAGS="-static" EXEEXT="-static" LDFLAGS="-static"

#keep only the binaries to run
FROM alpine:latest AS artifact
COPY --from=builder /redis-stable/src/ .
#COPY --from=builder /lib/x86_64-linux-gnu ./lib/
