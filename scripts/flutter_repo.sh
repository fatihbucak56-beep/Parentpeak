#!/usr/bin/env bash

set -uo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "[flutter_repo] ERROR: flutter is not installed or not on PATH."
  exit 1
fi

# Repo-local safeguard against Flutter plugin SPM warnings on Apple platforms.
if flutter config --help 2>/dev/null | grep -q "enable-swift-package-manager"; then
  flutter config --no-enable-swift-package-manager >/dev/null 2>&1 || true
fi

OUTPUT_FILE="$(mktemp)"
trap 'rm -f "$OUTPUT_FILE"' EXIT

flutter "$@" 2>&1 | tee "$OUTPUT_FILE" | awk '
  BEGIN { skip=0 }
  /^The following plugins do not support Swift Package Manager for ios:/ { skip=1; next }
  /^The following plugins do not support Swift Package Manager for macos:/ { skip=1; next }
  skip && /^  - / { next }
  skip && /^This will become an error in a future version of Flutter\./ { next }
  skip && /^plugin maintainers to request Swift Package Manager adoption\./ { skip=0; next }
  { print }
'
EXIT_CODE=${PIPESTATUS[0]}
exit "$EXIT_CODE"
