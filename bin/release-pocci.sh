#!/bin/bash
set -e

BASE_DIR=$(cd $(dirname $0); pwd)
POCCI_BASE_DIR=${BASE_DIR}/pocci/src.tmp

source ${BASE_DIR}/util.sh

cd ${POCCI_BASE_DIR}
if [ `git status --porcelain |wc -l` -gt 0 ]; then
    echo "Uncommitted changes:"
    git status --porcelain | sed "s/^/    /g"
    exit 1
fi

if [ `get_number_of_diff_lines` -eq 0 ]; then
    echo "Nothing to do"
    exit 0
fi

NUM_COMMITS=`git log --oneline master..wip | wc -l | sed 's/ //g'`
if [ "${NUM_COMMITS}" -gt 1 ]; then
    echo "Too many commits (${NUM_COMMITS})"
    exit 1
fi

git checkout master
git merge wip
git branch -d wip

CURRENT_VERSION=`git describe --tags --abbrev=0 | tr -d v`
NEXT_VERSION=`get_next_version ${CURRENT_VERSION} p`
git tag "v${NEXT_VERSION}"
git push origin master
git push origin "v${NEXT_VERSION}"
