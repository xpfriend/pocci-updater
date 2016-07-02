#!/bin/bash
set -e

IMAGE_NAME=sonarqube
DOCKER_FILE=`dirname $0`/src.tmp/Dockerfile
UPDATED_PACKAGES=`get_newest_version_of_apt_package ${IMAGE_NAME} "sonar:SONARQUBE_VERSION"`
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

get_latest_plugin_version() {
    PLUGIN_NAME=$1
    VERSIONS=`curl -s https://sonarsource.bintray.com/Distribution/${PLUGIN_NAME}/ | grep -v '.jar.asc' | grep "${PLUGIN_NAME}-" | sed -E "s/^.+<a .+=.+>${PLUGIN_NAME}-(.+)\.jar<\/a>.+$/\1/g"`
    LATEST=0
    for i in ${VERSIONS}; do
        LATEST=`get_greater_version "$i" "${LATEST}"`
    done
    echo ${LATEST}
}

update_plugin_version() {
    PLUGIN_NAME=`echo $1 | cut -d: -f1`
    LATEST=`get_latest_plugin_version $1`
    replace_version_env "${DOCKER_FILE}" "$2:${LATEST}"
}

update_plugin_version sonar-ldap-plugin SONAR_LDAP_PLUGIN
update_plugin_version sonar-javascript-plugin SONAR_JAVASCRIPT_PLUGIN
update_plugin_version sonar-findbugs-plugin SONAR_FINDBUGS_PLUGIN
update_gitlab_plugin_version

replace_version_env "${DOCKER_FILE}" "${UPDATED_PACKAGES}"
replace_from_version "${DOCKER_FILE}" "${FROM_VERSION}"

if [ `get_number_of_updated_files ${DOCKER_FILE}` -gt 0 ]; then
    NEXT_VERSION=`get_next_version_of ${IMAGE_NAME}`
    register_image ${IMAGE_NAME} ${NEXT_VERSION}
fi
