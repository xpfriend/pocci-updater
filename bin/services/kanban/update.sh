#!/bin/bash
set -eu

POCCI_DIR=$1
LATEST_VERSION=`curl -s https://api.github.com/repos/leanlabsio/kanban/releases/latest |grep tag_name |sed -E 's/.+"tag_name": *"(.+[^"])".*/\1/'`
sed "s/^KANBAN_VERSION=.*$/KANBAN_VERSION=${LATEST_VERSION}/g" -i ${POCCI_DIR}/template/services/core/kanban/create-config.sh
