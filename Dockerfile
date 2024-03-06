ARG GO_VERSION=1.21.7
ARG PY_VERSION=3.9.13

FROM --platform=${BUILDPLATFORM} golang:${GO_VERSION}-bullseye as gobuilder
# TARGETARCH is an automatic platform ARG enabled by Docker BuildKit.
ARG TARGETARCH
# TARGETOS is an automatic platform ARG enabled by Docker BuildKit.
ARG TARGETOS

ARG HELM_VERSION=3.13.3
ARG GO111MODULE=on
ARG GOARCH=${TARGETARCH}
ARG CGO_ENABLED=0

WORKDIR /tmp
RUN curl -sS -L https://get.helm.sh/helm-v${HELM_VERSION}-${TARGETOS}-${TARGETARCH}.tar.gz -o helm.tar.gz \
    && tar xvzf helm.tar.gz \
    && cp ${TARGETOS}-${TARGETARCH}/helm /go/bin/helm
#
WORKDIR /go/src/
RUN git clone https://github.com/norwoodj/helm-docs -b v1.11.0 \
    && cd helm-docs \
    && go build ./cmd/helm-docs \
    && cp helm-docs /go/bin/helm-docs

RUN git clone https://github.com/dadav/helm-schema -b 0.9.0 \
    && cd helm-schema \
    && go build ./cmd/helm-schema \
    && cp helm-schema /go/bin/helm-schema

RUN chmod +x /go/bin/helm
RUN chmod +x /go/bin/helm-docs
RUN chmod +x /go/bin/helm-schema

FROM --platform=${BUILDPLATFORM} python:${PY_VERSION}-bullseye as pybuilder
# TARGETARCH is an automatic platform ARG enabled by Docker BuildKit.
ARG TARGETARCH
# TARGETOS is an automatic platform ARG enabled by Docker BuildKit.
ARG TARGETOS

RUN python3 -m pip install m2r2==0.3.3
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
FROM gcr.io/distroless/python3-debian12:latest@sha256:d1427d962660c43d476b11f9bb7d6df66001296bba9577e39b33d2e8897614cd

ARG PY_MINOR=3.9

COPY --from=gobuilder /go/bin/helm /usr/bin/helm
COPY --from=gobuilder /go/bin/helm-docs /usr/bin/helm-docs
COPY --from=gobuilder /go/bin/helm-schema /usr/bin/helm-schema
COPY --from=pybuilder /usr/local/lib/python${PY_MINOR}/site-packages /usr/local/lib/python${PY_MINOR}/dist-packages/
COPY --from=pybuilder /usr/local/bin/m2r2 /usr/bin/m2r2

# Override the entrypoint from distroless since we can also run go static bins.
ENTRYPOINT []
CMD ["/usr/bin/helm"]
#CMD ["/usr/bin/helm-docs"]
#CMD ["python3", "/usr/bin/m2r2"]
