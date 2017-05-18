#!/bin/bash

REGISTRY=quay.io
COMPANY=giantswarm
PROJECT=docs-proxy

default: docker-build

docker-build:
	docker build -t $(REGISTRY)/$(COMPANY)/$(PROJECT):latest .

docker-delete:
	docker rmi $(REGISTRY)/$(COMPANY)/$(PROJECT):latest
