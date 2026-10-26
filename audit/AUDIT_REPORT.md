You can raise this report for me # Audit Report: <Project Name>

**Auditor:** Vaibhav Aryan
**Auditee:** Aneesa Fatima
**Repo:** https://github.com/AOSSIE-Org/CarbonTracker.git https://github.com/AOSSIE-Org/CarbonTracker-WatchCompanionApp

## Method
Manually tested the app's features and did a code review.

## Findings

### 1. AOSSIE logo not displaying correctly on splash screen (UI, Low)
- **Where:** Splash screen
- **Issue:** The AOSSIE logo does not render correctly.
- **Suggested fix:** Check the asset path and that it is declared in `pubspec.yaml`. 

### 2. Matchmaking API returns an error during onboarding (Logic, High)
- **Where:** Onboarding, matchmaking step
- **Issue:** The matchmaking API call fails with an error, so users cannot complete onboarding.
- **Suggested fix:** Check the endpoint URL, request payload and server status. Also add error handling so the app shows a friendly message and a retry option instead of failing.

### 3. Room database warning when building the watch app (Build, Low)
- **Where:** Watch app build
- **Issue:** The build shows a Room warning that no schema export directory is provided.
- **Suggested fix:** Set `room.schemaLocation` in the module's `build.gradle`. If schema export isn't needed, set `exportSchema = false`.

## Summary
3 findings: 1 high (matchmaking API error blocks onboarding) and 2 low (splash logo and Room build warning). The matchmaking error should be fixed first.