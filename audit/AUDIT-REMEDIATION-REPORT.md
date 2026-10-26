# Remediation Report: CarbonTracker

**Developer:** Aneesa Fatime
**Audit report:** `audit/AUDIT_REPORT.md`

## Summary

All 3 findings have been addressed. Findings 1 and 2 are fixed in this repo. Finding 3 concerns the
watch app, so it is fixed in the watch repo.

## Findings

### 1. AOSSIE logo not displaying correctly on splash screen

- **Status:** Fixed (this repo)
- **Fix:** Android 12+ crops and scales the splash image into a circle. Added a padded square logo
  for Android 12 and pointed `android_12` in `flutter_native_splash` to it.

### 2. Matchmaking API error during onboarding

- **Status:** Fixed (this repo)
- **Fix:** In `MainActivity.kt`, moved the feature check into
  performMatchmaking() so every path uses it. The listed matchmaking statuses (e.g., not_available,
  failed) no longer block onboarding.

### 3. Room schema export warning (watch app)

- **Status:** Fixed in the **watch repo**, since it concerns the watch app.
- **Fix:** Added `room.schemaLocation` to the wear module's `build.gradle.kts` and committed the
  generated `schemas/` folder. The build no longer shows the warning.
