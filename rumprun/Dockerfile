FROM debian:stretch

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -q -y \
        --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        genisoimage \
        git \
        libseccomp-dev \
        libxen-dev \
        sudo \
        xorriso \
        zlib1g-dev \
    && apt-get clean

RUN git clone https://github.com/cloudkernels/rumprun -b solo5-aarch64
RUN cd rumprun && git submodule update --init solo5
RUN cd rumprun && git submodule update --init buildrump.sh
RUN cd rumprun && git submodule update --init src-netbsd
COPY src-netbsd.patch /src-netbsd.patch
WORKDIR /rumprun/src-netbsd
RUN patch -p1 < /src-netbsd.patch
WORKDIR /
RUN cd rumprun && DESTDIR=/usr/local make && cd .. && rm -rf rumprun
