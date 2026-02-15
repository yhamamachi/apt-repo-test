#!/bin/bash

VERSION=$1
PKG=sparrow-hawk-pcie-fw

rm -rf ${PKG}_${VERSION}.orig.tar.gz
tar czf ${PKG}_${VERSION}.orig.tar.gz bin

rm -rf ${PKG}-${VERSION}
mkdir ${PKG}-${VERSION}
tar xf ${PKG}_${VERSION}.orig.tar.gz --strip-components=1 -C ${PKG}-${VERSION}
cd ${PKG}-${VERSION}

cp -r ../debian ./
dpkg-buildpackage -us -uc

