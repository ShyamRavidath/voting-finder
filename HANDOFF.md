# Vote4U — Handoff

**Audience: future me (Claude), resuming this project cold.** Written 2026-09-20.
Owner: Shyam Ravidath (`ShyamRavidath/voting-finder`), git user `vote4u`.

Read this first, then `CODEX_HANDOFF.md` if Codex has been working (it has), then `CLAUDE.md` for
web architecture. `ios/APP_STORE.md` holds the submission copy. `TRANSFER.md` is the record of the
Windows→Mac move and is mostly historical now.

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

---

## 2. Current state

### Where the repo is

`main`, pushed. Recent history newest-first:

```
1da4c8d feat(ios): harden iOS 17 and polish SwiftUI experience   ← Codex
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
├── ios/                      the native app, ~2.5k lines of Swift
│   ├── Vote4U.xcodeproj      HAND-WRITTEN pbxproj — see §5
│   ├── Vote4U/
│   │   ├── Vote4UApp.swift   @main, TabView root, DEBUG launch-arg hook
│   │   ├── Design/           Vote4UTheme, Vote4UActionStyle        (Codex)
│   │   ├── Models/           ElectionCalendar, ElectoralState, PollingResult
│   │   ├── Services/         APIClient, LocationManager, ReminderScheduler,
│   │   │                     SavedPlace, Formatting, SafariView, MapDirections
│   │   ├── Features/{Home,Vote,Map,News}/
│   │   └── Resources/        states.json, statePaths.json, officialLinks.json
│   ├── Vote4UTests/          28 unit tests
│   ├── Vote4UUITests/        7 UI tests
│   ├── screenshots/          5 × 1320×2868 App Store shots
│   ├── APP_STORE.md          listing copy, privacy labels, review notes
│   └── IOS_DEVELOPMENT_GUIDE.md   Codex's workflow notes — see §7
├── scripts/
│   ├── export-ios-data.mjs   regenerates the app's bundled JSON from client/src/data
│   ├── capture-screenshots.sh
│   └── test-ios.sh           THE iOS test runner — plain xcodebuild is NOT equivalent
├── tests/e2e/                Playwright, 3 device profiles, axe
├── CODEX_HANDOFF.md          on-ramp written for Codex
├── CLAUDE.md                 web architecture + React 19 traps (gitignored, local only)
└── TRANSFER.md               Windows→Mac move record
```

### Test status

| Suite | Command | Expected |
|---|---|---|
| Server | `npm test --prefix server` | **20 pass** |
| Web e2e local | `npm run test:e2e` | **87 passed, 9 skipped** |
| Web e2e prod | `BASE_URL=https://vote4ucyl.vercel.app npx playwright test` | **88 passed, 8 skipped** |
| iOS | `./scripts/test-ios.sh` | **35 tests, 0 failures, 0 skipped** |

Release build of the iOS app: clean, no warnings.

### Live site

https://vote4ucyl.vercel.app — healthy, auto-deploys from `main` on Vercel Hobby (non-commercial
use only, worth remembering).

- `/api/health` 200 · `/api/polling?zip=90210` 200 real venues · `/api/news` 200 via Google News RSS
- `/api/polling?lat=34.0736&lng=-118.4004` → ZIP 90212, nearest venue **0.1 km** (device-relative)
- `/api/elections` → **503 "Election data is not configured"**. Expected: `GOOGLE_CIVIC_API_KEY`
  is not in Vercel. The owner is rotating a leaked key. The app does not consume this endpoint yet.

### The environment

Mac, Apple Silicon, macOS 27 (Darwin 27.0.0). Repo at `~/voting-finder`. Node 26.0.0 / npm 11.12.1
(project was built on Node 22; everything passes on 26). Homebrew at `/opt/homebrew`.
**Xcode 27.0** at `/Applications/Xcode.app`, `xcode-select` correctly pointed at it.
Simulator runtimes: **iOS 27.0 and iOS 17.5** (Codex added 17.5 — see §4).
No `watchman`, `pod`, `eas`, `expo` — none are needed.
`server/.env` does **not** exist locally. Claude memory lives in
`~/.claude/projects/-Users-shyamravidath-voting-finder/memory/`.

---

## 3. Files actively being edited

