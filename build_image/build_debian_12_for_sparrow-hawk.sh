#!/bin/bash -eu

#################################
# Configuable parameter         #
#################################
DEVICE=sparrow-hawk # Currently, it doesn't support to change device.
IMAGE_NAME=${DEVICE}-debian-based-dist.img
HOSTNAME=${DEVICE}
USERNAME=rcar # Default password is same as USERNAME
EXTRA_IMAGE_SIZE=1000 # MiB

# For X11 with Gnome/LXQt
DESKTOP_PKG=""
#DESKTOP_PKG="gnome"
#DESKTOP_PKG="lxqt"

REPO_BRANCH=bookworm
EXTRA_APT_REPO="\
deb [arch=arm64 trusted=yes signed-by=/etc/apt/trusted.gpg.d/kernel-repo.asc] https://raw.githubusercontent.com/yhamamachi/apt-repo-test/${REPO_BRANCH} bookworm main \
"
GPG_KEY_URL=https://github.com/yhamamachi/apt-repo-test/raw/refs/heads/${REPO_BRANCH}/gpg

CODENAME=bookworm
DEBIAN_VER=12 # どちらかからもう片方を取得する仕組みのほうが良いか？
VARIANT=debootstrap # minbase # default=debootstrap
ARCH=arm64

SCRIPT_DIR=$(cd `dirname $0` && pwd)
CHROOT_DIR=${SCRIPT_DIR}/rootfs

NET_DEV=eth0
if [[ "$DEVICE" == "s4sk" ]]; then
    NET_DEV=tsn0
fi
if [[ "$DEVICE" == "sparrow-hawk" ]]; then
    NET_DEV=end0
fi
DHCP_CONF="
[Match]
Name=${NET_DEV}
[Network]
DHCP=ipv4
"
PKG_LIST="
systemd dbus net-tools iproute2 pciutils usbutils \
sudo passwd login adduser tzdata locales alsa-utils \
vim net-tools ssh tzdata rsyslog udev wget \
unzip curl kmod git python3-pip nano \
systemd-resolved systemd-timesyncd \
${DESKTOP_PKG} \
"
# root privilege is needed for this script
if [ "`whoami`" != "root" ]; then
    echo "Error: Root privilege is needed. Try again with sudo or root user."
    exit -1
fi

echo "Download gpg key for debian repository to Host PC"
 wget -c -q --directory-prefix /etc/apt/trusted.gpg.d/ https://ftp-master.debian.org/keys/archive-key-${DEBIAN_VER}.asc
 wget -c -q --directory-prefix /etc/apt/trusted.gpg.d/ https://ftp-master.debian.org/keys/archive-key-${DEBIAN_VER}-security.asc

echo "Run mmdebstrap to make initial rootfs"
rm -rf ${CHROOT_DIR}
mmdebstrap --variant=$VARIANT --arch=$ARCH \
    --include="ca-certificates ${PKG_LIST}" $CODENAME ${CHROOT_DIR} \
    \
    --customize-hook="echo \"${DHCP_CONF}\" > ${CHROOT_DIR}/etc/systemd/network/01-${NET_DEV}.network" \
    --customize-hook="echo ${HOSTNAME} > ${CHROOT_DIR}/etc/hostname" \
    --customize-hook="echo 127.0.0.1 localhost > ${CHROOT_DIR}/etc/hosts" \
    --customize-hook="echo 127.0.1.1 ${HOSTNAME} >> ${CHROOT_DIR}/etc/hosts" \
    --customize-hook="echo '#!/bin/sh' > ${CHROOT_DIR}/etc/rc.local" \
    --customize-hook="echo '/sbin/insmod /lib/modules/\$(uname -r)/kernel/drivers/pci/controller/dwc/pcie-rcar-gen4.ko & ' >> ${CHROOT_DIR}/etc/rc.local" \
    --customize-hook="echo 'exit 0' >> ${CHROOT_DIR}/etc/rc.local" \
    --customize-hook="chroot ${CHROOT_DIR} chmod +x /etc/rc.local" \
    --customize-hook="chroot ${CHROOT_DIR} useradd -m -s /bin/bash -G sudo ${USERNAME}" \
    --customize-hook="chroot ${CHROOT_DIR} sh -c 'echo ${USERNAME}:${USERNAME} | chpasswd'" \
    --customize-hook="echo \"${USERNAME}   ALL=(ALL) NOPASSWD:ALL\" >> ${CHROOT_DIR}/etc/sudoers" \
    --customize-hook="curl -fsSL ${GPG_KEY_URL} -o ${CHROOT_DIR}/etc/apt/trusted.gpg.d/kernel-repo.asc" \
    --customize-hook="echo \"$EXTRA_APT_REPO\" | tee ${CHROOT_DIR}/etc/apt/sources.list.d/kernel-repo.list > /dev/null" \
    --customize-hook="chroot ${CHROOT_DIR} rm /etc/resolv.conf" \
    --customize-hook="echo nameserver 1.1.1.1 >  ${CHROOT_DIR}/etc/resolv.conf" \
    --customize-hook="echo nameserver 8.8.8.8 >> ${CHROOT_DIR}/etc/resolv.conf" \
    --customize-hook="chroot ${CHROOT_DIR} apt-get update" \
    --customize-hook="chroot ${CHROOT_DIR} apt-get install -y kernel-* linux-fitimage" \
    --customize-hook="chroot ${CHROOT_DIR} depmod -a \$(ls ${CHROOT_DIR}/lib/modules)" \
    --customize-hook="chroot ${CHROOT_DIR} apt-get clean" \
    --customize-hook="chroot ${CHROOT_DIR} rm /etc/resolv.conf" \
    --customize-hook="chroot ${CHROOT_DIR} systemctl enable systemd-networkd" \
    --customize-hook="chroot ${CHROOT_DIR} systemctl enable systemd-resolved" \
    --customize-hook="chroot ${CHROOT_DIR} ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf" \

echo "Make flashable image from rootfs"
USED_SIZE=$(du --max-depth=1 ${CHROOT_DIR} | tail -1 | awk '{print int($1/1000)}')
IMAGE_SIZE=$(( $USED_SIZE + $EXTRA_IMAGE_SIZE ))
mkdir -p ./tmp

dd if=/dev/zero of=${IMAGE_NAME} bs=1M count=${IMAGE_SIZE}
parted ./${IMAGE_NAME} mklabel msdos mkpart primary ext4 1MiB 100%
SEEK=$(fdisk -l ${IMAGE_NAME} | grep img1 | awk '{print $2}')
SECTORS=$(fdisk -l ${IMAGE_NAME} | grep img1 | awk '{print $4}')
PART_SIZE_MB=$(( ${SECTORS} * 512 / 1024 / 1024))
dd if=/dev/zero of=rootfs.ext4 bs=512 count=${SECTORS}
mkfs.ext4 -L reformsdroot -d ${CHROOT_DIR} rootfs.ext4 ${PART_SIZE_MB}M
dd if=rootfs.ext4 of=${IMAGE_NAME} bs=512 seek=${SEEK} conv=notrunc
gzip -f ./${IMAGE_NAME}

echo "Cleanup"
rm -rf ${CHROOT_DIR} ./tmp rootfs.ext4

echo "Finished"

