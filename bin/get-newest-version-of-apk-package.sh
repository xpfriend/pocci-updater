#!/bin/sh
set -e

if [ -n "`which sudo`" ]; then
    SUDO=sudo
fi

${SUDO} apk update

for i in ${PACKAGES}; do
    PACKAGE_NAME=`echo $i | cut -d: -f1`
    VAR_NAME=`echo $i | cut -d: -f2`
    VERSION=`${SUDO} apk search -x ${PACKAGE_NAME} | grep ${PACKAGE_NAME} | sed -E "s/${PACKAGE_NAME}-(.+)/\1/"`
    echo "---->${VAR_NAME}:${VERSION}"
done
