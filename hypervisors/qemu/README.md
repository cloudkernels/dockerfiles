##QEMU Dockerfile
```
DOCKER_BUILDKIT=1 docker build -t qemu_x86_aarch64 -f Dockerfile --output type=local,dest=./output .

```

Builds QEMU from source using Docker. LDFLAGS="-static" can be added to make step to avoid libgc incompatibilities although this is not a very healthy practice.
Supports x86_64 and aarch64. To include more architectures, modify the `--target-list=x86_64-softmmu,aarch64-softmmu` accordingly or remove it completely to build for maximum support possible. 
