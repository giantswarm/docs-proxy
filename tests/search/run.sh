#!/bin/sh
# Runs the /searchapi gateway integration test: builds docs-proxy, starts it
# with OpenSearch and fixture indices, runs the checks and cleans up. On
# failure it prints the containers' logs.
set -eu
cd "$(dirname "$0")"
compose="docker compose -p docs-proxy-search-test -f compose.yaml"
trap '$compose down -v >/dev/null 2>&1' EXIT
$compose up -d --build sitesearch-app docs-app coredns.kube-system.svc.cluster.local docs-proxy
if ! $compose run --rm tests; then
    $compose logs || true
    exit 1
fi
