# Vote4U — Handoff

**Audience: future me (Claude), resuming this project cold.** Rewritten 2026-09-20, late evening,
at the end of the session that reviewed Codex's first commit and fixed what the review found.
Owner: Shyam Ravidath (`ShyamRavidath/voting-finder`), git user `vote4u`.

Read this first, then `CODEX_HANDOFF.md` (Codex has been working and will again), then `CLAUDE.md`
for web architecture. `ios/APP_STORE.md` holds the submission copy. `TRANSFER.md` is the record of
the Windows→Mac move and is now mostly historical.

**If you read only one thing:** the app is finished and unshipped, `main` is green and pushed at
`08e4bc7`, the only hard blocker is Apple's account verification, and the most valuable work
available right now is §8A — making the polling search degrade gracefully when Nominatim returns
nothing, which is a real user-facing hole the owner asked for by name.

---

## 1. The goal, and the constraints that shape every decision

Ship **Vote4U** to the iOS App Store as a **native Swift/SwiftUI** app while keeping the website
live. Two UIs, one Express backend.

**Everything must stay free except the $99/yr Apple Developer Program.** The owner set this
explicitly and has reaffirmed it. It is the reason for: Vercel Hobby, keyless APIs, MapKit instead
of paid tiles, local notifications instead of a push server, no third-party Swift dependencies.
**Flag anything with a recurring cost rather than adopting it.**

The app is **functionally complete and unshipped.** Every feature works in the Simulator against
the live production API.

### Decision log — don't relitigate these without new information

| Decision | When | Why |
|---|---|---|
| Native Swift/SwiftUI, not Expo/React Native | 2026-09-20 | Expo existed only because the old dev machine was Windows with no Mac. That constraint is gone. Native is also the strongest answer to guideline 4.2. |
| Build locally in Xcode, not EAS | 2026-09-20 | A Mac removes the entire cloud-build apparatus. No 15-builds/month quota, no 90-min queue, no App Store Connect API key juggling. |
| `shared/` JS extraction **cancelled** | 2026-09-20 | It only existed so JS could be shared with React Native. With Swift on the other side there is nothing to share. **Do not refactor `client/` for the app's benefit.** |
| iPhone only (`TARGETED_DEVICE_FAMILY = 1`) | 2026-09-20 | Avoids maintaining a second set of iPad screenshots. Revisit only if the owner wants iPad. |
| iOS 17 deployment target | 2026-09-20 | ~95%+ of devices, and unlocks `@Observable`, `.sensoryFeedback`, `ContentUnavailableView`, modern MapKit-in-SwiftUI. |
| NewsAPI removed entirely | 2026-09-20 | Free plan is development-only under its own terms → guideline 5.2.2 violation. Production had always used the Google News RSS fallback. |
| News is the **last** tab | 2026-09-19 | 4.2.2 treats news aggregators as thin. This is the single biggest rejection risk. |
| UI tests drive stubs, not production | 2026-09-20 | A live third-party geocoder made a correct build fail. See §4 and §8A. |

---

## 2. Current state

### Where the repo is

`main`, **pushed**, clean worktree. Newest-first:

```
08e4bc7 fix(ios): repair the iOS 17.5 test command and decouple UI tests from the live API  ← me
452bc0b docs: record the Codex review outcome and four new iOS lessons
a7dfe10 fix(ios): repair a scheduling race, an unreachable search, and silent test skips    ← me
8a3613b docs: rewrite HANDOFF.md as a cold-restart record for myself
1da4c8d feat(ios): harden iOS 17 and polish SwiftUI experience                              ← Codex
16410db docs: add a handoff to Codex for the work that needs no Apple Team ID
c9285f3 docs: record the iOS test suite and what still needs hardware
3af60a9 test(ios): add unit and UI tests, and fix two bugs they found
84ea4cc feat(api)!: remove NewsAPI; Google News RSS is now the only news source
d4b0993 feat(ios): capture the App Store screenshot set, reproducibly
a595aa8 docs: draft the App Store listing and record what is left
d8aefd6 feat: harden the iOS app and document the app in the privacy policy
3bfaa9d feat(ios): add location, reminders, saved place, sharing and haptics
c431de0 feat(ios): build the Vote and News tabs against the live API
54b2781 feat(ios): scaffold the native SwiftUI app with a working electoral map
17a7dfa feat(api): accept ?lat=&lng= on /api/polling for the iOS location lookup
b11d711 docs: pivot to native Swift/SwiftUI on Mac; rewrite handoff and transfer
```

The branch `fix/ios-test-runner-and-live-api-decoupling` was fast-forwarded into `main` and can be
deleted. **The owner approved that push explicitly; still ask before the next one.**

### Tree