| File | State / what to know |
|---|---|
| `ios/Vote4U/Features/Home/HomeView.swift` | Contains a **deliberate `Binding` instead of `.onChange`** — reverting that reintroduces a real bug (§4). Codex split it into `ElectionCountdownCard`, `ElectionReminderCard`, `HomeSavedPlaceCard`, `HomeVotingPlanCard`, `NonpartisanNotice`. |
| `ios/Vote4U/Features/Vote/VoteView.swift` | Was the largest view; Codex decomposed it into `VoteSearchForm`, `VoteStateContent`, `PollingResultsView`, `VoteSearchErrorView`, `SavedPollingPlaceCard`, `OfficialSourcesView`, `PollingSearchLoadingView`. Still holds the `#if DEBUG` launch-arg hook. |
| `ios/Vote4U/Features/Map/*` | Codex split `ElectoralMapView` into `ElectoralMapCanvas`, `ElectoralStateShapeView`, `ElectoralTallyView`, `ElectoralStateList`, `ElectoralStateDetail`, `ElectoralMapLegend`. |
| `ios/Vote4U/Features/Map/SVGPath.swift` | Hand-rolled parser, ~60 lines, M/L/Z only. Two bugs found in it so far. Every one of the 51 bundled shapes is covered by a test. |
| `ios/Vote4U/Services/Formatting.swift` | Codex replaced the cached `ISO8601DateFormatter` statics with `Date.ISO8601FormatStyle` for Sendable-safety. Reasonable; verify no perf regression if news lists grow. |
| `ios/Vote4U/Services/APIClient.swift` | Field names **must** match `server/services/*.js` exactly. This bit me once (§4). Distinguishes offline/unreachable/timeout/server/decoding. |
| `ios/Vote4U/Services/ReminderScheduler.swift` | Local notifications, fully unit-tested. |
| `ios/Vote4UUITests/ReminderPermissionUITests.swift` | **Most fragile file in the repo.** Read §4 and §5 before touching. |
| `server/routes/polling.js` | Recently gained `?lat=&lng=`. Device lookups deliberately bypass the Postgres cache. |
| `server/services/newsService.js` | NewsAPI just removed; the domain exclusion moved into `dedupeAndSort`. |
| `scripts/test-ios.sh` | Rewritten three times. Its comments explain why plain `xcodebuild test` is wrong. |

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
it, but ask first.

### iOS / Xcode

- **`simctl privacy` has no `notifications` service.** Only a UI-test tap can grant it. It *does*
  have `location`.
- **A notification grant survives both `simctl uninstall` and `simctl privacy reset`.** The only
  reliable reset is a **freshly created simulator**. `scripts/test-ios.sh` creates and destroys
  throwaway ones for exactly this.
- **iOS writes "Don’t Allow" with U+2019**, not an ASCII apostrophe. Match on a prefix.
- **A cold, freshly created simulator needs `app.wait(for: .runningForeground, timeout: 30)`
  before the first tap**, or the tap silently no-ops and no alert appears — indistinguishable from
  "the alert never came".
- **Never share a `derivedDataPath` between concurrent `xcodebuild` runs.** Result bundles collide
  (`mkstemp: No such file or directory`) and tests report `Executed 0 tests` while looking fine.
- **`xcrun simctl shutdown all`** when done.
- **`CGFloat.init` is overloaded enough to break Swift type inference** —
  `Double(sub).map(CGFloat.init)` produced *"failed to produce diagnostic for expression; please
  submit a bug report"*. Spell conversions out.
- **SwiftUI `Path.closeSubpath()` on an empty path leaves it non-empty.** Guard it.
- **A SwiftUI `Link` wrapping a `VStack` exposes one element whose label is the combined text**
  ("Find your official polling place, USA.gov"). Exact-match XCUITest queries fail; use `CONTAINS`.
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
- **A freshly created simulator is cold enough to outrun a UI test's patience.** The permission
  alert lands outside the timeout and the failure looks like "no alert appeared" rather than
  "slow boot". `scripts/test-ios.sh` now warms each new simulator with a throwaway
  install/launch/terminate before the real run. `app.wait(for: .runningForeground)` is **not**
  sufficient — it returns before SwiftUI has settled.
- **`.onChange` cannot distinguish a programmatic revert from a user action.** Denying
  notification permission set a warning flag *and* flipped the toggle back; the revert re-fired
  `.onChange`, re-entered the handler, and wiped the flag — so denial was completely unexplained.
  Fixed with an explicit `Binding`. **This is the class of bug to watch for in SwiftUI.**
