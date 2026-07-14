#!/usr/bin/env bash

set -euo pipefail

BASE_URL="${BACKEND_BASE_URL:-}"
INTERNAL_REVIEWER_EMAIL="${INTERNAL_REVIEWER_EMAIL:-lead@parentpeak.de}"
INTERNAL_REVIEWER_NAME="${INTERNAL_REVIEWER_NAME:-Lead Review}"
EXPECT_INTERNAL_MODERATION_LOCK="${EXPECT_INTERNAL_MODERATION_LOCK:-1}"
SMOKE_ORIGIN="${SMOKE_ORIGIN:-https://parentpeak.de}"

if [[ -z "$BASE_URL" ]]; then
  echo "[weekly_impulse_community_smoke_test] ERROR: BACKEND_BASE_URL is required"
  echo "Example: BACKEND_BASE_URL=https://api.parentpeak.de bash scripts/weekly_impulse_community_smoke_test.sh"
  exit 1
fi

BASE_URL="${BASE_URL%/}"
SMOKE_TS="$(date +%s)"
SMOKE_USER_ID="weekly-smoke-${SMOKE_TS}"
SMOKE_EMAIL="weekly-smoke-${SMOKE_TS}@example.com"
SMOKE_NAME="Weekly Smoke ${SMOKE_TS}"
SMOKE_ROLE_TITLE="Familienberater:in"
SMOKE_ORG="Parentpeak Smoke Lab"
SMOKE_NOTE="Automatischer Smoke-Test fuer Fachverifizierung"

headers_file="$(mktemp)"
body_file="$(mktemp)"
trap 'rm -f "$headers_file" "$body_file"' EXIT

request_json() {
  local method="$1"
  local url="$2"
  local body="${3:-}"

  local curl_args=(
    -sS
    -D "$headers_file"
    -o "$body_file"
    -w "%{http_code}"
    -X "$method"
    "$url"
    -H "Origin: $SMOKE_ORIGIN"
    -H "Accept: application/json"
  )

  if [[ "$method" != "GET" ]]; then
    curl_args+=( -H "Content-Type: application/json" )
  fi

  if [[ -n "$body" ]]; then
    curl_args+=( --data "$body" )
  fi

  curl "${curl_args[@]}"
}

assert_exact_status() {
  local status="$1"
  local expected="$2"
  local label="$3"
  if [[ "$status" == "$expected" ]]; then
    echo "[OK] $label ($status)"
  else
    echo "[ERROR] $label expected $expected, got $status"
    echo "[ERROR] Response body:"
    cat "$body_file"
    return 1
  fi
}

assert_body_contains() {
  local needle="$1"
  local label="$2"
  if grep -Fq "$needle" "$body_file"; then
    echo "[OK] $label"
  else
    echo "[ERROR] $label missing '$needle'"
    echo "[ERROR] Response body:"
    cat "$body_file"
    return 1
  fi
}

echo "[weekly_impulse_community_smoke_test] Base URL: $BASE_URL"
echo "[weekly_impulse_community_smoke_test] Internal reviewer: $INTERNAL_REVIEWER_EMAIL"

status="$(request_json GET "$BASE_URL/api/weekly-impulse")"
assert_exact_status "$status" "200" "GET /api/weekly-impulse"
assert_body_contains 'community_posts' 'Weekly impulse hub payload includes community posts'

verification_request_body=$(cat <<JSON
{"userId":"$SMOKE_USER_ID","email":"$SMOKE_EMAIL","displayName":"$SMOKE_NAME","roleTitle":"$SMOKE_ROLE_TITLE","organization":"$SMOKE_ORG","note":"$SMOKE_NOTE"}
JSON
)
status="$(request_json POST "$BASE_URL/api/weekly-impulse/community/verification-requests" "$verification_request_body")"
assert_exact_status "$status" "201" "POST verification request"
assert_body_contains '"status":"pending"' 'Verification request stored as pending'

status="$(request_json GET "$BASE_URL/api/weekly-impulse/community/verification-status?userId=$SMOKE_USER_ID&email=$SMOKE_EMAIL")"
assert_exact_status "$status" "200" "GET verification status before approval"
assert_body_contains '"pendingRequest":true' 'Verification status shows pending request'

status="$(request_json GET "$BASE_URL/api/weekly-impulse/community/verification-requests?status=pending&reviewerEmail=$SMOKE_EMAIL")"
if [[ "$EXPECT_INTERNAL_MODERATION_LOCK" == "1" ]]; then
  assert_exact_status "$status" "403" "External reviewer blocked from verification review"
else
  echo "[INFO] EXPECT_INTERNAL_MODERATION_LOCK=0, skipping strict external reviewer 403 assertion (status=$status)"
fi

status="$(request_json GET "$BASE_URL/api/weekly-impulse/community/verification-requests?status=pending&reviewerEmail=$INTERNAL_REVIEWER_EMAIL")"
assert_exact_status "$status" "200" "Internal reviewer can load verification requests"
assert_body_contains "$SMOKE_USER_ID" 'Pending verification request visible to reviewer'

request_id="$(grep -o '"id":"verif_[^"]*' "$body_file" | head -n1 | sed 's/"id":"//')"
if [[ -z "$request_id" ]]; then
  echo "[ERROR] Could not extract verification request id"
  cat "$body_file"
  exit 1
fi

approval_body=$(cat <<JSON
{"reviewerName":"$INTERNAL_REVIEWER_NAME","reviewerEmail":"$INTERNAL_REVIEWER_EMAIL","reviewNote":"Smoke approval","verificationLabel":"Verifizierte Fachstimme"}
JSON
)
status="$(request_json POST "$BASE_URL/api/weekly-impulse/community/verification-requests/$request_id/approve" "$approval_body")"
assert_exact_status "$status" "200" "Approve verification request"
assert_body_contains '"status":"approved"' 'Verification request stored as approved'

status="$(request_json GET "$BASE_URL/api/weekly-impulse/community/verification-status?userId=$SMOKE_USER_ID&email=$SMOKE_EMAIL")"
assert_exact_status "$status" "200" "GET verification status after approval"
assert_body_contains '"verified":true' 'Verification status shows verified expert'
assert_body_contains '"verifiedProfile":' 'Verification status exposes verified profile'

community_post_body=$(cat <<JSON
{"impulseId":"imp_years_3_gfk_w1","title":"Smoke Fachbeitrag","body":"Dies ist ein automatisch freigegebener Fachbeitrag fuer den Smoke-Test.","authorName":"$SMOKE_NAME","authorUserId":"$SMOKE_USER_ID","authorEmail":"$SMOKE_EMAIL","role":"Paedagog:in"}
JSON
)
status="$(request_json POST "$BASE_URL/api/weekly-impulse/community/posts" "$community_post_body")"
assert_exact_status "$status" "201" "POST verified educator community post"
assert_body_contains '"verified_expert":true' 'Approved educator post receives verified badge'

echo "[weekly_impulse_community_smoke_test] Completed"
