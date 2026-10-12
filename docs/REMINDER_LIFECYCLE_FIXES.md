# Countdown, reminder lifecycle, and database fixes

Continuation of the October 11 handoff, based on merged main `d8b8279`.
Branch: `fix/countdown-reminder-lifecycle`.

## Changes

- OPUS-14: Home uses the existing Today/singular wording and VoiceOver summary. Its
  timeline advances at local midnight, including DST, rather than hourly.
- OPUS-15 / OPUS-24: Reconcile enabled reminders on app foreground (on every tab),
  return to Home, and saved-place changes. Revocation turns the toggle off, removes
  pending reminders, and preserves an explanatory warning across launches.
- Explicit user-toggle binding remains. A shared main-actor coordinator serializes changes;
  revision checks reject stale authorization results and queued work. An opt-out during
  scheduling cleans up after that add finishes. Cancellation observes the real pending
  queue before allowing a later opt-in to add replacements.
- OPUS-16: Pure request construction retains fixed 2026 boundary assertions and verifies
  rollover to 2028. Notification-center integration schedules against an election safely
  beyond the real clock. Missing authorization now fails instead of skipping these tests.
- OPUS-18: The Postgres pool handles idle errors with a static warning. Error objects,
  codes, connection details, and user data are never included in that message.

## Validation

iPhone SE (3rd generation), iOS 17.5: the full mandatory runner passed 81 tests
(66 unit, 13 smoke, allow and deny), with no failures/skips. Release stub and widget-family
checks passed at implementation commit `04f1359`.
Hosted [web CI](https://github.com/ShyamRavidath/voting-finder/actions/runs/38193893540)
and [iOS CI](https://github.com/ShyamRavidath/voting-finder/actions/runs/38193893486) also passed
at that commit: 81 native tests, Release checks, and actual widget registration.

The later test-only cold-render adjustment adds one blank-content test. Final native rerun
results and latest hosted status are recorded in [PR #18](https://github.com/ShyamRavidath/voting-finder/pull/18).
This ledger preserves earlier attempts rather than treating every run as equivalent.

Server: 56 passed; web: 96 passed / 9 deliberate skips;
client build and configured lint passed. Isolated mutation checks fail when removing the
pool listener or reminder revision guards; neither mutation touched the candidate.

### Failed attempts

- Sandboxed server tests could not open loopback listeners. The escalated run passed.
- Sandboxed Xcode macro processes failed; the escalated build succeeded.
- The documented `ios/.swift-format` file is absent from main. Validation uses the exact
  four-space configuration recovered from `origin/chore/swift-format` in a temporary file.
- The preliminary iOS 17.5 run passed allow, its unit/smoke tests, and deny, but stopped
  before Release checks because a comment edit changed the live shell script's read offset
  (`AndExplains: command not found`). Do not edit a running runner, even its comments.
  That run is not full-suite evidence. Final native runs use frozen source.
- The first final-source iOS 27 run failed at the initial toggle tap before the permission
  alert (`value` remained `0`). Its recording shows the switch off, without an alert or denial
  warning; synthesized-event coordinates land on the switch. The cause is not established.
  That run never reached unit/smoke, deny, or Release checks.
- An unchanged iOS 27 retry passed Allow, all new reminder/date tests, and all 13 smoke tests,
  but the existing first widget render test produced a blank image with an image-provider
  timeout while its graphics pipeline initialized. Following widget render tests passed.
  Deny and Release checks were not reached. The widget test helper now retries rendering up
  to three times with short waits; the same visibility assertions remain, and a separate
  permanently-blank-content test verifies the wait does not manufacture a passing image.
  Consult PR #18 for complete native rerun results for that test-only adjustment.
- The new blank-content guard then exposed a false positive in the old pixel checker.
  The checker now keeps its buffer scoped through drawing and requires both visible alpha
  and pixel variation, ignoring RGB bytes under zero alpha. Direct probes rejected transparent
  and uniform images, accepted visible variation, and rejected an actual SwiftUI clear render.
  The already-failed native attempt was stopped before remaining smoke/deny/Release checks.
  No application code changed during these test-harness corrections.

## Limits

Foreground reconciliation requires opening or returning to the app; this does not introduce
background execution or server push. Simulator queue acceptance is not evidence of delivered
notification banners on a physical device. Production database/hosting behavior, TestFlight,
store screenshots, and the remaining Opus release findings remain outside this batch.

## Local evidence

Worktree: `/private/tmp/vote4u-reminder-fixes`. The original documentation checkout and
Claude worktrees were not reset, switched, or committed by this batch.

- `/private/tmp/vote4u-reminders-server.log`
- `/private/tmp/vote4u-reminders-web.log`
- `/private/tmp/vote4u-reminders-client.log`
- `/private/tmp/vote4u-reminders-ios175-final.log`
- `/private/tmp/vote4u-reminders-ios27-final.log` (first failed attempt)
- `/private/tmp/vote4u-reminders-ios27-allow-failure.log`
- `/private/tmp/vote4u-reminders-ios27-retry.log` (render failure)
- `/private/tmp/vote4u-reminders-ios27-render-failure.log`
- `/private/tmp/vote4u-reminders-ios27-verified.log` (blank-check failure)
- `/private/tmp/vote4u-reminders-ios27-blank-check-failure.log`
- `/private/tmp/vote4u-reminders-ios27-complete.log`
- `/private/tmp/vote4u-reminders-hosted-ios.log` (hosted success at `04f1359`)
- `/private/tmp/vote4u-ios27-all-attachments/` (first failure's recording and tap events)
- `/private/tmp/vote4u-reminders-db-mutation.log`
- `/private/tmp/vote4u-reminders-race-baseline.log`
- `/private/tmp/vote4u-reminders-race-mutation.log`

The incomplete preliminary native log is `/private/tmp/vote4u-reminders-ios175.log`.
Temporary evidence may disappear; do not treat these paths as permanent archived artifacts.
