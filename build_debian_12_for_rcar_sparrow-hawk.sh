#!/bin/bash -eu

#################################
# Configuable parameter         #
#################################
DEVICE=sparrow-hawk # Currently, it doesn't support to change device.
USERNAME=rcar
HOSTNAME=${DEVICE}
EXTRA_IMAGE_SIZE=3000 # MiB

EXTRA_APT_REPO="\
deb [arch=arm64 trusted=yes signed-by=/etc/apt/keyrings/kernel-repo.asc] https://raw.githubusercontent.com/yhamamachi/apt-repo-test/debian12 bookworm sparrow-hawk \
"
#EXTRA_APT_REPO="\
#deb [arch=arm64 trusted=yes signed-by=/etc/apt/keyrings/kernel-repo.asc] https://raw.githubusercontent.com/yhamamachi/apt-repo-test/debian12-dev bookworm sparrow-hawk \
#"
GPG_KEY_URL=https://github.com/yhamamachi/apt-repo-test/raw/refs/heads/debian12/gpg

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

echo "Download gpg key for debian repository to Host PC(sudo is used)"
sudo wget -c -q --directory-prefix /etc/apt/trusted.gpg.d/ https://ftp-master.debian.org/keys/archive-key-${DEBIAN_VER}.asc
sudo wget -c -q --directory-prefix /etc/apt/trusted.gpg.d/ https://ftp-master.debian.org/keys/archive-key-${DEBIAN_VER}-security.asc


echo "Run mmdebstrap to make initial rootfs"
for name in dev proc sys; do
    sudo umount ${CHROOT_DIR}/$name || true
done
sudo rm -rf ${CHROOT_DIR}
mmdebstrap --variant=$VARIANT --arch=$ARCH --include="ca-certificates" $CODENAME ${CHROOT_DIR}


echo "Use chroot to install additional packages"
for name in dev proc sys; do
    sudo mount -o bind /$name ${CHROOT_DIR}/$name
done
curl -fsSL ${GPG_KEY_URL} | sudo gpg --dearmor -o ${CHROOT_DIR}/etc/apt/keyrings/kernel-repo.asc
echo "$EXTRA_APT_REPO" | sudo tee ${CHROOT_DIR}/etc/apt/sources.list.d/kernel-repo.list > /dev/null

# For X11 with Gnome/LXQt
DESKTOP_PKG=""
#DESKTOP_PKG="gnome"
#DESKTOP_PKG="lxqt"

sudo chroot ${CHROOT_DIR} sh -c "
    export DEBIAN_FRONTEND=noninteractive \
    && echo nameserver 1.1.1.1 >> /etc/resolve.conf \
    && echo nameserver 8.8.8.8 >> /etc/resolve.conf \
    && apt-get update \
    && apt-get install -y kernel* linux-fitimage \
        systemd dbus net-tools iproute2 pciutils usbutils \
        sudo passwd login adduser tzdata locales alsa-utils \
        vim net-tools ssh tzdata rsyslog udev wget \
        unzip curl kmod git python3-pip nano \
        ${DESKTOP_PKG} \
        systemd-resolved systemd-timesyncd \
    && echo \"${DHCP_CONF}\" > /etc/systemd/network/01-${NET_DEV}.network \
    && useradd -m -s /bin/bash -G sudo ${USERNAME} \
    && echo ${USERNAME}:${USERNAME} | chpasswd \
    && echo \"${USERNAME}   ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers \
    && echo ${HOSTNAME} > /etc/hostname \
    && systemctl enable systemd-networkd \
    && systemctl enable systemd-resolved \
    && rm /etc/resolv.conf \
    && ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf \
    && echo 127.0.0.1 localhost > /etc/hosts \
    && echo 127.0.1.1 ${HOSTNAME} >> /etc/hosts \
    && echo '#!/bin/sh' > /etc/rc.local \
    && echo '/sbin/insmod /lib/modules/\$(uname -r)/kernel/drivers/pci/controller/dwc/pcie-rcar-gen4.ko & ' >> /etc/rc.local \
    && echo 'exit 0' >> /etc/rc.local \
    && chmod +x /etc/rc.local \
    && depmod -a \`ls /lib/modules\` \
    && apt clean \
    && exit \
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
sudo parted ${LOOP_DEV} mklabel msdos mkpart primary ext4 1MiB 100%
mkdir -p tmp
sudo mkfs.ext4 ${LOOP_DEV}p1
sudo mount ${LOOP_DEV}p1 ./tmp
sudo cp -a ${CHROOT_DIR}/* -t ./tmp && sync
sudo umount ./tmp
sudo losetup -d ${LOOP_DEV}
gzip -fk ./debian.img


echo "Cleanup"
sudo rm -rf ${CHROOT_DIR} tmp

echo "Finished"


