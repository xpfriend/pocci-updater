#!/bin/bash
set -e

IMAGE_NAME="fluentd"
DOCKER_FILE=`dirname $0`/src.tmp/Dockerfile
FROM_VERSION=`get_from_version ${IMAGE_NAME}`

replace_from_version "${DOCKER_FILE}" "${FROM_VERSION}"

if [ `get_number_of_updated_files ${DOCKER_FILE}` -gt 0 ]; then
    NEXT_VERSION=`echo ${FROM_VERSION} | sed 's/^v//'`
    register_image ${IMAGE_NAME} ${NEXT_VERSION}
fi
