# TODO

Install buildkit-cli-for-kubectl on gir and checkout mediabrainz.  Attempt to `kubectl build -t mediabrainz:test -f Dockerfile ./`

If that works figure out how RBAC works and how to create a limited user that can build images

populate a k8s secret with that

build plugin image that reads from secret and builds image

change mediabrainz to use that


bench