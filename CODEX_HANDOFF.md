# Vote4U — handoff to Codex

Written 2026-09-20 by Claude, for Codex. You have the same authority I had: **edit, refactor,
delete, restructure, and push.** Nothing here is off limits, and nothing below is a rule you must
obey — it is what I learned, including the parts I got wrong. If you think a decision was wrong,
change it and say why. Claude will review your changes afterwards and may push back, the same way
you should push back on this document.

**The brief from the owner:** the Apple Developer account is in verification, so the Team ID is
not available and nothing can run on a physical device or reach TestFlight. Everything that does
*not* need that should continue: testing, development, polish, UI improvement. Find the work that
is genuinely unblocked and do it.

---

## 1. The goal

Ship **Vote4U** to the iOS App Store as a native Swift/SwiftUI app, while keeping the existing
website running. Two UIs, one backend.

**Hard constraint: everything must stay free except the $99/yr Apple Developer Program.** The
owner set this and has reaffirmed it. Flag anything with a recurring cost rather than adopting it.
This is why the stack is Vercel Hobby, keyless APIs, MapKit instead of paid tiles, and local
notifications instead of a push server.

The app is functionally complete. It is not shipped.

---

## 2. Current state

### Repo

`github.com/ShyamRavidath/voting-finder`, branch `main`, currently `c9285f3`. Clean, pushed.
Local checkout: `~/voting-finder` on the owner's Mac (Apple Silicon, macOS 27, Node 26).

```
voting-finder/
├── api/index.js              Vercel serverless entry → re-exports the Express app
├── server/                   Express 5 API, runs standalone on :3001
│   ├── app.js                builds the app (no listen)
│   ├── routes/{news,polling,elections}.js
│   ├── services/{news,polling→geocode,civic}Service.js
│   ├── lib/fetchWithTimeout.js
│   └── test/api.test.js      20 tests, node:test, upstreams stubbed, no network
├── client/                   React 19 + Vite + Tailwind v4 — the website, still live
├── ios/                      NEW — the native app
│   ├── Vote4U.xcodeproj
│   ├── Vote4U/               app sources
│   ├── Vote4UTests/          28 unit tests
│   ├── Vote4UUITests/        7 UI tests
│   ├── screenshots/          5 App Store screenshots, 1320×2868
│   └── APP_STORE.md          listing copy, privacy labels, review notes
├── scripts/
│   ├── export-ios-data.mjs   generates the app's bundled JSON from the web app's data
│   ├── capture-screenshots.sh
│   └── test-ios.sh           the iOS test runner — read §6 before using plain xcodebuild
├── tests/e2e/                Playwright, 3 device profiles, axe a11y
├── HANDOFF.md                the long-running project handoff — read it too
├── TRANSFER.md               record of the Windows→Mac move
└── CLAUDE.md                 architecture notes, gitignored, local-only
```

### Everything currently green

| Suite | Command | Result |
|---|---|---|
| Server | `npm test --prefix server` | **20 pass** |
| Web e2e (local) | `npm run test:e2e` | **87 passed, 9 skipped** |
| Web e2e (production) | `BASE_URL=https://vote4ucyl.vercel.app npx playwright test` | **88 passed, 8 skipped** |
| iOS | `./scripts/test-ios.sh` | **35 tests, 0 failures, 0 skipped** |

Release build of the iOS app succeeds with no warnings.

### The live site

https://vote4ucyl.vercel.app — healthy. Deploys automatically from `main` on Vercel Hobby.

- `/api/health` → 200
- `/api/polling?zip=90210` → 200, real venues
- `/api/polling?lat=34.0736&lng=-118.4004` → 200, ZIP 90212, nearest venue 0.1 km
- `/api/news` → 200, Google News RSS
- `/api/elections` → **503 "Election data is not configured"** — `GOOGLE_CIVIC_API_KEY` is not
  set in Vercel. Expected. The owner is rotating a leaked key; until then this endpoint is off by
  design and the app does not use it.

### The iOS app, feature by feature

Four tabs. **News is last on purpose** — App Store guideline 4.2.2 treats a news aggregator as
thin, so the voting tools lead. Do not reorder without reading §7.

- **Home** — countdown to the next federal election, reminder toggle, nonpartisan disclaimer.
- **Vote** — ZIP entry, "Use my location", result cards with distance/Directions/Save/Share, a
  MapKit map, official-source links. Saved place persists and is readable offline.
