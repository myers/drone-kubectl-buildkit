# drone-kubectl-buildkit

Why?  Because you want to build an image, run tests in that image in your k8s cluster, then deploy that same image to the same cluster.  It's going to go faster if aren't pushing and pulling from a registry.

<https://github.com/vmware-tanzu/buildkit-cli-for-kubectl>

## TODO

- Build command that uses buildkit running on git.  iterate.
- github
- docker hub




## vars

PLUGIN_NAMESPACE
PLUGIN_KUBERNETES_USER
PLUGIN_KUBERNETES_TOKEN
PLUGIN_KUBERNETES_SERVER
PLUGIN_KUBERNETES_CERT

## limitations

- all registries need a k8s Secret with the auth it to push images too.  Thus we won't support
  - PLUGIN_REGISTRY
  - PLUGIN_USERNAME
  - PLUGIN_PASSWORD

## build

```shell
docker build . -t myers/drone-kubectl-buildkit
```

## test

```shell
docker run --rm \
    -e PLUGIN_KUBERNETES_SERVER=https://192.168.42.8:6443
    -e PLUGIN_KUBERNETES_TOKEN=
    -e PLUGIN_DOCKERFILE=/drone/Dockerfile.test \
    -e PLUGIN_REPO=registry.monoloco.net/foo/bar \
    -v $(pwd):/drone \
    -w /drone \
    myers/drone-kubectl-buildkit:latest
```
