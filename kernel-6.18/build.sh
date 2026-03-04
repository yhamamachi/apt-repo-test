#!/bin/bash

SCRIPT_DIR=$(cd `dirname $0` && pwd)
RAW_VERSION=${1:-6.18.6-2026-01-20}
VERSION=$(echo $RAW_VERSION | cut -d'-' -f1)

PKG=sparrow-hawk-kernel-6.18
wget -O ${PKG}_${VERSION}.orig.tar.gz \
    -c https://github.com/rcar-community/linux/archive/refs/heads/renesas-lts/v${RAW_VERSION}-sparrow-hawk.tar.gz

rm -rf ${PKG}-${VERSION}
mkdir ${PKG}-${VERSION}
tar xf ${PKG}_${VERSION}.orig.tar.gz --strip-components=1 -C ${PKG}-${VERSION}

cp -r ${SCRIPT_DIR}/debian -t ${PKG}-${VERSION}

docker run --rm -it --platform linux/amd64 \
    -v ${SCRIPT_DIR}:/build:Z -u $(id -u):$(id -g) \
    -w /build/${PKG}-${VERSION} \
    debian-amd64-builder \
    dpkg-buildpackage -us -uc -a arm64

