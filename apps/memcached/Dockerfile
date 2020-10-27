FROM ubuntu AS builder
ARG DEBIAN_FRONTEND=noninteractive
#we will need wget and some important packages
RUN apt-get -y update && apt -y install wget && apt-get -y install build-essential && apt-get -y install libevent-dev
#get the source tar
RUN wget http://www.memcached.org/files/memcached-1.6.7.tar.gz && tar xvzf memc*
WORKDIR /memcached-1.6.7/
RUN ./configure --prefix=/memcached
RUN make LDFLAGS="-static" && make install


FROM alpine:latest AS artifact
COPY --from=builder /memcached/ .
