#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

has_error=0
strict_mode="${STRICT_PROD:-1}"
firebase_cli_path="${FIREBASE_CLI_PATH:-$HOME/.local/npm-global/bin/firebase}"

ok() {
  echo "[OK] $1"
}

warn() {
  echo "[WARN] $1"
}

err() {
  echo "[ERROR] $1"
  has_error=1
}

echo "[verify_prod_backend_setup] Checking Firebase and backend production wiring..."

if command -v firebase >/dev/null 2>&1; then
  ok "Firebase CLI installed"
elif [[ -x "$firebase_cli_path" ]]; then
  ok "Firebase CLI installed at $firebase_cli_path"
else
  err "Firebase CLI missing (install: https://firebase.google.com/docs/cli)"
fi

if [[ -x "$HOME/.pub-cache/bin/flutterfire" ]] || command -v flutterfire >/dev/null 2>&1; then
  ok "FlutterFire CLI installed"
else
  err "FlutterFire CLI missing (run: dart pub global activate flutterfire_cli)"
fi

if [[ -f "android/app/google-services.json" ]]; then
  ok "Found android/app/google-services.json"
else
  err "Missing android/app/google-services.json"
fi

if [[ -f "ios/Runner/GoogleService-Info.plist" ]]; then
  ok "Found ios/Runner/GoogleService-Info.plist"
else
  err "Missing ios/Runner/GoogleService-Info.plist"
fi

if [[ -f "lib/firebase_options.dart" ]]; then
  ok "Found lib/firebase_options.dart"
else
  err "Missing lib/firebase_options.dart (run flutterfire configure)"
fi

if grep -q 'com.google.gms.google-services' android/settings.gradle.kts; then
  ok "Google Services plugin configured in android/settings.gradle.kts"
else
  err "Google Services plugin missing in android/settings.gradle.kts"
fi

if grep -q 'id("com.google.gms.google-services")' android/app/build.gradle.kts; then
  ok "Google Services plugin applied in android/app/build.gradle.kts"
else
  err "Google Services plugin not applied in android/app/build.gradle.kts"
fi

if [[ -f ".env" ]]; then
  ok "Found .env"

  if grep -q '^GEMINI_API_KEY=' .env; then
    ok "GEMINI_API_KEY present"
  else
    err "GEMINI_API_KEY missing in .env"
  fi

  if grep -q '^BACKEND_API_TOKEN=' .env; then
    ok "BACKEND_API_TOKEN present"
  else
    err "BACKEND_API_TOKEN missing in .env"
  fi

  if grep -q '^BACKEND_BASE_URL=' .env; then
    base_url="$(grep '^BACKEND_BASE_URL=' .env | head -n1 | cut -d'=' -f2-)"
    if [[ "$base_url" =~ ^https:// ]]; then
      ok "BACKEND_BASE_URL uses https"
    else
      if [[ "$strict_mode" == "1" ]]; then
        err "BACKEND_BASE_URL is not https: $base_url"
      else
        warn "BACKEND_BASE_URL is not https: $base_url"
      fi
    fi
    if [[ "$base_url" =~ 10\.0\.2\.2|localhost|127\.0\.0\.1 ]]; then
      if [[ "$strict_mode" == "1" ]]; then
        err "BACKEND_BASE_URL appears local/dev-only: $base_url"
      else
        warn "BACKEND_BASE_URL appears local/dev-only: $base_url"
      fi
    fi
  else
    err "BACKEND_BASE_URL missing in .env"
  fi
else
  err "Missing .env"
fi

if [[ "$has_error" -ne 0 ]]; then
  echo "[verify_prod_backend_setup] FAILED: fix errors above."
  exit 1
fi

echo "[verify_prod_backend_setup] PASSED: production wiring prerequisites are in place."
