#!/bin/bash
set -e

SCRIPT_DIR=$(cd $(dirname $0); pwd)

cat ${SCRIPT_DIR}/src.tmp/test/docker-compose.yml | sed "s|xpfriend/pocci-account-center:latest|$1|" > ${SCRIPT_DIR}/docker-compose.yml.tmp

docker-compose -f ${SCRIPT_DIR}/docker-compose.yml.tmp up -d

trap "docker-compose -f ${SCRIPT_DIR}/docker-compose.yml.tmp kill && docker-compose -f ${SCRIPT_DIR}/docker-compose.yml.tmp rm -fv > /dev/null 2>&1" EXIT

for i in {1..60}; do
    set +e
    curl -s http://127.0.0.1:9898
    if [ $? -eq 0 ]; then
      set -e
      NODEJS_IMAGE=`docker images |grep workspace-nodejs | head -1 | awk '{printf "%s:%s",$1,$2}'`
      docker run --rm \
        --net pocciaccountcenter_default \
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

echo "pocci-account-center: timeout"
exit 2
