#!/bin/bash

REGISTRY=registry.giantswarm.io
COMPANY=giantswarm
PROJECT=docs-proxy

default: docker-build

docker-build:
	docker build -t $(REGISTRY)/$(COMPANY)/$(PROJECT):firstgen .

docker-delete:
	docker rmi $(REGISTRY)/$(COMPANY)/$(PROJECT):firstgen
