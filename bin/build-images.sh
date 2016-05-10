#!/bin/bash
set -e

export BASE_DIR=$(cd $(dirname $0); pwd)
export REGISTERED_IMAGES=${BASE_DIR}/registered-images.txt

${BASE_DIR}/setup-git-user.sh

for i in `cat ${REGISTERED_IMAGES} | tr -d "\r"`; do
    echo "=============================="
    echo $i
    echo "------------------------------"
    IMAGE=`echo $i | cut -d: -f1`
    TAG=`echo $i | cut -d: -f2`
    cd ${BASE_DIR}/images/${IMAGE}/src.tmp

    if [ `git status --porcelain |wc -l` -gt 0 ]; then
        DOCKER_FILE_DIR=$(dirname $(find ${BASE_DIR}/images/${IMAGE}/src.tmp -name Dockerfile))
        docker build -t xpfriend/$i ${DOCKER_FILE_DIR}
        if [ -f ${BASE_DIR}/images/${IMAGE}/verify.sh ]; then
            echo "Verify: ${IMAGE} image"
            bash ${BASE_DIR}/images/${IMAGE}/verify.sh xpfriend/$i
        fi
        git commit -am "Update software to the latest version"
        git tag "v${TAG}"
        git push origin master
        git push origin "v${TAG}"
    fi
done
