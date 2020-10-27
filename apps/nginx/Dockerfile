FROM ubuntu:16.04 AS builder
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
RUN ./Configure linux-x86_64 --prefix=/usr && make && make install
#back to nginx building
WORKDIR /
RUN wget https://nginx.org/download/nginx-1.19.0.tar.gz && tar xvzf ngin* && rm -r ngin*.gz
WORKDIR /nginx-1.19.0/
RUN ./configure --prefix=/mynginx --with-http_ssl_module --with-stream --with-mail=dynamic --with-openssl=/openssl-1.1.1g
RUN make LDFLAGS="-static"
RUN make install

FROM scratch AS artifact
COPY --from=builder /mynginx .
