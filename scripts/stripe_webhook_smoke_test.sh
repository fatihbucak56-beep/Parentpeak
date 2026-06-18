#!/usr/bin/env bash

set -euo pipefail

BASE_URL="${BACKEND_BASE_URL:-}"
WEBHOOK_SECRET="${STRIPE_WEBHOOK_SECRET:-}"
EXPECT_CLIENT_PROVIDER_EVENTS_BLOCKED="${EXPECT_CLIENT_PROVIDER_EVENTS_BLOCKED:-1}"
SMOKE_ORIGIN="${SMOKE_ORIGIN:-https://parentpeak.de}"
PAYMENT_INTENT_REF="${STRIPE_TEST_PAYMENT_INTENT_REF:-pi_smoke_test_001}"

if [[ -z "$BASE_URL" ]]; then
  echo "[stripe_webhook_smoke_test] ERROR: BACKEND_BASE_URL is required"
  echo "Example: BACKEND_BASE_URL=https://api.parentpeak.de STRIPE_WEBHOOK_SECRET=whsec_xxx bash scripts/stripe_webhook_smoke_test.sh"
  exit 1
fi

if [[ -z "$WEBHOOK_SECRET" ]]; then
  echo "[stripe_webhook_smoke_test] ERROR: STRIPE_WEBHOOK_SECRET is required"
  echo "Example: STRIPE_WEBHOOK_SECRET=whsec_xxx"
  exit 1
fi

if ! command -v openssl >/dev/null 2>&1; then
  echo "[stripe_webhook_smoke_test] ERROR: openssl is required"
  exit 1
fi

BASE_URL="${BASE_URL%/}"
WEBHOOK_URL="$BASE_URL/payments/stripe/webhook"
PROVIDER_EVENTS_URL="$BASE_URL/payments/provider-events"

echo "[stripe_webhook_smoke_test] Base URL: $BASE_URL"

tmp_headers="$(mktemp)"
trap 'rm -f "$tmp_headers"' EXIT

request_status() {
  local method="$1"
  local url="$2"
  local body="${3:-}"
  local signature_header="${4:-}"

  local curl_args=(
    -sS
    -o /dev/null
    -D "$tmp_headers"
    -w "%{http_code}"
    -X "$method"
    "$url"
    -H "Origin: $SMOKE_ORIGIN"
    -H "Accept: application/json"
    -H "Content-Type: application/json"
  )

  if [[ -n "$signature_header" ]]; then
    curl_args+=( -H "Stripe-Signature: $signature_header" )
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
    return 1
  fi
}

assert_any_status() {
  local status="$1"
  local label="$2"
  shift 2
  local expected
  for expected in "$@"; do
    if [[ "$status" == "$expected" ]]; then
      echo "[OK] $label ($status)"
      return 0
    fi
  done
  echo "[ERROR] $label expected one of: $*; got $status"
  return 1
}

stripe_signature_for_payload() {
  local timestamp="$1"
  local payload="$2"
  local signed_payload="$timestamp.$payload"
  local digest
  digest="$(printf '%s' "$signed_payload" | openssl dgst -sha256 -hmac "$WEBHOOK_SECRET" -hex | sed 's/^.* //')"
  printf 't=%s,v1=%s' "$timestamp" "$digest"
}

# 1) Invalid signature must fail
invalid_payload='{"type":"payment_intent.succeeded","data":{"object":{"id":"pi_invalid_sig"}}}'
status="$(request_status POST "$WEBHOOK_URL" "$invalid_payload" "t=1,v1=deadbeef")"
assert_exact_status "$status" "400" "POST /payments/stripe/webhook with invalid signature"

# 2) Valid signature should be accepted (200 if mapped+found, 202 if mapped+not found)
timestamp="$(date +%s)"
valid_payload="{\"type\":\"payment_intent.succeeded\",\"data\":{\"object\":{\"id\":\"$PAYMENT_INTENT_REF\"}}}"
valid_signature="$(stripe_signature_for_payload "$timestamp" "$valid_payload")"
status="$(request_status POST "$WEBHOOK_URL" "$valid_payload" "$valid_signature")"
assert_any_status "$status" "POST /payments/stripe/webhook with valid signature" "200" "202"

# 3) Optional security check: provider-events endpoint should be blocked in production
provider_event_payload='{"provider":"stripe","providerTransactionRef":"pi_smoke_test_001","status":"completed","verified":true}'
status="$(request_status POST "$PROVIDER_EVENTS_URL" "$provider_event_payload")"
if [[ "$EXPECT_CLIENT_PROVIDER_EVENTS_BLOCKED" == "1" ]]; then
  # Depending on whether write auth runs before provider-event gating, blocked can be 401 or 403.
  assert_any_status "$status" "POST /payments/provider-events blocked" "401" "403"
else
  echo "[INFO] EXPECT_CLIENT_PROVIDER_EVENTS_BLOCKED=0; skipping strict provider-events block assertion (status=$status)"
fi

echo "[stripe_webhook_smoke_test] Completed"