```
voting-finder/
├── api/index.js              Vercel serverless entry → re-exports the Express app
├── server/                   Express 5, standalone on :3001
│   ├── app.js                builds the app (no listen); server/index.js listens
│   ├── routes/{news,polling,elections}.js
│   ├── services/{news,geocode,civic}Service.js
│   ├── lib/fetchWithTimeout.js
│   └── test/api.test.js      20 tests, node:test, upstreams stubbed, no network
├── client/                   React 19 + Vite + Tailwind v4 — the live website
├── ios/                      the native app, ~2.7k lines of Swift
│   ├── Vote4U.xcodeproj      HAND-WRITTEN pbxproj — see §5
│   ├── Vote4U/
│   │   ├── Vote4UApp.swift   @main, TabView root, DEBUG launch-arg hook
│   │   ├── Design/           Vote4UTheme, Vote4UActionStyle        (Codex)
│   │   ├── Models/           ElectionCalendar, ElectoralState, PollingResult
│   │   ├── Services/         APIClient, APIStub (DEBUG only), LocationManager,
│   │   │                     ReminderScheduler, SavedPlace, Formatting,
│   │   │                     SafariView, MapDirections
│   │   ├── Features/{Home,Vote,Map,News}/   ~20 small views after Codex's split
│   │   └── Resources/        states.json, statePaths.json, officialLinks.json
│   ├── Vote4UTests/          28 unit tests
│   ├── Vote4UUITests/        10 UI tests
│   ├── screenshots/          5 × 1320×2868 App Store shots — see §8B
│   ├── APP_STORE.md          listing copy, privacy labels, review notes
│   └── IOS_DEVELOPMENT_GUIDE.md   Codex's workflow notes — see §7
├── scripts/
│   ├── export-ios-data.mjs   regenerates the app's bundled JSON from client/src/data
│   ├── capture-screenshots.sh
│   └── test-ios.sh           THE iOS test runner — plain xcodebuild is NOT equivalent
├── tests/e2e/                Playwright, 3 device profiles, axe
├── CODEX_HANDOFF.md          on-ramp written for Codex, with my replies inline
├── CLAUDE.md                 web architecture + React 19 traps (gitignored, local only)
└── TRANSFER.md               Windows→Mac move record
```

### Test status — all of this was run, not assumed, on 2026-09-20 evening

| Suite | Command | Result |
|---|---|---|
| Server | `npm test --prefix server` | **20 pass** |
| Web e2e local | `npm run test:e2e` | 87 passed, 9 skipped *(not re-run this session)* |
| Web e2e prod | `BASE_URL=https://vote4ucyl.vercel.app npx playwright test` | 88 passed, 8 skipped *(not re-run)* |
| iOS on iOS 27.0 | `./scripts/test-ios.sh` | **41 tests, 0 failures, 0 skipped** (2026-09-21, after the §8A/§8D work) |
| iOS on iOS 17.5 | `DEVICE_TYPE='iPhone 15 Pro' RUNTIME='com.apple.CoreSimulator.SimRuntime.iOS-17-5' ./scripts/test-ios.sh` | **38 tests, 0 failures, 0 skipped** |

`test-ios.sh` now ends with a Release build and greps the binary to prove no DEBUG launch-argument
or stub string shipped. Release build is clean, no warnings.

### Live site

https://vote4ucyl.vercel.app — healthy, auto-deploys from `main` on Vercel Hobby (non-commercial
use only, worth remembering).

- `/api/health` 200 · `/api/news` 200 via Google News RSS
- **`/api/polling?zip=90210` → 200 with `dataSource:"none"` and zero locations.** Verified with a
  cache-busted `x-vercel-cache: MISS`, so it is not a stale CDN entry. `10001` returns 5 venues and
  `60601` returns 3, and the device path `?lat=34.0736&lng=-118.4004` resolves ZIP 90212 and
  returns 4. **This is upstream, not a regression** — see §4 and §8A.
- `/api/elections` → **503 "Election data is not configured"**. Expected: `GOOGLE_CIVIC_API_KEY`
  is not in Vercel. The owner is rotating a leaked key. The app does not consume this endpoint yet.

### The environment

Mac, Apple Silicon, macOS 27 (Darwin 27.0.0). Repo at `~/voting-finder`. Node 26.0.0 / npm 11.12.1
(project was built on Node 22; everything passes on 26). Homebrew at `/opt/homebrew`.
**Xcode 27.0** at `/Applications/Xcode.app`, `xcode-select` correctly pointed at it.
Simulator runtimes: **iOS 27.0 and iOS 17.5** (Codex installed 17.5 — see §7). Devices that exist:
iPhone 17 / 17e / 18 Pro / 18 Pro Max / Air on 27.0; iPhone 15 / 15 Plus / 15 Pro / 15 Pro Max /
SE 3 on 17.5. **There is no iPhone 15 Pro on iOS 27, which matters — see §4.**
No `watchman`, `pod`, `eas`, `expo` — none are needed. Playwright browsers are **not** installed.
`server/.env` does **not** exist locally. Claude memory lives in
`~/.claude/projects/-Users-shyamravidath-voting-finder/memory/`.

---

## 3. Files actively being edited

