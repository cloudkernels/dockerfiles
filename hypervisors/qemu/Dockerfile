FROM ubuntu:latest AS builder
#supress stdin hangs
ARG DEBIAN_FRONTEND=noninteractive
#we need git and a few dependencies to build qemu
RUN apt-get -y update && apt -y install git
RUN apt-get -y install libglib2.0-dev libfdt-dev libpixman-1-dev zlib1g-dev
#we also need python3 tools or else configure is not going to work
RUN apt-get -y install python3-setuptools && apt-get -y install python3-pip && pip3 install Ninja
#cloning the repo results in a /qemu folder
RUN git clone git://git.qemu-project.org/qemu.git
#browse the source code dir
WORKDIR /qemu/
#Prepare a native debug build (out of tree)
RUN mkdir -p bin/debug/native
WORKDIR bin/debug/native
#configure and build for x86 and aarch64
RUN ../../../configure --target-list=x86_64-softmmu,aarch64-softmmu --enable-debug && make -j 4

#now that qemu is build, isolate the binaries
FROM scratch AS artifact
COPY --from=builder /qemu/bin/debug/native/ .
