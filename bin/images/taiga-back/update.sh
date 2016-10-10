#!/bin/bash
set -e

update_taiga_back() {
    if [ -d taiga-back.tmp ]; then
        rm -fr taiga-back.tmp
    fi
    git clone https://github.com/xpfriend/taiga-back.git taiga-back.tmp
    cd taiga-back.tmp
    git checkout stable
    CURRENT_COMMIT=`git log -1 --pretty=format:"%H"`

    git remote add upstream https://github.com/taigaio/taiga-back.git
    git pull upstream stable
    LAST_COMMIT=`git log -1 --pretty=format:"%H"`

    if [ "${LAST_COMMIT}" == "${CURRENT_COMMIT}" ]; then
        return
    fi

    git push origin stable
    git checkout pocci
    git rebase stable
    git push -f origin pocci
}

update_taiga_back

IMAGE_NAME=taiga-back
DOCKER_FILE=`dirname $0`/src.tmp/Dockerfile
UPDATED_PACKAGES=`get_newest_version_of_apk_package ${IMAGE_NAME} "alpine-sdk:ALPINE_SDK_VERSION gettext:GETTEXT_VERSION git:GIT_VERSION jpeg-dev:JPEG_DEV_VERSION libxml2-dev:LIBXML2_DEV_VERSION libxslt-dev:LIBXSLT_DEV_VERSION linux-headers:LINUX_HEADERS_VERSION netcat-openbsd:NETCAT_VERSION postgresql-dev:POSTGRESQL_DEV_VERSION"`
FROM_VERSION=`get_from_version ${IMAGE_NAME}`

replace_version_env "${DOCKER_FILE}" "TAIGA_BACK_VERSION:${LAST_COMMIT}"
replace_version_env "${DOCKER_FILE}" "${UPDATED_PACKAGES}"
replace_from_version "${DOCKER_FILE}" "${FROM_VERSION}"

if [ `get_number_of_updated_files ${DOCKER_FILE}` -gt 0 ]; then
    NEXT_VERSION=`get_next_version_of ${IMAGE_NAME}`
    register_image ${IMAGE_NAME} ${NEXT_VERSION}
fi
