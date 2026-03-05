FROM --platform=linux/arm64 debian:trixie

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y \
    build-essential \
    devscripts \
    debhelper \
    fakeroot \
    dh-make \
    dpkg-dev \
    lintian \
    git \
    ca-certificates \
    pkg-config \
    cmake \
    meson \
    ninja-build \
    bc kmod cpio flex libncurses5-dev libelf-dev libssl-dev dwarves bison \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
