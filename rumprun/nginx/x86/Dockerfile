#Dockerfile that extracts the nginx webserver unikernel based on a local image containing rumprun
FROM myrumprun AS builder
#get the packages
RUN git clone https://github.com/cloudkernels/rumprun-packages
WORKDIR /rumprun-packages
#set config for x86_64 arch
RUN cp config.mk.dist config.mk

#apply patch so that pcre library building no longer hangs (nginx can't compile without it)
COPY /0001-ftp-mirror-no-longer-hanging.patch /
WORKDIR /rumprun-packages/pcre
RUN git config user.name "CI Bot"
RUN git config user.email "ci-bot@nubis-pc.eu"
RUN git am /0001-ftp-mirror-no-longer-hanging.patch

#build/compile nginx
WORKDIR /rumprun-packages/nginx
#make
RUN make
#bake the server binary with solo5 as the middleware interface
RUN rumprun-bake solo5-hvt bin/nginx.hvt bin/nginx

#extract the .hvt and .iso produced
FROM scratch as artifact
COPY --from=builder /rumprun-packages/nginx/bin/nginx.hvt ./
COPY --from=builder /rumprun-packages/nginx/images/data.iso ./
