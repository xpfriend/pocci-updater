#!/bin/bash
set -e

BASE_DIR=$(cd $(dirname $0); pwd)
NEW_IMAGES=${BASE_DIR}/new-images.txt

source ${BASE_DIR}/util.sh

update_docker_compose() {
    echo $1
    grep -E ' +image *:' $1 | sed -E 's/ +image *: *(.+)/"\1"/g' | \
      awk 'BEGIN{printf "["}NR>1{printf ", "}{print $0}END{printf "]\n"}' > ${BASE_DIR}/js/version.json
    for i in `${BASE_DIR}/get-updated-images.sh | sed -E -e 's/^.* --> //g'`; do
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
sed -e "s/^VERSION_WORKSPACE_BASE=.*$/VERSION_WORKSPACE_BASE=`get_current_version workspace-base`/" \
    -e "s/^VERSION_WORKSPACE_JAVA=.*$/VERSION_WORKSPACE_JAVA=`get_current_version workspace-java`/" \
    -e "s/^VERSION_WORKSPACE_NODEJS=.*$/VERSION_WORKSPACE_NODEJS=`get_current_version workspace-nodejs`/" \
    -i ${BASE_DIR}/pocci/src.tmp/bin/lib/version

update_new_images base
update_new_images java
update_new_images nodejs

for i in `find ${BASE_DIR}/pocci/src.tmp/template/services/ -name docker-compose.yml.template`; do
    update_docker_compose $i
done

cd ${BASE_DIR}/pocci/src.tmp
git --no-pager diff --unified=0
if [ `git status --porcelain |wc -l` -gt 0 ]; then
    git commit -am "Update software to the latest version"
fi
cd ${BASE_DIR}

