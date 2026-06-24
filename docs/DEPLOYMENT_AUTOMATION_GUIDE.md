# Deployment Automation Guide – Parentpeak Release

This guide provides automation scripts and procedures to streamline the release workflow from validation through production deployment.

---

## Prerequisites

- macOS with Xcode installed
- Flutter SDK configured
- GitHub CLI (`gh`) or Git credentials configured
- Firebase CLI configured (for dSYM management, optional)
- Apple Developer Account access (for iOS deployment)
- Google Play Console access (for Android deployment)

---

## 1. Pre-Release Validation (Automated)

### Run Validation Script

```bash
cd /path/to/Parentpeak
chmod +x scripts/validate_release.sh
./scripts/validate_release.sh
```

**What it checks:**
- ✅ Flutter/Dart environment
- ✅ Git working tree status
- ✅ `flutter analyze` (0 issues)
- ✅ `flutter test` (38/38 passing)
- ✅ Dependencies (firebase_crashlytics, etc.)
- ✅ Documentation files present
- ✅ Build artifacts (Android APK)
- ✅ Security checks (hardcoded credentials, silent catches)

**Expected Output:**
```
=== Release Validation Summary ===
Results:
  ✅ Passed: 35
  ⚠️  Warnings: 0
  ❌ Failed: 0
  Total: 35 checks

🎉 All checks passed! App is ready for release.
```

**If failures appear:** Review the specific failure and fix before proceeding.

---

## 2. Build Release Artifacts

### Build Android Release APK

```bash
flutter clean
flutter pub get
flutter build apk --release
```

**Output:**
- Artifact: `build/app/outputs/flutter-apk/app-release.apk`
- Size: ~98.7 MB
- Location for upload: Google Play Console

### Build Android App Bundle (AAB)

```bash
flutter build appbundle --release
```

**Output:**
- Artifact: `build/app/outputs/bundle/release/app-release.aab`
- Recommended for Google Play (better size optimization)

### Build iOS Release IPA

```bash
flutter build ios --release
```

**Output:**
- Artifact: `build/ios/ipa/Parentpeak.ipa`
- Size: ~70 MB (estimated)
- Location for upload: TestFlight or App Store Connect

**Note:** This requires an Apple Developer account and provisioning profiles configured in Xcode.

---

## 3. Post-Build: dSYM Upload (iOS Only)

### Automatic Upload (Preferred)

During the `flutter build ios --release` process, Xcode should automatically upload dSYMs to Crashlytics if the build phase script is installed.

**To verify Xcode build phase:**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** project → **Build Phases**
3. Look for **"Run Script – Crashlytics"** phase
4. If present and enabled, dSYMs will upload automatically

### Manual Upload (If Needed)

```bash
# After building, locate the dSYM
DSYM_PATH="build/ios/archive/Parentpeak.xcarchive/dSYMs"

# Upload via Firebase Crashlytics CLI
cd ios
./Pods/FirebaseCrashlytics/upload-symbols \
  -gsp GoogleService-Info.plist \
  -p ios \
  ../$DSYM_PATH
```

**Verify Upload:**
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Navigate to **Crashlytics** → **Symbol Files**
3. Confirm the new build's dSYM is listed with the correct UUID

---

## 4. Release to TestFlight (iOS)

### Option A: Via Xcode

```bash
# Open Xcode project
open ios/Runner.xcworkspace

# In Xcode:
# 1. Product → Archive
# 2. Distribute App
# 3. Select TestFlight
# 4. Follow dialog to upload
```

### Option B: Via Transporter CLI

```bash
# Sign in to App Store Connect
xcrun altool --username your-apple-id@example.com --password @keychain:Application-Loader

# Upload the IPA
xcrun altool --upload-app -f build/ios/ipa/Parentpeak.ipa \
  -t ios \
  --username your-apple-id@example.com \
  --password @keychain:Application-Loader
```

**After Upload:**
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select **TestFlight** → **Builds**
3. Wait for processing (5–15 minutes)
4. Add internal testers and invite to test

---

## 5. Release to Google Play Console (Android)

### Upload AAB/APK

```bash
# Via web console:
# 1. Go to Google Play Console → Select App → Release
# 2. Choose Internal Testing / Closed Testing / Production
# 3. Click "Create new release"
# 4. Upload app-release.aab or app-release.apk
# 5. Add release notes (reference RELEASE_NOTES_v1.0.0.md)
# 6. Review and publish

# Or use Google Play API (requires setup):
# See: https://developer.android.com/google-play/api/get-started
```

**Testing Track (Recommended):**
- Internal Testing (first)
- Closed Testing (beta testers)
- Production (full rollout or gradual rollout)

---

## 6. Smoke Test Automation

### Run Automated Smoke Tests

```bash
# (Optional) Automate smoke test steps
# This script simulates the manual procedures in TESTFLIGHT_SMOKE_TEST.md

./scripts/smoke_test.sh

# Expected flow:
# 1. Install app on test device
# 2. Trigger test network error
# 3. Wait for Crashlytics dashboard update (10 min)
# 4. Verify error appears with readable stack trace
# 5. Return pass/fail status
```

