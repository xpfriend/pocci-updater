#!/bin/bash
set -e

BASE_DIR=$(cd $(dirname $0); pwd)
source ${BASE_DIR}/util.sh

EXIT_CODE=0
for i in `find ${BASE_DIR} -name src.tmp`; do
    cd $i
    NAME=`echo $i | sed -e "s|${BASE_DIR}/||" -e "s|/src.tmp||"`

    if [ `git status --porcelain |wc -l` -gt 0 ]; then
        echo " ${NAME} (git status)"
        git status --porcelain | sed "s/^/    /g"
        EXIT_CODE=1
    fi

    if [ `git branch | grep wip | wc -l` -gt 0 ]; then
        echo " ${NAME} (git branch)"
        git branch | sed "s/^/    /g"
        EXIT_CODE=1
    fi
done

exit ${EXIT_CODE}
