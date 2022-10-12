#!/usr/bin/env bash
set -e

export SHORT_SHA=${SHORT_SHA:-"head"}
export BRANCH_NAME=${BRANCH_NAME:-"local"}
export PROJECT_ID=${PROJECT_ID:-"teknoir"}
export ARCH_LIST=${ARCH_LIST:-"linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6"}

docker run --privileged --name mybuilderpod gcr.io/teknoir/binfmt-qemu:v0.8-v7.0.0 || true
docker buildx create --name mybuilder --use
docker buildx inspect --bootstrap

build(){
  docker buildx build \
    --progress=plain \
    --platform=${ARCH_LIST} \
    --label "git-commit=${SHORT_SHA}" \
    --push \
    -t gcr.io/${PROJECT_ID}/teknoir-app-cpp:${1} \
    .
}

build ${BRANCH_NAME}-${SHORT_SHA}

if [ ${BRANCH_NAME} == 'main' ]; then
  build latest
fi

docker buildx stop mybuilder || true
docker buildx rm mybuilder || true
docker rm -f mybuilderpod || true
