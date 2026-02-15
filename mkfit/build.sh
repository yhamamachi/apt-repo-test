#!/bin/bash

VERSION=${1:-1.0.0}
PKG=sparrow-hawk-mkfit

rm -rf ${PKG}_${VERSION}.orig.tar.gz
tar czf ${PKG}_${VERSION}.orig.tar.gz src

rm -rf ${PKG}-${VERSION}
mkdir ${PKG}-${VERSION}
tar xf ${PKG}_${VERSION}.orig.tar.gz --strip-components=1 -C ${PKG}-${VERSION}
cd ${PKG}-${VERSION}

cp -r ../debian ./
dpkg-buildpackage -us -uc

