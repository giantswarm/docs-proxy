#!/bin/bash

PROJECT=docs-auth
registry=registry.giantswarm.io
name=docs-auth

run:
	docker run --name=$(name) --rm -p 80:80 $(registry)/$(PROJECT)

build:
	docker build -t $(registry)/$(PROJECT) .

delete:
	docker stop $(name)
	docker rm $(name)
	docker rmi $(registry)/$(PROJECT)
