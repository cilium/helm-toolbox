#!/bin/bash

TAG ?= latest

CONTAINER_ENGINE=docker
HELM_TOOLBOX_IMAGE=quay.io/cilium/helm-toolbox:$(TAG)
DOCKER_RUN := $(CONTAINER_ENGINE) container run --rm \
        --workdir /src/ \
        --volume $(CURDIR)/cilium:/src/cilium \
        --user "$(shell id -u):$(shell id -g)"
HELM_DOCS := $(DOCKER_RUN) $(HELM_TOOLBOX_IMAGE) helm-docs
HELM_SCHEMA_GEN := $(DOCKER_RUN) $(HELM_TOOLBOX_IMAGE) helm-schema
HELM := $(DOCKER_RUN) $(HELM_TOOLBOX_IMAGE) helm

.PHONY:
all: test

.PHONY:
build:
	# Note that there's no multiplatform or push here.
	$(CONTAINER_ENGINE) buildx build . -t quay.io/cilium/helm-toolbox:${TAG} --load

.PHONY:
pull-cilium:
	@helm repo list | grep -q cilium \
	|| helm repo add cilium https://helm.cilium.io
	@rm -rf -- ./cilium
	helm pull cilium/cilium --untar

.PHONY:
test: build pull-cilium
	$(HELM) lint --with-subcharts --values ./cilium/values.yaml ./cilium
	$(HELM_DOCS)
	$(HELM_SCHEMA_GEN) -c cilium --skip-auto-generation title,description,required,default,additionalProperties
