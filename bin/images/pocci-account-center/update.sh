#!/bin/bash
set -e

IMAGE_NAME=pocci-account-center
DOCKER_FILE=`dirname $0`/src.tmp/docker/Dockerfile

REGISTERED_NODEJS_IMAGE=`get_registered_image workspace-nodejs`
if [ -n "${REGISTERED_NODEJS_IMAGE}" ]; then
    FROM_VERSION=`echo "${REGISTERED_NODEJS_IMAGE}" | cut -d: -f2`
    replace_from_version ${DOCKER_FILE} ${FROM_VERSION}
    NEXT_VERSION=`get_next_version_of ${IMAGE_NAME} p`
    register_image ${IMAGE_NAME} ${NEXT_VERSION}
fi
