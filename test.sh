#!/bin/sh

export DOCKER_SCAN_SUGGEST=false

if [ -f .env ]; then
  export $(cat .env | sed 's/#.*//g' | xargs)
fi

docker build . -t myers/drone-kubectl-buildkit

echo "\n## TEST ##\n"

docker run --rm \
    -e PLUGIN_KUBERNETES_SERVER=$PLUGIN_KUBERNETES_SERVER \
    -e PLUGIN_KUBERNETES_TOKEN=$PLUGIN_KUBERNETES_TOKEN \
    -e PLUGIN_KUBERNETES_CERT=$PLUGIN_KUBERNETES_CERT \
    -e PLUGIN_DOCKERFILE=/drone/Dockerfile.test \
    -e PLUGIN_REPO=registry.monoloco.net/foo/bar \
    -v $(pwd):/drone \
    -w /drone \
    myers/drone-kubectl-buildkit:latest

