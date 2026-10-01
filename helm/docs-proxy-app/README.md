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
| architecture | string | `""` | Target CPU architecture for this workload. Empty imposes no constraint. `arm64` pins the pod to arm64 nodes, adding both the `kubernetes.io/arch` node selector and the toleration for the `kubernetes.io/arch=arm64:NoSchedule` taint that Giant Swarm arm64 node pools carry. Both are required, so this single value sets both. Requires a multi-arch container image; an amd64-only image will crash-loop with `exec format error` on an arm64 node. |
| nodeSelector | object | `{}` | Node selector for pod scheduling. Merged with `architecture`. Pinning to arm64 here rather than through `architecture` also adds the arm64 taint toleration, so either route is safe. A value that contradicts `architecture` fails the render. |
| tolerations | list | `[]` | Tolerations for pod scheduling. Merged with the toleration that `architecture: arm64` adds. |
