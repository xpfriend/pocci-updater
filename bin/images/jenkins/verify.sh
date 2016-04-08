#!/bin/bash
set -e

NAME=pocci_updater_jenkins_test
BASE_DIR=$(cd $(dirname $0); pwd)
PLUGINS_TXT_OLD=/tmp/${NAME}.old
PLUGINS_TXT_NEW=/tmp/${NAME}.new
PLUGINS_TXT_DIFF=/tmp/${NAME}.diff

cat ${BASE_DIR}/src.tmp/config/plugins.txt | cut -d: -f1 | sort > ${PLUGINS_TXT_OLD}

docker run -d -p 8080:8080 --name ${NAME} $1

trap "docker rm -v -f ${NAME} > /dev/null 2>&1; rm /tmp/${NAME}.*" EXIT

for i in {1..60}; do
    curl -s --compressed http://localhost:8080/pluginManager/installed | \
        sed -E -e 's/data-plugin-id="[^"]+"/\n\0\n/g' | grep data-plugin-id | \
        sed -E -e 's/data-plugin-id=//g' -e 's/"//g' | grep -v jenkins-core | \
        sort | uniq > ${PLUGINS_TXT_NEW}
    if [ `cat ${PLUGINS_TXT_NEW} | wc -l` -gt 0 ]; then
        diff ${PLUGINS_TXT_OLD} ${PLUGINS_TXT_NEW} | tee ${PLUGINS_TXT_DIFF}
        if [ `cat ${PLUGINS_TXT_DIFF} | wc -l` -gt 0 ]; then
          exit 1
        else
          exit 0
        fi
    fi
    echo -n "."
    sleep 2
done

echo "Jenkins server timeout"
exit 2