| File | State / what to know |
|---|---|
| `ios/Vote4U/Services/APIStub.swift` | **New in `08e4bc7`.** DEBUG-only canned API responses. The whole file is inside `#if DEBUG`. It invents polling venues, so it must never ship — `test-ios.sh` proves that on every run. Extend it when you add a state worth testing. |
| `ios/Vote4U/Services/APIClient.swift` | Now consults `APIStub` first (via two small `#if DEBUG` helpers) before hitting the network. Field names **must** match `server/services/*.js` exactly — this bit me once (§4). Distinguishes offline/unreachable/timeout/server/decoding. |
| `ios/Vote4UUITests/AppSmokeUITests.swift` | 8 tests. Seven are stub-driven and deterministic; `testLiveAPIReachesATerminalStateOnVoteAndNews` is the only one that touches production and deliberately accepts any terminal state. |
| `ios/Vote4UUITests/ReminderPermissionUITests.swift` | **Most fragile file in the repo.** Read §4 and §5 before touching. Codex added a coordinate tap at `dx: 0.9` because SwiftUI exposes the whole row as the switch's frame while only the control end is tappable on iOS 17. |
| `scripts/test-ios.sh` | Rewritten four times now. Its comments explain why plain `xcodebuild test` is wrong, why the build uses a generic destination, and why it ends with a Release grep. |
| `ios/Vote4U/Features/Home/HomeView.swift` | Contains a **deliberate `Binding` instead of `.onChange`** — reverting that reintroduces a real bug (§4). Codex split it into `ElectionCountdownCard`, `ElectionReminderCard`, `HomeSavedPlaceCard`, `HomeVotingPlanCard`, `NonpartisanNotice`. Takes a `Binding<Tab>` so cards can switch tabs. |
| `ios/Vote4U/Features/Vote/VoteView.swift` | Was the largest view; Codex decomposed it into `VoteSearchForm`, `VoteStateContent`, `PollingResultsView`, `VoteSearchErrorView`, `SavedPollingPlaceCard`, `OfficialSourcesView`, `PollingSearchLoadingView`. Still holds the `#if DEBUG` `-startZip` hook. |
| `ios/Vote4U/Features/Map/*` | Codex split `ElectoralMapView` into `ElectoralMapCanvas`, `ElectoralStateShapeView`, `ElectoralTallyView`, `ElectoralStateList`, `ElectoralStateDetail`, `ElectoralMapLegend`. `.searchable` is pinned open with `.navigationBarDrawer(displayMode: .always)` — do not revert that (§4). |
| `ios/Vote4U/Features/Map/SVGPath.swift` | Hand-rolled parser, ~60 lines, M/L/Z only. Two bugs found in it so far. Every one of the 51 bundled shapes is covered by a test. |
| `ios/Vote4U/Services/Formatting.swift` | Codex replaced the cached `ISO8601DateFormatter` statics with `Date.ISO8601FormatStyle` for Sendable-safety. Tries fractional seconds first, then plain. Fine; watch for perf only if news lists grow large. |
| `ios/Vote4U/Services/ReminderScheduler.swift` | Local notifications, fully unit-tested. Never cancel-then-add (§4). |
| `server/services/geocodeService.js` | **The file §8A is about.** `findNearbyPollingVenues` queries Nominatim three times (library / community center / town hall), 1s apart, `bounded=1` inside a ±0.03° box, discarding anything ≥10 km. |
| `server/routes/polling.js` | Has `?lat=&lng=`. Device lookups deliberately bypass the Postgres cache (centroid-relative distances would be poisoned). |
| `server/services/newsService.js` | NewsAPI removed; the domain exclusion moved into `dedupeAndSort` with its own test. |

---

## 4. Everything that failed — the expensive lessons

**This is the section I would most regret losing.** Each cost real time, and several were my own
misreporting rather than genuine obstacles.

### Process mistakes I made (most important — these are about judgement, not iOS)

**I declared something "done" that had never actually run.** I told the owner "the notification
gap is closed" on the strength of one passing allow-test, while the deny path had never executed
and was broken. The owner asked *"we can't test without my id?"* — that single sceptical question
exposed a wrong assumption plus two real bugs. **Treat scepticism as a gift and verify before
declaring.**

**I reviewed an artefact by reading its commit message.** I wrote in HANDOFF that Codex's
screenshots were "stale, showing the pre-redesign UI". They were not: all five had been
regenerated inside that same commit, and I could have seen it by opening one PNG or checking the
file mtimes. **Open the artefact. A commit message is a claim, not evidence.**

**A skip is not a pass.** `XCTSkipUnless` turned a broken selector into a silent green run for
several iterations. I removed it from the permission tests; a missing alert now `XCTFail`s and
prints the actual springboard button labels. Keep it that way.

**I overstated a blocker.** I claimed notifications couldn't be tested without a physical device.
Wrong: XCUITest taps system alerts, and **Simulator tests need no signing identity at all**. Most
of what I'd filed under "device testing" was never blocked. Before declaring something blocked,
check empirically.

**I chased three confident wrong theories in a row** (grants survive uninstall → grants survive
privacy reset → cold-start timing) when the actual cause was a typographic apostrophe. **Dump the
actual state early** instead of theorising; the diagnostic that printed real button labels solved
it in one run.

**I corrupted two test runs by launching concurrent `xcodebuild` processes** against the same
`derivedDataPath`, then misreported the results as real. And I **exhausted system memory** by
leaving four simulators booted, which killed a run.

**I committed directly to `main` twice without branching** before asking. The owner was fine with
it, and approved the `08e4bc7` push when asked, but ask every time.

**I hid a build failure behind `>/dev/null 2>&1`** and then had to reproduce it by hand to find
out what it was. Redirect if you must, but always print the tail on failure.

### iOS / Xcode

- **A bare device name in `-destination` is resolved against the newest installed runtime.**
  `platform=iOS Simulator,name=iPhone 15 Pro` fails with *"no available devices matched"* when the
  newest runtime is iOS 27 and that device only exists on 17.5. This made the **documented** iOS
  17.5 command unable to run at all — my bug in `a7dfe10`, and it silently invalidated a result
  Codex had reported honestly. Build with `generic/platform=iOS Simulator`, or append `,OS=17.5`.
