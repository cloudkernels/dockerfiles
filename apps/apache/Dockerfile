FROM alpine/git:latest AS getter
#clone the apache repo
WORKDIR /cloned_rep/
RUN git clone https://github.com/apache/httpd.git .


#the important stage that does the building
FROM ubuntu:16.04 AS builder
COPY --from=getter /cloned_rep/ /clone
WORKDIR /clone/
#suppress stdin hangs
ARG DEBIAN_FRONTEND=noninteractive
#need to set up every tool required first
RUN apt-get update && apt-get -y install subversion
RUN svn co http://svn.apache.org/repos/asf/apr/apr/trunk srclib/apr
RUN apt-get -y install autoconf
RUN apt-get -y install libtool-bin && apt-get -y install libpcre3-dev && apt -y install python && apt-get -y install make && apt-get -y install libexpat1-dev && apt-get -y install libexpat1
#back to apache building
WORKDIR /clone/
RUN mkdir /final
RUN ./buildconf && ./configure --with-included-apr --prefix=/final --with-expat=/lib/x86_64-linux-gnu/
RUN make LDFLAGS="-static"
RUN make install

#extract only the product of the building process
FROM scratch AS artifact
COPY --from=builder /final/ .
#test case for running container
ENTRYPOINT ["../bin/apachectl", "-k", "start"]
