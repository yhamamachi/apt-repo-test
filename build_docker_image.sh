#!/bin/bash

docker build --platform linux/arm64 -t debian-arm64-builder ./_dev/arm64
docker build --platform linux/amd64 -t debian-amd64-builder ./_dev/x64

