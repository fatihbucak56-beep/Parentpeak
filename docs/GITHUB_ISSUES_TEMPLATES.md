# GitHub Issues Templates & Textblocks

This document provides pre-formatted GitHub issue templates for common work packages. Copy and paste directly into GitHub issue creation.

---

## SPM Plugin Migration Work Package

### Issue 1: Migrate `printing` Plugin to Swift Package Manager

**Title:** Upgrade `printing` plugin to support Swift Package Manager (SPM)

**Labels:** `iOS`, `macOS`, `dependencies`, `release-blockers`

**Body:**

```markdown
## Summary
The `printing` plugin currently does not support Swift Package Manager for iOS and macOS. This will become an error in a future Flutter version and must be resolved before release.

## Details
- **Current Status:** Warnings appear in `flutter analyze` for iOS and macOS builds.
- **Plugin:** `printing` v7.x.x
- **Impact:** App builds successfully, but SPM adoption is blocked.
- **Timeline:** Must upgrade before final release.

## Acceptance Criteria
- [ ] Upgrade `printing` to a version that supports SPM
- [ ] Run `flutter analyze` and verify no SPM-related warnings for iOS/macOS
- [ ] Confirm printing functionality works in debug and release builds
- [ ] Update `pubspec.yaml` lock file and document the version bump

## Steps
1. Check pub.dev for latest `printing` version with SPM support
2. Update `pubspec.yaml` with new version
3. Run `flutter pub get`
4. Build iOS and macOS targets to verify
5. Confirm printing features (PDF generation, etc.) still work as expected

## Notes
- Consider checking the plugin's GitHub repository for SPM support status before upgrading
- If no SPM-compatible version exists, investigate alternative plugins or file an issue with the plugin maintainer
```

---

### Issue 2: Migrate `flutter_tts` Plugin to Swift Package Manager

**Title:** Upgrade `flutter_tts` plugin to support Swift Package Manager (SPM)

**Labels:** `iOS`, `macOS`, `dependencies`, `release-blockers`

**Body:**

```markdown
## Summary
The `flutter_tts` plugin currently does not support Swift Package Manager for iOS and macOS. This will become an error in a future Flutter version and must be resolved before release.

## Details
- **Current Status:** Warnings appear in `flutter analyze` for iOS and macOS builds.
- **Plugin:** `flutter_tts` (current version)
- **Impact:** App builds successfully, but SPM adoption is blocked.
- **Timeline:** Must upgrade before final release.

## Acceptance Criteria
- [ ] Upgrade `flutter_tts` to a version that supports SPM
- [ ] Run `flutter analyze` and verify no SPM-related warnings for iOS/macOS
- [ ] Confirm text-to-speech functionality works in debug and release builds
- [ ] Update `pubspec.yaml` lock file and document the version bump

## Steps
1. Check pub.dev for latest `flutter_tts` version with SPM support
2. Update `pubspec.yaml` with new version
3. Run `flutter pub get`
4. Build iOS and macOS targets to verify
5. Test text-to-speech features in-app (e.g., voice announcements, notification TTS)

## Notes
- Text-to-speech is used in Parentpeak for accessibility; ensure voice output works after upgrade
- Check plugin's GitHub/pub.dev for breaking changes or API updates
```

---

### Issue 3: Migrate `mobile_scanner` Plugin to Swift Package Manager (iOS)

**Title:** Upgrade `mobile_scanner` plugin to support Swift Package Manager (SPM) for iOS

**Labels:** `iOS`, `dependencies`, `release-blockers`

**Body:**

```markdown
## Summary
The `mobile_scanner` plugin currently does not support Swift Package Manager for iOS. This will become an error in a future Flutter version and must be resolved before release.

## Details
- **Current Status:** Warning appears in `flutter analyze` for iOS builds.
- **Plugin:** `mobile_scanner` (current version)
- **Impact:** App builds successfully, but SPM adoption is blocked.
- **Timeline:** Must upgrade before final release.

## Acceptance Criteria
- [ ] Upgrade `mobile_scanner` to a version that supports SPM for iOS
- [ ] Run `flutter analyze` and verify no SPM-related warnings for iOS
- [ ] Confirm QR/barcode scanning functionality works in debug and release builds
- [ ] Test on physical iOS device to ensure camera permissions and scanning work correctly
- [ ] Update `pubspec.yaml` lock file and document the version bump

## Steps
1. Check pub.dev for latest `mobile_scanner` version with iOS SPM support
2. Update `pubspec.yaml` with new version
3. Run `flutter pub get`
4. Build iOS target and test on a physical device
5. Verify QR code scanning in-app (e.g., backup QR restoration flow)

## Notes
- Mobile scanner is critical for backup QR code recovery; ensure this feature is thoroughly tested
- iOS camera privacy settings may need adjustment; verify Info.plist is updated
- macOS does not show this warning; only iOS requires attention
```

---

## Related Documentation

- **Current SPM Status:** See [docs/SPM_PLUGIN_STATUS.md](SPM_PLUGIN_STATUS.md) for full tracking and timeline.
- **Crashlytics Checklist:** See [docs/CRASHLYTICS_RELEASE_CHECKLIST.md](CRASHLYTICS_RELEASE_CHECKLIST.md) for crash reporting validation and deployment workflow.
- **Release Readiness:** Core app hardening (error monitoring, auth release-path, test coverage) is tracked in the main repository.
