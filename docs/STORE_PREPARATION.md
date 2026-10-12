# Store preparation — October 11, 2026

Candidate branch: `release/app-store-preparation`, based on merged PR #18,
`75ad345a492b6fad8bd59d9d94a8f1cfd20ceb61`. Build settings: version 1.0, build 3.
This records preparation for owner review; it is not submission or privacy approval.

## Changes reviewed

- OPUS-21: both maps show neutral electoral allocations, alphabetical state lists,
  538 total and 270 majority. Removed unsourced partisan predictions from bundled/web
  data. Checked all 51 allocations against the [National Archives](https://www.archives.gov/electoral-college/allocation),
  including the 2024/2028 applicability and Maine/Nebraska explanation.
- OPUS-20: removed candidate-derived party chips. Explicit source-name and publisher-host
  exclusions cover the observed advocacy, party committee and junk items. This is not
  a complete publisher-bias assessment. Omitted the old news marketing screenshot.
- OPUS-35, partial: skip malformed news dates and unsafe links, protect native Safari
  opening, version database and memory news caches by validation schema/election year,
  reject blank/array coordinates, narrow preview CORS, and remove unused body parsing.
  Route logs contain static messages, never upstream errors, URLs or request values.
  TLS configuration and operational cron/retention evidence remain outstanding.
- Feed-year rollover uses the end of Election Day across US time zones; the memory cache
  also changes with the query year. This does not resolve OPUS-28 native calendar behavior.
- Updated listing drafts, screenshot capture options and build number. The local privacy
  manifest uses the same conservative linked/nontracking categories as the proposed labels;
  final hosting facts and owner declarations remain pending.

## Verification

- Server: `npm test --prefix server`: 67 passed, zero failed/skipped.
- Browser: `npm run test:e2e`: 99 passed, 9 expected skips (duplicate mobile API checks
  and Vercel-only headers). Local production client build ran as part of this suite.
  Log: `/private/tmp/vote4u-resume-web.log`.
- `npm run lint --prefix client`, `git diff --check`, privacy-manifest plist validation
  and screenshot-script shell syntax passed.
- Web/native bundled data match: 51 entries, 538 votes, no party fields.
- Mutation proof: removing the HTTP(S) guard in a disposable server copy makes
  `only absolute HTTP(S) article URLs survive` fail on script/data/file/relative links.
  The candidate was never mutated.
- Changed Swift files: explicit four-space lint reports the existing
  `URL: @retroactive Identifiable` conformance in `NewsView.swift`; other changed files pass.
  No whole-repository lint pass is claimed.
- Native iPhone 15 Pro / iOS 17.5: required `scripts/test-ios.sh` passed 83 tests
  (68 unit, 13 UI smoke, notification allow and deny), zero failures/skips. Release
  stub-string and widget-family checks passed. Xcode 27.0 (27A266a).
  Log: `/private/tmp/vote4u-resume-ios175.log`; DerivedData: `/private/tmp/vote4u-resume-ios175`.
- Native iPhone 17 / iOS 27: all 83 tests passed (68 unit, 13 UI smoke, allow and deny),
  zero failures/skips. Release stub-string and widget-family checks passed.
  Log: `/private/tmp/vote4u-resume-ios27.log`; DerivedData: `/private/tmp/vote4u-resume-ios27`.
- Supplementary iOS 17.5 symbol inspection: `APIStub` exists in `Vote4U.debug.dylib`,
  and is absent from the Release app and widget symbol tables. This is local simulator
  evidence; signed archive inspection remains required.
- Both Release simulator bundles were inspected: version 1.0 (3), four-category privacy
  manifest present, widget build 3 with families 1/2 and the WidgetKit extension point.
- Widget registration succeeded via `pluginkit` on a clean iOS 27 simulator.
- Screenshot capture: large 1320×2868 and medium 1206×2622 opaque JPEGs. Live production
  ZIP 90210, no polling/news fixtures. All eight final images were visually reviewed; rejected captures were replaced.

### Capture failures and limits

Initial 12-second captures intermittently omitted status bars or clipped the navigation title.
A two-second termination/relaunch pause alone did not fix this. Device Hub visibly showed
correct Home layout; later settled captures were correct without app-source edits. Replaced
rejected images and raised the capture script's default wait to 30 seconds (overridable with
`CAPTURE_WAIT_SECONDS`). Always inspect the actual outputs; elapsed time is not proof.

`open -a Simulator` and the historical Developer/Applications path failed on this Xcode.
The installed viewer is `/Applications/Xcode.app/Contents/Applications/DeviceHub.app`.
Its initial computer-use inspection stalled 536 seconds; subsequent screenshot observation
completed in six seconds. Avoid using UI automation for owner form entry.

The filtered news backend is not deployed yet; news art remains omitted. The four captured
voting screens do not depend on that news change. Screenshots establish light/default-text
appearance only, not a full dark/large-text/VoiceOver or physical-device pass.

## Gates after this PR

1. Owner merges; verify the deployed source and keyless production behavior.
2. Review host log/backup retention and cleanup history, then finalize privacy/age
   questionnaires and owner contact/rights fields. Draft text is in `ios/APP_STORE.md`.
3. Archive/export from clean integrated source with SHA, toolchain, build number,
   signatures, profiles, embedded widget and DEBUG-exclusion evidence.
4. With upload authorization, verify Apple processing and install that TestFlight build.
5. Record physical denial/revocation → ZIP, GPS, saved-place cold launch offline,
   delivered notification, widget placement, large text and VoiceOver checks.
6. Owner authorizes App Review submission separately.

Keep Civic disabled pending OPUS-6/11/12. Preserve remaining findings: OPUS-19 latency/load,
23 leaked-key deletion evidence, 27 ZIP paste, 28 non-US calendar boundaries, 29 Settings/error
UX, 31 stronger Release inspection, 32 UI-test gaps, 33 radius wording, 34 latent Civic/polish,
35 TLS/cron/retention remainder and 38 GitHub Pages. This batch does not close those items.

Prior interrupted runs are not passes. No new signed archive, upload, TestFlight installation,
production deployment or App Review submission is established by these local results.