- **Map** — all 51 states as SwiftUI `Path`s from bundled Albers-projected data, 538 tally,
  270 line, tappable state list.
- **News** — headlines with relative time, pull to refresh, `SFSafariViewController`.

Native: CoreLocation (when-in-use), UserNotifications (local only), `ShareLink`, haptics.
**No third-party dependencies at all.** Keep it that way if you can — it is a real advantage for
guideline 5.2.2 and there is nothing to audit or version-drift.

Build settings worth knowing: iOS 17 deployment target, Swift 5 language mode (code is written to
be Swift 6 clean, switching is a one-line change), `TARGETED_DEVICE_FAMILY = 1` (iPhone only,
deliberately — avoids maintaining iPad screenshots), `ITSAppUsesNonExemptEncryption = NO`,
bundle ID `com.shyamravidath.Vote4U`.

The Xcode project uses **file-system-synchronized root groups**, so adding a `.swift` file under
`ios/Vote4U/` needs no `project.pbxproj` edit. The pbxproj was hand-written; it works, but if you
need to add a target, copy the existing pattern carefully (see §6).

---

## 3. What is blocked, and what is not

**Blocked (needs the Team ID / a physical iPhone):**
- Running on real hardware at all.
- Seeing a notification banner actually arrive at its scheduled time.
- Real GPS, airplane mode, revoking permissions on-device.
- Archive, TestFlight, App Store Connect submission.
- Anything against iOS < 27 — only the iOS 27 runtime is installed, while the target is iOS 17.
  (You *can* download an older runtime from Xcode ▸ Settings ▸ Components without an account.
  Worth doing — it is the largest untested surface and needs no Team ID.)

**Not blocked — this is your playground:**
- Every Simulator test. **Simulator tests need no signing identity.** I initially told the owner
  notifications could not be tested without hardware; that was wrong, and correcting it found two
  real bugs. Assume more is testable than it looks.
- All UI, UX and accessibility work.
- Server changes, and the web app.
- Performance, Instruments, launch time.
- Localisation, Dynamic Type, VoiceOver, dark mode.
- Everything in §8.

---

## 4. Files actively being edited

Most recently touched, and where the live edges are:

| File | State |
|---|---|
| `ios/Vote4U/Features/Home/HomeView.swift` | Just fixed a re-entrancy bug (§5). The `Binding` there is deliberate — do not revert it to `.onChange`. |
| `ios/Vote4U/Features/Vote/VoteView.swift` | Largest view. Has a `#if DEBUG` launch-argument hook. Ripe for refactoring; see §8. |
| `ios/Vote4U/Features/Vote/VoteViewModel.swift` | `@Observable`, `@MainActor`. Owns state, saved place, location. |
| `ios/Vote4U/Features/Map/SVGPath.swift` | Hand-rolled parser, ~60 lines. Two bugs found so far. |
| `ios/Vote4U/Services/ReminderScheduler.swift` | Local notifications. Fully unit-tested. |
| `ios/Vote4U/Services/APIClient.swift` | `URLSession` + `Codable`. Field names must match `server/services/*.js` exactly — see §5. |
| `ios/Vote4UUITests/ReminderPermissionUITests.swift` | Most fragile tests in the repo. Read §6 before touching. |
| `server/routes/polling.js` | Recently gained `?lat=&lng=`. |
| `server/services/newsService.js` | NewsAPI just removed. |
| `scripts/test-ios.sh` | Rewritten three times. The comments explain why it is not just `xcodebuild test`. |

---

## 5. Everything that failed — do not repeat these

This is the most valuable section. Each of these cost real time.

### iOS / Xcode

**`simctl privacy` has no `notifications` service.** You cannot grant notification permission from
the CLI. The only way is to tap the alert in a UI test. `simctl privacy` *does* do `location`.

**A notification grant survives both `simctl uninstall` and `simctl privacy reset`.** I assumed
each would clear it; neither does. The only reliable reset is a **freshly created simulator**.
`scripts/test-ios.sh` creates and destroys throwaway simulators for exactly this reason.

