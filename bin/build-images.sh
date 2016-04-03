#!/bin/bash
set -e

export BASE_DIR=$(cd $(dirname $0); pwd)
export REGISTERED_IMAGES=${BASE_DIR}/registered-images.txt

for i in `cat ${REGISTERED_IMAGES} | tr -d "\r"`; do
    echo "=============================="
    echo $i
    echo "------------------------------"
    IMAGE=`echo $i | cut -d: -f1`
    TAG=`echo $i | cut -d: -f2`
    cd ${BASE_DIR}/images/${IMAGE}/src.tmp

    if [ `git status --porcelain |wc -l` -gt 0 ]; then
        if [ `docker images |awk '{printf "%s:%s\n",$1,$2}' | grep $i | wc -l` -eq 0 ]; then
            DOCKER_FILE_DIR=$(dirname $(find ${BASE_DIR}/images/${IMAGE}/src.tmp -name Dockerfile))
            docker build -t xpfriend/$i ${DOCKER_FILE_DIR}
        fi
    fi
done
