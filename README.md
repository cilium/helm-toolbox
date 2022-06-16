# helm-toolbox

Docker image to distribute tools used for generating and validating helm and
markdown content. Includes:

* [helm](https://github.com/helm/helm)
* [helm-docs](https://github.com/norwoodj/helm-docs)
* [m2r2](https://github.com/CrossNox/m2r2)

## Building the image

```
$ export PLATFORMS=linux/amd64,linux/arm64
$ export TAG=vX.Y.Z
$ docker buildx create --use --platform ${PLATFORMS}
$ docker buildx build --platform ${PLATFORMS} . -t quay.io/cilium/helm-toolbox:${TAG} --push
```

## Usage

```
$ docker container run THIS-IMAGE helm ...
$ docker container run --rm --workdir /src/install/kubernetes --volume /path/to/cilium/:/src --user "1001:1001" THIS-IMAGE /usr/bin/helm-docs ...
$ docker container run THIS-IMAGE python3 /usr/bin/m2r2 ...
```

