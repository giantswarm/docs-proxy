#!/bin/bash

PROJECT=docs-auth
registry=registry.giantswarm.io
name=docs-auth
VERSION=$(cat ./VERSION)

build:
	docker build -t $(registry)/$(PROJECT) .
	docker tag $(registry)/$(PROJECT) "$(registry)/$(PROJECT):$(VERSION)"

run:
	docker run --name=$(name) --rm -p 80:80 \
		-e UPSTREAM_PORT_8000_TCP_ADDR=$(UPSTREAM_PORT_8000_TCP_ADDR) \
		-e UPSTREAM_PORT_8000_TCP_PORT=$(UPSTREAM_PORT_8000_TCP_PORT) \
		-e SITESEARCH_PORT_9200_TCP_ADDR=$(SITESEARCH_PORT_9200_TCP_ADDR) \
		-e SITESEARCH_PORT_9200_TCP_PORT=$(SITESEARCH_PORT_9200_TCP_PORT) \
		$(registry)/$(PROJECT)

delete:
	docker stop $(name)
	docker rm $(name)
	docker rmi $(registry)/$(PROJECT)
