# Vote4U: independent pre-submission review request for Opus

Prepared October 11, 2026. This is a review assignment, not a release approval.

## 1. Your mission

Act as an independent, skeptical principal engineer, product reviewer, accessibility tester,
and release auditor. Review this app as if a misleading result could send a voter to the wrong
place and a false readiness claim could cause us to submit the wrong build.

Find reproducible bugs, challenge unsupported claims, evaluate whether the MVP actually serves
its purpose, and produce a prioritized route to submission. Read the implementation, run it,
inspect real screenshots, exercise failure paths, and trace the release artifacts. Do not merely
summarize previous agents' reports or endorse a green test suite.

The owner is also running a **Claude ultrareview concurrently**. This assignment complements it.
First form your own assessment of the highest-risk paths; then reconcile its findings when its
output is available. Do not wait indefinitely for that report. Identify overlapping findings,
disagreements, and areas neither review exercised. Another agent's confidence is not evidence.

We want to remove as many material defects as possible before submission. Do not promise that
all bugs are eliminated. A useful conclusion states exactly what was verified, what remains
uncertain, and whether any uncertainty blocks submission.

### Priorities, in order

1. Voter safety: supported locations, truthful confidence, official lookup, correct dates.
2. Release integrity: reviewed source = integrated source = built artifact = deployed behavior.
3. Core usability: ZIP without GPS, understandable results, saved-place persistence, recovery.
4. Privacy, security, notification correctness, and data lifecycle.
5. Native quality, accessibility, responsive web behavior, and App Store readiness.
6. Maintainability and polish where they address a concrete risk or user problem.

Do not manufacture findings to fill a quota. Distinguish a reproducible defect from a hypothesis,
a product tradeoff, missing evidence, and a preference. Challenge previous work without deferring
to its author, and accept correct behavior when evidence supports it.

## 2. Start here: a confirmed integration trap

The owner reported merging PRs #13 and #14. GitHub and fetched refs were checked for this request:

| Item | Observed state at preparation time |
| --- | --- |
| PR #13 | Merged into `main` at `2026-10-11T02:54:21Z` |
| `origin/main` | `4f104f3`, merge of #13 |
| PR #14 | Merged at `2026-10-11T02:54:36Z`, **into `release/ios-signing-validation`** |
| Release branch | `e39eeeb`, merge of #14 |
| UI polish commit | `3f9ab31`; present on release branch, absent from fetched `main` |
| Difference | 52 files; 610 insertions, 212 deletions between fetched main and release branch |
| PR #14 checks | Web lint/build, server tests, Playwright, hosted iOS and Vercel preview passed; Supabase preview skipped |

**A merged badge on both PRs does not mean both changes reached main.** #13 merged first;
#14 then updated its old base branch. Main therefore lacked #14 at this snapshot. The preview
deployment passing does not establish which source is running in Production.

Re-fetch and verify: another reviewer or the owner may resolve this before you start. If still
present, propose or prepare a focused follow-up integration PR from the release branch to main;
leave merging to the owner. Do not silently cherry-pick a second copy of already-integrated work.
Review both current main and the intended release candidate, and name which one every finding
and test result describes. Never validate one tree and approve a different tree.