- **An all-`Optional` `Codable` model decodes successfully with wrong field names.** The `Article`
  model used `publishedAt`/`image`; the API sends `date`/`imageUrl`. No crash, no compiler error,
  timestamps silently blank. Caught only by looking at the running app. **There are now decoding
  tests pinned to real captured payloads — add one whenever you touch a model.**
- Hand-written `project.pbxproj` works and uses **file-system-synchronized root groups**, so new
  `.swift` files under `ios/Vote4U/` need no project edit. Adding a *target* means copying the
  existing pattern carefully. An empty `<TestPlans></TestPlans>` in a scheme silently disables the
  whole `Testables` list — that produced *"Scheme is not currently configured for the test action"*.

### Product / infrastructure

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
- **React 19 traps (web only, still live in `client/`):** effects and ref callbacks must use block
  bodies. `useEffect(() => window.scrollTo(0,0))` returns Chromium's scroll Promise and React
  treats it as cleanup; `ref={(el) => (x = el)}` returns the element. Both caused production
  blank-page crashes.
- **Playwright locally runs `retries: 0`**, so flakes read as hard failures. A
  `browserContext.close: ENOENT … .playwright-artifacts-*` trace error is a known flake — re-run
  before investigating.
- **The old Windows C: drive filling up** surfaced as bizarre `ENOSPC` test failures, not an
  obvious disk error. Moot now (127 GB free) but a good reminder that infrastructure failures
  masquerade as code failures.

---

## 5. How to run everything

