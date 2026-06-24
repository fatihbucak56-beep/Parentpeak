# TestFlight Smoke Test – Crashlytics Release Validation

This document provides step-by-step instructions for validating Parentpeak's Crashlytics error reporting on TestFlight before production release.

## Prerequisites

- Internal TestFlight build deployed to TestFlight testers group
- Access to [Firebase Console](https://console.firebase.google.com) for the Parentpeak project
- At least one iOS device (physical or simulator) for testing
- ~10–15 minutes for full validation

## Steps

### 1. Install TestFlight Build on Device

1. Open **TestFlight** app on iOS device
2. Navigate to **Parentpeak** → tap **Install** (or **Update** if already installed)
3. Wait for installation to complete
4. Open the app to confirm it launches successfully

**Expected Outcome:** App launches without errors, shows home/login screen normally.

---

### 2. Verify App Logs Network Connectivity

1. Open **Settings** → **Parentpeak** → check app has **WiFi** and/or **Cellular** permission
2. Open **Parentpeak** app and navigate to **Profile** tab
3. Observe that the app connects to backend (family data loads, profile info displays)

**Expected Outcome:** App communicates with backend; no obvious network errors in UI.

---

### 3. Trigger a Test Non-Fatal Error

To verify Crashlytics reports errors correctly, we'll simulate a controlled non-fatal error:

1. Open **Parentpeak** and navigate to **Events & Aktivitäten** tab
2. Disable internet/WiFi on device (Settings → WiFi → toggle off, or use airplane mode)
3. Try to **pull-to-refresh** or **load more events**
4. Observe that the app displays a snackbar error message (e.g., "Netzwerkfehler" or "Connection failed")
5. **Re-enable internet** and allow app to recover

**Expected Outcome:** App gracefully handles the error; snackbar appears; no crash.

**Technical Details:**
- This action triggers an API failure in `EventDiscoveryAgent`
- The error is caught, logged, and reported to Crashlytics via `ErrorReportingService`
- The error will appear in Firebase Crashlytics within **5–10 minutes** after re-enabling internet

---

### 4. (Optional) Trigger a Controlled Crash

**⚠️ Advanced Testing Only** – This step intentionally crashes the app to validate crash reporting.

To implement a crash trigger button (for advanced QA only):

```dart
// Add this to a debug/test screen (e.g., Profile tab hidden button)
FloatingActionButton(
  onPressed: () {
    // Intentional crash for testing Crashlytics
    throw Exception('Test crash for Crashlytics validation');
  },
  label: Text('Test Crash (QA only)'),
)
```

If you implement this:
1. Tap the crash button
2. App will crash and restart
3. On restart, Crashlytics will automatically send the crash report
4. Check Firebase Crashlytics console (see step 5 below) within **5–10 minutes**

**⚠️ Remove crash button before release** – Do not ship this code to production.

---

### 5. Verify Crashlytics Receives the Error

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select **Parentpeak** project
3. Navigate to **Crashlytics** in the left menu
4. Wait **5–10 minutes** for the error/crash to appear in the dashboard
5. Look for:
   - **Error Details:** Should show the network error or controlled crash
   - **Stack Trace:** Should show readable function names and file names (not hexadecimal)
   - **Affected Users:** Should show 1 (your test device)
   - **Timestamp:** Should match when you triggered the error

**Expected Outcome:**
```
EventDiscoveryAgent: ❌ Failed to fetch events
Stack trace (readable):
  0  EventDiscoveryAgent.loadEvents()
  1  EventsActivitiesScreen.build()
  2  ...
Affected Users: 1
```

**If Stack Trace is NOT Readable (shows hex addresses):**
- dSYM was not uploaded to Firebase
- Re-check [CRASHLYTICS_RELEASE_CHECKLIST.md](CRASHLYTICS_RELEASE_CHECKLIST.md) section "dSYM and Symbol Upload"
- Rebuild and re-upload dSYM following the iOS build procedure

---

### 6. Verify Debug Flag Behavior

Confirm that **debug/test builds do NOT send errors to Crashlytics**:

1. Run debug build on device:
   ```bash
   flutter run --debug
   ```
2. Trigger the same network error (pull-to-refresh with WiFi off)
3. Check Firebase Crashlytics console – **no new error should appear** after 10 minutes
4. Check device logs (`flutter logs`) – should show `debugPrint` logs instead

**Expected Outcome:** 
- Debug build: errors logged locally only (console output)
- Release build: errors sent to Firebase Crashlytics

---

### 7. Verify App Stability in Production Paths

Test the following critical user flows on the TestFlight build:

#### 7.1 Authentication Flow
- [ ] Login with valid credentials
- [ ] Logout and re-login
- [ ] Verify no authentication errors in Crashlytics

#### 7.2 Create Event Flow
- [ ] Navigate to Events tab → Create Event
- [ ] Fill in event details (name, date, location, participants)
- [ ] Submit event
- [ ] Verify event appears in home feed
- [ ] Check Crashlytics – no creation errors should appear

#### 7.3 Payment/Paywall Flow
- [ ] Navigate to Profile → unlock premium features
- [ ] Tap "Upgrade to Premium"
- [ ] Verify paywall displays correctly
- [ ] Close paywall without purchasing
- [ ] Check Crashlytics – no paywall errors

#### 7.4 Tab Navigation
- [ ] Switch between Home → Profile → Events tabs rapidly (5–10 times)
- [ ] Verify no UI glitches or crashes
- [ ] Check Crashlytics – no memory/lifecycle errors

**Expected Outcome:** All flows complete without errors; Crashlytics remains quiet (no unexpected errors).

---

### 8. Final Verification

After completing all steps above:

1. **Confirm Crashlytics Dashboard is Clean:**
   - Only test errors from step 3 appear (network error)
   - No unexpected crashes or errors
   - Stack traces are readable (properly symbolicated)

2. **Confirm Device Behavior:**
   - App is responsive and stable
   - Tab navigation is smooth
   - No freezing, stuttering, or crashes during normal use

3. **Record Results:**
   - Date/time of test: _______________
   - Build version: _______________
   - Device model: _______________
   - iOS version: _______________
   - Errors observed: _______________
   - Pass/Fail: _______________

---

## Troubleshooting

### Errors Not Appearing in Crashlytics

**Symptom:** Error triggered but doesn't appear in Firebase Console after 15 minutes.

**Solutions:**
1. Confirm device has internet connection (WiFi or cellular)
2. Confirm app has **Background App Refresh** permission enabled (Settings → Parentpeak → Background App Refresh)
3. Verify Firebase project credentials are correct in app
4. Check Firebase Console is showing the correct project (top-left dropdown)
5. Try force-killing the app and waiting another 5 minutes (Crashlytics batches reports)

### Stack Traces Show Hex Addresses Instead of Function Names

**Symptom:** Stack trace in Crashlytics shows `0x00a2f4b8` instead of `EventDiscoveryAgent.loadEvents()`.

**Solution:** dSYM upload failed for iOS.
- Rebuild release app with dSYM upload enabled
- Manually upload dSYM using Firebase CLI or Xcode build phase
- See [CRASHLYTICS_RELEASE_CHECKLIST.md](CRASHLYTICS_RELEASE_CHECKLIST.md) section "dSYM and Symbol Upload"

### App Crashes During TestFlight Test

**Symptom:** App crashes when performing a user flow.

**Solution:**
1. Check Crashlytics dashboard – the crash should appear
2. Investigate the stack trace to identify the root cause
3. File a GitHub issue with the crash details and stack trace
4. Fix the issue and redeploy TestFlight build
5. Re-run the smoke test

---

## Sign-Off Checklist

- [ ] Release APK/IPA built successfully
- [ ] TestFlight build deployed to internal testers
- [ ] Test network error triggered and verified in Crashlytics (5–10 min delay)
- [ ] Stack traces are readable (properly symbolicated)
- [ ] Debug flag behavior verified (debug build doesn't send to Crashlytics)
- [ ] Critical user flows tested without crashes
- [ ] No unexpected errors in Crashlytics dashboard
- [ ] Device stability confirmed (smooth navigation, responsive UI)

**If all items are checked:** ✅ **Release-Ready**

---

## Next Steps After Validation

1. **Deploy to Production:** If all smoke tests pass, proceed with App Store/Play Store release
2. **Monitor First 24 Hours:** Keep Crashlytics dashboard open and monitor for issues
3. **Set Up Alerts:** Configure Crashlytics alerts for critical error spikes (see [CRASHLYTICS_RELEASE_CHECKLIST.md](CRASHLYTICS_RELEASE_CHECKLIST.md))
4. **Triage Any Issues:** Assign crashes to team members and create follow-up fixes

---

## References

- [CRASHLYTICS_RELEASE_CHECKLIST.md](CRASHLYTICS_RELEASE_CHECKLIST.md) – Full deployment workflow
- [Firebase Crashlytics Documentation](https://firebase.google.com/docs/crashlytics)
- [Flutter TestFlight Guide](https://flutter.dev/docs/deployment/ios)
