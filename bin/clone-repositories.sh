#!/bin/bash
set -e

IMAGES_DIR=$(cd $(dirname $0)/images; pwd)

for i in `ls -d ${IMAGES_DIR}/*/ | sed 's|/$||g'`; do
    if [ -d $i/src.tmp ]; then
        rm -fr $i/src.tmp
    fi
    bash $i/clone.sh $i/src.tmp
done
