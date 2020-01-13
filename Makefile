GOOGLE_PROJECT=$(shell gcloud config get-value project)
REPOSITORY=eu.gcr.io/$(GOOGLE_PROJECT)/algolia-instant-search-demo

HELM_RELEASE=instant-search-demo

DOCKER_TAG=$(shell git log --pretty=format:'%H' -n 1)

MINIKUBE_OPTS=""
ifeq ($(MINIKUBE),true)
MINIKUBE_OPTS="gcpBackendConfig.enabled=false,privateRegistry.enabled=true,privateRegistry.password=$(shell gcloud auth application-default print-access-token),replicaCount=2,image.pullPolicy=Always,"
endif

.phony: build push install upgrade uninstall

all: build push install

build:
	docker build . -t "$(REPOSITORY):$(DOCKER_TAG)"

push:
	docker push "$(REPOSITORY):$(DOCKER_TAG)"

install: build push
	@helm install --dry-run --set "$(MINIKUBE_OPTS)image.tag=$(DOCKER_TAG),image.repository=$(REPOSITORY)" $(HELM_RELEASE) helm/instant-search-demo
	@helm install --set "$(MINIKUBE_OPTS)image.tag=$(DOCKER_TAG),image.repository=$(REPOSITORY)" $(HELM_RELEASE) helm/instant-search-demo --wait --timeout 50m --atomic

upgrade: build push
	@helm upgrade --dry-run --set "$(MINIKUBE_OPTS)image.tag=$(DOCKER_TAG),image.repository=$(REPOSITORY)" $(HELM_RELEASE) helm/instant-search-demo
	@helm upgrade --set "$(MINIKUBE_OPTS)image.tag=$(DOCKER_TAG),image.repository=$(REPOSITORY)" $(HELM_RELEASE) helm/instant-search-demo --wait --timeout 50m --atomic

uninstall:
	helm delete instant-search-demo
