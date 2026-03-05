#!/bin/bash

SCRIPT_DIR=$(cd `dirname $0` && pwd)
VERSION=${1:-1.0.0}
PKG=sparrow-hawk-misc-config

rm -rf ${PKG}_${VERSION}.orig.tar.gz
tar czf ${PKG}_${VERSION}.orig.tar.gz src

rm -rf ${PKG}-${VERSION}
mkdir ${PKG}-${VERSION}
tar xf ${PKG}_${VERSION}.orig.tar.gz --strip-components=1 -C ${PKG}-${VERSION}
cd ${PKG}-${VERSION}

cp -r ../debian ./

docker run --rm -it --platform linux/amd64 \
    -v ${SCRIPT_DIR}:/build:Z -u $(id -u):$(id -g) \
    -w /build/${PKG}-${VERSION} \
    debian-amd64-builder \
    dpkg-buildpackage -us -uc