PR links: [#13](https://github.com/ShyamRavidath/voting-finder/pull/13),
[#14](https://github.com/ShyamRavidath/voting-finder/pull/14).

## 3. Working boundaries and concurrent-review safety

- Read `AGENTS.md`, then `HANDOFF.md` §5 and §7 **before changes**. Read the latest dated
  handoff entries too. Some old factual statements in these files are stale; preserve the rules,
  verify the claims, and call out contradictions explicitly.
- Read `CODEX_HANDOFF.md`, local gitignored `CLAUDE.md`, `ios/APP_STORE.md`, and
  `ios/RELEASE_VALIDATION.md`. On the release branch, also read `docs/UI_REVIEW.md` and HANDOFF §14.
- Do not overwrite the concurrent ultrareview's work, switch its checkout, reset files, delete
  branches, or kill its processes. Inventory dirty files first. Use a separate checkout/worktree
  and distinct artifact directory when needed. Coordinate expensive simulator runs rather than
  running two suites at once on the same machine.
- Review first. Small fixes with demonstrated repros may be made on an isolated branch, with
  regression evidence and a reviewable PR. Separate unrelated fixes. Broad redesigns, framework
  migrations, blanket formatting, and speculative infrastructure changes are outside this audit.
- Follow branch → commit → push → PR. The owner merges. This review request does not authorize
  production database mutations, deployment, TestFlight upload, App Store submission, publication,
  credential rotation, or sending messages to third parties. Prepare concrete next steps for those.
- Reversible local tests are appropriate. Use synthetic coordinates for adversarial tests.
  Do not load-test production, hammer upstreams, or run destructive migrations there.
- Never print or commit keys, tokens, signing credentials, profiles, personal device identifiers,
  user coordinates, ZIPs tied to a user, household-identifying cache keys, or sensitive logs.
  Record evidence without exposing those values. Obtain any required account actions through the
  owner's normal sign-in interface, not by asking for secrets in chat.
- If access is missing, complete unaffected work and state the exact missing evidence. Do not
  convert an unavailable account screen into a claim that the feature works or fails.

## 4. Inventory branches, builds, and actual deployment

Capture date, dirty status, local HEAD, remote main SHA, intended candidate SHA, and available
toolchain/runtime versions. Refresh remote refs without deleting branches. Inspect all open PRs
and meaningful unmerged branches, not just the latest two.

At preparation time #9 (formatting), #10 (structured logging), and #12 (handoff) were still open.
Earlier notes called #9/#10 drafts. Verify current draft status, checks, conflicts, dependencies,
and whether their useful content is already integrated another way.

Useful read-only starting commands:

```sh
git status --short --branch
git log -8 --oneline --decorate
git branch -avv
git fetch origin
gh pr list --state all --limit 30 --json number,title,state,isDraft,baseRefName,headRefName,mergedAt,url
git log --oneline origin/main..origin/release/ios-signing-validation
git diff --stat origin/main origin/release/ios-signing-validation
git diff origin/main origin/release/ios-signing-validation -- ios/Vote4U.xcodeproj/project.pbxproj
gh run list --limit 20
```

For each relevant branch/PR, report: purpose, base, unique changes, merged reachability, conflicts,
test evidence, release relevance, and disposition: integrate, superseded, defer, or investigate.
Do not require a formatting PR merely because a historical checklist called it required. Decide
which logging/privacy fixes are necessary from actual behavior, not their PR title.

Trace Vercel Production to its actual deployment and source SHA where access allows. Compare
public behavior with the intended code. Check server and frontend deploy together as expected.
Inspect migrations, environment-variable scope and redeploy requirements without disclosing values.
Determine whether the native API base URL reaches that same backend. Detect stale screenshots,
old archives, preview endpoints, test configuration, and source/artifact version mismatches.

## 5. Claims that require independent verification

These are **historical reports**, not promises or results for current main:

| Previous claim | Scope / limitation to challenge |
| --- | --- |
| Server: 50 passed | Stubbed upstreams; does not prove live provider availability |
| Web: 93 passed, 9 expected skips | PR #14 candidate; inspect every skip and project selection |
| Later web subset: 54 passed | After final map changes; not a second complete suite |
| iOS: 69 passed | SE 3 / iOS 17.5: 55 unit, 12 smoke, 2 permission decisions, plus Release checks |
| Real device installation | Build 1.0 (2) installed/launched; not equivalent to a processed TestFlight install |
| Widget works | Owner added it to the actual Home Screen; update/deep-link/date coverage still limited |
| Offline works | Owner saw an existing screen in airplane mode without tapping Save; this does **not** prove persisted saved data |
| Visual QA completed | Captures at selected sizes; a passing largest-text test initially missed visibly broken text wrapping |
| Store images refreshed | Five live-data JPEGs on #14, 1320×2868, no alpha; inspect pixels and current listing requirements |
| Local distribution export succeeded | No recorded upload, processing, TestFlight acceptance, or submission |
| Production elections returned 503 | Last reported October 10: “Election data is not configured.” Recheck and establish actual cause |
| Strict formatting | Known pre-existing URL retroactive-conformance finding in NewsView; not an all-repo clean lint claim |
| Toolchain accepted | Previous Apple documentation check supported Xcode 27 family; reverify current requirements and actual package processing |

Known missing evidence: physical delivered notification banners, VoiceOver task completion,
full permission revocation/recovery, true offline cold launch after Save, production cleanup
recurrence and deletion, host-log retention, final App Store privacy answers, and processed
TestFlight critical paths. Some may have been completed since; ask for evidence, not repetition.

Build a claim ledger with: exact claim, source/date, applicable SHA/build/environment, independent
check, result, evidence path, and status: verified / contradicted / partial / stale / unavailable.
Explicitly identify cases where a true local claim was generalized to production or distribution.

## 6. MVP and civic correctness: highest scrutiny

Start by writing the actual user promise in plain language. Can a first-time voter discover what
this app can reliably tell them, find their official authority, and avoid mistaking a suggested
venue for their assigned polling place? Judge the full journey, not just individual warnings.

### Location evidence and misleading certainty

- Trace a result from upstream → server normalization → cache → JSON → web/native models → card,
  map marker/popup, saved state, share sheet, directions, and notification. At each transition,
  check that provenance and uncertainty survive.
- Construct a truth table for `isReal`, `isEstimated`, missing/null flags, conflicting flags,
  source tier, widened radius, and older saved records. Use the actual API contract to determine
  expected behavior. Challenge whether an explicit `isEstimated: false` alone is sufficient
  confirmation. Ensure web and iOS interpret equivalent evidence consistently.
- Distinguish a real building, an officially listed voting site, an active site for a specific
  election/date, and the user's assigned site. These are different claims. Neither proximity
  nor an official venue list necessarily establishes voter eligibility at that venue.
- ZIP-only searches must not suggest address-level assignment. Check state borders, ZIP
  centroids, multi-jurisdiction areas, nearby expansion, and missing state identification.
- Inspect fallback venue filtering: libraries/schools/community buildings may be plausible
  buildings yet have no election role. Is showing them as voting candidates defensible even with
  a warning? Evaluate user misunderstanding and whether the safer MVP should prefer official
  lookup over weak suggestions. Support any recommendation with concrete screens and behavior.
- Weaker data must produce stronger caution. Empty results must lead to official sources.
  No fallback may fabricate an address, venue, opening time, assignment, or election fact.
- Verify exclusion of the Civic test election and all fabricated fixtures from Release,
  production routes, saved defaults, screenshots and marketing. Inspect the stub exclusion test
  itself: does it search enough of the artifact to catch accidental fixture shipping?
- Check cache age and election rollover: could yesterday's valid site become tomorrow's stale
  instruction? Determine whether users can see freshness and whether stale saved locations are
  revalidated or clearly qualified. Offline convenience must not imply current confirmation.
- Review directions/share action wording. Does tapping directions communicate certainty the
  warning just disclaimed? Does shared text include uncertainty and official lookup?

### Dates, electoral map, sources, and nonpartisanship

- Independently verify election calendar rules and boundary dates with official sources. Test
  before/on/after election day, midnight, time-zone changes, DST, leap years, and next-cycle rollover.
  Distinguish the next federal election from local/special elections and a presidential contest.
- Check countdown and reminder wording for incorrect assumptions about polls being open,
  registration deadlines, early voting, or universal hours.
- Verify all state/DC official links, supported geography, totals, electoral allocations and
  bundled web/iOS data parity. Check the export script and whether generated resources are stale.
- Inspect the 2028 static electoral illustration: is its purpose, date and non-live status clear?
  Can party colors/tallies be mistaken for current results, forecasts, endorsements, or voting advice?
- News must remain last. Assess source labels, timestamps, stale articles, duplicate stories,
  foreign-election leakage, sensational content and unsupported “nonpartisan” implications.
- Assess whether the native app delivers enough useful functionality beyond links/news, while
  keeping release scope realistic. Do not add features solely to inflate an App Store pitch.

## 7. Native app: functional and adversarial journeys

Read the actual models/services and SwiftUI state flow, particularly `VoteViewModel`,
`LocationManager`, `APIClient`, `SavedPlace`, `ReminderScheduler`, `ElectionCalendar`,
`PollingResult`, Home/Vote views, widget entry points and shared resources.

### Search and state transitions

- Fresh install: deny GPS → enter valid ZIP → search → understand result → official lookup.
- Allow GPS; test approximate location, no fix, timeout, restricted permission, disabled system
  location, permission revoked in Settings, and return from background. ZIP stays usable.
- Empty/short/long ZIP, leading zero, whitespace/paste, non-ASCII digits, unsupported ZIP,
  keyboard dismissal, rapid Search taps, and editing input while a request is in flight.
- Start request A, then B; return B first, then A. Ensure old responses/errors cannot overwrite
  new results, labels, state, or saved actions. Check task cancellation and location continuations.
- Slow/offline network, 400/404/429/500/503, malformed/partial payload, empty response, timeout,
  retry after reconnection, tab switching/backgrounding during work. Loading must always resolve.
- Distinguish denied permission from API failure; do not hide a backend defect behind reassuring
  permission copy. Retry must use the intended search input and method.

### Save, offline, and lifecycle

- Search → Save → Home → force quit → airplane mode → cold launch. Address, venue type,
  warning and official reference must persist. Separate data available offline from actions
  requiring connectivity (map tiles, website, directions, fresh results).
- Save A then B; remove on each available surface; navigate between Home and Vote; relaunch.
  Check duplicate identity, state refresh, stale button labels, and removal persistence.
- Decode pre-change saved records, missing fields, malformed storage, and unsupported versions.
  Failure must not crash or silently upgrade uncertainty to confirmed.
- Verify save/remove while reminders are enabled, disabled in-app, denied at OS level, or revoked.
  Check whether a queued notification keeps an old address or stale trust wording.

### Notifications and widget

- Test notification allow and deny independently on fresh warmed simulators; denial must remain
  visible and ZIP/search use must not depend on notification permission.
- Audit scheduling identifiers, replacement/removal ordering, async races, toggle re-entry,
  app relaunch, timezone/date changes and expired events. No duplicate or resurrected reminders.
- Test delivered physical banners separately from queued requests. Use a documented controlled
  local test; never change the device's real clock or schedule misleading live civic reminders
  without explaining and obtaining the appropriate owner action.
- Inspect widget plist nesting, target membership, embedding, supported families, availability,
  shared date calculations, timeline refresh and deep links. Confirm behavior on supported OSes.
- Exercise small and medium widget layouts at normal and boundary dates. Registration, rendered
  previews, actual placement, actual refresh, and tap behavior are distinct evidence levels.

### Accessibility and visual quality

- Inspect actual rendered Home, Vote idle/loading/results/empty/error/saved states, Map list/detail,
  News loading/error/content, settings/reminders, share and external-link flows.
- Use small iPhone/SE and large iPhone, light/dark, normal and largest accessibility text, bold
  text and reduced motion. Inspect supported iPad behavior if the target advertises iPad support;
  do not infer app support from widget-family checks. Test rotation where supported.
- Check text fit, warning prominence, color contrast in context, focus order, safe areas, keyboard
  overlap, hit targets, scroll reachability, long names/addresses and loading layout stability.
- Perform VoiceOver tasks, not just an accessibility-tree inspection. Check labels, hints,
  grouping, selected/saved state, toggles, links, announced errors and loading completion.
- Confirm the map's accessible list is usable; do not turn every decorative state path into a
  target contrary to the intentional summary/list design.
- Preserve real native affordances. Cosmetic changes must improve a measured or observed problem.

## 8. Server, privacy, cache, and security

Inspect `server/routes`, services, middleware, `server/lib`, database schema/migrations, Vercel
configuration, and both clients' request construction. Trace success and exception paths.

- Validate ZIP and coordinate shape/ranges, leading-zero handling, mixed ZIP/device inputs,
  state derivation and unknown locations. Check consistent error contracts and safe messages.
- Examine upstream timeouts, retry limits, pacing, result filtering, malformed data, provider
  quotas and partial failures. Ensure a slow fallback chain does not create indefinite loading.
- Audit device-versus-ZIP cache key separation, coordinate precision, key collisions, schema
  rollout compatibility, TTL semantics, stale fallback, simultaneous misses and failure caching.
- Verify production migration state without mutating it. Check cleanup authentication, method,
  query bounds, schedule configuration, expired-row deletion and retention. A 401 to an
  unauthenticated request proves only that path, not recurring successful cleanup.
- Audit all logs, including caught error objects and upstream errors. Raw coordinates, ZIPs,
  precise cache keys, upstream URLs containing the Civic key, and client IP must not be logged.
  `ZipNotFoundError` has historically carried coordinates in its message; typed handling can be
  safe while logging the whole error elsewhere is unsafe. Trace actual exceptions.
- Permitted operational fields describe shape: mode, stateAbbr, dataSource, searchRadiusKm,
  cacheHit, upstreamMs, locationCount. Check structured logging PR #10 against this commitment.
- Separate application logs from Vercel/hosting/CDN/provider logging. Investigate retention,
  identifiability and access where accounts permit. Document what remains unknown.
- Verify previous exposed keys were rotated through owner/account evidence without displaying
  the keys. Scan tracked files/build outputs for secrets with redacted output; do not dump history.
- Review rate limiting under serverless deployment and shared networks, trust-proxy/IP handling,
  CORS scope, errors, dependency risks, untrusted URL handling and HTML in map/news content.
  Assess exploitability before assigning severity. Check for injection and SSRF where URLs are
  actually accepted or fetched; do not report theoretical categories with no reachable path.
- Compare privacy policy, App Store answers, permission text, actual network traffic, persistence,
  caching and third-party services. “Not stored,” “not collected,” and “not linked” are distinct
  claims requiring evidence. Verify deletion/expiry commitments against real operations.
- Identify a safe, bounded production health check set. Report the elections 503 separately from
  fallback polling behavior; do not infer either the entire app is broken or the failure is harmless.

## 9. Web app: interaction, responsive layout, and recovery

- Exercise all routes and deep links, refresh/navigation, unknown routes, browser back/forward,
  empty/loading/error states, permission denial, ZIP search, official links, news and state detail.
- Test at 320, 390, 768 and 1440 CSS pixels, plus resizing during open UI. Test browser zoom and
  keyboard-only navigation. Check bottom navigation clearance and viewport/keyboard behavior.
- Review `usePolling`, `useNews`, request cancellation, stale-response races, retries, and whether
  old results stay labelled with new input. Confirm errors are announced and recoverable.
- Inspect Leaflet popup bounds, long addresses, marker changes, repeated selection of the same
  result, resize while open, auto-pan, controls, focus and return to card. No warning can be hidden
  by clipping. A document without horizontal overflow can still contain a clipped popup.
- Validate identical confirmation semantics in cards, marker styling and popup text. Inject
  missing/conflicting flags using local fixtures; never manipulate production data to test this.
- Test focus visibility, hover, disabled/loading controls, target sizes, semantic headings and
  link names. Run axe but also manually exercise keyboard/screen reader interaction.
- Check page-level crash boundaries and React effect/ref cleanup behavior. Prior React 19 bugs
  returned values from effect/ref callbacks and caused blank pages.
- Verify no web UI promises native-only offline saving. If any worker/cache/install behavior
  exists, test its update and stale-content behavior rather than assuming PWA support.

## 10. Test the tests and preserve trustworthy evidence

Use existing dependencies and inspect scripts before running. Baseline commands:

```sh
npm test --prefix server
npm run build
npm run test:e2e
DEVICE_TYPE='iPhone SE (3rd generation)' \
RUNTIME='com.apple.CoreSimulator.SimRuntime.iOS-17-5' \
DERIVED='/tmp/vote4u-opus-review-ios17' ./scripts/test-ios.sh
```

Confirm installed device/runtime identifiers first. Also exercise a current supported OS where
the implementation has availability-specific behavior. Run expensive iOS suites sequentially,
with a distinct DerivedData directory and retained logs. Do not disrupt another reviewer's run.

**The iOS runner is mandatory.** Do not substitute plain `xcodebuild test` or an MCP test wrapper.
It creates fresh warmed permission devices, runs notification allow before unit tests, exercises
deny independently, and checks Release stub exclusion and widget families. Do not edit it while
it is running. Do not hide failures with redirection or silently skip unavailable system alerts.

For formatting, use `xcrun swift-format` from `ios/` with the existing four-space configuration;
do not autoformat the project as part of this review. Inspect the current lint baseline.

Audit test quality:

- Are names stronger than assertions? An “all tabs in order” test may check only existence.
- Do tests prove persistence across a terminated process, rather than continued in-memory state?
- Does the denial test actually tap the system denial and subsequently complete ZIP search?
- Do mocked payloads resemble real payloads, including missing and optional fields?
- Are notification queue tests meaningful under their authorization setup?
- Are retries hiding races? Are skips documented and justified per device/profile?
- Does the final subset cover all changes since the last full suite? State any gap explicitly.
- Could screenshot or reachability assertions pass with unusable word wrapping or hidden warnings?
- For important new regressions, demonstrate a targeted deliberate mutation causes failure,
  then restore it. Use an isolated working tree and never commit the mutation.

Prior intensive web QA hit local 429s. A later local run used `RATE_LIMIT_MAX=5000`. Keep tests
deterministic without raising production limits, and test default production-like limits separately.
Do not report a relaxed-limit run as rate-limit validation.

Capture for each result: exact SHA, dirty diff if applicable, command, timestamp, OS/runtime,
device/profile, environment, exit code, passed/failed/skipped counts, artifact path and limitations.
Separate fixture tests from live smoke tests; live provider availability is inherently variable.

## 11. App Store and release-package audit

Read `ios/APP_STORE.md` against the actual candidate. Check current Apple primary documentation
for requirements that may have changed. Quote/link the relevant requirement where it creates a
gate. Separate our product commitments from your prediction about App Review; never guarantee approval.

- Confirm bundle ID, team, version/build, target deployment minimum, device families, entitlements,
  extension embedding, privacy manifests, signing identity/profile and Release build configuration.
- Verify no debug fixtures, debug start-state behavior, test endpoints, secrets or fake venues
  ship. Inspect the exported artifact, not just project settings.
- Verify source SHA provenance of archive/export. Do not infer it from an IPA's filename or build
  number alone. If provenance cannot be established, build a fresh candidate after integration.
- Inspect required-reason API usage versus declared reasons, dependencies and app/extension
  manifests. A UserDefaults reason declaration does not settle data-collection labels.
- Review privacy/support URLs, review notes, age rating, third-party content rights/attribution,
  encryption/export answers and account/agreements status. Mark owner-only unknowns precisely.
- Verify GPS is optional, app value beyond news, non-government positioning, usable review access,
  and accurate description of uncertain results/offline behavior. Review relevant current guidance
  rather than inventing a rule that only governments can distribute civic apps.
- Open every marketing screenshot. Check correct current UI, real live-data provenance, warning
  visibility, dates, dimensions, formats, alpha, device classes, and lack of DEBUG fiction.
  Store images and QA fixture captures must remain clearly separate.
- Distinguish local archive success, local distribution export, upload success, Apple processing,
  TestFlight installation, external testing approval if applicable, App Review submission, approval,
  and public release. Record each separately; none automatically proves the next.
- Before recommendation to submit, require critical-path testing of the actual processed
  TestFlight candidate and a fresh production API/configuration check.

Historical artifacts from #14, possibly still present:

```text
/tmp/Vote4U-polished-final.xcarchive
/tmp/vote4u-polished-final-export/Vote4U.ipa
/tmp/vote4u-visual-small-final.log
/tmp/vote4u-visual-small/Logs/Test/
/tmp/vote4u-visual-e2e-final.log
/tmp/vote4u-visual-map-final-retry.log
/tmp/vote4u-final-attachments/manifest.json
```

The archive/IPA were reported as 1.0 (2). Older packages without `polished-final` are superseded.
Even the final-named package is historical evidence, **not automatically the next upload**.
Temporary files may be gone; report absence honestly and regenerate needed evidence.

## 12. Minimum review matrix

For each row record PASS / FAIL / NOT RUN / BLOCKED / NOT APPLICABLE, with evidence and reason.
Do not use a green checkbox for “read the code and it seems fine.” Label static analysis separately.

| Area | Required scenarios |
| --- | --- |
| Integration | Main vs intended candidate vs production vs IPA; #13/#14 ancestry; remaining PRs |
| Search | ZIP, leading zero, denied/revoked GPS, slow request, out-of-order responses, 429, empty, malformed data |
| Truth | Official, estimated, widened nearby, absent/conflicting evidence, legacy saved data, shared and notification text |
| Offline | Save then cold launch offline; replace/remove/relaunch; unavailable external services |
| Dates | Before/on/after election, midnight, timezone/DST change, next-cycle rollover |
| Reminders | Allow, deny, revoke, opt-out, save/remove, duplicate/stale request, delivered banner |
| Widget | Registration, placement, supported families, boundary text, refresh and tap |
| Native UX | Small/large phone, supported tablet, dark/light, largest type, keyboard, VoiceOver, reduced motion |
| Web UX | Four widths, resize open popup, keyboard/focus, browser navigation, axe, recovery |
| Backend | Cache separation/expiry, migration compatibility, upstream failures, cleanup auth/recurrence |
| Privacy | Every exception/log path, hosting retention, third-party transfers, disclosures, no secrets |
| Release | Correct candidate artifact, Release exclusion, signing, screenshots, metadata, TestFlight, live backend |

Use risk-based combinations rather than an unbounded Cartesian product. Explain important omitted
combinations, especially where a feature behaves differently across OS versions or environments.

## 13. Reconcile the concurrent Claude ultrareview

When its report is available, preserve the original and record its reviewed SHA/environment.
Map its findings to yours using stable IDs; do not silently discard duplicates or accept assertions.

For every material external finding: independently reproduced / supported by static evidence /
not reproduced / already fixed / wrong baseline / requires access. Explain disagreements with
repros, source references or artifacts. A failure to reproduce once does not disprove a race.

Look specifically for shared blind spots: both reviews using the same stub, same old handoff,
same simulator, same screenshot, same incorrect assumption about merged branches, or neither
checking the distribution artifact. If both agents edited code, reconcile diffs deliberately
and retest the combined result; two separately green branches do not validate their combination.

## 14. Deliverables and finding format

Produce one durable `docs/OPUS_RELEASE_REVIEW.md` with these sections (appendices are fine):

1. Executive decision: **not ready**, **ready for TestFlight**, or **ready for submission**, with
   evidence scope and top blockers. Distinguish technical recommendation from owner approval.
2. Source/deployment/artifact and branch/PR matrix, with exact SHAs and recommended dispositions.
3. Prioritized findings ledger, including product risks and evidence gaps as clearly separate types.
4. Claim verification ledger and the completed test/visual/device matrix.
5. MVP assessment: core user promise, whether current behavior meets it, and smallest required changes.
6. Ultrareview reconciliation and remaining independent coverage gaps.
7. Fixes made, regression proof, PRs, and unresolved risks. Include unsuccessful tests and attempts.
8. Release gates and exact owner actions, in execution order, each with a success criterion.
9. Short next-session handoff: candidate SHA, commands, artifacts, remaining work and account blockers.

Use this format for each substantive finding:

```text
ID / title:
Type: defect | product risk | evidence gap | optional improvement
Severity: P0 | P1 | P2 | P3
Confidence: confirmed | strongly supported | hypothesis
Baseline: SHA, build, environment, device/OS
User consequence and affected population:
Preconditions and minimal reproduction:
Expected vs actual:
Evidence: file:line, redacted log, screenshot, test/artifact path
Root cause, or what still needs establishing:
Smallest proposed fix and scope/risk:
Regression test and verification result:
Release-blocking? Why:
Status / related ultrareview ID / owner action if any:
```

Severity guidance: P0 is immediate severe harm/exposure; P1 blocks a core flow, can materially
mislead a voter, or invalidates the release; P2 is significant but bounded; P3 is minor polish.
Do not inflate severity for uncertain hypotheses. An evidence gap can block submission without
being a proven code bug. Include actionable file references instead of generic advice.

### Stop conditions for recommending submission

- All P0/P1 findings affecting the candidate are fixed and verified, or the feature is safely
  removed through an explicit reviewed decision. No silent acceptance of voting misinformation.
- Required core journeys pass on the integrated candidate and the processed TestFlight build.
- No unexplained critical test failures, hidden skips, unresolved source/artifact mismatch,
  or missing privacy/configuration gate remains.
- Remaining lower-risk issues have explicit disposition and do not contradict the product promise.
- Owner-only steps are clearly separated from completed work; production and App Store facts
  have been checked recently enough to support the conclusion.

If those conditions are not met, finish with **not ready**, a concise blocker list, and the exact
next actions. A candid incomplete gate is more valuable than a confident unsupported sign-off.
