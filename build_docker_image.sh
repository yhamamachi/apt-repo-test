#!/bin/bash

docker build --platform linux/arm64 -t debian-12-arm64-builder ./_dev/arm64/debian12
docker build --platform linux/arm64 -t debian-13-arm64-builder ./_dev/arm64/debian13
docker build --platform linux/amd64 -t debian-amd64-builder ./_dev/x64

