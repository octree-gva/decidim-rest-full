#!/usr/bin/env bash
set -euo pipefail

: "${HOST:?Set HOST}"
: "${TOKEN:?User or impersonation token with proposals.vote}"
: "${PROPOSAL_ID:?Set PROPOSAL_ID}"

# Async (default under load)
curl -sS -X POST "http://${HOST}/api/rest_full/v0.3/vote_proposals" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"proposal_id\":${PROPOSAL_ID},\"data\":{\"weight\":1}}" | jq .

# Sync slim vote body:
# curl -sS -X POST "http://${HOST}/api/rest_full/v0.3/vote_proposals/sync?include_proposal=false" ...
