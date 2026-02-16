#!/bin/bash -eu

SCRIPT_DIR=$(cd `dirname $0` && pwd)
cd ${SCRIPT_DIR}

docker build -t debian-image-builder .
docker run --rm --cap-add SYS_ADMIN --security-opt seccomp=unconfined --security-opt apparmor=unconfined \
    -v $(pwd):/work debian-image-builder ./build_debian_for_sparrow-hawk.sh $@

