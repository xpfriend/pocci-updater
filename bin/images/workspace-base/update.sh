#!/bin/bash
set -e

IMAGE_NAME=workspace-base
DOCKER_FILE=`dirname $0`/src.tmp/Dockerfile
UPDATED_PACKAGES=`get_newest_version_of_apt_package ${IMAGE_NAME} "firefox:FIREFOX_VERSION google-chrome-stable:CHROME_VERSION"`
FROM_VERSION=`get_from_version ${IMAGE_NAME}`

replace_version_env "${DOCKER_FILE}" "${UPDATED_PACKAGES}"
replace_from_version "${DOCKER_FILE}" "${FROM_VERSION}"

if [ `get_number_of_updated_files ${DOCKER_FILE}` -gt 0 ]; then
    NEXT_VERSION=`get_next_version_of ${IMAGE_NAME}`
    register_image ${IMAGE_NAME} ${NEXT_VERSION}
fi
