#!/bin/bash

SCRIPT_DIR=$(cd `dirname $0` && pwd)
COMMIT=f4c3dee21770b9b8817c80265b9f81eda1833731
VERSION=${1:-0.6.0}
PKG=sparrow-hawk-libcamera

cd ${SCRIPT_DIR}
git clone https://git.libcamera.org/libcamera/libcamera.git
cd libcamera
git fetch
git archive ${COMMIT} -o ../${PKG}_${VERSION}.orig.tar.gz

cd ${SCRIPT_DIR}
rm -rf ${PKG}-${VERSION}
mkdir ${PKG}-${VERSION}
tar xf ${PKG}_${VERSION}.orig.tar.gz --strip-components=0 -C ${PKG}-${VERSION}

cp -r ${SCRIPT_DIR}/debian -t ${PKG}-${VERSION}

docker run --rm -it --platform linux/arm64 \
    -v ${SCRIPT_DIR}:/build:Z -u $(id -u):$(id -g) \
    -w /build/${PKG}-${VERSION} \
    debian-arm64-builder \
    dpkg-buildpackage -us -uc -a arm64

