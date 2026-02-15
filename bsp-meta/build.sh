#!/bin/bash

VERSION=$1
PKG=sparrow-hawk-bsp

rm -rf ${PKG}-${VERSION}
mkdir ${PKG}-${VERSION}
cd ${PKG}-${VERSION}

cp -r ../debian ./
dpkg-buildpackage -us -uc

