#!/bin/bash

SCRIPT_DIR=$(cd `dirname $0` && pwd)
COMMIT=761a765901ab9e009f6503904276c62fcf5cbb9b
VERSION=1.0.0
PKG=qos-lib
DEBIAN_VER=""
# Check version and codename
while [[ $# -gt 0 ]]; do
    case "$1" in
        --version)
            DEBIAN_VER=$2
            shift ;;
        *) ;; # Ignore unknown option
    esac
    shift
done
if [[ "${DEBIAN_VER}" == "" ]];then
    echo "Error: Target debian version is not specified"
    echo " Ex.) $0 --version 13"
    exit -1
fi

cd ${SCRIPT_DIR}
git clone https://github.com/renesas-rcar/qos_lib
cd qos_lib
git fetch
git archive ${COMMIT} -o ../${PKG}_${VERSION}.orig.tar.gz

cd ${SCRIPT_DIR}
rm -rf ${PKG}-${VERSION}
mkdir ${PKG}-${VERSION}
tar xf ${PKG}_${VERSION}.orig.tar.gz --strip-components=0 -C ${PKG}-${VERSION}

cp -r ${SCRIPT_DIR}/debian -t ${PKG}-${VERSION}
sed -i ${PKG}-${VERSION}/debian/changelog \
    -e "s/\(${VERSION}-[0-9]*\)/\1+deb${DEBIAN_VER}/"

docker run --rm -it --platform linux/arm64 \
    -v ${SCRIPT_DIR}:/build:Z -u $(id -u):$(id -g) \
    -w /build/${PKG}-${VERSION} \
    debian-${DEBIAN_VER}-arm64-builder \
    dpkg-buildpackage -us -uc -a arm64

