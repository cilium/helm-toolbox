ARG GO_VERSION=1.18.3
ARG PY_VERSION=3.9.13

FROM --platform=${BUILDPLATFORM} golang:${GO_VERSION}-bullseye as gobuilder
# TARGETARCH is an automatic platform ARG enabled by Docker BuildKit.
ARG TARGETARCH
# TARGETOS is an automatic platform ARG enabled by Docker BuildKit.
ARG TARGETOS

ARG HELM_VERSION=3.9.0
ARG GO111MODULE=on
ARG GOARCH=${TARGETARCH}
ARG CGO_ENABLED=0

WORKDIR /tmp
RUN curl -sS -L https://get.helm.sh/helm-v${HELM_VERSION}-${TARGETOS}-${TARGETARCH}.tar.gz -o helm.tar.gz \
    && tar xvzf helm.tar.gz \
    && cp ${TARGETOS}-${TARGETARCH}/helm /go/bin/helm
#
WORKDIR /go/src/
RUN git clone https://github.com/norwoodj/helm-docs \
    && cd helm-docs \
    && go build ./cmd/helm-docs \
    && cp helm-docs /go/bin/helm-docs

RUN chmod +x /go/bin/helm
RUN chmod +x /go/bin/helm-docs

FROM --platform=${BUILDPLATFORM} python:${PY_VERSION}-bullseye as pybuilder
# TARGETARCH is an automatic platform ARG enabled by Docker BuildKit.
ARG TARGETARCH
# TARGETOS is an automatic platform ARG enabled by Docker BuildKit.
ARG TARGETOS

RUN python3 -m pip install m2r2==0.3.2
RUN rm -rf -- /usr/local/lib/python*/site-packages/pip*
RUN rm -rf -- /usr/local/lib/python*/site-packages/setuptools*
RUN rm -rf -- /usr/local/lib/python*/site-packages/wheel*

FROM gcr.io/distroless/python3-debian11:latest@sha256:8d85861bce59d78b171fa9f23223e5197aad13035fe7e9f411b1a983da8eddd0

ARG PY_MINOR=3.9

COPY --from=gobuilder /go/bin/helm /usr/bin/helm
COPY --from=gobuilder /go/bin/helm-docs /usr/bin/helm-docs
COPY --from=pybuilder /usr/local/lib/python${PY_MINOR}/site-packages /usr/local/lib/python${PY_MINOR}/dist-packages/
COPY --from=pybuilder /usr/local/bin/m2r2 /usr/bin/m2r2

# Override the entrypoint from distroless since we can also run go static bins.
ENTRYPOINT []
CMD ["/usr/bin/helm"]
#CMD ["/usr/bin/helm-docs"]
#CMD ["python3", "/usr/bin/m2r2"]
