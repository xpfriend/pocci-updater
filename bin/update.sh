#!/bin/bash
set -e

BASE_DIR=$(cd $(dirname $0); pwd)
LOG_DIR=${BASE_DIR}/log

execute() {
    LOG_FILE=${LOG_DIR}/$1.log
    echo "### $1"
    ./$1.sh > ${LOG_FILE} 2>&1

    if [ "$2" = "print_log" ]; then
        cat ${LOG_FILE}
        echo ""
    fi
}

on_exit() {
    if [ "$?" -ne 0 ]; then
        tail -100 ${LOG_FILE}
        echo ""
        if [ `wc -l ${LOG_FILE} | cut -d' ' -f1` -gt 100 ]; then
            echo "See ${LOG_FILE}"
            echo ""
        fi
        echo "Error!"
    fi
}

cd ${BASE_DIR}
./check-wip.sh

if [ -d ${LOG_DIR} ]; then
    rm -fr ${LOG_DIR}
fi
mkdir ${LOG_DIR}

if [ -f ${BASE_DIR}/pocci/src.tmp/test/clean-containers.sh ]; then
    ${BASE_DIR}/pocci/src.tmp/test/clean-containers.sh
fi

trap "on_exit" EXIT
execute update-images print_log
execute build-images
execute build-images-on-docker-hub
execute update-pocci print_log
execute check-broken-links print_log
execute pull-new-images
execute test-pocci
execute release-pocci
echo ""
echo "Done."
