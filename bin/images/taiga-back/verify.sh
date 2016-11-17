#!/bin/bash
set -e

SCRIPT_DIR=$(cd $(dirname $0); pwd)

TAIGA_FRONT_VERSION=`cd ${SCRIPT_DIR}/../taiga-front/src.tmp && git describe --abbrev=1 --tags | sed s/v//`
TAIGA_FRONT_IMAGE="xpfriend/taiga-front:${TAIGA_FRONT_VERSION}"
bash ${SCRIPT_DIR}/../taiga-front/verify.sh "${TAIGA_FRONT_IMAGE}" "$1"
