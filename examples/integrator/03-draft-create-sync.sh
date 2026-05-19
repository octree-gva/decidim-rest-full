#!/usr/bin/env bash
set -euo pipefail

: "${HOST:?Set HOST}"
: "${TOKEN:?Run 01-token.sh first}"
: "${COMPONENT_ID:?Set COMPONENT_ID from search}"

RESP=$(curl -sS -X POST "http://${HOST}/api/rest_full/v0.3/draft_proposals/sync" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"data\":{\"type\":\"draft_proposal\",\"attributes\":{\"title\":{\"en\":\"API draft\"},\"body\":{\"en\":\"From examples/integrator\"},\"component_id\":${COMPONENT_ID}}}}")

echo "$RESP" | jq .
export DRAFT_ID
DRAFT_ID=$(echo "$RESP" | jq -r '.data.id')
echo "DRAFT_ID=${DRAFT_ID}"
