# Validation — November 24, 2026

Source branch: `feat/local-civic-overhaul`, based on `origin/main` at `d5f1b6d`.

## Completed

- Backend: 64 tests passed, zero failures or skips. Hermetic API tests bind localhost; the
  sandboxed run could not bind and was rerun with the required permission.
- Live official-source import after parser changes: 567 services, 35 public meetings and six
  recorded Council actions; all three collections returned `live` in 13.7 seconds. No user
  query or location was sent. This checks source access, not deployment of the new endpoint.
- Required native runner on iPhone 15 Pro / iOS 17.5: 77 unit tests, 17 smoke UI tests,
  notification allow and deny on fresh simulators — 96 passed, no skips. Release build passed
  the DEBUG fixture/string exclusion and widget device-family checks.
- Calendar save and cancel both executed. Following survived relaunch and retained a meeting
  after it left the recent feed. Search found the official drug-reporting service. Largest text,
  genuine dark appearance and existing polling trust/ZIP flows were exercised.

Runner: `TEST_DIAGNOSTICS=never DEVICE_TYPE='iPhone 15 Pro' RUNTIME=com.apple.CoreSimulator.SimRuntime.iOS-17-5 DERIVED=/private/tmp/vote4u-overhaul-tests ./scripts/test-ios.sh`.
The optional diagnostics setting suppresses slow sysdiagnose collection only; test assertions,
attachments, xcresults, fresh permission simulators and Release checks still execute.

Main iOS 17.5 result: `Test-Vote4U-2026.11.24_00-46-16--0800.xcresult` under the DerivedData
`Logs/Test` directory. Screenshots are unmodified XCTest attachment exports; the Calendar editor
uses a conspicuously named DEBUG-only future fixture so saving is exercised even after real
meetings pass. These are QA evidence, not App Store marketing assets.

## Failures found and corrected

- A newer-runtime accessibility selector assumed a SwiftUI Link was a Button. It now matches
  the element's explicit accessibility identifier across element types.
- Unfollowing a record outside the latest feed removed its open detail screen. Navigation now
  uses a stable ID, and the detail retains its last known record.
- An OS launch appearance argument did not actually produce dark mode. The UI test now uses a
  DEBUG-only SwiftUI appearance override; the resulting dark screenshot was visually checked.
- The source parser initially accepted the end time when the start time was malformed. It now
  requires the complete time field, and a malformed-start test verifies failure.
- Future agenda publication could erase recorded outcomes. The importer now follows bounded,
  actual archive links and excludes future sessions without promoting procedural steps to approval.

## Boundaries

The iPhone may remain unplugged during simulator validation. This revised build has not yet been
installed or physically tested. Backend refresh in a device build remains unavailable until the
owner merges/deploys the new endpoint; bundled dated data still supports browsing/search/following.
No App Store upload, public release or merge is included. Following is on-device persistence and
foreground refresh, with no push notification service. The feed covers recent city listings,
not every historical meeting or committee action.

## Newer-runtime check in progress

The first clean iOS 27 run did not display the notification prompt; a fresh retry passed it.
The retry then passed 77 unit tests and 16 of 17 smoke tests. Calendar's separate system editor
had not loaded within the 10-second UI timeout. The simulator log shows its remote extension
checking in about ten seconds after presentation, shortly before the test ended. A focused
rerun now allows 60 seconds for first editor startup; no permission request or assertion was
removed. This is not yet a full newer-runtime pass.

The runner accepts `UI_TEST_TARGET` for a focused smoke case while retaining all units, fresh
allow/deny simulators and the Release binary check. Focused runs are reported separately.
The Release check writes `strings` to a file before matching, so `grep -q` cannot close a pipe
early and hide a match under `pipefail`.
