#!/bin/bash
set -e

IMAGE_NAME="jenkins"
DOCKER_FILE=`dirname $0`/src.tmp/Dockerfile
PLUGINS_TXT=`dirname $0`/src.tmp/config/plugins.txt
FROM_VERSION=`get_from_version ${IMAGE_NAME}`

update_plugin_version() {
    PLUGIN_NAME=`echo $1 | cut -d: -f1`
    LATEST=`curl -s https://updates.jenkins.io/download/plugins/${PLUGIN_NAME}/ |grep -e '<a href' |grep -v latest |head -1 | sed -E 's/^.+<a href=.+>(.+)<\/a>.+$/\1/g'`
    echo "${PLUGIN_NAME}:${LATEST}" >>${PLUGINS_TXT}
}

PLUGINS=`cat ${PLUGINS_TXT}`
 >${PLUGINS_TXT}
for i in ${PLUGINS}; do
    update_plugin_version $i
done

replace_from_version "${DOCKER_FILE}" "${FROM_VERSION}"

if [ `get_number_of_updated_files ${DOCKER_FILE}` -gt 0 ]; then
    NEXT_VERSION=`get_next_version_of ${IMAGE_NAME}`
    register_image ${IMAGE_NAME} ${NEXT_VERSION}
fi
