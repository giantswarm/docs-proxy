# docs-proxy

This repository provides an NGINX based proxy server for use in [docs.giantswarm.io](https://docs.giantswarm.io/).

The main purpose is to

- Route requests to their respective backends.
  - Route content URL requests to the content backend.
  - Route search requests to the search API server.
- Respond to requests for some historic URLs and URL patterns with redirects.
- Set some common expires headers for cache control.
- Set permissive CORS headers on RSS feeds.

Please refer to the [giantswarm/docs](https://github.com/giantswarm/docs) repository for more context and explanation on how to run this locally with other related components.

The app is deployed as a Giant Swarm [App](https://docs.giantswarm.io/app-platform/). See the `helm` folder for details.