- **`simctl privacy` has no `notifications` service.** Only a UI-test tap can grant it. It *does*
  have `location`.
- **A notification grant survives both `simctl uninstall` and `simctl privacy reset`.** The only
  reliable reset is a **freshly created simulator**. `scripts/test-ios.sh` creates and destroys
  throwaway ones for exactly this.
- **iOS writes "Don’t Allow" with U+2019**, not an ASCII apostrophe. Match on a prefix.
- **A cold, freshly created simulator needs warming** — `app.wait(for: .runningForeground)` is
  *not* sufficient, it returns before SwiftUI has settled. `test-ios.sh` does a throwaway
  install/launch/terminate before the real run.
- **Never share a `derivedDataPath` between concurrent `xcodebuild` runs.** Result bundles collide
  (`mkstemp: No such file or directory`) and tests report `Executed 0 tests` while looking fine.
- **`xcrun simctl shutdown all`** when done.
- **`CGFloat.init` is overloaded enough to break Swift type inference** —
  `Double(sub).map(CGFloat.init)` produced *"failed to produce diagnostic for expression"*. Spell
  conversions out.
- **SwiftUI `Path.closeSubpath()` on an empty path leaves it non-empty.** Guard it.
- **A SwiftUI `Link` wrapping a `VStack` exposes one element whose label is the combined text**
  ("Find your official polling place, USA.gov"). Exact-match XCUITest queries fail; use `CONTAINS`.
- **SwiftUI exposes the whole row as a `Toggle`'s accessibility frame**, but only the control end
  is tappable on iOS 17. Tap `coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))`.
- **`XCUIElementQuery.containing(_:)` is not `matching(_:)`.** `containing` keeps elements that
  have a **descendant** satisfying the predicate and ignores the element's own attributes, so it
  can never match a leaf button by its own label. `ReminderPermissionUITests` used
  `springboard.buttons.containing(label BEGINSWITH "Allow")` and failed on 2026-09-21 with a
  diagnostic that printed `springboard buttons: ["Don’t Allow", "Allow"]` while claiming no
  button started with "Allow" — the contradiction *was* the clue. Fixed by switching both
  lookups to `matching(_:)`. Note this file passed 38/38 on 2026-09-20 with the same code, so
  the hierarchy it depended on is not stable across runs: **when a selector and its own
  diagnostic disagree, suspect the query API, not the app.**
- **A failing first phase hides the rest of the suite.** `test-ios.sh` runs the allow-permission
  test first and stops there, so that one failure meant the unit tests and `AppSmokeUITests`
  never executed at all. A red run is not evidence about anything downstream of the red test.
- **A failed UI test costs ten extra minutes.** Xcode tries to collect simulator diagnostics and
  gives up only after a 600 s timeout (`Failure collecting diagnostics from simulator`). A run
  that seems hung after a failure is usually just this.
- **A `LazyVStack` keeps off-screen cards out of the accessibility tree.** The reminder-toggle
  helper scrolls before it looks, and checks `isHittable`, because XCTest reports a partially
  clipped control as existing.
- **Electoral map state shapes are useless as VoiceOver targets** — several are a few points wide,
  DC is effectively invisible. The map is one summary element; the state list is the real
  interaction surface. Don't "fix" this by making shapes focusable.
- **A fixed `.font(.system(size: 72))` ignores Dynamic Type entirely.** Use `@ScaledMetric`, cap
  with `.dynamicTypeSize(...)`, add `minimumScaleFactor`.
- **`removePendingNotificationRequests` is processed asynchronously by the notification daemon.**
  `ReminderScheduler.schedule()` used to `cancelAll()` then add; the removal could land *after*
  the adds and wipe them, so toggling reminders on silently scheduled nothing — intermittently.
  **Adding a request with an existing identifier already replaces it atomically**, so never
  cancel-then-add. Remove only what you deliberately did not schedule, afterwards.
- **A single green run does not prove the absence of a race.** That bug passed once and I took it
  as verified. It only surfaced after I removed the skips.
- **`.searchable` with default placement collapses behind the title until the user scrolls.** The
  field is unreachable to UI tests and easy to miss as a user. Use
  `.navigationBarDrawer(displayMode: .always)` when it should always be visible.
- **`.onChange` cannot distinguish a programmatic revert from a user action.** Denying
  notification permission set a warning flag *and* flipped the toggle back; the revert re-fired
  `.onChange`, re-entered the handler, and wiped the flag — so denial was completely unexplained.
  Fixed with an explicit `Binding`. **This is the class of bug to watch for in SwiftUI.**
- **An all-`Optional` `Codable` model decodes successfully with wrong field names.** The `Article`
  model used `publishedAt`/`image`; the API sends `date`/`imageUrl`. No crash, no compiler error,
  timestamps silently blank. Caught only by looking at the running app. **There are decoding tests
  pinned to real captured payloads — add one whenever you touch a model.**
- Hand-written `project.pbxproj` works and uses **file-system-synchronized root groups**, so new
  `.swift` files under `ios/Vote4U/` need no project edit (`APIStub.swift` was picked up with no
  project change at all). Adding a *target* means copying the existing pattern carefully. An empty
  `<TestPlans></TestPlans>` in a scheme silently disables the whole `Testables` list — that
  produced *"Scheme is not currently configured for the test action"*.

