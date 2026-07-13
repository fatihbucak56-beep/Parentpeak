# Apple SPM Plugin Status

## Why this exists
Flutter currently prints warnings for plugins that do not yet support Swift Package Manager (SPM), for example `printing`, `flutter_tts`, and `mobile_scanner`.

These warnings are currently non-blocking, but Flutter notes they may become errors in future versions.

## Current handling
- Repo-safe local Flutter wrapper: `bash scripts/flutter_repo.sh <flutter-args>`
- Local Apple builds: use `bash scripts/prepare_apple_build.sh`
- CI analyze: use `bash scripts/ci_flutter_analyze.sh`

The repo-safe wrapper does two things automatically:
- disables Flutter plugin SPM integration when the Flutter version supports the flag
- filters the known SPM warning block from terminal output while keeping real Flutter/analyzer failures intact

The CI wrapper still fails on real analyzer findings and only tolerates the known SPM support warning text when no analyzer issues are present.

## Migration trigger checklist
Switch from workaround to normal flow when all items are true:
- `flutter analyze` no longer prints SPM support warnings for Apple targets
- Required plugins (`printing`, `flutter_tts`) document SPM support in their release notes
- Apple builds (`flutter build ios`, `flutter build macos`) pass without CocoaPods fallback steps

## Team quick check
Run:
- `flutter pub outdated`
- `bash scripts/flutter_repo.sh analyze`
- `bash scripts/prepare_apple_build.sh` (Apple local builds)

If warnings disappear, remove the CI wrapper and keep a normal `flutter analyze` step.

## Current warning set (2026-06-24)
- iOS: `printing`, `mobile_scanner`, `flutter_tts`
- macOS: `printing`, `flutter_tts`

## Work package (release tracking)
Track these items as separate tickets in your issue system:

1. P1: SPM compatibility watch for Apple targets
- Scope: monitor `printing`, `mobile_scanner`, `flutter_tts` release notes for SPM support and test upgrades in a branch.
- Done when: warnings disappear in `bash scripts/flutter_repo.sh analyze` and Apple builds still pass.

2. P1: Dependency refresh cadence
- Scope: run `flutter pub outdated` weekly, upgrade non-breaking versions, and re-run analyze/tests.
- Done when: no pending non-major updates remain for Apple-relevant plugins.

3. P0: CI gate keeps real failures visible
- Scope: keep `bash scripts/ci_flutter_analyze.sh` in pipeline until migration triggers are fully met.
- Done when: pipeline catches analyzer errors while tolerating only the known SPM warning block.
