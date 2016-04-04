#!/bin/bash

if [ -n "`which sudo`" ]; then
    SUDO=sudo
fi

${SUDO} apt-get update

for i in ${PACKAGES}; do
    PACKAGE_NAME=`echo $i | cut -d: -f1`
    VAR_NAME=`echo $i | cut -d: -f2`
    CANDIDATE=`apt-cache policy ${PACKAGE_NAME} | grep Candidate | cut -d: -f2 | tr -d '[[:space:]]'`
    INSTALLED=`apt-cache policy ${PACKAGE_NAME} | grep Installed | cut -d: -f2 | tr -d '[[:space:]]'`
    if [ "${CANDIDATE}" != "${INSTALLED}" ]; then
        echo "---->${VAR_NAME}:${CANDIDATE}"
    fi
done