**iOS writes "Don’t Allow" with a typographic apostrophe (U+2019).** Matching a source-code
`"Don't Allow"` finds nothing. Match on a prefix or use a `BEGINSWITH` predicate. This cost me
several runs because `XCTSkipUnless` turned the miss into a silent skip.

**A skip is not a pass.** I reported "notification testing works" off one passing test while the
deny path had never run — and it was broken. I removed `XCTSkipUnless` from the permission tests;
a missing alert now `XCTFail`s and prints the actual springboard button labels. Keep that.

**A cold, freshly created simulator needs `app.wait(for: .runningForeground, timeout: 30)` before
the first tap.** Otherwise the tap silently does nothing and no alert appears — which looks
identical to "the alert never came."

**Never run two `xcodebuild` invocations against the same `derivedDataPath`.** The result bundles
collide (`mkstemp: No such file or directory`) and tests report `Executed 0 tests` while
appearing to have run. I corrupted two runs this way and misreported the results.

**Shut simulators down.** I left four booted and exhausted system memory, which killed a test run.
`xcrun simctl shutdown all`.

**`CGFloat.init` is overloaded enough to blow up Swift type inference.**
`Double(substring).map(CGFloat.init)` produced "failed to produce diagnostic for expression;
please submit a bug report". Spell conversions out.

**SwiftUI `Path.closeSubpath()` on an empty path leaves it non-empty.** Guard it.

**A SwiftUI `Link` wrapping a `VStack` exposes one accessibility element whose label is the
combined text** ("Find your official polling place, USA.gov"). Exact-match XCUITest queries fail;
use `CONTAINS`.

**Individual state shapes on the electoral map are useless as VoiceOver targets** — several are a
few points wide and DC is effectively invisible. The map is one summary element and the state
list below it is the real interaction surface. Do not "fix" this by making the shapes focusable.

**A fixed `.font(.system(size: 72))` ignores Dynamic Type entirely.** The countdown now uses
`@ScaledMetric` capped at `accessibility2` with `minimumScaleFactor`.

**The `Article` model guessed its field names and silently shipped blanks.** The API sends `date`
and `imageUrl`; I wrote `publishedAt` and `image`. Because every field is `Optional`, decoding
*succeeded* and timestamps rendered as empty strings — no crash, no compiler error. Caught only by
looking at the running app. **There are now decoding tests pinned to real captured payloads;
keep them, and add one whenever you touch a model.**

**A re-entrancy bug hid behind `.onChange`.** Denying notification permission set a warning flag
*and* flipped the toggle back; flipping it back re-fired `.onChange`, which re-entered the handler
and wiped the flag. Users who denied got no explanation at all. Fixed with an explicit `Binding`.
The general lesson: in SwiftUI, if you programmatically revert a control's state, `.onChange`
cannot distinguish that from a user action.

### Product / infrastructure

**Railway is dead.** The old backend deployment returns "Application not found" and the free tier
is gone. Do not try to revive it.

**CARTO basemap tiles now stamp "API KEY REQUIRED" across every tile.** Replaced.

**OpenStreetMap's tile usage policy discourages app traffic** — which is why the iOS app uses
MapKit rather than reusing the web map. Nominatim (used server-side for geocoding) is a different
OSM service and is fine at low volume with a proper `User-Agent`, which `geocodeService.js` sets.

**Google Civic with a ZIP-only address always returns zero polling locations.** "Failed to parse
address" without an election ID, empty results with one. Official data generally needs a street
address and only appears close to an election.

**Google's "VIP Test Election" (id 2000) returns fake locations** that would have been labelled
"Official". Explicitly excluded in `civicService.js`. Do not remove that exclusion.

**Sample/fabricated polling locations were removed deliberately.** The old code invented "123 Main
St". See §7 — this is the one rule that matters most.

**NewsAPI was removed on 2026-09-20.** Its free plan is development-only under its own terms,
which is an App Store 5.2.2 violation for a shipped app. Production had always used the Google
News RSS fallback anyway. Do not reintroduce it without a paid plan that permits production use.
Subtlety: the biztoc/freerepublic exclusion was a NewsAPI *query parameter*, so removing the call
would have silently dropped the filter — it now lives in `dedupeAndSort` with its own test.

**React 19 crash traps (web only, but still live in `client/`):** an effect or ref callback must
use a block body. `useEffect(() => window.scrollTo(0,0))` returns Chromium's scroll Promise and
React treats it as a cleanup function; `ref={(el) => (x = el)}` returns the element. Both caused
production blank-page crashes.

