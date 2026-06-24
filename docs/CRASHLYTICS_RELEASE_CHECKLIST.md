# Crashlytics Release Checklist

This document describes the step-by-step workflow for validating and deploying Parentpeak with Firebase Crashlytics error reporting enabled.

## Pre-Release Validation

### 1. Verify Crashlytics Integration

```bash
# Check that the ErrorReportingService is properly initialized
grep -r "ErrorReportingService\(\)" lib/main.dart

# Verify Crashlytics dependency is present
grep "firebase_crashlytics" pubspec.yaml

# Ensure debug flag toggling is working
grep -A 3 "kDebugMode" lib/logic/error_reporting_service.dart
```

**Expected Outcome:** All three checks return matches showing the integration is in place.

### 2. Run Full Test Suite

```bash
flutter test
```

**Expected Outcome:** All tests pass (currently 38 tests green).

### 3. Run Static Analysis

```bash
flutter analyze
```

**Expected Outcome:** No issues found.

### 4. Test Crash Reporting in Debug Mode

Create a temporary test file to verify Crashlytics records crashes:

```dart
// File: test/crashlytics_test.dart (temporary, delete after validation)
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() {
  testWidgets('Crashlytics logs non-fatal errors', (WidgetTester tester) async {
    // Verify Crashlytics is initialized
    expect(FirebaseCrashlytics.instance, isNotNull);

    // Record a test non-fatal error
    await FirebaseCrashlytics.instance.recordError(
      Exception('Test error for validation'),
      StackTrace.current,
      reason: 'Crashlytics integration test',
    );

    // In debug mode, this should be logged but NOT sent to Firebase
    // In release mode, this WILL be sent to Firebase
  });
}
```

**Run:** `flutter test test/crashlytics_test.dart`

**Expected Outcome:** Test passes; no runtime errors; debug output shows error recorded.

### 5. Verify Debug Flag Behavior

- **Debug/Test Build:** Error reporting is **disabled** (logs locally only).
  - Firebase initialization is skipped (`disableFirebaseInitForTesting = true`).
  - Calls to `ErrorReportingService.reportError()` log to `debugPrint` only.
  
- **Release Build:** Error reporting is **enabled** (reports to Firebase).
  - Firebase initializes normally.
  - Calls to `ErrorReportingService.reportError()` forward to Crashlytics.

Verify this behavior:
```bash
# Debug build (default):
flutter run  # Should NOT send errors to Firebase

# Release build:
flutter run --release  # WILL send errors to Firebase
```

## dSYM and Symbol Upload (iOS)

### 1. Build iOS Release Archive

```bash
flutter build ios --release
```

### 2. Upload dSYM to Crashlytics

Firebase Crashlytics for iOS requires debug symbols (dSYM) for proper stack trace symbolication.

**Automatic Upload (Recommended):**
- If you've integrated the Crashlytics build phase script in Xcode, dSYMs are uploaded automatically during the build.
- Check that the build phase exists in Xcode: **Build Phases** → look for **"Crashlytics" run script**.

**Manual Upload (If Needed):**
```bash
# After building, upload dSYMs manually
cd ios
./Pods/FirebaseCrashlytics/upload-symbols \
  -gsp GoogleService-Info.plist \
  -p ios \
  ../build/ios/archive/Parentpeak.xcarchive/dSYMs
```

### 3. Verify Upload in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com).
2. Navigate to **Parentpeak project** → **Crashlytics**.
3. Check **"Symbol Files"** section; confirm the build's dSYM is listed with the correct UUID.

## Release Build & Deployment

### 1. Create Release Build

```bash
flutter build apk --release     # Android
flutter build ios --release     # iOS (archive for TestFlight/App Store)
```

### 2. Deploy to TestFlight or Internal Testing Track

- **iOS:** Archive and upload to TestFlight for internal testers.
- **Android:** Upload to Google Play internal testing track.

### 3. Perform Smoke Test on Release Build

On the testflight/internal build:
1. **Trigger a Non-Fatal Error:**
   - Navigate to a screen that exercises the error-reporting path.
   - Example: Disable network, attempt an API call, observe error is reported.

2. **Verify Crash Reports Appear:**
   - Open [Firebase Console](https://console.firebase.google.com) → **Crashlytics**.
   - Within 5–10 minutes, new crash/error should appear.
   - Verify stack trace is **properly symbolicated** (readable function/file names, not hexadecimal addresses).

**If Stack Traces Are Not Symbolicated:**
- dSYM upload may have failed; re-check Firebase Console symbol files.
- Rebuild and re-upload dSYM following the section above.

### 4. Monitor Initial Release

After production deployment:
1. Monitor **Crashlytics Dashboard** for crashes/errors in the first 24 hours.
2. Establish alerts for critical error spikes (Firebase allows setting up notification rules).
3. Keep a changelog of known issues and their resolution status.

## Post-Release

### 1. Set Up Crash Monitoring Alerts

In Firebase Console:
1. Navigate to **Crashlytics** → **Alerts** (if available in your plan).
2. Configure alert thresholds (e.g., notify on any new crash type, or if error rate exceeds X% of sessions).

### 2. Document Known Issues

If crashes are discovered post-release:
- File a GitHub issue with the Crashlytics link and stack trace.
- Tag as `[Crash]` or `[Critical]` depending on severity.
- Link to the Firebase Crashlytics issue for tracking.

### 3. Triage and Fix

- Assign crashes to team members based on component.
- Create hotfix PRs and deploy follow-up releases.
- Once fixed, deploy new release and monitor for regression.

## Rollback Plan

If Crashlytics introduces instability:
1. **Immediate:** Disable error reporting by setting `disableFirebaseInitForTesting = true` globally (temporary measure).
2. **Short-term:** Revert the Crashlytics dependency from `pubspec.yaml` and the integration code.
3. **Medium-term:** Investigate root cause and re-integrate with fixes.

## Troubleshooting

### Crashlytics Dashboard Shows No Data

- Confirm release build is deployed (not debug).
- Verify app has network access (crashes are sent only on next app launch or after timeout).
- Check Firebase project credentials are correctly configured in the app.
- Ensure dSYM (iOS) is uploaded for proper symbolication.

### Stack Traces Are Not Symbolicated

- Re-upload dSYM via Firebase Console or re-run the build script.
- Verify the dSYM UUID matches the app build version.

### Local Testing Sends Errors to Firebase

- Confirm `disableFirebaseInitForTesting = true` is set before tests/debug builds.
- Check that `kDebugMode` is correctly detected by Flutter.

## References

- [Firebase Crashlytics Documentation](https://firebase.google.com/docs/crashlytics)
- [Flutter Firebase Plugin](https://pub.dev/packages/firebase_crashlytics)
- [dSYM Upload for iOS](https://firebase.google.com/docs/crashlytics/get-deobfuscated-stack-traces#upload-ios-symbols)
