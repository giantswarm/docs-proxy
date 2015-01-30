#!/bin/bash

REGISTRY=registry.giantswarm.io
COMPANY=giantswarm
PROJECT=docs-auth


build:
	docker build -t $(REGISTRY)/$(COMPANY)/$(PROJECT) .

run:
	docker run --name=$(PROJECT) --rm -p 80:80 \
		-e DOCS_MASTER_PORT_8000_TCP_ADDR=$(MKDOCSMASTER_PORT_8000_TCP_ADDR) \
		-e DOCS_MASTER_PORT_8000_TCP_PORT=$(MKDOCSMASTER_PORT_8000_TCP_PORT) \
		-e DOCS_SLAVE_PORT_8000_TCP_ADDR=$(MKDOCSSLAVE_PORT_8000_TCP_ADDR) \
		-e DOCS_SLAVE_PORT_8000_TCP_PORT=$(MKDOCSSLAVE_PORT_8000_TCP_PORT) \
		-l sitesearch:sitesearch \
		$(REGISTRY)/$(COMPANY)/$(PROJECT)

delete:
	docker stop $(PROJECT)
	docker rm $(PROJECT)
	docker rmi $(REGISTRY)/$(COMPANY)/$(PROJECT)