**Note:** Full automation of UI interactions requires device/emulator. See [docs/TESTFLIGHT_SMOKE_TEST.md](TESTFLIGHT_SMOKE_TEST.md) for manual procedures.

---

## 7. Monitor Post-Release

### Firebase Crashlytics Dashboard

```bash
# Open Firebase Console
open https://console.firebase.google.com/project/parentpeak/crashlytics

# Monitor for:
# - New crash types appearing
# - Error rate spikes
# - Stack trace quality (should be readable, not hex addresses)
```

### Set Up Alerts

1. Go to Firebase Console → **Crashlytics**
2. Click **Alerts** or **Settings**
3. Configure threshold rules:
   - Alert if crash count > 10 in 1 hour
   - Alert if new crash type detected
   - Alert if error rate > 5% of sessions

4. Configure notification channels:
   - Email
   - Slack (if integrated)
   - PagerDuty (if integrated)

---

## 8. Rollback Plan

If critical issues are discovered post-release:

### Quick Rollback (Within Hours)

```bash
# For iOS (TestFlight):
# 1. Go to App Store Connect → TestFlight
# 2. Deselect current build
# 3. Select previous stable build
# 4. Notify testers

# For Android (Google Play):
# 1. Go to Google Play Console → Release
# 2. Click on current release
# 3. Select "Stop rollout" (if gradual)
# 4. Upload previous stable AAB/APK
# 5. Re-publish
```

### Hotfix Release

```bash
# If rollback needed, implement hotfix:
git checkout -b hotfix/v1.0.1
# Fix the critical issue
git commit -m "fix: Critical issue from v1.0.0"
git push origin hotfix/v1.0.1

# Re-run validation and deployment:
./scripts/validate_release.sh
flutter build apk --release
flutter build ios --release
# Upload to TestFlight/Play Console
```

---

## 9. Release Checklist (Mechanical Steps)

```bash
# Step 1: Validate
./scripts/validate_release.sh
# Expected: All checks pass

# Step 2: Build
flutter clean
flutter pub get
flutter build apk --release
flutter build ios --release
# Expected: build/app/outputs/flutter-apk/app-release.apk exists

# Step 3: Verify dSYM (iOS)
open https://console.firebase.google.com/project/parentpeak/crashlytics
# Expected: New build's dSYM listed in Symbol Files

# Step 4: Upload to TestFlight
open https://appstoreconnect.apple.com
# Manual step: Upload IPA, add testers

# Step 5: Smoke Test
# See docs/TESTFLIGHT_SMOKE_TEST.md
# Expected: All 8 steps pass, sign-off checklist complete

# Step 6: Monitor First 24 Hours
open https://console.firebase.google.com/project/parentpeak/crashlytics
# Expected: No unexpected crash spikes

# Step 7: Production Rollout
open https://play.google.com/console
# Manual step: Publish Android build
open https://appstoreconnect.apple.com
# Manual step: Submit iOS for review / release to App Store
```

---

## 10. Debugging Failed Automation

### Common Issues

**Android Build Fails:**
```bash
# Clear caches and rebuild
flutter clean
rm -rf build/
flutter pub get
flutter build apk --release --verbose
```

**iOS Build Fails (Code Signing):**
```bash
# Ensure provisioning profiles are installed
open ios/Runner.xcworkspace
# In Xcode: Signing & Capabilities → Verify signing team and certificate
```

**Crashlytics dSYM Upload Fails:**
```bash
# Verify build phase script exists in Xcode
open ios/Runner.xcworkspace
# Product → Build Phases → Look for Crashlytics run script

# If missing, add it manually:
# See: https://firebase.google.com/docs/crashlytics/get-started#ios
```

**TestFlight Upload Fails:**
```bash
# Verify Apple ID has necessary permissions
# App Manager or Developer role required
# Check xcode-select is pointing to correct Xcode:
xcode-select --print-path

# If needed, switch:
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

---

## 11. Continuous Integration (Future)

To automate this further, set up GitHub Actions CI/CD:

```yaml
# .github/workflows/release.yml
name: Release Pipeline

on:
  push:
    tags:
      - 'v*'

jobs:
  validate:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: ./scripts/validate_release.sh
  
  build:
    needs: validate
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter build apk --release
      - run: flutter build ios --release
      - uses: actions/upload-artifact@v3
        with:
          name: release-artifacts
          path: build/
  
  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/download-artifact@v3
      - name: Deploy to TestFlight/Play Console
        run: |
          # Add deployment logic here
```

---

## References

- [Flutter Release Documentation](https://flutter.dev/docs/deployment)
- [Firebase Crashlytics Setup](https://firebase.google.com/docs/crashlytics/get-started)
- [App Store Connect Help](https://help.apple.com/app-store-connect)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)

---

**Ready to automate your release workflow!** ✅
