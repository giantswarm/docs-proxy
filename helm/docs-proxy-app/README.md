# docs-proxy-app

Reverse proxy that brings several documentation components together at https://docs.giantswarm.io/

**Homepage:** <https://github.com/giantswarm/docs-proxy>

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| name | string | `"docs-proxy-app"` |  |
| namespace | string | `"docs"` |  |
| image.name | string | `"docs-proxy"` |  |
| image.tag | string | `""` |  |
| hostnames[0] | string | `"docs.giantswarm.io"` |  |
| hostnames[1] | string | `"docs.operations.awsprod.gigantic.io"` |  |
| resources.requests.cpu | string | `"10m"` |  |
| resources.requests.memory | string | `"10Mi"` |  |
| resources.requests.ephemeralStorage | string | `"50Mi"` |  |
| resources.limits.cpu | string | `"100m"` |  |
| resources.limits.memory | string | `"50Mi"` |  |
| resources.limits.ephemeralStorage | string | `"200Mi"` |  |
