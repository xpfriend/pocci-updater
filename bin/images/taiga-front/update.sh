#!/bin/bash
set -e

TAIGA_BRANCH=stable

IMAGE_NAME=taiga-front
DOCKER_FILE=`dirname $0`/src.tmp/Dockerfile
UPDATED_PACKAGES=`get_newest_version_of_apk_package ${IMAGE_NAME} "git:GIT_VERSION"`
FROM_VERSION=`get_from_version ${IMAGE_NAME}`

update_dist() {
    if [ -d taiga-front-dist.tmp ]; then
        rm -fr taiga-front-dist.tmp
    fi
    git clone https://github.com/xpfriend/taiga-front-dist.git taiga-front-dist.tmp
    cd taiga-front-dist.tmp

    git checkout stable
    git remote add upstream https://github.com/taigaio/taiga-front-dist.git
    git pull upstream stable
    git push origin stable

    if [ "${TAIGA_BRANCH}" = "stable" ]; then
      LAST_COMMIT=`git log -1 --pretty=format:"%s"`
      return
    fi

    git checkout pocci
    CURRENT_COMMIT=`git log -1 --pretty=format:"%s"`

    git clone https://github.com/taigaio/taiga-front tmp
    cd tmp
    git checkout stable
    LAST_COMMIT=`git log -1 --pretty=format:"%H"`

    if [ "${LAST_COMMIT}" == "${CURRENT_COMMIT}" ]; then
        return
    fi

    ${POCCI_DIR}/bin/oneoff nodejs npm install
    ${POCCI_DIR}/bin/oneoff nodejs bower install
    ${POCCI_DIR}/bin/oneoff nodejs gulp deploy

    cd ..
    rm -r ./dist
    cp -r ./tmp/dist/ ./dist
    git add -A
    git commit -am "${LAST_COMMIT}"
    git push origin pocci
}

update_dist

replace_version_env "${DOCKER_FILE}" "TAIGA_BRANCH:${TAIGA_BRANCH} TAIGA_FRONT_VERSION:${LAST_COMMIT}"
replace_version_env "${DOCKER_FILE}" "${UPDATED_PACKAGES}"
replace_from_version "${DOCKER_FILE}" "${FROM_VERSION}"

if [ `get_number_of_updated_files ${DOCKER_FILE}` -gt 0 ]; then
    NEXT_VERSION=`get_next_version_of ${IMAGE_NAME}`
    register_image ${IMAGE_NAME} ${NEXT_VERSION}
fi
