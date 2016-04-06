#!/bin/bash
set -e

BASE_DIR=$(cd $(dirname $0); pwd)
POCCI_BASE_DIR=${BASE_DIR}/pocci/src.tmp

source ${BASE_DIR}/util.sh

cd ${POCCI_BASE_DIR}
if [ `get_number_of_diff_lines` -eq 0 ]; then
    exit
fi

if [ `git log --oneline master..wip | wc -l` -gt 1 ]; then
    echo "Too many commits"
    exit 1
fi

git checkout master
git merge wip
git branch -d wip

CURRENT_VERSION=`git describe --tags --abbrev=0 | tr -d v`
NEXT_VERSION=`get_next_version ${CURRENT_VERSION} p`
git tag "v${NEXT_VERSION}"
git push origin master
git push origin "v${TAG}"
