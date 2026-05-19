#!/usr/bin/env bash
set -euo pipefail

: "${HOST:?Set HOST}"
: "${TOKEN:?Run 01-token.sh first}"
: "${DRAFT_ID:?Run 03-draft-create-sync.sh first}"

curl -sS -X POST "http://${HOST}/api/rest_full/v0.3/draft_proposals/${DRAFT_ID}/publish/sync" \
  -H "Authorization: Bearer ${TOKEN}" | jq .
