#!/bin/bash -eu

SCRIPT_DIR=$(cd `dirname $0` && pwd)
cd ${SCRIPT_DIR}

docker build -t debian-image-builder .
docker run --rm -v $(pwd):/work debian-image-builder ./build_debian_12_for_sparrow-hawk.sh

