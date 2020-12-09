#!/bin/sh

app_binary="APP"
#temporarily
ip addr add 10.0.5.3/24 dev eth0
#start the binary the initramfs contains in /usr/bin after sed takes place
/usr/bin/$app_binary
