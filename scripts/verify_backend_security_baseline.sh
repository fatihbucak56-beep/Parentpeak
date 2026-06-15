#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

has_error=0

ok() {
  echo "[OK] $1"
}

err() {
  echo "[ERROR] $1"
  has_error=1
}

check_contains() {
  local file="$1"
  local needle="$2"
  local description="$3"

  if grep -Fq "$needle" "$file"; then
    ok "$description"
  else
    err "$description fehlt ($needle)"
  fi
}

echo "[verify_backend_security_baseline] Checking backend hardening baseline..."

if [[ ! -f backend/server.js ]]; then
  err "backend/server.js fehlt"
else
  check_contains backend/server.js "X-Content-Type-Options" "Security header X-Content-Type-Options"
  check_contains backend/server.js "X-Frame-Options" "Security header X-Frame-Options"
  check_contains backend/server.js "Referrer-Policy" "Security header Referrer-Policy"
  check_contains backend/server.js "Permissions-Policy" "Security header Permissions-Policy"
  check_contains backend/server.js "CORS_ALLOWED_ORIGINS" "CORS allowlist config"
  check_contains backend/server.js "REQUIRE_AUTH_FOR_WRITES" "Write auth toggle"
  check_contains backend/server.js "WRITE_RATE_LIMIT_WINDOW_MS" "Write rate limit window config"
  check_contains backend/server.js "WRITE_RATE_LIMIT_MAX" "Write rate limit max config"

  payment_decl_count="$(grep -c "const paymentTransactions = \[\];" backend/server.js || true)"
  if [[ "$payment_decl_count" == "1" ]]; then
    ok "paymentTransactions declaration is unique"
  else
    err "paymentTransactions declaration expected once, found $payment_decl_count"
  fi
fi

if [[ ! -f .env.example ]]; then
  err ".env.example fehlt"
else
  check_contains .env.example "REQUIRE_AUTH_FOR_WRITES=1" "Secure default for write auth"
  check_contains .env.example "CORS_ALLOWED_ORIGINS=" "CORS allowlist variable present"
  check_contains .env.example "WRITE_RATE_LIMIT_WINDOW_MS=" "Write rate limit window variable present"
  check_contains .env.example "WRITE_RATE_LIMIT_MAX=" "Write rate limit max variable present"
fi

if [[ "$has_error" -ne 0 ]]; then
  echo "[verify_backend_security_baseline] FAILED"
  exit 1
fi

echo "[verify_backend_security_baseline] PASSED"
