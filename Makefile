#!/bin/bash

REGISTRY=registry.giantswarm.io
COMPANY=giantswarm
PROJECT=docs-proxy


docker-build:
	docker build -t $(REGISTRY)/$(COMPANY)/$(PROJECT):latest .

docker-delete:
	docker rmi $(REGISTRY)/$(COMPANY)/$(PROJECT):latest
