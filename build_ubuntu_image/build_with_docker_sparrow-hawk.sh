#!/bin/bash -eu

SCRIPT_DIR=$(cd `dirname $0` && pwd)
cd ${SCRIPT_DIR}

docker build -t ubuntu-image-builder .
docker run --rm --cap-add SYS_ADMIN --security-opt seccomp=unconfined --security-opt apparmor=unconfined \
    -v $(pwd):/work ubuntu-image-builder ./build_ubuntu_for_sparrow-hawk.sh $@

