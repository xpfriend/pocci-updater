#!/bin/bash
set -e

IMAGE_NAME=workspace-java
DOCKER_FILE=`dirname $0`/src.tmp/Dockerfile


LATEST=`curl -s http://www.us.apache.org/dist/maven/maven-3/ |grep "\[DIR\]" |sed -E 's/^.+<a href=.+\/">(.+)\/<\/a> +(....-..-.. ..:..)(.+)/\2 \1/g' |sort -r |head -1 |cut -d" " -f3`
CURRENT=`grep "ENV MVN_VERSION" ${DOCKER_FILE} | cut -d" " -f3`
if [ "${LATEST}" != "${CURRENT}" ]; then
    replace_version_env "${DOCKER_FILE}" "MVN_VERSION:${LATEST}"
fi

register_workspace_image ${DOCKER_FILE} ${IMAGE_NAME}
