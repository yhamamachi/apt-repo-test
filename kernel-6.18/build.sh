#!/bin/bash

SCRIPT_DIR=$(cd `dirname $0` && pwd)
RAW_VERSION=${1:-6.18.6-2026-01-20}
BRANCH=origin/renesas-lts/v${RAW_VERSION}-sparrow-hawk
VERSION=$(echo $RAW_VERSION | cut -d'-' -f1)
PKG=sparrow-hawk-kernel-6.18

cd ${SCRIPT_DIR}
git clone https://github.com/rcar-community/linux.git
cd linux
git fetch
git archive ${BRANCH} -o ../${PKG}_${VERSION}.orig.tar.gz


cd ${SCRIPT_DIR}
rm -rf ${PKG}-${VERSION}
mkdir ${PKG}-${VERSION}
tar xf ${PKG}_${VERSION}.orig.tar.gz --strip-components=0 -C ${PKG}-${VERSION}

cp -r ${SCRIPT_DIR}/debian -t ${PKG}-${VERSION}

docker run --rm -it --platform linux/amd64 \
    -v ${SCRIPT_DIR}:/build:Z -u $(id -u):$(id -g) \
    -w /build/${PKG}-${VERSION} \
    debian-amd64-builder \
    dpkg-buildpackage -us -uc -a arm64

