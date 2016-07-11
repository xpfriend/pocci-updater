#!/bin/bash
set -e

export BASE_DIR=$(cd $(dirname $0); pwd)
export REGISTERED_IMAGES=${BASE_DIR}/registered-images.txt

source ${BASE_DIR}/get-token.sh

tag_exits() {
    IMAGE=$1
    TAG=$2
    INFO=`curl -s -S -H "Content-Type: application/json" https://registry.hub.docker.com/v2/repositories/xpfriend/${IMAGE}/tags/${TAG}/`
    if [ `echo "${INFO}" | grep "${TAG}" | wc -l` -gt 0 ]; then
        echo "yes"
    else
        echo "no"
    fi
}

get_image_with_tag() {
    grep $1 ${REGISTERED_IMAGES} | head -1 | tr -d "\r"
}

build_image() {
    IMAGE_WITH_TAG=`get_image_with_tag $1`
    if [ -z "${IMAGE_WITH_TAG}" ]; then
        return
    fi

    echo "Build: ${IMAGE_WITH_TAG}"
    IMAGE=`echo ${IMAGE_WITH_TAG} | cut -d: -f1`
    TAG=`echo ${IMAGE_WITH_TAG} | cut -d: -f2`

    if [ `tag_exits "${IMAGE}" "${TAG}"` = "no" ]; then
        TOKEN="$2"
        curl -s -S -H "Content-Type: application/json" --data '{"source_type": "Tag", "source_name": "v'${TAG}'"}' -X POST https://registry.hub.docker.com/u/xpfriend/${IMAGE}/trigger/${TOKEN}/
        echo ""
    fi
}

wait_for_build_completion() {
    IMAGE_WITH_TAG=`get_image_with_tag $1`
    if [ -z "${IMAGE_WITH_TAG}" ]; then
        return
    fi

    echo -n "Wait for build completion: ${IMAGE_WITH_TAG}"
    IMAGE=`echo ${IMAGE_WITH_TAG} | cut -d: -f1`
    TAG=`echo ${IMAGE_WITH_TAG} | cut -d: -f2`

    for i in {1..30}; do
        if [ `tag_exits "${IMAGE}" "${TAG}"` = "yes" ]; then
            echo ""
            return
        fi
        echo -n "."
        sleep 60
    done
    echo "Build timeout: ${IMAGE}:${TAG}"
    exit 1
}

build_image workspace-base ${WORKSPACE_BASE_TOKEN}
build_image jenkins ${JENKINS_TOKEN}
build_image fluentd ${FLUENTD_TOKEN}
build_image postfix ${POSTFIX_TOKEN}
build_image sonarqube ${SONARQUBE_TOKEN}

wait_for_build_completion workspace-base
build_image workspace-nodejs ${WORKSPACE_NODEJS_TOKEN}
build_image workspace-java ${WORKSPACE_JAVA_TOKEN}
build_image workspace-python27 ${WORKSPACE_PYTHON27_TOKEN}

wait_for_build_completion workspace-nodejs
build_image pocci-account-center ${POCCI_ACCOUNT_CENTER_TOKEN}

wait_for_build_completion jenkins
wait_for_build_completion fluentd
wait_for_build_completion postfix
wait_for_build_completion sonarqube
wait_for_build_completion java
wait_for_build_completion python27
wait_for_build_completion pocci-account-center
