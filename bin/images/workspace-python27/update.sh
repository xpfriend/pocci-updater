#!/bin/bash
set -e

IMAGE_NAME=workspace-python27
DOCKER_FILE=`dirname $0`/src.tmp/Dockerfile

register_workspace_image ${DOCKER_FILE} ${IMAGE_NAME}
