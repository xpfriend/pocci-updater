#!/bin/bash
set -e

cd $(dirname $0)

./check-wip.sh
./update-images.sh
./build-images.sh
./build-images-on-docker-hub.sh
./update-pocci.sh
./pull-new-images.sh
./test-pocci.sh
