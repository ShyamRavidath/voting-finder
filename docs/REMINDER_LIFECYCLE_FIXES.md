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
checks passed. The final iOS 27 run is pending.

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
- `/private/tmp/vote4u-reminders-ios27-final.log`
- `/private/tmp/vote4u-reminders-db-mutation.log`
- `/private/tmp/vote4u-reminders-race-baseline.log`
- `/private/tmp/vote4u-reminders-race-mutation.log`

The incomplete preliminary native log is `/private/tmp/vote4u-reminders-ios175.log`.
Temporary evidence may disappear; do not treat these paths as permanent archived artifacts.
