# Parentpeak Web MVP Plan

## Goal
Launch Parentpeak Web as a lean growth channel while keeping iOS/Android as primary product surfaces.

## Current Status
- Flutter web platform files are enabled (`web/` created).
- Debug run in Chrome works.
- Release web build works (`build/web` generated).

## Product Scope (Phase 1)
Include:
- Home navigation and basic onboarding
- Treasure feed browsing
- Treasure detail view
- Reserve/handover intent flow

Defer to later phases:
- Heavy camera-first creation flows
- Mobile-native-only interactions
- Non-essential secondary modules

## Phase Plan

### Phase 1: Technical Baseline (done)
- Enable web target in Flutter project.
- Verify `flutter run -d chrome` launches.
- Verify `flutter build web --release` succeeds.

### Phase 2: Web UX Hardening (next)
- Add responsive breakpoints for small/medium/large layouts.
- Improve desktop spacing and max-content width.
- Ensure long text and chips never overflow.
- Replace or hide mobile-only affordances where needed.

### Phase 3: Web Launch Readiness
- Add environment configuration for production API base URLs.
- Add smoke test checklist for core web flows.
- Deploy preview and production pipelines.
- Add analytics events for acquisition funnel.

## Technical Notes
- `flutter_tts` reports Wasm dry-run incompatibility warnings. Current JS web build still works.
- Existing iOS/macOS Swift Package Manager warnings remain unrelated to web shipping.

## Runbook

### Local run
```bash
flutter run -d chrome --target lib/main.dart
```

### Production build
```bash
flutter build web --release
```

### Output
- Build artifacts: `build/web`

## Acceptance Criteria for Web MVP
- App launches in Chrome with no runtime crashes.
- Treasure browse -> detail -> reserve flow is usable on desktop and mobile web viewport.
- No visible text overflow in treasure handover and feed cards.
- Release web build is reproducible in CI.
