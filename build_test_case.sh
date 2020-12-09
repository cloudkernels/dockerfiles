#!/bin/sh
#shell script that builds a complete case for testing an argument-specified app binary within a qemu guest
#build context can be specified as third argument. If not set, will use . as context
#github token must be set with $ expose TOKEN=<yourtoken>
#invoke the build of the target specified in 2nd argument, output destination is 3rd argument
if [ -z "$3" ]
then
	```DOCKER_BUILDKIT=1 docker build -t apptest --build-arg "GITHUB_OAUTH_TOKEN=$TOKEN" --target $1 --output type=local,dest=$2 -f Dockerfile .```
else
	```DOCKER_BUILDKIT=1 docker build -t apptest --build-arg "GITHUB_OAUTH_TOKEN=$TOKEN" --target $1 --output type=local,dest=$2 -f Dockerfile $3```
fi

if [ $? -eq 0 ]
then
	echo "Built a qemu testcase for app \"$1\" at $2 ."
else
	echo "Something went wrong..."
fi
