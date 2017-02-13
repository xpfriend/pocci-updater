#!/bin/bash
set -e

BASE_DIR=$(cd $(dirname $0); pwd)
NEW_IMAGES=${BASE_DIR}/new-images.txt
UPDATED_IMAGES=${BASE_DIR}/updated-images.txt


source ${BASE_DIR}/util.sh

update_docker_compose() {
    echo $1
    grep -E ' +image *:' $1 | sed -E 's/ +image *: *(.+)/"\1"/g' | \
      awk 'BEGIN{printf "["}NR>1{printf ", "}{print $0}END{printf "]\n"}' > ${BASE_DIR}/js/version.json
    ${BASE_DIR}/get-updated-images.sh > ${UPDATED_IMAGES}
    for i in `cat ${UPDATED_IMAGES} | sed -E -e 's/^.* --> //g'`; do
      IMAGE_FULL=`echo $i | cut -d: -f1`
      IMAGE=`echo ${IMAGE_FULL} | sed -E -e 's|^library/||g'`
      TAG=`echo $i | cut -d: -f2`
      sed -E -e "s| +image *: *${IMAGE}:.+$|  image: ${IMAGE}:${TAG}|g" -i $1
      echo "${IMAGE_FULL}:${TAG}" | tee -a ${NEW_IMAGES}
    done
}

update_new_images() {
    LNAME=$1
    UNAME=`echo $1 |tr '[:lower:]' '[:upper:]'`
    cd ${BASE_DIR}/pocci/src.tmp
    NEW_VERSION=`git --no-pager diff --unified=0 | grep "^+VERSION_WORKSPACE_${UNAME}=" | cut -d= -f2`
    if [ -n "${NEW_VERSION}" ]; then
        echo "xpfriend/workspace-${LNAME}:${NEW_VERSION}" | tee -a ${NEW_IMAGES}
    fi
    cd ${BASE_DIR}
}

> ${NEW_IMAGES}

if [ ! -d ${BASE_DIR}/pocci ]; then
    mkdir ${BASE_DIR}/pocci
fi

cd ${BASE_DIR}/pocci
if [ -d ./src.tmp ]; then
    sudo rm -fr ./src.tmp
fi
git clone git@github.com:xpfriend/pocci.git src.tmp

cd src.tmp
git checkout -b wip

cd ${BASE_DIR}
CURRENT_BASE_VERSION=`get_current_version workspace-base`
CURRENT_JAVA_VERSION=`get_current_version workspace-java`
CURRENT_NODEJS_VERSION=`get_current_version workspace-nodejs`

sed -e "s/^VERSION_WORKSPACE_BASE=.*$/VERSION_WORKSPACE_BASE=${CURRENT_BASE_VERSION}/" \
    -e "s/^VERSION_WORKSPACE_JAVA=.*$/VERSION_WORKSPACE_JAVA=${CURRENT_JAVA_VERSION}/" \
    -e "s/^VERSION_WORKSPACE_NODEJS=.*$/VERSION_WORKSPACE_NODEJS=${CURRENT_NODEJS_VERSION}/" \
    -i ${BASE_DIR}/pocci/src.tmp/bin/lib/version

sed -e "s|xpfriend/workspace-nodejs.*$|xpfriend/workspace-nodejs:${CURRENT_NODEJS_VERSION}|" \
    -i ${BASE_DIR}/pocci/src.tmp/template/services/core/gitlab/runner/workspaces.yml.template

sed -e "s|xpfriend/workspace-nodejs.*$|xpfriend/workspace-nodejs:${CURRENT_NODEJS_VERSION}|" \
    -i ${BASE_DIR}/pocci/src.tmp/template/code/example/example-nodejs/.gitlab-ci.yml

sed -e "s|xpfriend/workspace-java.*$|xpfriend/workspace-java:${CURRENT_JAVA_VERSION}|" \
    -i ${BASE_DIR}/pocci/src.tmp/template/code/example/example-java/.gitlab-ci.yml

sed -e "s|xpfriend/workspace-java.*$|xpfriend/workspace-java:${CURRENT_JAVA_VERSION}|" \
    -i ${BASE_DIR}/pocci/src.tmp/document/gitlab-ci.ja.md

update_new_images base
update_new_images java
update_new_images nodejs

for i in `find ${BASE_DIR}/pocci/src.tmp/template/services/ -name docker-compose.yml.template`; do
    update_docker_compose $i
done

for i in `find ${BASE_DIR}/pocci/src.tmp/template/services/ -name workspaces.yml.template`; do
    update_docker_compose $i
done

for i in `ls ${BASE_DIR}/services/*/update.sh`; do
    bash $i ${BASE_DIR}/pocci/src.tmp
done

cd ${BASE_DIR}/pocci/src.tmp/bin
if [ -f js/yarn.lock ]; then
    rm js/yarn.lock
fi
../test/clean-containers.sh
./build

cd ${BASE_DIR}/pocci/src.tmp
git --no-pager diff --unified=0
if [ `git status --porcelain |wc -l` -gt 0 ]; then
    git commit -am "Update software to the latest version"
else
    git checkout master
    git branch -d wip
fi
cd ${BASE_DIR}

