#!/bin/bash
set -e

IMAGE_NAME=sonarqube
DOCKER_FILE=`dirname $0`/src.tmp/Dockerfile
FROM_VERSION=`get_from_version ${IMAGE_NAME}`

get_latest_gitlab_plugin_version() {
    VERSIONS=`curl -s http://nexus.talanlabs.com/content/groups/public_release/com/synaptix/sonar-gitlab-plugin/ | grep -e '<a href' | grep -v 'Parent Directory' | grep -v maven-metadata | sed -E "s/^.+<a .+=.+>(.+)\/<\/a>.+$/\1/g"`
    LATEST=0
    for i in ${VERSIONS}; do
        LATEST=`get_greater_version "$i" "${LATEST}"`
    done
    echo ${LATEST}
}

update_gitlab_plugin_version() {
    LATEST=`get_latest_gitlab_plugin_version`
    replace_version_env "${DOCKER_FILE}" "SONAR_GITLAB_PLUGIN:${LATEST}"
}

get_latest_plugin_url() {
    PLUGIN_NAME=$1
    VERSIONS=`curl -s https://update.sonarsource.org/update-center.properties | grep ${PLUGIN_NAME} | grep downloadUrl | sed -E "s/^${PLUGIN_NAME}\.(.+)\.downloadUrl=.+$/\1/g"`
    LATEST=0
    for i in ${VERSIONS}; do
        LATEST=`get_greater_version "$i" "${LATEST}"`
    done
    curl -s https://update.sonarsource.org/update-center.properties | grep ${PLUGIN_NAME}.${LATEST}.downloadUrl | sed -E "s/^${PLUGIN_NAME}.${LATEST}.downloadUrl=(.+)$/\1/" | sed 's/\\//g'
}

update_plugin_url() {
    LATEST=`get_latest_plugin_url $1`
    sed -i "s|^ENV $2.*|ENV $2 ${LATEST}|" ${DOCKER_FILE}
}

get_latest_sonar_version() {
    VERSIONS=`curl -s https://sonarsource.bintray.com/Distribution/sonarqube/ | grep -v '.zip.md5' | grep -v '.zip.sha' | grep -v '.zip.asc' | grep "sonarqube-" | grep -v "\-RC" | sed -E "s/^.+<a .+=.+>sonarqube-(.+)\.zip<\/a>.+$/\1/g"`
    LATEST=0
    for i in ${VERSIONS}; do
        LATEST=`get_greater_version "$i" "${LATEST}"`
    done
    echo ${LATEST}
}

update_plugin_url ldap SONAR_LDAP_PLUGIN_URL
update_plugin_url javascript SONAR_JAVASCRIPT_PLUGIN_URL
update_plugin_url findbugs SONAR_FINDBUGS_PLUGIN_URL
update_gitlab_plugin_version

replace_version_env "${DOCKER_FILE}" "SONARQUBE_VERSION:`get_latest_sonar_version`"
replace_from_version "${DOCKER_FILE}" "${FROM_VERSION}"

if [ `get_number_of_updated_files ${DOCKER_FILE}` -gt 0 ]; then
    NEXT_VERSION=`get_next_version_of ${IMAGE_NAME}`
    register_image ${IMAGE_NAME} ${NEXT_VERSION}
fi
