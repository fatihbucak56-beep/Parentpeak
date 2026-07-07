#!/usr/bin/env bash

set -euo pipefail

BASE_URL="${BACKEND_BASE_URL:-}"
API_TOKEN="${BACKEND_API_TOKEN:-}"
SMOKE_USER_ID="${PARENT_MATCHING_SMOKE_USER_ID:-smoke-user-001}"
SMOKE_FAMILY_ID="${PARENT_MATCHING_SMOKE_FAMILY_ID:-demo-family-001}"

if [[ -z "$BASE_URL" ]]; then
  echo "[parent_matching_smoke_test] ERROR: BACKEND_BASE_URL is required"
  echo "Example: BACKEND_BASE_URL=https://parentpeak.onrender.com BACKEND_API_TOKEN=... bash scripts/parent_matching_smoke_test.sh"
  exit 1
fi

if [[ -z "$API_TOKEN" ]]; then
  echo "[parent_matching_smoke_test] ERROR: BACKEND_API_TOKEN is required"
  exit 1
fi

echo "[parent_matching_smoke_test] Base URL: $BASE_URL"
echo "[parent_matching_smoke_test] User ID: $SMOKE_USER_ID"
echo "[parent_matching_smoke_test] Family ID: $SMOKE_FAMILY_ID"

profiles_response="$(curl -sS -X GET "$BASE_URL/parent-matching/profiles" \
  -H "Authorization: Bearer $API_TOKEN")"

profile_id="$(printf '%s' "$profiles_response" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p' | head -n1)"

if [[ -z "$profile_id" ]]; then
  echo "[parent_matching_smoke_test] ERROR: Could not extract profileId from /parent-matching/profiles"
  echo "[parent_matching_smoke_test] Response: $profiles_response"
  exit 1
fi

echo "[parent_matching_smoke_test] Using profileId=$profile_id"

post_action() {
  local action="$1"
  local response
  local status
  local body

  response="$(curl -sS -w '\n%{http_code}' -X POST "$BASE_URL/parent-matching/actions" \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $API_TOKEN" \
    --data "{\"familyId\":\"$SMOKE_FAMILY_ID\",\"profileId\":\"$profile_id\",\"action\":\"$action\",\"userId\":\"$SMOKE_USER_ID\"}")"

  status="${response##*$'\n'}"
  body="${response%$'\n'*}"

  if [[ "$status" != "201" ]]; then
    echo "[parent_matching_smoke_test] ERROR: POST /parent-matching/actions ($action) returned $status"
    echo "[parent_matching_smoke_test] Response: $body"
    exit 1
  fi

  if printf '%s' "$body" | grep -q '"source":"in-memory-fallback"'; then
    echo "[parent_matching_smoke_test] ERROR: fallback marker detected in response for action=$action"
    echo "[parent_matching_smoke_test] Response: $body"
    exit 1
  fi

  if ! printf '%s' "$body" | grep -q '"item":'; then
    echo "[parent_matching_smoke_test] ERROR: missing item payload for action=$action"
    echo "[parent_matching_smoke_test] Response: $body"
    exit 1
  fi

  echo "[OK] POST /parent-matching/actions ($action) -> 201"
}

post_action "like"
post_action "block"
post_action "report"

echo "[parent_matching_smoke_test] Completed"
