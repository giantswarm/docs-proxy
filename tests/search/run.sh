#!/bin/sh
# Runs the /searchapi gateway integration test: builds docs-proxy, starts it
# with OpenSearch and fixture indices, runs the checks and cleans up.
set -eu
cd "$(dirname "$0")"
compose="docker compose -p docs-proxy-search-test -f compose.yaml"
trap '$compose down -v >/dev/null 2>&1' EXIT
$compose up -d --build
python3 -I test_gateway.py
