# Vote4U release validation — 2026-10-10

## Owner steps to unblock device testing

1. The archive attempt reached team `M6L74ZB5KS`; account access is available.
   If Xcode requests renewed sign-in/2FA, complete it in Xcode, not in chat.
2. Connect and unlock an iPhone. Accept Trust This Computer. If Xcode requests Developer Mode,
   enable Settings → Privacy & Security → Developer Mode and follow the restart prompts.
3. Open `ios/Vote4U.xcodeproj`, choose the Vote4U scheme and the connected iPhone.
   App, widget and test targets now use the supplied team with automatic signing.
4. Sign in to App Store Connect and resolve any pending membership/agreement prompts.
   Before upload, create or confirm the app record for `com.shyamravidath.Vote4U`.
   Use the listing draft in `APP_STORE.md`; final privacy answers still need host-log review.

Apple references: [Developer Mode](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device),
[app records](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app),
[upload builds](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds).

## Required real-device evidence

Record phone/iOS version, build number, date and observed result for each:

- Deny location access, then complete a ZIP search and open official sources.
- Allow location and check the result state; revoke permission in Settings and retry with ZIP.
- Save a real result, relaunch in airplane mode, and confirm the saved address and its warning.
- Add the countdown widget through the actual Home Screen gallery and open the app from it.
- Grant notifications and observe a delivered banner (queuing tests alone are insufficient).
- Exercise large text, dark appearance and VoiceOver across all four tabs.
- Install the processed TestFlight build and repeat the critical paths.

## Current evidence

- GitHub refreshed: PRs #9 and #10 remain drafts; #12 contains the latest handoff.
- Initial outside-sandbox signing check: zero valid signing identities; no physical devices listed.
- Signed archive with automatic provisioning failed: Apple reported no registered devices
  from which to generate development profiles for the app and widget. No archive/upload resulted.
- Server: 50 passed, zero skipped.
- Browser/accessibility: 90 passed, 9 expected skips.
- Production client build: passed.
- Public production checks: health 200, news 200 (15 articles), privacy 200,
  unauthenticated cleanup 401, elections 503. The elections route returns 503 when
  GOOGLE_CIVIC_API_KEY is missing; verify Production configuration and redeploy.
- iOS validation is in progress; do not treat this document as release approval.

## Changes under validation

- Configure Team ID for automatic signing on app, widget and test targets.
- Saving/removing a place now respects the in-app reminder opt-out even when OS permission remains granted.
- Preserve unconfirmed-location warnings in saved cards, shared text and notifications.
- Preserve saved venue type and add an official lookup from both saved cards.
- Decode official `isReal` evidence; absent evidence no longer silently means confirmed.
- Old saved records remain readable and conservatively unconfirmed.
- Add the required UserDefaults privacy-manifest reason CA92.1 for app-local preferences.
  This API declaration does not replace the App Store Connect data-collection disclosures.
- Election Day notification no longer claims polls are open at 7am everywhere.

## Still required before submission

Finish integration of logging PR #10 and formatting PR #9, inspect current real-data screenshots,
verify production cleanup/log retention and final privacy answers, complete device testing,
archive with an accepted distribution toolchain, upload and verify processing in TestFlight.
The owner merges code PRs. No upload, App Store submission or publication is recorded here.
