#!/bin/bash -eu

docker build -t debian-image-builder .
docker run --rm -v $(pwd):/work debian-image-builder ./build_debian_12_for_sparrow-hawk.sh

