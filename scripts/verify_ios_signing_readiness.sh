#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

has_error=0
project_file="ios/Runner.xcodeproj/project.pbxproj"

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

echo "[verify_ios_signing_readiness] Checking iOS signing prerequisites..."

if command -v xcodebuild >/dev/null 2>&1; then
  ok "Xcode command line tools available"
else
  err "xcodebuild missing (install Xcode and run xcode-select --install)"
fi

if [[ -f "$project_file" ]]; then
  ok "Found $project_file"
else
  err "Missing $project_file"
fi

if [[ -f "ios/Runner/GoogleService-Info.plist" ]]; then
  ok "Found ios/Runner/GoogleService-Info.plist"
else
  warn "Missing ios/Runner/GoogleService-Info.plist (required for Firebase at runtime)"
fi

identities_output="$(security find-identity -v -p codesigning 2>/dev/null || true)"
if echo "$identities_output" | grep -Eq '^[[:space:]]*[0-9]+\) [0-9A-F]{40} '; then
  ok "At least one valid code-signing identity is available"
else
  err "No valid code-signing identity found in keychain"
fi

if [[ -f "$project_file" ]]; then
  team_id="$(grep -E 'DEVELOPMENT_TEAM = [A-Z0-9]{10};' "$project_file" | head -n1 | sed -E 's/.*DEVELOPMENT_TEAM = ([A-Z0-9]{10});.*/\1/' || true)"
  if [[ -n "$team_id" ]]; then
    ok "DEVELOPMENT_TEAM set in Xcode project ($team_id)"
  else
    err "DEVELOPMENT_TEAM missing in $project_file"
  fi

  if grep -q 'CODE_SIGN_STYLE = Automatic;' "$project_file"; then
    ok "CODE_SIGN_STYLE is Automatic"
  else
    warn "CODE_SIGN_STYLE is not Automatic (manual provisioning may be required)"
  fi

  bundle_id="$(grep -E 'PRODUCT_BUNDLE_IDENTIFIER = ' "$project_file" | grep -v RunnerTests | head -n1 | sed -E 's/.*PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);/\1/' || true)"
  if [[ -n "$bundle_id" ]]; then
    ok "PRODUCT_BUNDLE_IDENTIFIER detected ($bundle_id)"
  else
    err "PRODUCT_BUNDLE_IDENTIFIER missing in $project_file"
  fi
fi

if [[ "$has_error" -ne 0 ]]; then
  echo "[verify_ios_signing_readiness] FAILED:"
  echo "  1) Open ios/Runner.xcworkspace in Xcode"
  echo "  2) Select Runner target -> Signing & Capabilities"
  echo "  3) Set Team and let Xcode create/manage provisioning"
  echo "  4) Re-run: bash scripts/verify_ios_signing_readiness.sh"
  exit 1
fi

echo "[verify_ios_signing_readiness] PASSED: iOS signing prerequisites are in place."
