FROM ubuntu:20.04 AS builder
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get -y update && apt -y install git
#grab latest kernel from Torvald
RUN git clone https://github.com/torvalds/linux
WORKDIR /linux/
#install necessary packages to build linux
RUN apt-get -y install build-essential libncurses-dev bc bison flex libssl-dev libelf-dev
#use a custom config
RUN apt-get -y install wget
RUN wget -O arch/x86/configs/kvmm.config https://gist.githubusercontent.com/ananos/4749c77111a560503bd9725409d82800/raw/3e65dec157a7a19d965675054ef85ce8bc06c74b/basic%2520kernel%2520config
RUN touch .config
RUN make kvmm.config
#compile it using parallel
RUN make -j $(nproc)

#extract the bzImage to use with qemu
FROM scratch AS artifact
COPY --from=builder /linux/arch/x86/boot/bzImage .
