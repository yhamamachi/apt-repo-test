#!/bin/bash

VERSION=${1:-1.0.0}
PKG=sparrow-hawk-bsp

rm -rf ${PKG}-${VERSION}
mkdir ${PKG}-${VERSION}
cd ${PKG}-${VERSION}

cp -r ../debian ./
dpkg-buildpackage -us -uc

