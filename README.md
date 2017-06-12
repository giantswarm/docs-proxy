# docs-proxy

This repository represents the Documentation proxy server component.

Please refer to the [docs](https://github.com/giantswarm/docs) repository for more context and explanation on how to run this locally with other related components.

## Admin access

To access some Search status URLs, use these credentials:

User: admin
Password: e4dfbjb3rohi8qpoadsffodin

Monitoring URLs

 * /api/search/status
 * /api/search/stats
 * /api/search/health

## Kubernetes manifests

Docs-proxy is deployed to the `docs` namespace in g8s.

It depends on a registry pull secret being present in that namespace.
An example registry-pull-secret is available in the docs repo.

It also depends on a secret called `giantswarm-cert` being present. An example
of this secret _is_ present in this repo at kubernetes/giantswarm-cert.yaml.dist

It should containe base64 encrypted values for Giant Swarm's wildcard certificate
so that the nginx container can properly SSL terminate.
