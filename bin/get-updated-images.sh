#!/bin/bash
set -e

cd $(dirname $0)/js
docker images | tail -n +2 | grep $1 "xpfriend/" | awk 'BEGIN{printf "["}NR>1{printf ", "}{printf "\"%s:%s\"",$1,$2}END{printf "]\n"}' >./version.json

IMAGE=`docker images |grep workspace-nodejs | head -1 | awk '{printf "%s:%s",$1,$2}'`
docker run --rm -it -v ${PWD}:/app -w /app ${IMAGE} node ./get-updated-images.js
