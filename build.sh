#!/bin/sh

IMAGE=registry.giantswarm.io/docs-auth
VERSION=$(cat ./VERSION)

docker build -t $IMAGE .
docker tag $IMAGE $IMAGE:$VERSION
