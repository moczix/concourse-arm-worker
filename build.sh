#!/bin/bash

set -x
set -e

docker build --build-arg http_proxy --build-arg https_proxy \
  -t registry-image . \
  -f Dockerfile-registry-image
docker create --name registry-image registry-image
mkdir -p resource-types/registry-image
docker export registry-image | gzip \
  > resource-types/registry-image/rootfs.tgz
docker rm -v registry-image



docker build --build-arg http_proxy --build-arg https_proxy \
  -t git-resource . \
  -f Dockerfile-git-resource
docker create --name git-resource git-resource
mkdir -p resource-types/git-resource
docker export git-resource | gzip \
  > resource-types/git-resource/rootfs.tgz
docker rm -v git-resource
  
  
  
docker build -t concourse-arm-worker:local-1.2 .
