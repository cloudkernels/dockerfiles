### README
Builds and bakes the haproxy load balancer unikernel for x86.
Requires the patch file included as build context or haproxy make cannot be completed (ftp mirror hanging).

```DOCKER_BUILDKIT=1 docker build -t haproxy_unik --output type=local,dest=./output -f Dockerfile .```
