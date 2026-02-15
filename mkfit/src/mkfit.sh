#!/bin/bash

KERNEL_VERSION=$(strings /usr/lib/sparrow-hawk/Image | grep "Linux version" | head -1 | awk '{print $3}')
BUSYBOX_BIN_PATH=$(which busybox)

# Generate initramfs
INITRAMFS_DIR=$(mktemp -d)
mkdir -p $INITRAMFS_DIR/{bin,sbin,etc,lib,usr,var,proc,sys,mnt}
cp -a ${BUSYBOX_BIN_PATH} -t $INITRAMFS_DIR/bin/
pushd $INITRAMFS_DIR/bin/
./busybox --install ./
popd
mkdir -p $INITRAMFS_DIR/lib/modules/
cp -a /lib/modules/${KERNEL_VERSION} -t $INITRAMFS_DIR/lib/modules/
cp -a /usr/lib/sparrow-hawk/init -t $INITRAMFS_DIR/
mkdir -p $INITRAMFS_DIR/lib/firmware
cp -a /usr/lib/firmware/* -t $INITRAMFS_DIR/lib/firmware

# tree $INITRAMFS_DIR/

pushd $INITRAMFS_DIR
find . | cpio -H newc -o | gzip > /usr/lib/sparrow-hawk/uInitramfs.cpio.gz
popd

# Generate fitImage
cd /usr/lib/sparrow-hawk/
cp -f /boot/fitImage{,.old} || true
mkimage -f fit-image.its /boot/fitImage

