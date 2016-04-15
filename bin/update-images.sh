#!/bin/bash
set -e

export BASE_DIR=$(cd $(dirname $0); pwd)
export REGISTERED_IMAGES=${BASE_DIR}/registered-images.txt
export UPDATED_IMAGES=${BASE_DIR}/updated-images.txt

source ${BASE_DIR}/util.sh

get_from_version() {
    grep "^xpfriend/$1" ${UPDATED_IMAGES} | head -1 | cut -d' ' -f3 | cut -d: -f2
}

register_image() {
    echo "$1:$2" >> ${REGISTERED_IMAGES}
}

get_registered_image() {
    grep "^$1" ${REGISTERED_IMAGES} | head -1
}

get_image_name_with_tag() {
    docker images | grep "xpfriend/$1" | head -1 | awk '{printf "%s:%s",$1,$2}'
}

get_newest_version_of_apt_package() {
    cp ${BASE_DIR}/get-newest-version-of-apt-package.sh checkupdate.tmp
    IMAGE=`get_image_name_with_tag $1`
    docker run --rm -e PACKAGES="$2" -v ${PWD}:/app ${IMAGE} bash /app/checkupdate.tmp | grep '\---->' | sed 's/---->//g'
}

replace_version_env() {
    if [ -n "$2" ]; then
        for i in $2; do
            NAME=`echo "$i" | cut -d: -f1`
            VERSION=`echo "$i" | cut -d: -f2`
            sed -i "s/^ENV ${NAME}.*/ENV ${NAME} ${VERSION}/" $1
        done
    fi
}

replace_from_version() {
    if [ -n "$2" ]; then
        sed -i "s/^\(FROM.*\):.*$/\1:$2/" $1
    fi
}

get_registered_base_image_version() {
    REGISTERED_BASE_IMAGE=`get_registered_image workspace-base`
    if [ -n "${REGISTERED_BASE_IMAGE}" ]; then
        echo "${REGISTERED_BASE_IMAGE}" | cut -d: -f2
    fi
}

register_workspace_image() {
    FROM_VERSION=`get_registered_base_image_version`

    replace_from_version "$1" "${FROM_VERSION}"

    if [ `get_number_of_updated_files $1` -gt 0 ]; then
        if [ -n "${FROM_VERSION}" ]; then
            NEXT_VERSION=${FROM_VERSION}
        else
            NEXT_VERSION=`get_next_version_of $2 p`
        fi
        register_image $2 ${NEXT_VERSION}
    fi
}

show_status() {
    for i in `cat ${REGISTERED_IMAGES}`; do
        echo "=============================="
        echo $i
        echo "------------------------------"
        IMAGE=`echo $i | cut -d: -f1`
        cd ${BASE_DIR}/images/${IMAGE}/src.tmp
        git --no-pager diff --unified=0
        cd ${BASE_DIR}
    done
}

print_target() {
    VERSION=`get_current_version $1`
    echo '"xpfriend/'$1:${VERSION}'"'$2
}

print_targets() {
    echo "["
    print_target workspace-base ","
    print_target workspace-java ","
    print_target workspace-nodejs ","
    print_target workspace-python27 ","
    print_target pocci-account-center ","
    print_target fluentd ","
    print_target jenkins ","
    print_target sonarqube
    echo "]"
}

export -f get_from_version
export -f register_image
export -f get_registered_image
export -f get_image_name_with_tag
export -f get_newest_version_of_apt_package
export -f replace_version_env
export -f replace_from_version
export -f get_registered_base_image_version
export -f register_workspace_image

${BASE_DIR}/clone-repositories.sh
print_targets > ./js/version.json
${BASE_DIR}/get-updated-images.sh from | tee ${UPDATED_IMAGES} && handle_error
> ${REGISTERED_IMAGES}

bash ${BASE_DIR}/images/workspace-base/update.sh
bash ${BASE_DIR}/images/workspace-java/update.sh
bash ${BASE_DIR}/images/workspace-nodejs/update.sh
bash ${BASE_DIR}/images/workspace-python27/update.sh
bash ${BASE_DIR}/images/pocci-account-center/update.sh
bash ${BASE_DIR}/images/fluentd/update.sh
bash ${BASE_DIR}/images/jenkins/update.sh
bash ${BASE_DIR}/images/sonarqube/update.sh

show_status
