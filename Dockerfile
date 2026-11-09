ARG GO_VERSION=1.27.3
ARG PY_VERSION=3.13.18

FROM --platform=${BUILDPLATFORM} golang:${GO_VERSION}-trixie@sha256:af1bfc2614ebb1dbd31af514b78740fd678850e76498762b425ecee4c5c6ea80 AS gobuilder
# TARGETARCH is an automatic platform ARG enabled by Docker BuildKit.
ARG TARGETARCH
# TARGETOS is an automatic platform ARG enabled by Docker BuildKit.
ARG TARGETOS

ARG HELM_VERSION=4.3.1
ARG GO111MODULE=on
ARG GOARCH=${TARGETARCH}
ARG CGO_ENABLED=0

WORKDIR /tmp
RUN curl -fsSLO https://get.helm.sh/helm-v${HELM_VERSION}-${TARGETOS}-${TARGETARCH}.tar.gz \
    && curl -fsSLO https://get.helm.sh/helm-v${HELM_VERSION}-${TARGETOS}-${TARGETARCH}.tar.gz.sha256sum \
    && sha256sum -c helm-v${HELM_VERSION}-${TARGETOS}-${TARGETARCH}.tar.gz.sha256sum \
    && tar xvzf helm-v${HELM_VERSION}-${TARGETOS}-${TARGETARCH}.tar.gz \
    && cp ${TARGETOS}-${TARGETARCH}/helm /go/bin/helm
#
WORKDIR /go/src/
RUN git clone https://github.com/norwoodj/helm-docs -b v1.14.2 \
    && cd helm-docs \
    && go build ./cmd/helm-docs \
    && cp helm-docs /go/bin/helm-docs

RUN git clone https://github.com/dadav/helm-schema -b 0.24.0 \
    && cd helm-schema \
    && go build ./cmd/helm-schema \
    && cp helm-schema /go/bin/helm-schema

RUN chmod +x /go/bin/helm
RUN chmod +x /go/bin/helm-docs
RUN chmod +x /go/bin/helm-schema

FROM --platform=${BUILDPLATFORM} python:${PY_VERSION}-trixie@sha256:51db6babcbd039687e5362a676db5444b5926739abb03b10c8c6a8144872611f AS pybuilder
# TARGETARCH is an automatic platform ARG enabled by Docker BuildKit.
ARG TARGETARCH
# TARGETOS is an automatic platform ARG enabled by Docker BuildKit.
ARG TARGETOS

RUN python3 -m pip install m2r2==2.1.0
RUN rm -rf -- /usr/local/lib/python*/site-packages/pip*
RUN rm -rf -- /usr/local/lib/python*/site-packages/setuptools*
RUN rm -rf -- /usr/local/lib/python*/site-packages/wheel*

# distroless images are signed by cosign. You should verify the image with the following command:
#
# $ cosign verify $IMAGE_NAME --certificate-oidc-issuer https://accounts.google.com  --certificate-identity keyless@distroless.iam.gserviceaccount.com
#
# Cosign may be found at the following address:
# https://github.com/sigstore/cosign
#
# For more information, see:
# https://github.com/GoogleContainerTools/distroless?tab=readme-ov-file#how-do-i-verify-distroless-images
FROM gcr.io/distroless/python3-debian13:latest@sha256:9a1ed29d41d7695245ff86bc2e08684d3dd253a3f9c8ca45677427f9f4fe3598

ARG PY_MINOR=3.13
ENV PYTHONPATH=/usr/local/lib/python${PY_MINOR}/site-packages

COPY --from=gobuilder /go/bin/helm /usr/bin/helm
COPY --from=gobuilder /go/bin/helm-docs /usr/bin/helm-docs
COPY --from=gobuilder /go/bin/helm-schema /usr/bin/helm-schema
COPY --from=pybuilder /usr/local/lib/python${PY_MINOR}/site-packages /usr/local/lib/python${PY_MINOR}/site-packages/
COPY --from=pybuilder /usr/local/bin/m2r2 /usr/bin/m2r2

# Override the entrypoint from distroless since we can also run go static bins.
ENTRYPOINT []
CMD ["/usr/bin/helm"]
#CMD ["/usr/bin/helm-docs"]
#CMD ["python3", "/usr/bin/m2r2"]
