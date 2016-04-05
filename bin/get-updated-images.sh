#!/bin/bash
set -e

cd $(dirname $0)/js
IMAGE=`docker images |grep workspace-nodejs | head -1 | awk '{printf "%s:%s",$1,$2}'`
if [ ! -d node_modules ]; then
    docker run --rm -v ${PWD}:/app -w /app ${IMAGE} npm install
fi
docker run --rm -v ${PWD}:/app -w /app ${IMAGE} node ./get-updated-images.js $1 | tr -d "\r"
