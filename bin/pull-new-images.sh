#!/bin/bash
set -e

BASE_DIR=$(cd $(dirname $0); pwd)
NEW_IMAGES=${BASE_DIR}/new-images.txt

for i in `cat ${NEW_IMAGES} | sort | uniq`; do
    NAME=`echo $i | cut -d: -f1`
    IMAGES=`docker images |grep ${NAME} |awk '{printf "%s:%s ",$1,$2}'`
    if [ -n "${IMAGES}" ]; then
        docker rmi ${IMAGES}
    fi
    docker pull $i
done

LATESTS=`docker images |grep latest |awk '{printf "%s:%s ",$1,$2}'`
if [ -n "${LATESTS}" ]; then
    docker rmi ${LATESTS}
fi
for i in `echo ${LATESTS}`; do
    docker pull $i
done
