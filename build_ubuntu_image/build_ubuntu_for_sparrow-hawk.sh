#!/bin/bash -eu

#################################
# Configuable parameter         #
#################################
HOSTNAME=sparrow-hawk
USERNAME=rcar # Default password is same as USERNAME
EXTRA_IMAGE_SIZE=1000 # MiB
ADDITIONAL_PACKAGE=""
VARIANT=debootstrap # minbase # default=debootstrap

# For X11 with Gnome/LXQt
DESKTOP_PKG=""
#DESKTOP_PKG="gnome"
#DESKTOP_PKG="lxqt"

#################################
# Fixed parameter               #
#################################
DEVICE=sparrow-hawk # Currently, it doesn't support to change device.
GH_REPO="rcar-community/kernel-apt-repository"
REPO_BRANCH=apt-repo
EXTRA_APT_REPO="\
deb [trusted=yes] https://yhamamachi.github.io/apt-repo/ bookworm main \
"
ARCH=arm64
SCRIPT_DIR=$(cd `dirname $0` && pwd)
CHROOT_DIR=${SCRIPT_DIR}/rootfs
NET_DEV=end0
USE_LOCAL_DEB="no"

DHCP_CONF="
[Match]
Name=${NET_DEV}
[Network]
DHCP=ipv4
"
BASE_PKG=" \
    systemd dbus net-tools iproute2 \
    sudo passwd login adduser tzdata locales \
    vim net-tools ssh tzdata rsyslog udev wget \
    kmod nano systemd-resolved systemd-timesyncd \
"
UTIL_PKG=" \
    pciutils usbutils alsa-utils i2c-tools can-utils psmisc \
    unzip curl git htop parted \
    python3 python3-pip python3-venv python3-dev python3-libgpiod \
"
PKG_LIST=" \
    ${BASE_PKG} \
    ${UTIL_PKG} \
    ${DESKTOP_PKG} \
    ${ADDITIONAL_PACKAGE} \
"

#################################
# Function                      #
#################################
Usage () {
    echo "Usage:"
    echo "    $0 <DEBIAN_VERSION> [OPTIONS]"
    echo "DEBIAN_VERSION: Only major version(ex. 13)"
    echo "OPTIONS:"
    echo "    -h | --help:          Show this help"
    echo "    -l | --use-local-deb: Use local deb package instead of kernel-apt-repo(For development)"
    exit
}

Get_codename_from_version () {
    VERSION=$1
    if [[ $VERSION == "24.04" ]]; then
        echo noble
    fi
    curl -s https://debian.pages.debian.net/distro-info-data/debian.csv \
        | grep ^${VERSION}, | cut -d',' -f3
}

#################################
# Main process                  #
#################################

# Check version and codename
DEBIAN_VER=${1:-24.04}
CODENAME=$( Get_codename_from_version ${DEBIAN_VER} )
IMAGE_NAME=${DEVICE}-debian-${DEBIAN_VER}-based-bsp.img
if [[ $CODENAME == "" ]]; then
    Usage; exit -1
fi
echo $CODENAME

for arg in $@; do
    if [[ "$arg" == "-l" || "$arg" == "--use-local-deb" ]]; then
        USE_LOCAL_DEB="yes"
    elif [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
        Usage; exit;
    fi
done

# root privilege is needed for this script
if [ "`whoami`" != "root" ]; then
    echo "Error: Root privilege is needed. Try again with sudo or root user."
    exit -1
fi

if [[ "${#DEBIAN_VER}" == "2" ]]; then
echo "Download gpg key for debian repository to Host PC"
    wget -c -q --directory-prefix /etc/apt/trusted.gpg.d/ https://ftp-master.debian.org/keys/archive-key-${DEBIAN_VER}.asc
    wget -c -q --directory-prefix /etc/apt/trusted.gpg.d/ https://ftp-master.debian.org/keys/archive-key-${DEBIAN_VER}-security.asc
fi

echo "Run mmdebstrap to make initial rootfs"
rm -rf ${CHROOT_DIR}
INSTALL_KERNEL_PACKAGE="apt-get install -y sparrow-hawk-bsp"
mmdebstrap --variant=$VARIANT --arch=$ARCH \
    --include="ca-certificates ${PKG_LIST}" $CODENAME ${CHROOT_DIR} \
    --components="main restricted universe multiverse" https://ports.ubuntu.com/ubuntu-ports \
    \
    --customize-hook="echo \"${DHCP_CONF}\" > ${CHROOT_DIR}/etc/systemd/network/01-${NET_DEV}.network" \
    --customize-hook="echo ${HOSTNAME} > ${CHROOT_DIR}/etc/hostname" \
    --customize-hook="echo 127.0.0.1 localhost > ${CHROOT_DIR}/etc/hosts" \
    --customize-hook="echo 127.0.1.1 ${HOSTNAME} >> ${CHROOT_DIR}/etc/hosts" \
    --customize-hook="chroot ${CHROOT_DIR} addgroup gpio" \
    --customize-hook="chroot ${CHROOT_DIR} useradd -m -s /bin/bash -G sudo,audio,video,i2c,gpio,dialout ${USERNAME}" \
    --customize-hook="chroot ${CHROOT_DIR} sh -c 'echo ${USERNAME}:${USERNAME} | chpasswd'" \
    --customize-hook="echo \"${USERNAME}   ALL=(ALL) NOPASSWD:ALL\" >> ${CHROOT_DIR}/etc/sudoers" \
    --customize-hook="echo \"$EXTRA_APT_REPO\" | tee ${CHROOT_DIR}/etc/apt/sources.list.d/kernel-repo.list > /dev/null" \
    --customize-hook="chroot ${CHROOT_DIR} rm /etc/resolv.conf" \
    --customize-hook="echo nameserver 1.1.1.1 >  ${CHROOT_DIR}/etc/resolv.conf" \
    --customize-hook="echo nameserver 8.8.8.8 >> ${CHROOT_DIR}/etc/resolv.conf" \
    --customize-hook="chroot ${CHROOT_DIR} apt-get update" \
    --customize-hook="chroot ${CHROOT_DIR} ${INSTALL_KERNEL_PACKAGE}" \
    --customize-hook="chroot ${CHROOT_DIR} depmod -a \$(ls ${CHROOT_DIR}/lib/modules)" \
    \
    --customize-hook="chroot ${CHROOT_DIR} apt-get clean" \
    --customize-hook="chroot ${CHROOT_DIR} rm /etc/resolv.conf" \
    --customize-hook="chroot ${CHROOT_DIR} systemctl enable systemd-networkd" \
    --customize-hook="chroot ${CHROOT_DIR} systemctl enable systemd-resolved" \
    --customize-hook="chroot ${CHROOT_DIR} ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf" \
    || false

# Other setup
## Remount rootfs
echo '/dev/root  /  auto  defaults  1  1' >> ${CHROOT_DIR}/etc/fstab
## GPIO udev rule
echo 'SUBSYSTEM=="gpio", MODE="0660", GROUP="gpio"' > ${CHROOT_DIR}/etc/udev/rules.d/50-gpio.rules
## I2C application symlinl
for path in $(cd ${CHROOT_DIR} && ls usr/sbin/i2c* ); do ln -sf /${path} ${CHROOT_DIR}/usr/bin/; done

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

