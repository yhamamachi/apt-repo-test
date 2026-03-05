#!/bin/bash

SCRIPT_DIR=$(cd `dirname $0` && pwd)
VERSION=${1:-2026.01}
PKG=sparrow-hawk-u-boot
#wget -O ${PKG}_${VERSION}.orig.tar.gz \
#    -c https://github.com/u-boot/u-boot/archive/refs/tags/v${VERSION}.tar.gz 

rm -rf ${PKG}-${VERSION}
mkdir ${PKG}-${VERSION}
tar xf ${PKG}_${VERSION}.orig.tar.gz --strip-components=1 -C ${PKG}-${VERSION}
cp -r ${SCRIPT_DIR}/debian -t ${PKG}-${VERSION}

docker run --rm -it --platform linux/amd64 \
    -v ${SCRIPT_DIR}:/build:Z -u $(id -u):$(id -g) \
    -w /build/${PKG}-${VERSION} \
    debian-amd64-builder \
    dpkg-buildpackage -us -uc -a arm64

