#!/usr/bin/env bash

set -uo pipefail

# CI-safe wrapper for flutter analyze.
# Goal: keep failing on real analyzer issues, but do not fail on known
# Swift Package Manager plugin support warnings from Flutter tooling.

OUTPUT_FILE="$(mktemp)"
trap 'rm -f "$OUTPUT_FILE"' EXIT

ANALYZE_TARGETS=()
if [ "$#" -gt 0 ]; then
  ANALYZE_TARGETS=("$@")
else
  # Avoid scanning generated/vendor folders (for example build/SourcePackages)
  # and focus on first-party Dart code that we own.
  for dir in lib test tool; do
    if [ -d "$dir" ]; then
      ANALYZE_TARGETS+=("$dir")
    fi
  done
fi

# Keep CI strict on compile/analyzer errors while allowing existing lint debt.
flutter analyze --no-fatal-infos --no-fatal-warnings "${ANALYZE_TARGETS[@]}" 2>&1 | tee "$OUTPUT_FILE"
ANALYZE_EXIT=${PIPESTATUS[0]}

if [ "$ANALYZE_EXIT" -eq 0 ]; then
  exit 0
fi

if grep -Eq "error •|[0-9]+ issues found" "$OUTPUT_FILE"; then
  echo "[ci_flutter_analyze] Analyzer reported issues. Failing build."
  exit "$ANALYZE_EXIT"
fi

if grep -q "The following plugins do not support Swift Package Manager" "$OUTPUT_FILE"; then
  echo "[ci_flutter_analyze] Ignoring known SPM plugin support warning (no analyzer issues found)."
  exit 0
fi

echo "[ci_flutter_analyze] flutter analyze failed for an unknown reason. Failing build."
exit "$ANALYZE_EXIT"
