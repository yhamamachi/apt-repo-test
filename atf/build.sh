#!/bin/bash

VERSION=$1
PKG=sparrow-hawk-arm-trusted-firmware
wget -O ${PKG}_${VERSION}.orig.tar.gz \
    -c https://github.com/ARM-software/arm-trusted-firmware/archive/refs/tags/v${VERSION}.tar.gz 

rm -rf ${PKG}-${VERSION}
mkdir ${PKG}-${VERSION}
tar xf ${PKG}_${VERSION}.orig.tar.gz --strip-components=1 -C ${PKG}-${VERSION}
cd ${PKG}-${VERSION}

cp -r ../debian .
dpkg-buildpackage -us -uc

