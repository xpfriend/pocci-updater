#!/bin/bash
set -e

BASE_DIR=$(cd $(dirname $0); pwd)

source ${BASE_DIR}/util.sh

update_docker_compose() {
    echo $1
    grep -E ' +image *:' $1 | sed -E 's/ +image *: *(.+)/"\1"/g' | \
      awk 'BEGIN{printf "["}NR>1{printf ", "}{print $0}END{printf "]\n"}' > ${BASE_DIR}/js/version.json
    for i in `${BASE_DIR}/get-updated-images.sh | sed -E -e 's/^.* --> //g' -e 's|^library/||g'`; do
      IMAGE=`echo $i | cut -d: -f1`
      TAG=`echo $i | cut -d: -f2`
      echo "${IMAGE}:${TAG}"
      sed -E -e "s| +image *: *${IMAGE}:.+$|  image: ${IMAGE}:${TAG}|g" -i $1
    done
}

cd ${BASE_DIR}/pocci
if [ -d ./src.tmp ]; then
    rm -fr ./src.tmp
fi
git clone git@github.com:xpfriend/pocci.git src.tmp

cd src.tmp
git checkout -b wip

cd ${BASE_DIR}
sed -e "s/^VERSION_WORKSPACE_BASE=.*$/VERSION_WORKSPACE_BASE=`get_current_version workspace-base`/" \
    -e "s/^VERSION_WORKSPACE_JAVA=.*$/VERSION_WORKSPACE_JAVA=`get_current_version workspace-java`/" \
    -e "s/^VERSION_WORKSPACE_NODEJS=.*$/VERSION_WORKSPACE_NODEJS=`get_current_version workspace-nodejs`/" \
    -i ${BASE_DIR}/pocci/src.tmp/bin/lib/version

for i in `find ${BASE_DIR}/pocci/src.tmp/template/services/ -name docker-compose.yml.template`; do
    update_docker_compose $i
done

cd ${BASE_DIR}/pocci/src.tmp
git --no-pager diff --unified=0
if [ `git status --porcelain |wc -l` -gt 0 ]; then
    git commit -am "Update software to the latest version"
fi
cd ${BASE_DIR}

