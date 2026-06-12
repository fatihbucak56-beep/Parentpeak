#!/usr/bin/env bash

set -euo pipefail

echo "[prepare_apple_build] Starting Apple build preparation..."

if ! command -v flutter >/dev/null 2>&1; then
  echo "[prepare_apple_build] ERROR: flutter is not installed or not on PATH."
  exit 1
fi

# Flutter may emit warnings for plugins that do not support SPM yet.
# We explicitly prefer CocoaPods while plugins are catching up.
if flutter config --help 2>/dev/null | grep -q "enable-swift-package-manager"; then
  flutter config --no-enable-swift-package-manager
  echo "[prepare_apple_build] Swift Package Manager disabled for Flutter plugins."
else
  echo "[prepare_apple_build] Flutter config flag not available; skipping SPM toggle."
fi

flutter pub get

if [ -d "ios" ]; then
  echo "[prepare_apple_build] Running CocoaPods install for iOS..."
  (
    cd ios
    pod install --repo-update
  )
fi

if [ -d "macos" ]; then
  echo "[prepare_apple_build] Running CocoaPods install for macOS..."
  (
    cd macos
    pod install --repo-update
  )
fi

echo "[prepare_apple_build] Done. You can now run Flutter build commands for iOS/macOS."