### Product / infrastructure

- **Nominatim's venue results come and go, and 90210 is not a safe example.** On 2026-09-20 the
  exact query the server sends started returning `[]`:
  ```sh
  curl -s -A 'Vote4U-PollingFinder/1.1 (+https://vote4ucyl.vercel.app)' \
    "https://nominatim.openstreetmap.org/search?q=library%20Beverly%20Hills%20California&format=json&limit=3&addressdetails=1&bounded=1&viewbox=-118.4365,34.0601,-118.3765,34.1201&dedupe=1&countrycodes=us"
  # → []
  ```
  So `/api/polling?zip=90210` answers `dataSource:"none"` while 10001 and 60601 are fine. Earlier
  the same afternoon it returned Beverly Hills Public Library — the screenshots prove it. **Never
  assert live third-party data in a test, and check a ZIP before featuring it anywhere.**
- **Railway is dead** ("Application not found"), free tier gone. Don't revive it.
- **CARTO basemap tiles now stamp "API KEY REQUIRED"** across every tile.
- **OSM's tile policy discourages app traffic** — hence MapKit on iOS. Nominatim (server-side
  geocoding) is a different service, fine at low volume with a proper `User-Agent`.
- **Google Civic with a ZIP-only address always returns zero polling locations.** "Failed to parse
  address" without an election ID; empty with one. Official data needs a street address and only
  appears near an election.
- **Google's "VIP Test Election" (id 2000) returns fake locations** that would have been labelled
  "Official". Explicitly excluded in `civicService.js`. Don't remove that.
- **Fabricated sample locations were deliberately removed.** The old code invented "123 Main St".
- **NewsAPI's free plan is development-only** → 5.2.2 violation. Removed. Subtlety: the
  biztoc/freerepublic exclusion was a NewsAPI *query parameter*, so deleting the call would have
  silently dropped the filter — it now lives in `dedupeAndSort` with its own test.
- **The Google News RSS feed is not US-scoped.** The current News tab leads with Cyprus, Pakistan
  and Turkey headlines. That is a 4.2.2 argument handed to a reviewer — see §8D.
- **React 19 traps (web only, still live in `client/`):** effects and ref callbacks must use block
  bodies. `useEffect(() => window.scrollTo(0,0))` returns Chromium's scroll Promise and React
  treats it as cleanup; `ref={(el) => (x = el)}` returns the element. Both caused production
  blank-page crashes.
- **Playwright locally runs `retries: 0`**, so flakes read as hard failures. A
  `browserContext.close: ENOENT … .playwright-artifacts-*` trace error is a known flake — re-run
  before investigating.
- **The old Windows C: drive filling up** surfaced as bizarre `ENOSPC` test failures, not an
  obvious disk error. Moot now but a good reminder that infrastructure failures masquerade as code
  failures.

---

## 5. How to run everything

```bash
# Web
npm run dev                    # API :3001 + Vite :5173
npm test --prefix server       # 20 tests
npm run test:e2e               # needs `npx playwright install` first on this machine
BASE_URL=https://vote4ucyl.vercel.app npx playwright test

# iOS — USE THE SCRIPT, not plain `xcodebuild test`
./scripts/test-ios.sh                                    # 38 tests on the newest runtime
DEVICE_TYPE='iPhone 15 Pro' \
RUNTIME='com.apple.CoreSimulator.SimRuntime.iOS-17-5' \
  ./scripts/test-ios.sh                                  # deployment-era regression run
./scripts/capture-screenshots.sh
node scripts/export-ios-data.mjs    # after changing client/src/data/*

# One-off build. Note the OS= — without it a 15 Pro cannot be resolved (§4).
xcodebuild -project ios/Vote4U.xcodeproj -scheme Vote4U \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.5' build
```

**Why `test-ios.sh` is not replaceable by `xcodebuild test`:**
1. iOS asks for notification permission once and remembers; neither uninstall nor privacy reset
   clears it, so allow and deny each need a **throwaway simulator**.
2. The allow test must run **before** the unit tests, because `ReminderScheduler` needs
   authorization before `UNUserNotificationCenter` will queue anything.
3. It warms each new simulator, because a cold boot outruns the permission alert's timeout.
4. It finishes with a Release build and greps the binary, so the DEBUG stubs cannot ship.

**DEBUG-only launch arguments** (the script proves they are compiled out of Release):
`-startTab home|vote|map|news`, `-startZip 90210`, `-stubPolling estimated|empty|error`,
`-stubNews sample|error`. They exist so screenshots, QA and UI tests need neither UI automation nor
a cooperative upstream. Extend them.