```bash
# Web
npm run dev                    # API :3001 + Vite :5173
npm test --prefix server       # 20 tests
npm run test:e2e               # 87 passed, 9 skipped
BASE_URL=https://vote4ucyl.vercel.app npx playwright test

# iOS — USE THE SCRIPT, not plain `xcodebuild test`
./scripts/test-ios.sh
DEVICE_TYPE='iPhone 15 Pro' RUNTIME='com.apple.CoreSimulator.SimRuntime.iOS-17-5' ./scripts/test-ios.sh
./scripts/capture-screenshots.sh
node scripts/export-ios-data.mjs    # after changing client/src/data/*

xcodebuild -project ios/Vote4U.xcodeproj -scheme Vote4U \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

**Why `test-ios.sh` is not replaceable by `xcodebuild test`:**
1. iOS asks for notification permission once and remembers; neither uninstall nor privacy reset
   clears it, so allow and deny each need a **throwaway simulator**.
2. The allow test must run **before** the unit tests, because `ReminderScheduler` needs
   authorization before `UNUserNotificationCenter` will queue anything. Without it those tests
   skip rather than fail.

**DEBUG-only launch arguments** (verified compiled out of Release with `strings`):
`-startTab home|vote|map|news`, `-startZip 90210`. They exist so screenshots and QA need no UI
automation. I used them heavily; extend them.

**Screenshotting the running app after every meaningful change caught three bugs that were
invisible to both the compiler and a green test run.** Do it.

---

## 6. Rules that are not negotiable

Product commitments, not style preferences.

1. **Never show a voter a location the data doesn't support.** Unofficial results are labelled
   "Not confirmed"; "no results" links to official state lookups rather than inventing something.
   Guideline 1.1.6, and simply correct.
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
back where warranted**, not to constrain it up front. `CODEX_HANDOFF.md` is the on-ramp I wrote.

**Codex's first commit, `1da4c8d`** — reviewed 2026-09-20. Kept, with follow-up fixes in
`a7dfe10` (see below):

- **Installed the iOS 17.5 runtime and verified against it.** This was my #1 recommendation and it
  closed the largest untested gap: nothing had ever run on the actual deployment target.
- **Decomposed the three big views** into ~20 focused subviews. `VoteView` went 188 lines lighter,
  `ElectoralMapView` 139. Good change; the monoliths were on my own list.
- **Added a design layer** (`Design/Vote4UTheme.swift`, `Vote4UActionStyle.swift`) with gradients
  and shared corner radii — addresses my "no app-wide visual identity" note.
- **Replaced cached `ISO8601DateFormatter` statics with `Date.ISO8601FormatStyle`** for
  Sendable-safety. Sound reasoning (formatters aren't Sendable); watch for perf if news grows.
- **Added `ios/IOS_DEVELOPMENT_GUIDE.md`**, distilled from an article the owner supplied. Useful,
  but **it is a translated third-party summary** and Codex flagged that itself. It references
  skills/plugins that may not exist here, and iOS 26 / Swift 6.2 / Liquid Glass guidance that does
  **not** apply to this iOS 17 project. Treat as inspiration, not instruction.

**Review outcome (`a7dfe10`).** The refactor and redesign are genuinely good and were kept — the
Home redesign in particular fixes the "Home is bare" criticism, and Codex's `test-ios.sh` change
fixed a real flaw of mine (my `run()` swallowed xcodebuild's exit status, so failures could pass
silently). Three follow-ups were needed:

1. Codex's new state search used `.searchable` with default placement → unreachable; pinned open.
2. My own `ReminderScheduler` cancel/add race, found only because I removed the test skips.
3. Simulator pre-warming, because cold boots were outrunning the permission-alert timeout.

**Still outstanding on Codex's work:**
- **`ios/screenshots/` is stale** — it shows the pre-redesign UI and these are App Store
  deliverables. Regenerate with `./scripts/capture-screenshots.sh`.
- **The new gradient theme is unverified in dark mode and at accessibility text sizes.** I
  verified those manually on the pre-Codex UI; the `Design/` layer is new since. Real regression
  risk from a change I otherwise like.
- Confirm the view decomposition preserved the accessibility grouping I added to cards and rows.

---

## 8. The next step I would take

**Immediately:** confirm `./scripts/test-ios.sh` is still 35/35 after Codex's refactor, then
**regenerate `ios/screenshots/`** — they are now stale relative to the polished UI, and they are
App Store deliverables.

Then, in rough value order:

**A. Verify the dark-mode / Dynamic Type passes still hold.** I verified them manually on the
pre-Codex UI; the new gradient theme is unverified at accessibility sizes and in dark mode. This
is a regression risk from a change I otherwise like.

**B. A WidgetKit extension.** Countdown or saved polling place. Genuinely useful, needs no Apple
account to build and test, and materially strengthens the 4.2 "elevates beyond a website"
argument. I rate this the highest-value *new* feature.

**C. Decouple UI tests from the live API.** Several smoke tests hit production with 30s timeouts
and fail when Vercel is slow. Launch-argument-driven state injection would make error states
deterministically testable — currently offline/timeout/decoding paths are only exercised by hand.

**D. Snapshot tests for the electoral map.** A silent `SVGPath` regression would render a
wrong-but-not-crashing map that only a human would notice.

**E. CI.** A GitHub Action on a macOS runner (free for public repos) running server tests,
Playwright and `test-ios.sh`. Would have caught by machine several things I caught by hand.

**F. SwiftLint or swift-format.** None exists; the codebase is small enough that adding one now
won't be noisy.

**G. Server:** a coordinate-aware cache key so device lookups aren't cache-bypassed; structured
logging; wire up `/api/elections` once the key lands so official-vs-estimated becomes visible.

**Things to verify rather than trust** (I wrote them all in one session):
`ElectionCalendar`'s fidelity to `client/src/lib/format.js`; `geocodeService.coordsToZip` edge
cases (ZIP+4 narrowing, outside-US); the Coarse-Location-only privacy label argument in
`APP_STORE.md`; whether iPhone-only is right.

---

## 9. Blocked on the owner

- **Apple Developer account is in verification.** No Team ID → no device build, no TestFlight, no
  submission. The owner will say when it clears. Then: Xcode ▸ Settings ▸ Accounts → add
  `ravidath@gmail.com`, set the team, or set `DEVELOPMENT_TEAM` and build with
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

### Still genuinely device-only

A notification **banner actually arriving** at its scheduled time (permission and queuing are
tested; delivery weeks later is unobservable), **real GPS**, **airplane mode**, and on-device
permission revocation. That's it — everything else is testable in the Simulator.

---

## 10. Working notes on the owner

- Direct, moves fast, says "continue" and "don't wait for me" — **bias toward doing the work and
  reporting, not asking.** But ask before pushing to `main` or anything irreversible.
- Asks sharp clarifying questions that have twice caught my errors. Don't get defensive; check.
- Speech-to-text occasionally inverts meaning ("we're *not* going to develop on this Mac" meant
  the opposite). If a message contradicts itself, ask rather than guess — I got this right once by
  asking, and it would have derailed the whole session.
- Wants Codex treated as a peer, not a subordinate.
- Prefers the full picture including what *didn't* work and what remains unverified.
