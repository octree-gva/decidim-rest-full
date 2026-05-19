#!/usr/bin/env bash
set -euo pipefail

: "${HOST:?Set HOST}"
: "${TOKEN:?Run 01-token.sh first}"

curl -sS "http://${HOST}/api/rest_full/v0.3/components/search?filter[manifest_name]=proposals" \
  -H "Authorization: Bearer ${TOKEN}" | jq .
