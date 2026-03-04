FROM --platform=linux/amd64 debian:bookworm

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
    g++-aarch64-linux-gnu \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
