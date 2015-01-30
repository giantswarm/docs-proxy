#!/bin/bash

REGISTRY=registry.giantswarm.io
COMPANY=giantswarm
PROJECT=docs-proxy


build:
	docker build -t $(REGISTRY)/$(COMPANY)/$(PROJECT) .

delete:
	docker rm $(PROJECT)
	docker rmi $(REGISTRY)/$(COMPANY)/$(PROJECT)
