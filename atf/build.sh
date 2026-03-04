#!/bin/bash

SCRIPT_DIR=$(cd `dirname $0` && pwd)
VERSION=${1:-2.14.0}
PKG=sparrow-hawk-arm-trusted-firmware
wget -O ${PKG}_${VERSION}.orig.tar.gz \
    -c https://github.com/ARM-software/arm-trusted-firmware/archive/refs/tags/v${VERSION}.tar.gz 

rm -rf ${PKG}-${VERSION}
mkdir ${PKG}-${VERSION}
tar xf ${PKG}_${VERSION}.orig.tar.gz --strip-components=1 -C ${PKG}-${VERSION}
cp -r ${SCRIPT_DIR}/debian -t ${PKG}-${VERSION}

docker run --rm -it --platform linux/amd64 \
    -v ${SCRIPT_DIR}:/build:Z -u $(id -u):$(id -g) \
    -w /build/${PKG}-${VERSION} \
    debian-amd64-builder \
    dpkg-buildpackage -us -uc -a arm64

