## Linux x86 Kernel image Dockerfile

Dockerfile to build and extract a linux x86 kernel bzImage to boot with QEMU/KVM.

```DOCKER_BUILDKIT=1 docker build -t bzimage --output type=local,dest=. -f Dockerfile .```

Builds latest version from Linus's tree and uses the custom kvmm config instead of menuconfig to avoid UI interaction in docker.
Compiles with nproc threads in parallel.
The extracted artifact is the bzImage.
