#!/bin/bash
set -e

IMAGE_NAME=workspace-nodejs
DOCKER_FILE=`dirname $0`/src.tmp/Dockerfile

update_version() {
    CURRENT=`grep "ENV $1" ${DOCKER_FILE} |cut -d" " -f3`
    if [ "$2" != "${CURRENT}" ]; then
        replace_version_env "${DOCKER_FILE}" "$1:$2"
    fi
}

update_npm_version() {
    LATEST=`curl --compressed -s https://registry.npmjs.com/$2/latest | sed -E 's/^.+,"version":"([^"]+).+/\1/'`
    update_version $1 ${LATEST}
}

update_nodejs_version() {
    LATEST=`curl -s https://nodejs.org/dist/latest-v4.x/SHASUMS256.txt |grep "\.pkg" |sed -E 's/.+node-(.+).pkg/\1/'`
    update_version $1 ${LATEST}
}

update_git_tag_version() {
    LATEST=`curl -s https://api.github.com/repos/$2/releases/latest |grep tag_name |sed -E 's/.+"tag_name": *"(.+[^"])".*/\1/'`
    update_version $1 ${LATEST}
}

update_git_tag_version NVM_VERSION creationix/nvm

update_nodejs_version NODEJS_VERSION

update_npm_version BOWER_VERSION bower
update_npm_version GRUNT_VERSION grunt-cli
update_npm_version GULP_VERSION gulp
update_npm_version YO_VERSION yo
update_npm_version YARN_VERSION yarn

register_workspace_image ${DOCKER_FILE} ${IMAGE_NAME}