**Manual dark-mode / Dynamic Type check** (this is how §7's verification was done):
```bash
xcrun simctl ui 'iPhone 15 Pro' appearance dark
xcrun simctl ui 'iPhone 15 Pro' content_size accessibility-extra-extra-extra-large
xcrun simctl launch 'iPhone 15 Pro' com.shyamravidath.Vote4U -startTab home
xcrun simctl io 'iPhone 15 Pro' screenshot /tmp/shot.png     # then actually look at it
```

**Screenshotting the running app after every meaningful change caught three bugs that were
invisible to both the compiler and a green test run.** Do it.

---

## 6. Rules that are not negotiable

Product commitments, not style preferences.

1. **Never show a voter a location the data doesn't support.** Unofficial results are labelled
   "Not confirmed"; "no results" links to official state lookups rather than inventing something.
   Guideline 1.1.6, and simply correct. **`APIStub` is the one place fake venues exist, it is
   DEBUG-only, and `test-ios.sh` enforces that.**
2. **ZIP entry must always work when location permission is declined.** Guideline 5.1.1(iv).
3. **Never imply government affiliation or endorsement.** Guidelines 5.2.1 / 5.2.4.
4. **News stays the last tab.** Guideline 4.2.2.
5. **Never commit keys.** The Civic key leaked in git history once already.

**App Store research, already done** (guidelines as of 2026-06-08, searched in full): "election",
"voter", "nonpartisan", "polling place" appear **zero times**. No rule requires a government
entity to publish an election app, and elections are **not** in 5.1.1(ix)'s highly-regulated list,
so the individual account is fine — it just publishes under the owner's legal name. **4.2 is the
real risk**, and native is the strongest answer. Detail in `ios/APP_STORE.md`.

---

## 7. Codex is also working on this

The owner brought in Codex (better iOS integration) and explicitly wanted it **unrestricted** —
same authority I have, free to change my decisions. My role is to **review afterwards and push
back where warranted**, not to constrain it up front. The owner wants Codex treated as a peer.
`CODEX_HANDOFF.md` is the on-ramp, and now carries my replies inline.

**Codex's commit `1da4c8d` — reviewed twice, kept in full.** What it did:

- **Installed the iOS 17.5 runtime and verified against it.** This was my #1 recommendation and it
  closed the largest untested gap: nothing had ever run on the actual deployment target.
- **Decomposed the three big views** into ~20 focused subviews. Good change; the monoliths were on
  my own list.
- **Added a design layer** (`Design/Vote4UTheme.swift`, `Vote4UActionStyle.swift`) with gradients,
  shared corner radii, and Liquid Glass guarded behind `if #available(iOS 26, *)` with a
  `.borderedProminent` fallback.
- **Replaced cached `ISO8601DateFormatter` statics with `Date.ISO8601FormatStyle`** for
  Sendable-safety.
- **Fixed a real flaw of mine in `test-ios.sh`** — my `run()` swallowed xcodebuild's exit status,
  so failures could pass silently.
- **Added `ios/IOS_DEVELOPMENT_GUIDE.md`**, distilled from an article the owner supplied. It is a
  translated third-party summary and Codex flagged that itself; it references skills that may not
  exist here and iOS 26 / Swift 6.2 guidance that does not apply to an iOS 17 project. **Treat as
  inspiration, not instruction.**

**Everything I flagged as outstanding is now closed** (verified 2026-09-20, second review):

- Screenshots were **not** stale — my error, see §4. Only the Map shot lags, predating `a7dfe10`'s
  pinned-open search field.
- **Dark mode and Dynamic Type verified** on iOS 17.5 including `accessibility-XXXL`: nothing
  clipped, nothing overlapping, the `@ScaledMetric` cap works.
- **Accessibility grouping survived** the decomposition and was extended (loading skeletons got
  labels, the reminder toggle got an identifier).
- **Release build clean; DEBUG arguments compiled out**, now machine-checked.
- Minor: `ElectoralStateShapeView` hardcodes `Color.white.opacity(0.85)` for state borders where
  the old code used adaptive `.background`. Reads fine in dark mode; just no longer theme-driven.
- Minor: `MapDirections` opens `http://maps.apple.com` (inherited). `https` would be tidier.

**My follow-ups to Codex's work:** `a7dfe10` (pinned-open search, the `ReminderScheduler` race,
simulator pre-warming) and `08e4bc7` (the destination bug I introduced in `a7dfe10`, plus the
API-stub decoupling).

---

## 8. The next step I would take

**The owner's instruction, verbatim, at the end of this session:** *"if there are no results being
returned, we can ideally report that to the user and then just come up with community centers or
something else (the next best thing)."* That is §8A and it is the next thing to build.

### A. Make the polling search degrade instead of dead-ending — **DONE 2026-09-21**

Built as described below, with one addition the investigation turned up. What shipped:

- **Two tiers in `findNearbyPollingVenues`.** Tier 1 is the old behaviour (library / community
  center / town hall, city+state in the query text, ±0.03° box, ≤10 km) and still answers
  `dataSource: 'estimated'`. Tier 2 runs **only when tier 1 is empty**: it drops the place name
  and lets the bounding box do the geography, over a ±0.1° box with a 25 km cap, adding `school`
  and `fire station`. It answers a new `dataSource: 'nearby'`.
- **Dropping the place name is the important part**, not the wider box. Re-probing on 2026-09-21
  showed `library Beverly Hills California` returning venues again — the 90210 hole was Nominatim's
  *text index* being flaky, not a geography problem, so tier 2 removes the text dependency.
