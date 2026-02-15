#!/bin/bash

RAW_VERSION=${1:-6.18.6-2026-01-20}
VERSION=$(echo $RAW_VERSION | cut -d'-' -f1)

PKG=sparrow-hawk-kernel-6.18
wget -O ${PKG}_${VERSION}.orig.tar.gz \
    -c https://github.com/rcar-community/linux/archive/refs/heads/renesas-lts/v${RAW_VERSION}-sparrow-hawk.tar.gz

rm -rf ${PKG}-${VERSION}
mkdir ${PKG}-${VERSION}
tar xf ${PKG}_${VERSION}.orig.tar.gz --strip-components=1 -C ${PKG}-${VERSION}

cd ${PKG}-${VERSION}
cp -r ../debian .

dpkg-buildpackage -us -uc

