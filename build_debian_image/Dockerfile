FROM debian:bookworm
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    mmdebstrap curl gnupg parted dosfstools kmod sudo \
    systemd dbus net-tools iproute2 pciutils \
    e2fsprogs gzip wget qemu-user-static fdisk udev unzip

WORKDIR /work

