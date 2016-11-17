#!/bin/bash
set -e

SCRIPT_DIR=$(cd $(dirname $0); pwd)

TAIGA_FRONT_IMAGE="$1"
TAIGA_BACK_IMAGE="$2"
POSTGRESQL_VERSION=`docker images |grep sameersbn/postgresql | awk '{print $2}' | grep -v latest | sort -r | head -1`

if [ -z "${TAIGA_BACK_IMAGE}" ]; then
    TAIGA_BACK_VERSION=`cd ${SCRIPT_DIR}/../taiga-back/src.tmp && git describe --abbrev=1 --tags | sed s/v//`
    TAIGA_BACK_IMAGE="xpfriend/taiga-back:${TAIGA_BACK_VERSION}"
fi

source ${SCRIPT_DIR}/docker-compose.yml.template > ${SCRIPT_DIR}/docker-compose.yml.tmp
docker-compose -f ${SCRIPT_DIR}/docker-compose.yml.tmp up -d

trap "docker-compose -f ${SCRIPT_DIR}/docker-compose.yml.tmp kill && docker-compose -f ${SCRIPT_DIR}/docker-compose.yml.tmp rm -fv > /dev/null 2>&1" EXIT

for i in {1..60}; do
    set +e
    curl -s http://127.0.0.1:80
    if [ $? -eq 0 ]; then
      set -e
      NODEJS_IMAGE=`docker images |grep workspace-nodejs | head -1 | awk '{printf "%s:%s",$1,$2}'`
      docker run --rm \
        --net taigafront_default \
        -v ${SCRIPT_DIR}:/app \
        -v ${POCCI_DIR}/bin/js/node_modules:/nodelib \
        -e NODE_PATH=/nodelib \
        -w /tmp \
        ${NODEJS_IMAGE} \
        bash -c 'mkdir /tmp/config && node /app/verify.js'
      exit 0
    fi
    echo -n "."
    sleep 5
done

echo "Taiga server timeout"
exit 2
