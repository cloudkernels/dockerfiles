#!/bin/sh
#$1 is built qemu test case dir, $2 is tap interface name
QEMU_BIN=$1/qemu/bin/qemu-system-x86_64 
MEM=2048
CORES=1
KERNEL=$1/bzImage
INITRD=$1/initramfs.cpio.gz
NET1="nic,model=virtio,macaddr=52:54:12:4a:85:7d"
NET2="tap,script=no,ifname=$2,vhost=on"
MISC_FLAGS=" -nographic -append "console=ttyS0"  -enable-kvm -cpu host"

```$QEMU_BIN -m $MEM -smp $CORES -kernel $KERNEL -initrd $INITRD -net $NET1 -net $NET2 $MISC_FLAGS``` &

echo "Running qemu under PID $!"
#run

