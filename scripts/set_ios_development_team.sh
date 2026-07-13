#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

TEAM_ID="${1:-${IOS_DEVELOPMENT_TEAM:-}}"
if [[ -z "$TEAM_ID" ]]; then
  echo "[set_ios_development_team] ERROR: Missing Team ID."
  echo "Usage: bash scripts/set_ios_development_team.sh ABCDE12345"
  echo "Or set env: IOS_DEVELOPMENT_TEAM=ABCDE12345"
  exit 1
fi

if [[ ! "$TEAM_ID" =~ ^[A-Z0-9]{10}$ ]]; then
  echo "[set_ios_development_team] ERROR: Team ID must be 10 chars (A-Z, 0-9)."
  exit 1
fi

PROJECT_FILE="ios/Runner.xcodeproj/project.pbxproj"
if [[ ! -f "$PROJECT_FILE" ]]; then
  echo "[set_ios_development_team] ERROR: Missing $PROJECT_FILE"
  exit 1
fi

tmp_file="$(mktemp)"

# Ensure Runner target build configs (Debug/Release/Profile) have exactly one DEVELOPMENT_TEAM.
awk -v team="$TEAM_ID" '
  /97C147061CF9000F007C117D \/\* Debug \*\// {in_runner_cfg=1; inserted=0}
  /97C147071CF9000F007C117D \/\* Release \*\// {in_runner_cfg=1; inserted=0}
  /249021D4217E4FDB00AE95B9 \/\* Profile \*\// {in_runner_cfg=1; inserted=0}
  in_runner_cfg && /DEVELOPMENT_TEAM = [A-Z0-9]{10};/ {
    next
  }
  in_runner_cfg && /PRODUCT_BUNDLE_IDENTIFIER = com.parentpeak.app;/ {
    print $0
    print "\t\t\t\tDEVELOPMENT_TEAM = " team ";"
    inserted=1
    next
  }
  in_runner_cfg && /};/ {
    if (!inserted) {
      print "\t\t\t\tDEVELOPMENT_TEAM = " team ";"
    }
    in_runner_cfg=0
  }
  {print}
' "$PROJECT_FILE" > "$tmp_file"

mv "$tmp_file" "$PROJECT_FILE"

echo "[set_ios_development_team] Applied DEVELOPMENT_TEAM=${TEAM_ID}"
echo "[set_ios_development_team] Next: bash scripts/verify_ios_signing_readiness.sh"
