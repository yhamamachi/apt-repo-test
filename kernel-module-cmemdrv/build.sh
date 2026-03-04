#!/bin/bash

SCRIPT_DIR=$(cd `dirname $` && pwd)
COMMIT=e67f473cddb089f71abead8bf18f618d42f515da
RAW_VERSION=${1:-6.18.6-2026-01-20}
VERSION=$(echo $RAW_VERSION | cut -d'-' -f1)
KERNEL_VERSION=$(echo $RAW_VERSION | sed 's/\.[0-9]*-.*//')
PKG=sparrow-hawk-kernel-module-cmemdrv

wget -O ${PKG}_${VERSION}.orig.tar.gz \
    -c https://github.com/renesas-rcar/cmem/archive/${COMMIT}.tar.gz

rm -rf ${PKG}-${VERSION}
mkdir ${PKG}-${VERSION}
tar xf ${PKG}_${VERSION}.orig.tar.gz --strip-components=1 -C ${PKG}-${VERSION}

cp -r ${SCRIPT_DIR}/debian -t ${PKG}-${VERSION}

mkdir -p ${SCRIPT_DIR}/kernel

set -x 
docker run --rm -it --platform linux/arm64 \
    -v ${SCRIPT_DIR}:/build -u $(id -u):$(id -g) \
    -v ${SCRIPT_DIR}/../kernel-${KERNEL_VERSION}/sparrow-hawk-kernel-${KERNEL_VERSION}-${VERSION}:/build/kernel \
    -w /build/${PKG}-${VERSION} \
    debian-arm64-builder \
    dpkg-buildpackage -us -uc

