#!/usr/bin/env bash
set -euo pipefail

: "${HOST:?Set HOST}"
: "${CLIENT_ID:?Set CLIENT_ID}"
: "${CLIENT_SECRET:?Set CLIENT_SECRET}"

RESP=$(curl -sS -X POST "http://${HOST}/oauth/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id=${CLIENT_ID}&client_secret=${CLIENT_SECRET}&scope=public proposals")

export TOKEN
TOKEN=$(echo "$RESP" | jq -r '.access_token')
echo "TOKEN=${TOKEN}"
