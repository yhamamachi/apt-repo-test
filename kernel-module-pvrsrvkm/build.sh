#!/bin/bash

SCRIPT_DIR=$(cd `dirname $` && pwd)
COMMIT=daf8608d920fbf1d179abab8a52cbc0f022c98a1
RAW_VERSION=${1:-6.18.6-2026-01-20}
VERSION=$(echo $RAW_VERSION | cut -d'-' -f1)
KERNEL_VERSION=$(echo $RAW_VERSION | sed 's/\.[0-9]*-.*//')
PKG=sparrow-hawk-kernel-module-pvrsrvkm

wget -c https://github.com/rcar-community/rcar-gfx/raw/${COMMIT}/gfxdrv/GSX_KM_V4H_SparrowHawk.tar.bz2
tar xf ./GSX_KM_V4H_SparrowHawk.tar.bz2
tar czf ${PKG}_${VERSION}.orig.tar.gz ./rogue_km
rm -rf ./rogue_km

rm -rf ${PKG}-${VERSION}
mkdir ${PKG}-${VERSION}
tar xf ${PKG}_${VERSION}.orig.tar.gz --strip-components=2 -C ${PKG}-${VERSION}

cp -r ${SCRIPT_DIR}/debian -t ${PKG}-${VERSION}

mkdir -p ${SCRIPT_DIR}/kernel

docker run --rm -it --platform linux/amd64 \
    -v ${SCRIPT_DIR}:/build:Z -u $(id -u):$(id -g) \
    -v ${SCRIPT_DIR}/../kernel-${KERNEL_VERSION}/sparrow-hawk-kernel-${KERNEL_VERSION}-${VERSION}:/build/kernel:Z \
    -w /build/${PKG}-${VERSION} \
    debian-amd64-builder \
    dpkg-buildpackage -us -uc -a arm64

