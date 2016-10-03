#!/bin/bash
set -e

IMAGE_NAME=taiga-back
DOCKER_FILE=`dirname $0`/src.tmp/Dockerfile
UPDATED_PACKAGES=`get_newest_version_of_apk_package ${IMAGE_NAME} "alpine-sdk:ALPINE_SDK_VERSION gettext:GETTEXT_VERSION git:GIT_VERSION jpeg-dev:JPEG_DEV_VERSION libxml2-dev:LIBXML2_DEV_VERSION libxslt-dev:LIBXSLT_DEV_VERSION linux-headers:LINUX_HEADERS_VERSION netcat-openbsd:NETCAT_VERSION postgresql-dev:POSTGRESQL_DEV_VERSION"`
FROM_VERSION=`get_from_version ${IMAGE_NAME}`

replace_version_env "${DOCKER_FILE}" "${UPDATED_PACKAGES}"
replace_from_version "${DOCKER_FILE}" "${FROM_VERSION}"

if [ `get_number_of_updated_files ${DOCKER_FILE}` -gt 0 ]; then
    NEXT_VERSION=`get_next_version_of ${IMAGE_NAME}`
    register_image ${IMAGE_NAME} ${NEXT_VERSION}
fi