**Playwright locally runs with `retries: 0`,** so a flake shows as a hard failure. A
`browserContext.close: ENOENT … .playwright-artifacts-*` trace-writer error is a known flake —
re-run before investigating.

**Expo / React Native was the original plan and is cancelled.** It only existed because the
previous dev machine was Windows with no Mac. The `shared/` JS extraction that plan required is
also cancelled — do not refactor `client/` for the app's benefit.

---

## 6. How to run things

```bash
# Web
npm run dev                    # API :3001 + Vite :5173
npm test --prefix server       # 20 tests
npm run test:e2e               # 87 passed, 9 skipped
BASE_URL=https://vote4ucyl.vercel.app npx playwright test   # 88 passed, 8 skipped

# iOS
./scripts/test-ios.sh          # 35 tests — USE THIS, not plain xcodebuild test
./scripts/capture-screenshots.sh
node scripts/export-ios-data.mjs   # regenerate bundled JSON after changing client/src/data/*

xcodebuild -project ios/Vote4U.xcodeproj -scheme Vote4U \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

**Why `test-ios.sh` exists and plain `xcodebuild test` is not equivalent:**

1. iOS asks for notification permission once and remembers. Neither uninstall nor privacy reset
   clears it, so the allow and deny tests each need a throwaway simulator.
2. The allow test must run **before** the unit tests, because `ReminderScheduler` needs
   authorization before `UNUserNotificationCenter` will queue anything. Without it those tests
   skip rather than fail.

**Debug-only launch arguments** (compiled out of Release — verified with `strings`):
`-startTab home|vote|map|news` and `-startZip 90210`. They exist so screenshots and QA need no UI
automation. Use them; extend them if useful.

---

## 7. The rules that are not negotiable

These are product commitments, not style preferences. Break them and the app misleads voters or
gets rejected.

1. **Never show a voter a location the data doesn't support.** Unofficial results are labelled
   "Not confirmed" in the UI and "no results" links to official state lookups rather than
   inventing something. Guideline 1.1.6, and the right thing to do.
2. **ZIP entry must always work when location permission is declined.** Guideline 5.1.1(iv).
3. **Never imply government affiliation or endorsement.** The nonpartisan disclaimer on Home and
   in the listing copy is deliberate. Guidelines 5.2.1 / 5.2.4.
4. **News stays the last tab and never becomes the centre of the app.** Guideline 4.2.2 — a news
   aggregator reads as thin, and this is the single biggest rejection risk.
5. **Never commit keys.** The Google Civic key was leaked in git history once already.

App Store research already done (guidelines as of June 8 2026, searched in full): "election",
"voter", "nonpartisan" and "polling place" appear **zero times**. There is no rule requiring a
government entity to publish an election app, and elections are **not** in 5.1.1(ix)'s
highly-regulated list, so the individual account is fine. **4.2 is the real risk**, and going
native is the strongest answer to it. Full detail in `HANDOFF.md` §10 and `ios/APP_STORE.md`.

---

## 8. What I would do next — the actual work list

Roughly ordered by value. Take, reorder, or reject freely.

### A. Close the biggest untested gap (no Team ID needed)

Download an **older iOS runtime** (Xcode ▸ Settings ▸ Components — free, no account) and run the
whole suite against **iOS 17**, the actual deployment target. Nothing has ever run on it.
`@Observable`, `.sensoryFeedback`, `ContentUnavailableView`, and the SwiftUI `MapKit` API are all
iOS 17 APIs, but "compiles against" is not "behaves on". I rate this the highest-value unblocked
task and I never got to it.

### B. UI and UX — the app is correct but plain

I built for correctness and ran out of room for craft. Honest assessment of each screen:

- **Home is bare.** A number, a toggle, a disclaimer. It should be the reason someone opens the
  app twice. Ideas: surface the saved polling place here, show registration deadlines, show
  "early voting starts in N days", make the countdown feel designed rather than defaulted.
- **The countdown is a plain number.** No typographic personality, no motion. A `ContentTransition`
  or a subtle ring would cost little.
- **Vote's result cards are functional and visually flat.** Three bordered buttons in a row is not
  a hierarchy — Directions is the primary action and does not look like it.
- **Screenshot 4 in `ios/screenshots/` is mostly whitespace** and I flagged it as the weak one.
  If the empty state gets better, that screenshot gets better.
- **The Map tab's state list is a long undifferentiated scroll** of 51 rows. It works and it is
  the accessibility surface, but it could be searchable or collapsible.
- **No empty/loading skeletons** anywhere — just `ProgressView`.
- **No app-wide visual identity.** The accent colour is set and otherwise it is stock SwiftUI.
  The web app has a design language (`client/src/index.css`); the app does not echo it.
- **Consider a widget.** A countdown or saved-polling-place WidgetKit extension is genuinely
  useful, strengthens the 4.2 story considerably, and needs no account to build and test.

### C. Testing depth

- **Snapshot tests** for the electoral map — a silent regression in `SVGPath` would currently
  produce a wrong-looking but non-crashing map, and only a human would notice.
- **Network-failure UI tests.** `APIClient` distinguishes offline / unreachable / timeout /
  server / decoding, but only the unreachable path has ever been exercised, and by hand.
- **A test for the saved-place lifecycle** (save → persists across launch → remove).
- **Launch-argument-driven state injection** so UI tests can exercise error states deterministically
  instead of depending on the live API. Several smoke tests currently hit production and take 30s
  timeouts — that is a real fragility.
- The UI smoke tests **depend on the live API**. If Vercel is slow they fail for no good reason.

### D. Code quality

- `VoteView.swift` is doing too much — search field, location button, saved card, results, error
  states, official links.
- `APIClient` has no retry and no request coalescing.
- Consider Swift 6 language mode; the code was written for it.
- There is **no SwiftLint / swift-format**. Adding one is free and the codebase is small enough
  that it will not be noisy.
- No CI. A GitHub Action running `npm test`, Playwright and `test-ios.sh` on a macOS runner is
  free for public repos and would have caught the things I caught by hand.

### E. Server

- `/api/polling` device lookups **bypass the Postgres cache** by design (stored distances are
  ZIP-centroid-relative and would poison later ZIP requests). A coordinate-aware cache key would
  restore caching for the app's primary path.
- `/api/elections` returns 503 until the owner sets `GOOGLE_CIVIC_API_KEY`. The app does not
  consume it yet — when it does, the official-vs-estimated distinction becomes visible and the
  "Not confirmed" badge finally has a counterpart.
- No structured logging or error reporting anywhere.

### F. Things to verify rather than trust

I wrote all of this in one session. A second pair of eyes on:
- `ElectionCalendar`'s port fidelity against `client/src/lib/format.js`.
- `geocodeService.coordsToZip` — ZIP+4 narrowing, the outside-US path.
- The privacy-label answers in `ios/APP_STORE.md` (I argue Coarse Location only; check that).
- Whether `TARGETED_DEVICE_FAMILY = 1` is the right call.

---

## 9. When the Team ID arrives

1. Xcode ▸ Settings ▸ Accounts → add `ravidath@gmail.com`; set the team on the Vote4U target with
   automatic signing. Or set `DEVELOPMENT_TEAM` in the pbxproj and build with
   `-allowProvisioningUpdates`.
2. Device build → **confirm a reminder actually fires** (Phase 3's stated exit criterion, still
   unverified).
3. Airplane mode, real GPS, permission denial on-device.
4. Archive → Organizer → Distribute → App Store Connect → TestFlight.
5. Paste `ios/APP_STORE.md` into App Store Connect, upload `ios/screenshots/`, submit.

Owner's outstanding items, not yours: rotate the leaked Google Civic key into Vercel, and install
the App Store skills listed in `HANDOFF.md` §8.

---

## 10. How I worked, for whatever it is worth

- I screenshot the running app after every meaningful change. Three of the bugs above were
  invisible to the compiler and to a green test run, and visible instantly on screen.
- I write the commit message as an argument for the change, not a description of the diff.
- When I reported something as done that was not verified, I said so explicitly. The owner asked
  "we can't test without my id?" and that single question exposed a wrong assumption of mine plus
  two real bugs. Treat scepticism as a gift.
- `HANDOFF.md` is the long-running record and stays authoritative for project history; this file
  is specifically your on-ramp. Update both.

Good luck. Change whatever deserves changing.
