#!/bin/bash
set -e

BASE_DIR=$(cd $(dirname $0); pwd)
POCCI_BASE_DIR=${BASE_DIR}/pocci/src.tmp

source ${BASE_DIR}/util.sh

cd ${POCCI_BASE_DIR}
if [ `get_number_of_diff_lines` -eq 0 ]; then
    exit
fi

cd ${POCCI_BASE_DIR}/test
./test-private.sh $1
