## Linux x86 Kernel image Dockerfile w/ kvmm.

Dockerfile to build and extract a linux x86 kernel bzImage to boot with QEMU/KVM along with module dir output.
Requires a github api token to be set beforehand (https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line).
Run:
```export TOKEN=<your_token_goes_here>```
then:

```DOCKER_BUILDKIT=1 docker build -t get_bzimage -f Dockerfile --build-arg "TOKEN=$TOKEN" --output type=local,dest=./output .```


Builds 5.7 version from Linus's tree and uses the custom kvmm config instead of menuconfig to avoid UI interaction in docker.
Compiles with nproc threads in parallel.
