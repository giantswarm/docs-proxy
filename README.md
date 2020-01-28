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

## App

The `helm` folder contains an app chart.

An additional Docker pull secret is required, like this:

```yaml
apiVersion: v1
kind: Secret
metadata:
  namespace: docs
  name: docs-proxy-pull-secret
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: <base64-data>
```