- **`searchRadiusKm`** rides along in the response so both UIs can say how far the search went.
- **Labelling gets more cautious, not less** (rule #1): tier-2 venues are typed `Civic Building`,
  never `Likely Polling Place`, and both UIs carry distinct widened-search copy. Per-venue
  "Not confirmed" is unchanged — tier 2 is still `isEstimated: true`.
- **Nominatim's 1 req/s budget is shared across both tiers**, so the worst case is 7 sequential
  calls. `vercel.json` allows `maxDuration: 30`, and the CDN caches the answer either way.
- **New: a structural plausibility filter (`isPlausibleVenue`).** Nominatim matches free text, so
  "town hall" was returning the *bus stop* named "Paterson Plank Rd At Town Hall", "library" was
  returning a Little Free Library book box, and "community center" was returning the "Community
  Compost Center" — all shown to voters under "Likely Polling Place". `class`/`type` come back
  with `addressdetails=1` and are enough to reject them. It is a **denylist, not an allowlist**,
  because a real community center is often only tagged `building=yes`.

Verified live against the local server on 2026-09-21: `83428` and `89060` used to dead-end and now
return real schools, fire stations and community centers as `nearby`; `07094`, `10001` and `90210`
still answer `estimated` and no longer contain the bus stop, the book box or the compost centre.
`59645` still answers `none`, which is correct — there genuinely is nothing.

Not done, and still worth considering: a `-stubPolling nearby` iOS screenshot, and item 5 below's
"first tier empty, second tier hits" case is covered but the Postgres cache still stores only
`data_source`, so a cached `nearby` row replays fine but `searchRadiusKm` comes from the stored
payload (older rows simply omit it and the clients default to null — there is a test for that).

<details>
<summary>The original plan, kept for the reasoning</summary>

Today, when Nominatim returns nothing, the user gets "No polling places found" and a link list.
That is honest but it is a dead end, and right now it is what every 90210 lookup sees.

What the server does now, in `server/services/geocodeService.js → findNearbyPollingVenues`:
three sequential Nominatim `search` calls (`library`, `community center`, `town hall`), 1s apart,
each `bounded=1` inside a **±0.03° box** (~3 km) around the ZIP centroid, `limit=3`, then anything
≥10 km is discarded. For 90210 all three now return `[]` inside that box.

Proposed shape — worth confirming with the owner before writing much of it:
1. **Widen progressively.** Retry the same queries with a ±0.1° box (~11 km) before giving up. The
   10 km distance filter already prevents absurd results, so the box is the real limiter.
2. **Add more venue types** as a second tier: `school`, `church`, `fire station`, `city hall`,
   `recreation center`. These are the buildings American precincts actually use.
3. **Say what happened.** A new `dataSource` value (e.g. `"nearby"`) plus a `searchRadiusKm`, so
   the app can show *"No polling places listed for 90210. Here are nearby civic buildings that
   often serve as polling places — none of these are confirmed."* **Rule #1 still applies: the
   labelling must get more cautious as the data gets weaker, not less.**
4. **Keep the official links** above the fold in that state.
5. Server tests are stubbed and fast — add cases for "first tier empty, second tier hits" and
   "everything empty". The iOS side already has `-stubPolling empty`; add a `-stubPolling nearby`.

Mind the budget: each Nominatim call is 1s apart by policy and `fetchWithTimeout` allows 5s, so a
naive "try everything" could exceed the serverless limit. Run later tiers only when the earlier
one is empty.
</details>

### B. Re-shoot the App Store screenshots — **blocked on the deploy, do it straight after**

Checked on 2026-09-21 by opening the PNGs rather than trusting the claim (§4):

- **`3-electoral-map.png` is genuinely stale.** There is no search field under the "Electoral Map"
  title, so it predates `a7dfe10`'s pinned-open `.searchable`. Re-shoot it.
- **`1-vote-results.png` is *not* stale.** Production answers `zip=90210` with the same two
  Beverly Hills libraries it shows. The HANDOFF previously said that ZIP "no longer returns"
  them; Nominatim's index simply comes and goes (§4 again).

**Do not re-shoot until the §8A/§8D server work is deployed.** The app points at
`https://vote4ucyl.vercel.app` directly, so a capture run today would bake the *old* unscoped news
feed — Turkey, the Philippines — into the App Store set, which is the exact 4.2.2 risk §8D exists
to remove. Sequence: push → Vercel deploys → `./scripts/capture-screenshots.sh` → check all five
by opening them.

**Do not use `-stubPolling` for App Store screenshots.** The suggestion below was mine and I now
think it is wrong: those venues are fabricated, and putting fabricated polling places into store
marketing is precisely what rule #1 exists to prevent. Shoot against a real ZIP and re-check it
on the day. The stub is for tests and QA, not for the listing.

<details>
<summary>The original note</summary>

Screenshot 1 shows Beverly Hills venues that ZIP no longer returns, and the Map shot predates the
pinned-open search field. The owner's steer above means the Vote screenshot should show a
*populated* result: shoot it against a ZIP that currently returns data (`10001` → 5 venues,
`60601` → 3; **re-check on the day**, that is the whole lesson), or against `-stubPolling
estimated` if you want it reproducible forever. Note `capture-screenshots.sh` defaults to
`iPhone 18 Pro Max` for the 1320×2868 size and sleeps 12s per shot for cold serverless starts.
If the listing copy in `ios/APP_STORE.md` names Beverly Hills, update it to match.
</details>

### C. A WidgetKit extension

Countdown or saved polling place. Genuinely useful, needs no Apple account to build and test, and
materially strengthens the 4.2 "elevates beyond a website" argument. The highest-value *new*
feature. Adding a target means hand-editing the pbxproj — copy the existing pattern carefully.

### D. Scope the news feed to US elections — **DONE 2026-09-21**

The `gl`/`hl`/`ceid` parameters were **already** on the request. They bias the Google News
*edition*, not the subject, which is why they did nothing: the query itself was
`"2028 election" OR "2028 presidential race"`, and Turkey's April 2028 election and the
Philippines' 2028 race match that perfectly. Confirmed by fetching the live feed — Erdoğan and
Teodoro were both in the top ten.

What shipped:

- **`newsQuery()` builds the terms from `nextFederalElectionYear()`**, which mirrors
  `nextFederalElection` in `client/src/lib/format.js` (same `(8 - weekday) % 7` arithmetic) so the
  feed doesn't go stale the morning after an election. A midterm year leads with the midterms and
  keeps the presidential race two years out; a presidential year drops the midterm terms.
  **Every term is year-qualified** — that is the rule, and a test enforces it.
- **`toArticle`'s relevance gate was silently undoing the fix.** It required the literal string
  `"2028"` in the title, so every midterm headline the new query returns was being thrown away
  ("Early voting begins in U.S. midterm elections" has no year in it at all). It now matches
  word-bounded election vocabulary. Word-bounded because a substring test matches "pollution".
- **`candidate` is now null** when no watchlist candidate is named. It used to be the placeholder
  string `"2028 Election"`, which `NewsCard.jsx` then had to compare against by hand to hide.

Measured on the live feed, before → after: 8 articles, several foreign → **15 (the `MAX_ARTICLES`
cap), all US, all election-related**, and now leading with early voting, mail-in ballots and voter
guides rather than 2028 horse-race speculation. That is a much better answer to 4.2.2 as well: the
tab now reads like a voting tool's news feed.

Left alone deliberately: near-duplicate headlines from different outlets covering the same event
("Early voting in Virginia begins ahead of 2026 midterms" / "…for 2026 midterms"). `dedupeAndSort`
matches exact titles only. Normalising harder risks collapsing genuinely different stories.

### E. Snapshot tests for the electoral map

A silent `SVGPath` regression would render a wrong-but-not-crashing map that only a human notices.

### F. CI

A GitHub Action on a macOS runner (free for public repos) running server tests, Playwright and
`test-ios.sh`. Would have caught by machine several things I caught by hand — including the
destination bug, which no human would think to check twice.

### G. SwiftLint or swift-format

None exists; the codebase is small enough that adding one now won't be noisy.

### H. Server odds and ends

A coordinate-aware cache key so device lookups aren't cache-bypassed; structured logging; wire up
`/api/elections` once the key lands so official-vs-estimated becomes visible in the app.

**Things to verify rather than trust** (I wrote them in one session):
`geocodeService.coordsToZip` edge cases (ZIP+4 narrowing, outside-US); the Coarse-Location-only
privacy label argument in `APP_STORE.md`; whether iPhone-only is right.
*(`ElectionCalendar`'s fidelity to `client/src/lib/format.js` was on this list and is now
**verified** — the Swift port matches the JS line for line, including the `(8 - weekday) % 7`
first-Monday arithmetic.)*

---

## 9. Blocked on the owner

- **Apple Developer account is in verification.** No Team ID → no device build, no TestFlight, no
  submission. The owner confirmed again this session that they are still waiting, and asked to
  keep progressing until something genuinely needs it. When it clears: Xcode ▸ Settings ▸ Accounts
  → add the account, set the team, or set `DEVELOPMENT_TEAM` and build with
  `-allowProvisioningUpdates`.
- **Rotate the leaked Google Civic key** into Vercel as `GOOGLE_CIVIC_API_KEY`. It was public in
  the removed legacy `index.html` and remains in git history. The old NewsAPI key no longer
  matters here (integration removed) but should be rotated if reused elsewhere.
- **Install the App Store skills** (auto-install was blocked by the permission classifier):
  ```
  ! npx skills add eronred/aso-skills --skill aso-audit -g -a claude-code -y
  ! npx skills add eronred/aso-skills --skill apple-search-ads -g -a claude-code -y
  ! npx skills add truongduy2611/app-store-preflight-skills -g -a claude-code -y
  ! npx skills add https://github.com/code-with-beto/skills --skill app-icon -g -a claude-code -y
  ```
- **Playwright browsers are not installed** on this Mac (`npx playwright install`), so the web e2e
  numbers in §2 are inherited from the old machine rather than re-verified here.

### Still genuinely device-only

A notification **banner actually arriving** at its scheduled time (permission and queuing are
tested; delivery weeks later is unobservable), **real GPS**, **airplane mode**, and on-device
permission revocation. That's it — everything else is testable in the Simulator.

---

## 10. Working notes on the owner

- Direct, moves fast, says "continue" and "don't wait for me" — **bias toward doing the work and
  reporting, not asking.** But ask before pushing to `main` or anything irreversible; they say yes
  quickly when asked.
- Asks sharp clarifying questions that have twice caught my errors. Don't get defensive; check.
- Speech-to-text occasionally inverts meaning ("we're *not* going to develop on this Mac" meant
  the opposite) and drops punctuation. If a message contradicts itself, ask rather than guess.
- Wants Codex treated as a peer, not a subordinate.
- Prefers the full picture including what *didn't* work and what remains unverified. When I
  reported my own bug in `a7dfe10` alongside Codex's good work, the response was to keep going —
  accuracy is welcome, not punished.
- Asks for a written handoff before ending a session. Write it as if the next session starts with
  no memory at all, because it does.
