#!/usr/bin/env bash

set -euo pipefail

BASE_URL="${BACKEND_BASE_URL:-}"
RUN_BACKEND_SECURITY_SMOKE="${RUN_BACKEND_SECURITY_SMOKE:-1}"
RUN_STRIPE_WEBHOOK_SMOKE="${RUN_STRIPE_WEBHOOK_SMOKE:-1}"
RUN_PARENT_MATCHING_SMOKE="${RUN_PARENT_MATCHING_SMOKE:-0}"
RUN_WEEKLY_IMPULSE_COMMUNITY_SMOKE="${RUN_WEEKLY_IMPULSE_COMMUNITY_SMOKE:-0}"

if [[ -z "$BASE_URL" ]]; then
  echo "[release_smoke_suite] ERROR: BACKEND_BASE_URL is required"
  echo "Example: BACKEND_BASE_URL=https://api.parentpeak.de BACKEND_API_TOKEN=... STRIPE_WEBHOOK_SECRET=whsec_xxx bash scripts/release_smoke_suite.sh"
  exit 1
fi

echo "[release_smoke_suite] Base URL: $BASE_URL"
echo "[release_smoke_suite] RUN_BACKEND_SECURITY_SMOKE=$RUN_BACKEND_SECURITY_SMOKE"
echo "[release_smoke_suite] RUN_STRIPE_WEBHOOK_SMOKE=$RUN_STRIPE_WEBHOOK_SMOKE"
echo "[release_smoke_suite] RUN_PARENT_MATCHING_SMOKE=$RUN_PARENT_MATCHING_SMOKE"
echo "[release_smoke_suite] RUN_WEEKLY_IMPULSE_COMMUNITY_SMOKE=$RUN_WEEKLY_IMPULSE_COMMUNITY_SMOKE"

if [[ "$RUN_BACKEND_SECURITY_SMOKE" == "1" ]]; then
  echo "[release_smoke_suite] Running backend security smoke test..."
  BACKEND_BASE_URL="$BASE_URL" \
  BACKEND_API_TOKEN="${BACKEND_API_TOKEN:-}" \
  EXPECT_WRITE_AUTH="${EXPECT_WRITE_AUTH:-1}" \
  SMOKE_ORIGIN="${SMOKE_ORIGIN:-https://parentpeak.de}" \
  bash scripts/backend_security_smoke_test.sh
else
  echo "[release_smoke_suite] Skipping backend security smoke test"
fi

if [[ "$RUN_STRIPE_WEBHOOK_SMOKE" == "1" ]]; then
  if [[ -z "${STRIPE_WEBHOOK_SECRET:-}" ]]; then
    echo "[release_smoke_suite] ERROR: STRIPE_WEBHOOK_SECRET is required when RUN_STRIPE_WEBHOOK_SMOKE=1"
    exit 1
  fi

  echo "[release_smoke_suite] Running Stripe webhook smoke test..."
  BACKEND_BASE_URL="$BASE_URL" \
  STRIPE_WEBHOOK_SECRET="${STRIPE_WEBHOOK_SECRET}" \
  STRIPE_TEST_PAYMENT_INTENT_REF="${STRIPE_TEST_PAYMENT_INTENT_REF:-pi_smoke_test_001}" \
  EXPECT_CLIENT_PROVIDER_EVENTS_BLOCKED="${EXPECT_CLIENT_PROVIDER_EVENTS_BLOCKED:-1}" \
  SMOKE_ORIGIN="${SMOKE_ORIGIN:-https://parentpeak.de}" \
  bash scripts/stripe_webhook_smoke_test.sh
else
  echo "[release_smoke_suite] Skipping Stripe webhook smoke test"
fi

if [[ "$RUN_PARENT_MATCHING_SMOKE" == "1" ]]; then
  if [[ -z "${BACKEND_API_TOKEN:-}" ]]; then
    echo "[release_smoke_suite] ERROR: BACKEND_API_TOKEN is required when RUN_PARENT_MATCHING_SMOKE=1"
    exit 1
  fi

  echo "[release_smoke_suite] Running parent matching smoke test..."
  BACKEND_BASE_URL="$BASE_URL" \
  BACKEND_API_TOKEN="${BACKEND_API_TOKEN}" \
  PARENT_MATCHING_SMOKE_USER_ID="${PARENT_MATCHING_SMOKE_USER_ID:-smoke-user-001}" \
  PARENT_MATCHING_SMOKE_FAMILY_ID="${PARENT_MATCHING_SMOKE_FAMILY_ID:-demo-family-001}" \
  bash scripts/parent_matching_smoke_test.sh
else
  echo "[release_smoke_suite] Skipping parent matching smoke test"
fi

if [[ "$RUN_WEEKLY_IMPULSE_COMMUNITY_SMOKE" == "1" ]]; then
  echo "[release_smoke_suite] Running weekly impulse community smoke test..."
  BACKEND_BASE_URL="$BASE_URL" \
  INTERNAL_REVIEWER_EMAIL="${INTERNAL_REVIEWER_EMAIL:-lead@parentpeak.de}" \
  INTERNAL_REVIEWER_NAME="${INTERNAL_REVIEWER_NAME:-Lead Review}" \
  EXPECT_INTERNAL_MODERATION_LOCK="${EXPECT_INTERNAL_MODERATION_LOCK:-1}" \
  SMOKE_ORIGIN="${SMOKE_ORIGIN:-https://parentpeak.de}" \
  bash scripts/weekly_impulse_community_smoke_test.sh
else
  echo "[release_smoke_suite] Skipping weekly impulse community smoke test"
fi

echo "[release_smoke_suite] Completed"
