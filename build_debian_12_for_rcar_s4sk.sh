#!/bin/bash -eu

EXTRA_APT_REPO="\
deb [arch=arm64 trusted=yes signed-by=/etc/apt/keyrings/kernel-repo.asc] https://raw.githubusercontent.com/yhamamachi/apt-repo-test/debian12 bookworm main \
"
GPG_KEY_URL=https://github.com/yhamamachi/apt-repo-test/raw/refs/heads/debian12/gpg

CODENAME=bookworm
DEBIAN_VER=12 # どちらかからもう片方を取得する仕組みのほうが良いか？
VARIANT=debootstrap # minbase # default=debootstrap
ARCH=arm64
EXTRA_IMAGE_SIZE=300 # MiB

SCRIPT_DIR=$(cd `dirname $0` && pwd)
CHROOT_DIR=${SCRIPT_DIR}/rootfs


echo "Download gpg key for debian repository to Host PC(sudo is used)"
sudo wget -c -q --directory-prefix /etc/apt/trusted.gpg.d/ https://ftp-master.debian.org/keys/archive-key-${DEBIAN_VER}.asc
sudo wget -c -q --directory-prefix /etc/apt/trusted.gpg.d/ https://ftp-master.debian.org/keys/archive-key-${DEBIAN_VER}-security.asc


echo "Run mmdebstrap to make initial rootfs"
for name in dev proc sys; do
    sudo umount ${CHROOT_DIR}/$name
done
sudo rm -rf ${CHROOT_DIR}
mmdebstrap --variant=$VARIANT --arch=$ARCH --include="ca-certificates" $CODENAME ${CHROOT_DIR}


echo "Use chroot to install additional packages"
for name in dev proc sys; do
    sudo mount -o bind /$name ${CHROOT_DIR}/$name
done

sudo curl -fsSL ${GPG_KEY_URL} -o ${CHROOT_DIR}/etc/apt/keyrings/kernel-repo.asc
echo "$EXTRA_APT_REPO" | sudo tee ${CHROOT_DIR}/etc/apt/sources.list.d/kernel.list > /dev/null
sudo chroot ${CHROOT_DIR} sh -c "
    export DEBIAN_FRONTEND=noninteractive;
    apt-get update;
    apt-get install kernel* -y;
"
for name in dev proc sys; do
    sudo umount ${CHROOT_DIR}/$name
done


echo "Make flashable image from rootfs"
USED_SIZE=$(sudo du --max-depth=1 ./rootfs | tail -1 | awk '{print int($1/1000)}')
IMAGE_SIZE=$(( $USED_SIZE + $EXTRA_IMAGE_SIZE ))
dd if=/dev/zero of=debian.img bs=1M count=${IMAGE_SIZE}
LOOP_DEV=$(sudo losetup -f)
sudo losetup ${LOOP_DEV} debian.img
sudo parted ${LOOP_DEV}  mklabel msdos mkpart primary ext4 1MiB 100%
mkdir -p tmp
sudo mkfs.ext4 ${LOOP_DEV}p1
sudo mount ${LOOP_DEV}p1 ./tmp
sudo cp -a ${CHROOT_DIR}/* -t ./tmp && sync
sudo umount ./tmp
sudo losetup -d ${LOOP_DEV}
gzip -k ./debian.img


echo "Cleanup"
# sudo rm -rf ${CHROOT_DIR} tmp


echo "Finished"


