### README
Builds and bakes the nginx server unikernel for x86.
Requires the patch file included as build context or nginx make cannot be completed (ftp mirror hanging).

```DOCKER_BUILDKIT=1 docker build -t nginx_unik --output type=local,dest=./output -f Dockerfile .```
