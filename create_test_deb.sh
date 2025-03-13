#!/bin/bash

PKG_VER="0.01-1+deb9u1"

SCRIPT_DIR=$(cd `dirname $0` && pwd)
WORK_DIR=${SCRIPT_DIR}/work

mkdir -p ${WORK_DIR}
cd ${WORK_DIR}
mkdir -p ./DEBIAN ./usr/bin
echo "#!/bin/sh\necho 'My Hello'" > ./usr/bin/myhello
chmod 755 ./usr/bin/myhello
md5sum ./usr/bin/myhello > ./DEBIAN/md5sums

DEBIAN_DIR_SIZE=$(du -k | grep ./DEBIAN | awk '{print $1}')
ALL_DIR_SIZE=$(du -k | tail -1 | awk '{print $1}')
DIR_SIZE=$(( $ALL_DIR_SIZE - $DEBIAN_DIR_SIZE ))

cat << EOS > DEBIAN/control
Package: myhello
Version: $PKG_VER
Architecture: amd64
Maintainer: $(git config user.name) <$(git config user.email)>
Installed-Size: ${DIR_SIZE}
Section: devel
Priority: optional
Homepage: http://www.example.com/
Description: example package of myhello
 Sample Program for deb package
 .
 This is a sample program.
EOS

cd $SCRIPT_DIR/
fakeroot dpkg-deb --build $WORK_DIR
cp -f $WORK_DIR/*.deb $SCRIPT_DIR
rm -rf $WORK_DIR

