#!/usr/bin/env bash

set -euo pipefail

set -x

PLUGIN_NAMESPACE=${PLUGIN_NAMESPACE:-default}
PLUGIN_KUBERNETES_USER=${PLUGIN_KUBERNETES_USER:-default}
REGISTRY=${PLUGIN_REGISTRY:-docker.io}

if [ ! -z ${PLUGIN_KUBERNETES_TOKEN+x} ]; then
  KUBERNETES_TOKEN=$PLUGIN_KUBERNETES_TOKEN
fi

if [ ! -z ${PLUGIN_KUBERNETES_SERVER+x} ]; then
  KUBERNETES_SERVER=$PLUGIN_KUBERNETES_SERVER
fi

if [ ! -z ${PLUGIN_KUBERNETES_CERT+x} ]; then
  KUBERNETES_CERT=${PLUGIN_KUBERNETES_CERT}
fi

kubectl config set-credentials default --token=${KUBERNETES_TOKEN}
if [ ! -z ${KUBERNETES_CERT+x} ]; then
  mkdir -p ~/.kube
  echo ${KUBERNETES_CERT} | base64 -d > /root/.kube/ca.crt
  kubectl config set-cluster default --server=${KUBERNETES_SERVER} --certificate-authority=/root/.kube/ca.crt
else
  echo "WARNING: Using insecure connection to cluster"
  kubectl config set-cluster default --server=${KUBERNETES_SERVER} --insecure-skip-tls-verify=true
fi

kubectl config set-context default --cluster=default --user=${PLUGIN_KUBERNETES_USER}
kubectl config use-context default

DOCKERFILE=${PLUGIN_DOCKERFILE:-Dockerfile}
CONTEXT=${PLUGIN_CONTEXT:-$PWD}
LOG=${PLUGIN_LOG:-info}
EXTRA_OPTS=""

if [[ -n "${PLUGIN_TARGET:-}" ]]; then
    TARGET="--target=${PLUGIN_TARGET}"
fi

if [ -n "${PLUGIN_BUILD_ARGS:-}" ]; then
    BUILD_ARGS=$(echo "${PLUGIN_BUILD_ARGS}" | tr ',' '\n' | while read build_arg; do echo "--build-arg ${build_arg}"; done)
fi
if [ -n "${PLUGIN_BUILD_ARGS_FROM_ENV:-}" ]; then
    BUILD_ARGS_FROM_ENV=$(echo "${PLUGIN_BUILD_ARGS_FROM_ENV}" | tr ',' '\n' | while read build_arg; do echo "--build-arg ${build_arg}=$(eval "echo \$$build_arg")"; done)
fi
# auto_tag, if set auto_tag: true, auto generate .tags file
# support format Major.Minor.Release or start with `v`
# docker tags: Major, Major.Minor, Major.Minor.Release and latest
if [[ "${PLUGIN_AUTO_TAG:-}" == "true" ]]; then
    TAG=$(echo "${DRONE_TAG:-}" |sed 's/^v//g')
    part=$(echo "${TAG}" |tr '.' '\n' |wc -l)
    # expect number
    echo ${TAG} |grep -E "[a-z-]" &>/dev/null && isNum=1 || isNum=0
    if [ ! -n "${TAG:-}" ];then
        echo "latest" > .tags
    elif [ ${isNum} -eq 1 -o ${part} -gt 3 ];then
        echo "${TAG},latest" > .tags
    else
        major=$(echo "${TAG}" |awk -F'.' '{print $1}')
        minor=$(echo "${TAG}" |awk -F'.' '{print $2}')
        release=$(echo "${TAG}" |awk -F'.' '{print $3}')
    
        major=${major:-0}
        minor=${minor:-0}
        release=${release:-0}
    
        echo "${major},${major}.${minor},${major}.${minor}.${release},latest" > .tags
    fi  
fi
if [ -n "${PLUGIN_TAGS:-}" ]; then
    DESTINATIONS=$(echo "${PLUGIN_TAGS}" | tr ',' '\n' | while read tag; do echo "--tag ${REGISTRY}/${PLUGIN_REPO}:${tag} "; done)
elif [ -f .tags ]; then
    DESTINATIONS=$(cat .tags| tr ',' '\n' | while read tag; do echo "--tag ${REGISTRY}/${PLUGIN_REPO}:${tag} "; done)
elif [ -n "${PLUGIN_REPO:-}" ]; then
    DESTINATIONS="--tag ${REGISTRY}/${PLUGIN_REPO}:latest"
else
    DESTINATIONS="--no-push"
    # Cache is not valid with --no-push
    CACHE=""
fi

# /kaniko/executor -v ${LOG} \
#     --context=${CONTEXT} \
#     --dockerfile=${DOCKERFILE} \
#     ${EXTRA_OPTS} \
#     ${DESTINATIONS} \
#     ${CACHE:-} \
#     ${CACHE_TTL:-} \
#     ${CACHE_REPO:-} \
#     ${TARGET:-} \
#     ${BUILD_ARGS:-} \
#     ${BUILD_ARGS_FROM_ENV:-}

kubectl build \
  --file ${DOCKERFILE} \
  ${BUILD_ARGS:-} \
  ${DESTINATIONS} \
  ${CONTEXT}