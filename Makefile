#!/bin/bash

PROJECT=docs-auth
COMPANY=giantswarm
registry=registry.giantswarm.io
name=docs-auth
#VERSION=$(cat ./VERSION)

build:
	docker build -t $(registry)/$(COMPANY)/$(PROJECT) .

run:
	docker run --name=$(name) --rm -p 80:80 \
		-e MKDOCSMASTER_PORT_8000_TCP_ADDR=$(MKDOCSMASTER_PORT_8000_TCP_ADDR) \
		-e MKDOCSMASTER_PORT_8000_TCP_PORT=$(MKDOCSMASTER_PORT_8000_TCP_PORT) \
		-e MKDOCSSLAVE_PORT_8000_TCP_ADDR=$(MKDOCSSLAVE_PORT_8000_TCP_ADDR) \
		-e MKDOCSSLAVE_PORT_8000_TCP_PORT=$(MKDOCSSLAVE_PORT_8000_TCP_PORT) \
		-e SITESEARCH_PORT_9200_TCP_ADDR=$(SITESEARCH_PORT_9200_TCP_ADDR) \
		-e SITESEARCH_PORT_9200_TCP_PORT=$(SITESEARCH_PORT_9200_TCP_PORT) \
		$(registry)/$(COMPANY)/$(PROJECT)

delete:
	docker stop $(name)
	docker rm $(name)
	docker rmi $(registry)/$(COMPANY)/$(PROJECT)
