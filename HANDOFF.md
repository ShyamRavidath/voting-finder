# Vote4U — Handoff

**Audience: future me (Claude), resuming this project cold with no memory of it.** Rewritten
2026-09-21, after the session that shipped the polling fallback, the US news scoping, the
re-shot screenshots and the Home Screen widget.

Owner: Shyam Ravidath (`ShyamRavidath/voting-finder`), git user `vote4u`, email
`dpti0904@gmail.com`.

**Reading order:** this file, then `CODEX_HANDOFF.md` (Codex has worked here and will again),
then `CLAUDE.md` for architecture. `ios/APP_STORE.md` holds the submission copy.
`ios/IOS_DEVELOPMENT_GUIDE.md` is Codex's notes — inspiration, not instruction (§7).
`TRANSFER.md` is the Windows→Mac record and is now historical.

> ### If you read only one thing
>
> The app is **functionally complete and unshipped**. The only hard blocker is Apple's account
> verification. `main` is green at `6e00b86`; **two PRs are open and unmerged — #3 (screenshots)
> and #4 (widget)** — and the first thing to do is check whether they landed. Everything the
> owner asked for by name is done. The next work is §9: CI (§9B) is the highest-value item
> because it would have caught, by machine, two bugs I caught by hand.

---

## 1. The goal, and the constraints that shape every decision

Ship **Vote4U** to the iOS App Store as a **native Swift/SwiftUI** app while keeping the website
live. Two UIs, one Express backend, one deployment.

**Everything must stay free except the $99/yr Apple Developer Program.** The owner set this
explicitly and has reaffirmed it more than once. It is the reason for: Vercel Hobby, keyless
APIs, MapKit instead of paid tiles, local notifications instead of a push server, no third-party
Swift dependencies, no paid CI. **Flag anything with a recurring cost rather than adopting it.**

### Decision log — don't relitigate these without new information

| Decision | When | Why |
|---|---|---|
| Native Swift/SwiftUI, not Expo/React Native | 2026-09-20 | Expo existed only because the old dev machine was Windows with no Mac. That constraint is gone. Native is also the strongest answer to guideline 4.2. |
| Build locally in Xcode, not EAS | 2026-09-20 | A Mac removes the entire cloud-build apparatus. No 15-builds/month quota, no 90-min queue, no App Store Connect API key juggling. |
| `shared/` JS extraction **cancelled** | 2026-09-20 | It only existed so JS could be shared with React Native. With Swift on the other side there is nothing to share. **Do not refactor `client/` for the app's benefit.** |
| iPhone only (`TARGETED_DEVICE_FAMILY = 1`) | 2026-09-20 | Avoids maintaining a second set of iPad screenshots. Revisit only if the owner asks for iPad. |
| iOS 17 deployment target | 2026-09-20 | ~95%+ of devices, and unlocks `@Observable`, `.sensoryFeedback`, `ContentUnavailableView`, modern MapKit-in-SwiftUI. |
| NewsAPI removed entirely | 2026-09-20 | Free plan is development-only under its own terms → guideline 5.2.2 violation. Production had always used the Google News RSS fallback anyway. |
| News is the **last** tab | 2026-09-19 | 4.2.2 treats news aggregators as thin. This is the single biggest rejection risk. |
| UI tests drive stubs, not production | 2026-09-20 | A live third-party geocoder made a correct build fail. See §5 and §9. |
| Widget is offline-only, no App Group | 2026-09-21 | A widget that can fail shows a spinner on someone's Home Screen. It also keeps the widget unblocked by the missing Team ID. |
| Never use `-stubPolling` for App Store screenshots | 2026-09-21 | Those venues are fabricated. Store marketing is the last place rule #1 should bend. This reverses an earlier suggestion of mine. |

---

## 2. Current state

### Where the repo is

`main` is at **`6e00b86`** (merge of PR #2), pushed, clean. Newest-first:

```
bdec208 feat(ios): add an Election Countdown widget                    ← PR #4, OPEN
6e00b86 Merge pull request #2 …                                        ← main
445b269 docs: record the §8A/§8D work and three new lessons
dd72cb0 feat(api)!: scope the news feed to US elections
cad58f6 feat(api): widen the polling search instead of dead-ending
d4d93e0 fix(ios): answer system alerts by matching the button's own label
61b4aa9 docs: rewrite HANDOFF.md for a cold restart after the Codex review
08e4bc7 fix(ios): repair the iOS 17.5 test command and decouple UI tests from the live API
452bc0b docs: record the Codex review outcome and four new iOS lessons
a7dfe10 fix(ios): repair a scheduling race, an unreachable search, and silent test skips
1da4c8d feat(ios): harden iOS 17 and polish SwiftUI experience          ← Codex
```

### Open pull requests — **check these first**

| PR | Branch | What | State |
|---|---|---|---|
| **#6** | `test/electoral-map-render` | Electoral-map render tests (§9C) | OPEN, no checks — see §9B |
| **#5** | `ci/github-actions` | GitHub Actions CI (§9B) | OPEN, **both workflows green** |
| **#4** | `feat/election-countdown-widget` | The WidgetKit extension + every handoff update | OPEN, mergeable |
| **#3** | `docs/screenshots-post-deploy` | Re-shot App Store screenshots + `APP_STORE.md` rules | OPEN, mergeable |

None of them depend on each other and merge order does not matter. **Merge #5 first anyway**: no
other PR gets CI until the workflows are on `main` (§9B). **#2 is merged and deployed.**

**`HANDOFF.md` on `main` is the pre-rewrite version** — the cold-restart rewrite is in PR #4, so
every handoff update since lands there too. That is why PR #4's diff is wider than "the widget".

`gh` is installed and authenticated as `ShyamRavidath` (the owner set it up 2026-09-21), so
`gh pr create` / `gh pr view` work directly. Earlier in that session it was missing and PR bodies
had to be pasted by hand — that is no longer true.

### Tree

```
voting-finder/
├── api/index.js              Vercel serverless entry → re-exports the Express app
├── server/                   Express 5, standalone on :3001
│   ├── app.js                builds the app (no listen); server/index.js listens
│   ├── routes/{news,polling,elections}.js
│   ├── services/{news,geocode,civic}Service.js
│   ├── lib/fetchWithTimeout.js
│   └── test/api.test.js      27 tests, node:test, upstreams stubbed, no network
├── client/                   React 19 + Vite + Tailwind v4 — the live website
├── ios/                      the native app, 54 Swift files
│   ├── Vote4U.xcodeproj      HAND-WRITTEN pbxproj — see §6
│   ├── Vote4U/               the app target
│   │   ├── Vote4UApp.swift   @main, TabView root, DEBUG launch-arg hook
│   │   ├── Design/           Vote4UTheme, Vote4UActionStyle        (Codex)
│   │   ├── Models/           ElectionCalendar, ElectoralState, PollingResult
│   │   ├── Services/         APIClient, APIStub (DEBUG only), LocationManager,
│   │   │                     ReminderScheduler, SavedPlace, Formatting,
│   │   │                     SafariView, MapDirections
│   │   ├── Features/{Home,Vote,Map,News}/   ~20 small views after Codex's split
│   │   ├── Features/Widget/  ElectionCountdownWidgetView — app target ON PURPOSE (§4)
│   │   └── Resources/        states.json, statePaths.json, officialLinks.json
│   ├── Vote4UWidgets/        the extension: WidgetBundle + Widget/TimelineProvider only
│   ├── Vote4UWidgets-Info.plist   OUTSIDE the folder on purpose — see §5
│   ├── Vote4UTests/          41 unit tests across 7 files
│   ├── Vote4UUITests/        11 UI tests across 2 files
│   ├── screenshots/          5 × 1320×2868 App Store shots
│   ├── APP_STORE.md          listing copy, privacy labels, review notes, capture rules
│   └── IOS_DEVELOPMENT_GUIDE.md   Codex's notes — inspiration, not instruction
├── scripts/
│   ├── export-ios-data.mjs   regenerates the app's bundled JSON from client/src/data
│   ├── generate-icons.mjs    PWA/App Store icons from the logo
│   ├── capture-screenshots.sh
│   └── test-ios.sh           THE iOS test runner — plain xcodebuild is NOT equivalent
├── tests/e2e/                Playwright: api, electoral-map, navigation, news, pages, polling
├── CODEX_HANDOFF.md          on-ramp written for Codex, with my replies inline
├── CLAUDE.md                 architecture + traps — **GITIGNORED, local to this machine only**
└── TRANSFER.md               Windows→Mac move record (historical)
```

**`CLAUDE.md` is gitignored** (`.gitignore:9`). It holds architecture notes including the polling
tiers, the news-query rules and the widget layout. Those notes do **not** travel with the repo —
if you are on a different machine they will be missing, and this file is the only copy of that
knowledge. Anything important enough to survive belongs here too.

### Test status — every number below was run, not assumed, on 2026-09-21

| Suite | Command | Result |
|---|---|---|
| Server | `npm test --prefix server` | **27 pass, 0 fail** |
| Web e2e local | `npm run test:e2e` | **90 passed, 9 skipped** — first run ever performed on this Mac |
| Web e2e prod | `BASE_URL=https://vote4ucyl.vercel.app npx playwright test` | 88 passed, 8 skipped *(inherited from the old machine, not re-run here)* |
| iOS on iOS 27.0 | `./scripts/test-ios.sh` | **52 tests, 0 failures, 0 skipped** |
| iOS on iOS 17.5 | `DEVICE_TYPE='iPhone 15 Pro' RUNTIME='com.apple.CoreSimulator.SimRuntime.iOS-17-5' ./scripts/test-ios.sh` | **52 tests, 0 failures, 0 skipped** — re-run 2026-09-21 on `feat/election-countdown-widget`, so the widget is now proven on the deployment target, not just on 27.0 |

**Playwright browsers are now installed** (chromium + webkit, 2026-09-21). §10 used to list this
as a blocker; it no longer is.

The 52 breaks down as: 41 unit (Vote4UTests) + 9 smoke UI + 1 allow-notifications + 1
deny-notifications. `test-ios.sh` ends with a Release build and greps the binary to prove no
DEBUG launch-argument or stub string shipped.

### Live site — https://vote4ucyl.vercel.app

Healthy, auto-deploys from `main` on Vercel Hobby (non-commercial use only, worth remembering).
Verified 2026-09-21 after PR #2 deployed:

- `/api/health` → 200
- `/api/news` → 200, 15 articles, all US, leading with "2026 Midterm Elections: The races that
  will decide control of Congress" and "Voting in the 2026 midterms? Here's what you need to know
  before Nov. 3"
- `/api/polling?zip=90210` → `estimated`, radius 10
- `/api/polling?zip=83428` → `nearby`, radius 25 — **this ZIP used to dead-end**
- `/api/polling?zip=59645` → `none`, which is correct; there genuinely is nothing there
- `/api/elections` → **503 "Election data is not configured"**. Expected: `GOOGLE_CIVIC_API_KEY`
  is not in Vercel. The owner is rotating a leaked key. The app does not consume this endpoint.

### The environment (this machine)

Mac, Apple Silicon, macOS 27 (Darwin 27.0.0). Repo at `~/voting-finder`.
**Node v26.0.0 / npm 11.12.1** (project was built on Node 22; everything passes on 26).
Homebrew at `/opt/homebrew`. **Xcode 27.0** (build 27A266a) at `/Applications/Xcode.app`,
`xcode-select` correctly pointed at it.

Simulator runtimes: **iOS 27.0 and iOS 17.5**. Devices: iPhone 17 / 17e / 18 Pro / 18 Pro Max /
Air on 27.0; iPhone 15 / 15 Plus / 15 Pro / 15 Pro Max / SE 3 on 17.5. **There is no iPhone 15 Pro
on iOS 27, which matters — see §5.**

`gh` **is** installed and authed. `watchman`, `pod`, `eas`, `expo` are not, and none are needed.
`server/.env` does **not** exist locally, so local runs are keyless — same as production.
ImageMagick / PIL are **not** available, so contact-sheeting screenshots is not possible; read
PNGs one at a time.

Claude memory lives in `~/.claude/projects/-Users-shyamravidath-voting-finder/memory/`.

---

## 3. What shipped in the 2026-09-21 session

Four pieces of work. Two are merged and live, two are in open PRs.

### A. The polling search degrades instead of dead-ending (PR #2, **merged + deployed**)

The owner's request, verbatim: *"if there are no results being returned, we can ideally report
that to the user and then just come up with community centers or something else (the next best
thing)."*

`findNearbyPollingVenues` now runs in tiers, each running only when the one above came back empty:

| `dataSource` | what it is | box | distance cap |
|---|---|---|---|
| `official` | Google Civic | — | — |
| `estimated` | library / community center / town hall, city+state in the query text | ±0.03° | 10 km |
| `nearby` | **new** — place name dropped so the bbox does the geography, plus school and fire station | ±0.1° | 25 km |
| `none` | we say so rather than inventing anything | — | — |

**Dropping the place name mattered more than the wider box.** Re-probing on 2026-09-21 showed
`library Beverly Hills California` returning venues *again* — the 90210 hole was Nominatim's
**text index** being flaky, not a geography problem. Tier 2 removes the text dependency entirely.

`searchRadiusKm` rides along in the response so both UIs can say how far the search went.
**Labelling gets more cautious as the tier weakens, never less** (rule #1): tier-2 venues are
typed `Civic Building`, never `Likely Polling Place`, and both UIs carry distinct widened-search
copy. Per-venue "Not confirmed" is unchanged — tier 2 is still `isEstimated: true`.

Nominatim's 1 req/s policy is shared across both tiers, so the worst case is 7 sequential calls,
inside `vercel.json`'s `maxDuration: 30`.

**Found along the way, not in the plan: we were showing voters a bus stop.** Nominatim matches
free text, so `town hall` returned the bus stop named "Paterson Plank Rd At Town Hall", `library`
returned a Little Free Library book box, and `community center` returned the "Community Compost
Center" — all under "Likely Polling Place". `isPlausibleVenue` rejects them on OSM `class`/`type`.
It is a **denylist, not an allowlist**, because a real community center is often only tagged
`building=yes`.

### B. The news feed is scoped to US elections (PR #2, **merged + deployed**)

The tab led with Turkey's April 2028 election and the Philippines' 2028 race. `gl=US&hl=en-US&ceid=US:en`
were **already** on the request and did nothing about it — they bias the Google News *edition*,
not the subject. Two real bugs:

1. The query itself was `"2028 election" OR "2028 presidential race"`, which those stories match
   perfectly. `newsQuery()` now builds year-qualified terms from `nextFederalElectionYear()`,
   mirroring `nextFederalElection` in `client/src/lib/format.js` down to the `(8 - weekday) % 7`
   first-Monday arithmetic, so the feed will not go stale the morning after an election.
   **Every term must be year-qualified**, and a test enforces it.
2. **`toArticle`'s relevance gate was silently undoing the fix.** It required the literal string
   `"2028"` in the title, so every midterm headline the new query returns was discarded ("Early
   voting begins in U.S. midterm elections" has no year in it at all). It now matches
   word-bounded election vocabulary — word-bounded because a substring test matches "pollution".

Breaking change: `candidate` is now **null** when no watchlist candidate is named. It used to be
the placeholder string `"2028 Election"`, which `NewsCard.jsx` then had to compare against by hand
to hide. Nothing else reads it; iOS does not display it.

Measured on the live feed, before → after: **8 articles with foreign politics leading → 15 (the
`MAX_ARTICLES` cap), all US**, now leading with early voting, mail-in ballots and voter guides.

### C. App Store screenshots re-shot (PR #3, **open**)

Captured *after* #2 deployed, because the app points at production directly. All five opened and
checked rather than trusting the script's exit code.

- `3-electoral-map.png` was **genuinely stale** — no search field under the title, so it predated
  `a7dfe10`'s pinned-open `.searchable`. Now fixed.
- `1-vote-results.png` was **not** stale. The previous HANDOFF claimed that ZIP "no longer
  returns" Beverly Hills venues; production returns exactly what the shot showed.
- `4-official-sources.png` is byte-identical to the previous capture, which is correct for a
  purely static screen.

`APP_STORE.md` gained two rules, both learned rather than assumed: capture only after the server
is deployed, and never use `-stubPolling` for store screenshots.

### D. An Election Countdown widget (PR #4, **open**)

`Vote4UWidgets`, an app-extension target with one widget in five families: `.systemSmall`,
`.systemMedium`, `.accessoryRectangular`, `.accessoryCircular`, `.accessoryInline`.

- **Offline by design.** No network, no App Group, so nothing here is blocked on the Apple
  account. `ElectionCalendar` and the countdown views are compiled into the extension by explicit
  `PBXFileReference`s rather than duplicated — the same arithmetic already drives the Home
  countdown and the reminder schedule, and a third copy would be a third chance to disagree.
- **Timeline is one entry per local midnight**, seven ahead, then `.atEnd`, each computed for
  *its own* date. WidgetKit budgets refreshes per app per day; asking to be woken hourly for a
  number that moves once a day is how a widget gets throttled and goes stale.
- **The views live in the app target** (`Vote4U/Features/Widget/`). A test bundle cannot import an
  app extension, so anything living only in the widget can never be tested or rendered.
- 11 new tests: 8 logic, 3 rendering every family through `ImageRenderer`, including a bitmap
  check for a rendered-but-blank view that a size assertion would sail straight past.

---

## 4. Files actively being edited

| File | State / what to know |
|---|---|
| `server/services/geocodeService.js` | **Heavily rewritten in #2.** `VENUE_TIERS` drives the two-tier search; `isPlausibleVenue` is the OSM class/type denylist; `buildVenue` takes the venue's own `address.state`, not the ZIP's, because the widened box can cross a state line. Returns `{ locations, dataSource, searchRadiusKm }` — the shape changed, the route was updated with it. |
| `server/services/newsService.js` | `newsQuery()` + `nextFederalElectionYear()` + `isElectionRelevant()` are new and exported for tests. **Keep `nextFederalElectionYear` in step with `client/src/lib/format.js`.** `ELECTION_TERMS` is a word-bounded regex, deliberately. |
| `server/routes/polling.js` | Carries `searchRadiusKm` through to the payload and the Postgres cache. Device lookups still bypass the ZIP cache. |
| `server/test/api.test.js` | 27 tests. The suite takes ~29 s because Nominatim's 1 req/s pacing is real, not stubbed away. That is deliberate — it proves the budget. |
| `client/src/components/PollingFinder.jsx` | `SOURCE_NOTICE` now has a `nearby` entry whose body takes `(election, radiusKm)`. The empty state mentions that the search was widened. |
| `client/src/components/NewsCard.jsx` | No longer compares `candidate` against the magic string `'2028 Election'`. |
| `ios/Vote4U.xcodeproj/project.pbxproj` | **Hand-written, and now four targets.** The widget added ~90 lines across nine sections. ID scheme is `F4…0001`–`F4…0040`; the widget block is `0030`–`0040`. Uses **file-system-synchronized root groups**, so new `.swift` files under a target's folder need no project edit — but sharing one file between targets needs an explicit `PBXFileReference` + `PBXBuildFile` (that is how `ElectionCalendar.swift` and `ElectionCountdownWidgetView.swift` reach the widget). |
| `ios/Vote4UWidgets-Info.plist` | Carries the one key that cannot be a build setting. **Do not move it into `ios/Vote4UWidgets/`** — see §5. |
| `ios/Vote4U/Features/Widget/ElectionCountdownWidgetView.swift` | Holds `ElectionCountdownEntry` and both view structs. `ElectionCountdownContent` takes `family` explicitly so tests can render it. The medium layout's countdown column uses a **fixed** width; reverting that to `maxWidth` reintroduces the overflow. |
| `ios/Vote4U/Models/ElectionCalendar.swift` | Gained `countdownPhrase`, `shortKind`, `isPresidential`, `spokenSummary` and `countdownRefreshDates`. All are used by the widget and all are tested. |
| `ios/Vote4UUITests/ReminderPermissionUITests.swift` | **Still the most fragile file in the repo.** Now uses `matching(_:)`; do not revert to `containing(_:)` (§5). Codex's `dx: 0.9` coordinate tap is still needed. |
| `ios/Vote4U/Services/APIStub.swift` | DEBUG-only, entirely inside `#if DEBUG`. Gained a `nearby` case. It invents venues, so it must never ship — `test-ios.sh` proves that every run. |
| `scripts/test-ios.sh` | Rewritten four times. Its comments explain why plain `xcodebuild test` is wrong. **Not yet updated for the widget target** — it still only tests Vote4U's schemes, which is correct, but see §9. |
| `ios/APP_STORE.md` | Updated in #3 with the capture-ordering and no-stub rules. |

---

## 5. Everything that failed — the expensive lessons

**This is the section I would most regret losing.** Each cost real time, and several were my own
misreporting rather than genuine obstacles.

### Process mistakes I made (most important — these are about judgement, not iOS)

**I declared something "done" that had never actually run.** I told the owner "the notification
gap is closed" on the strength of one passing allow-test, while the deny path had never executed
and was broken. The owner asked *"we can't test without my id?"* — that single sceptical question
exposed a wrong assumption plus two real bugs. **Treat scepticism as a gift and verify before
declaring.**

**I reviewed an artefact by reading its commit message.** I wrote in HANDOFF that Codex's
screenshots were "stale, showing the pre-redesign UI". They were not. Later I repeated the same
class of error in the opposite direction: HANDOFF claimed `1-vote-results.png` was stale because
90210 "no longer returns" venues — production returns exactly what it shows. **Open the artefact.
A commit message is a claim, and so is a previous handoff.**

**A skip is not a pass.** `XCTSkipUnless` turned a broken selector into a silent green run for
several iterations. Removed; a missing alert now `XCTFail`s and prints the actual springboard
button labels. Keep it that way — that diagnostic is what solved the 2026-09-21 failure.

**A green build is not a working feature.** This bit twice in one session. The widget built
cleanly, embedded its `.appex`, and could never have appeared in anyone's gallery. **Ask what
observable thing proves the feature works, then check that thing.**

**I understated the blast radius of a failure.** I called the iOS suite failure "a pre-existing
test, not my changes" — true, but `test-ios.sh` runs that test *first*, so its failure aborted the
run before the unit tests and `AppSmokeUITests` ever executed. **A red run says nothing about
anything downstream of the red test.**

**I overstated a blocker.** I claimed notifications couldn't be tested without a physical device.
Wrong: XCUITest taps system alerts, and **Simulator tests need no signing identity at all**.

**I chased three confident wrong theories in a row** (grants survive uninstall → grants survive
privacy reset → cold-start timing) when the actual cause was a typographic apostrophe. **Dump the
actual state early** instead of theorising.

**I corrupted two test runs by launching concurrent `xcodebuild` processes** against the same
`derivedDataPath`, then misreported the results as real. And I **exhausted system memory** by
leaving four simulators booted. On 2026-09-21 I repeated a softer version: I left **five**
overlapping background watchers polling the same process, and the harness killed them for memory.
**One watcher, not five.**

**I fixed the wrong thing first.** My `ImageRenderer` dump showed the medium widget overflowing.
The layout was fine; the *harness* was wrong, because it did not simulate WidgetKit's ~16 pt
content margins. **When a render looks wrong, check the harness before changing the design.**

**I hid a build failure behind `>/dev/null 2>&1`** and had to reproduce it by hand. Redirect if
you must, but always print the tail on failure.

**I committed directly to `main` twice without branching** before asking. The owner was fine with
it. On 2026-09-21 the owner chose "branch, commit, push, open PR" when offered the options — **that
is the preferred flow now.**

### WidgetKit (all learned 2026-09-21)

- **`INFOPLIST_KEY_NSExtensionPointIdentifier` is accepted and then silently ignored.**
  `INFOPLIST_KEY_*` only writes *top-level* Info.plist keys, and this one must be nested inside
  `NSExtension`. A real Info.plist file is the only way.
  **Verify with `xcrun simctl spawn <device> pluginkit -m -v -p com.apple.widgetkit-extension`** —
  if the bundle id is not in that list, iOS does not think it is a widget.
- **That Info.plist must live *outside* the target's synchronized group folder.** A
  `PBXFileSystemSynchronizedRootGroup` sweeps everything in its directory into Copy Bundle
  Resources, and a file that is both the target's `INFOPLIST_FILE` and a copied resource fails
  with *"Multiple commands produce … Info.plist"*. Hence `ios/Vote4UWidgets-Info.plist` beside
  `ios/Vote4UWidgets/`.
- **`.frame(maxWidth:)` does not clamp a `Text`.** Frames do not clip, so a string that wants more
  room draws past the edge — "Tomorrow" ran straight off the medium widget. A *definite* width
  gives `minimumScaleFactor` something to scale against.
- **`\.widgetFamily` is a read-only environment key**, so a test cannot set it. Pass the family as
  an explicit parameter if the layouts are ever to be rendered outside a real widget.
- **Springboard automation to the widget gallery does not work and is not worth fixing.** It never
  reached jiggle mode and cost ten minutes per attempt. `pluginkit` proves registration and
  `ImageRenderer` proves rendering; the gallery adds only flakiness.

### iOS / Xcode

- **`XCUIElementQuery.containing(_:)` is not `matching(_:)`.** `containing` keeps elements that
  have a **descendant** satisfying the predicate and ignores the element's own attributes, so it
  can never match a leaf button by its label. The failure was self-refuting — the diagnostic
  printed `springboard buttons: ["Don't Allow", "Allow"]` while claiming no button started with
  "Allow". **When a selector and its own diagnostic disagree, suspect the query API.** Note this
  file passed 38/38 the day before with identical code, so the hierarchy it relied on is not
  stable across runs.
- **A failed UI test costs ten extra minutes.** Xcode tries to collect simulator diagnostics and
  gives up only after a 600 s timeout (`Failure collecting diagnostics from simulator`). A run
  that looks hung after a failure is usually just this.
- **A bare device name in `-destination` resolves against the newest installed runtime.**
  `platform=iOS Simulator,name=iPhone 15 Pro` fails when the newest runtime is iOS 27 and that
  device only exists on 17.5. Build with `generic/platform=iOS Simulator`, or append `,OS=17.5`.
- **`simctl privacy` has no `notifications` service.** Only a UI-test tap can grant it. It *does*
  have `location`.
- **A notification grant survives both `simctl uninstall` and `simctl privacy reset`.** The only
  reliable reset is a **freshly created simulator**. `test-ios.sh` creates and destroys throwaway
  ones for exactly this.
- **iOS writes "Don't Allow" with U+2019**, not an ASCII apostrophe. Match on a prefix.
- **A cold, freshly created simulator needs warming** — `app.wait(for: .runningForeground)` is
  *not* sufficient. `test-ios.sh` does a throwaway install/launch/terminate first.
- **Never share a `derivedDataPath` between concurrent `xcodebuild` runs.** Result bundles collide
  and tests report `Executed 0 tests` while looking fine.
- **`xcrun simctl shutdown all`** when done.
- **`CGFloat.init` is overloaded enough to break Swift type inference.** Spell conversions out.
- **SwiftUI `Path.closeSubpath()` on an empty path leaves it non-empty.** Guard it.
- **A SwiftUI `Link` wrapping a `VStack` exposes one element** whose label is the combined text.
  Use `CONTAINS`, not exact match.
- **SwiftUI exposes the whole row as a `Toggle`'s accessibility frame**, but only the control end
  is tappable on iOS 17. Tap `coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))`.
- **A `LazyVStack` keeps off-screen cards out of the accessibility tree.** Scroll before looking,
  and check `isHittable` — XCTest reports a partially clipped control as existing.
- **Electoral map state shapes are useless as VoiceOver targets.** The map is one summary element;
  the state list is the real interaction surface. Don't "fix" this.
- **A fixed `.font(.system(size: 72))` ignores Dynamic Type.** Use `@ScaledMetric`, cap with
  `.dynamicTypeSize(...)`, add `minimumScaleFactor`.
- **`removePendingNotificationRequests` is processed asynchronously.** `ReminderScheduler` used to
  `cancelAll()` then add; the removal could land *after* the adds. **Adding a request with an
  existing identifier already replaces it atomically**, so never cancel-then-add.
- **A single green run does not prove the absence of a race.** That bug passed once and I took it
  as verified. It only surfaced after I removed the skips.
- **`.searchable` with default placement collapses behind the title.** Use
  `.navigationBarDrawer(displayMode: .always)` when it should always be visible.
- **`.onChange` cannot distinguish a programmatic revert from a user action.** Denying
  notification permission set a warning flag *and* flipped the toggle back; the revert re-fired
  `.onChange` and wiped the flag. Fixed with an explicit `Binding`. **This is the class of bug to
  watch for in SwiftUI.**
- **An all-`Optional` `Codable` model decodes successfully with wrong field names.** The `Article`
  model used `publishedAt`/`image`; the API sends `date`/`imageUrl`. No crash, no compiler error,
  blank timestamps. **There are decoding tests pinned to real captured payloads — add one whenever
  you touch a model.**
- **An empty `<TestPlans></TestPlans>` in a scheme silently disables the whole `Testables` list**,
  producing *"Scheme is not currently configured for the test action"*.

### Product / infrastructure

- **Nominatim's venue results come and go, and 90210 is not a safe example.** On 2026-09-20 the
  exact query the server sends returned `[]`; on 2026-09-21 the same query returned venues again.
  **Never assert live third-party data in a test, and re-check any ZIP before featuring it.**
- **Nominatim matches free text, so it returns things that are not buildings.** Bus stops, book
  boxes, compost drop-offs. Filter on `class`/`type` (`isPlausibleVenue`).
- **`gl`/`hl`/`ceid` bias the Google News *edition*, not the subject.** They were already present
  and did nothing to stop foreign coverage. The query terms are the only real lever.
- **Railway is dead** ("Application not found"), free tier gone. Don't revive it.
- **CARTO basemap tiles now stamp "API KEY REQUIRED"** across every tile.
- **OSM's tile policy discourages app traffic** — hence MapKit on iOS. Nominatim (server-side
  geocoding) is a different service, fine at low volume with a proper `User-Agent`.
- **Google Civic with a ZIP-only address always returns zero polling locations.** Official data
  needs a street address and only appears near an election.
- **Google's "VIP Test Election" (id 2000) returns fake locations.** Explicitly excluded in
  `civicService.js`. Don't remove that.
- **Fabricated sample locations were deliberately removed.** The old code invented "123 Main St".
- **NewsAPI's free plan is development-only** → 5.2.2. Removed. Subtlety: the biztoc/freerepublic
  exclusion was a NewsAPI *query parameter*, so deleting the call would have silently dropped the
  filter — it now lives in `dedupeAndSort` with its own test.
- **React 19 traps (web only, still live in `client/`):** effects and ref callbacks must use block
  bodies. `useEffect(() => window.scrollTo(0,0))` returns Chromium's scroll Promise and React
  treats it as cleanup; `ref={(el) => (x = el)}` returns the element. Both caused production
  blank-page crashes.
- **Playwright locally runs `retries: 0`**, so flakes read as hard failures. A
  `browserContext.close: ENOENT … .playwright-artifacts-*` trace error is a known flake.
- **The old Windows C: drive filling up** surfaced as bizarre `ENOSPC` test failures. Moot now, but
  a good reminder that infrastructure failures masquerade as code failures.

---

## 6. How to run everything

```bash
# Web
npm run dev                    # API :3001 + Vite :5173
npm test --prefix server       # 27 tests, ~29 s (the Nominatim pacing is real)
npm run test:e2e               # 90 passed / 9 skipped; browsers ARE installed now
BASE_URL=https://vote4ucyl.vercel.app npx playwright test

# iOS — USE THE SCRIPT, not plain `xcodebuild test`
./scripts/test-ios.sh                                    # 52 tests on the newest runtime
DEVICE_TYPE='iPhone 15 Pro' \
RUNTIME='com.apple.CoreSimulator.SimRuntime.iOS-17-5' \
  ./scripts/test-ios.sh                                  # deployment-era regression run
./scripts/capture-screenshots.sh                          # ONLY after the server is deployed
node scripts/export-ios-data.mjs                          # after changing client/src/data/*

# One-off build. Note the OS= — without it a 15 Pro cannot be resolved (§5).
xcodebuild -project ios/Vote4U.xcodeproj -scheme Vote4U \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.5' build

# Prove the widget is registered as a widget (the check a green build does not give you)
xcrun simctl spawn <device-udid> pluginkit -m -v -p com.apple.widgetkit-extension | grep Vote4U
```

**Why `test-ios.sh` is not replaceable by `xcodebuild test`:**
1. iOS asks for notification permission once and remembers; neither uninstall nor privacy reset
   clears it, so allow and deny each need a **throwaway simulator**.
2. The allow test must run **before** the unit tests, because `ReminderScheduler` needs
   authorization before `UNUserNotificationCenter` will queue anything.
3. It warms each new simulator, because a cold boot outruns the permission alert's timeout.
4. It finishes with a Release build and greps the binary, so the DEBUG stubs cannot ship.

**DEBUG-only launch arguments** (compiled out of Release, machine-checked):
`-startTab home|vote|map|news`, `-startZip 90210`,
`-stubPolling estimated|nearby|empty|error`, `-stubNews sample|error`.

**Manual dark-mode / Dynamic Type check:**
```bash
xcrun simctl ui 'iPhone 15 Pro' appearance dark
xcrun simctl ui 'iPhone 15 Pro' content_size accessibility-extra-extra-extra-large
xcrun simctl launch 'iPhone 15 Pro' com.shyamravidath.Vote4U -startTab home
xcrun simctl io 'iPhone 15 Pro' screenshot /tmp/shot.png     # then actually look at it
```

**Screenshotting the running app after every meaningful change has now caught four bugs that were
invisible to both the compiler and a green test run.** Do it.

**CI runs the same commands** (`.github/workflows/`, added 2026-09-21 — see §9B):

```bash
gh run list --limit 5                 # did it pass?
gh run view <id> --log-failed         # why not
gh workflow run ios.yml --ref <branch>   # iOS is path-filtered; force it by hand
```

`test-ios.sh` takes three environment variables: `DEVICE_TYPE`, `RUNTIME`, and now **`DERIVED`**
(the DerivedData path, previously hardcoded to `$TMPDIR/vote4u-test`). CI pins `DERIVED` because
`TMPDIR` on a hosted runner is per-process and does not survive into the next workflow step.

---

## 7. Rules that are not negotiable

Product commitments, not style preferences.

1. **Never show a voter a location the data doesn't support.** Unofficial results are labelled
   "Not confirmed"; the labelling gets **more** cautious as the tier gets weaker, never less;
   "no results" links to official state lookups rather than inventing something. Guideline 1.1.6,
   and simply correct. **`APIStub` is the one place fake venues exist, it is DEBUG-only, and
   `test-ios.sh` enforces that. They must never reach App Store marketing either.**
2. **ZIP entry must always work when location permission is declined.** Guideline 5.1.1(iv).
3. **Never imply government affiliation or endorsement.** Guidelines 5.2.1 / 5.2.4.
4. **News stays the last tab.** Guideline 4.2.2.
5. **Never commit keys.** The Civic key leaked in git history once already.

**App Store research, already done** (guidelines as of 2026-06-08, searched in full): "election",
"voter", "nonpartisan", "polling place" appear **zero times**. No rule requires a government entity
to publish an election app, and elections are **not** in 5.1.1(ix)'s highly-regulated list, so the
individual account is fine — it just publishes under the owner's legal name. **4.2 is the real
risk**, and native plus the widget is the strongest answer. Detail in `ios/APP_STORE.md`.

---

## 8. Codex is also working on this

The owner brought in Codex (better iOS integration) and explicitly wanted it **unrestricted** —
same authority I have, free to change my decisions. My role is to **review afterwards and push
back where warranted**, not to constrain it up front. The owner wants Codex treated as a peer.
`CODEX_HANDOFF.md` is the on-ramp and carries my replies inline.

**Codex's commit `1da4c8d` — reviewed twice, kept in full.** It installed the iOS 17.5 runtime
(closing the largest untested gap), decomposed the three big views into ~20 focused subviews,
added the `Design/` layer with Liquid Glass behind `if #available(iOS 26, *)`, replaced cached
`ISO8601DateFormatter` statics with `Date.ISO8601FormatStyle` for Sendable-safety, and fixed a real
flaw in my `test-ios.sh` where `run()` swallowed xcodebuild's exit status.

Two minor things I noted and left: `ElectoralStateShapeView` hardcodes `Color.white.opacity(0.85)`
for state borders where the old code used adaptive `.background`; and `MapDirections` opens
`http://maps.apple.com` where `https` would be tidier.

**`ios/IOS_DEVELOPMENT_GUIDE.md` is a translated third-party summary** that Codex flagged itself.
It references skills that may not exist here and iOS 26 / Swift 6.2 guidance that does not apply to
an iOS 17 project. **Treat as inspiration, not instruction.**

---

## 9. The next step I would take

**First: check whether PRs #3 and #4 merged.** As of 2026-09-21 both are still OPEN, so the
widget lives only on `feat/election-countdown-widget`. When they merge, pull `main` and re-run
`./scripts/test-ios.sh` plus the iOS 17.5 variant to confirm nothing changed in the merge.

### A. Re-run the iOS 17.5 regression — **DONE 2026-09-21**

Run on `feat/election-countdown-widget` (not `main` — the widget is not there yet):
`DEVICE_TYPE='iPhone 15 Pro' RUNTIME='…iOS-17-5' ./scripts/test-ios.sh` → **52 tests, 0 failures,
0 skipped**, the same count as iOS 27.0. The 17.5 number used to be 38; the widget accounts for
11 of the 14 new tests (`ElectionCountdownTests` 8 + `ElectionCountdownRenderTests` 3) and the
other 3 predate it — don't read the delta as widget-only.
`ElectionCountdownRenderTests` ran unskipped and rendered all five families
(`systemSmall`, `systemMedium`, `accessoryRectangular`, `accessoryCircular`, `accessoryInline`)
on 17.5, so the `.containerBackground` / accessory / `ImageRenderer` worry is closed. Both
notification-permission directions passed and the Release-build stub grep was clean.

Also verified on 17.5 what a green build does not prove — the extension **registers as a widget**
on the deployment target, not just on 27.0:
`xcrun simctl spawn <udid> pluginkit -m -v -p com.apple.widgetkit-extension` lists
`com.shyamravidath.Vote4U.Widgets(1.0)` from the app's `PlugIns/`. The throwaway simulator was
deleted afterwards.

What this still does **not** prove: a widget actually sitting on a real Home Screen (§10).

### B. CI on GitHub Actions — **DONE 2026-09-21, but unproven until it runs**

Two workflows, deliberately split because macOS minutes are the expensive ones even when free
for a public repo (this repo is public, so both tiers are free):

- **`.github/workflows/ci.yml`** — every push to `main` and every PR. Three ubuntu jobs:
  `server` (`npm test --prefix server`, hermetic, no keys), `client` (oxlint + `vite build`),
  and `e2e` (Playwright, chromium + webkit only — firefox is not in any device profile).
- **`.github/workflows/ios.yml`** — `runs-on: macos-26`, **path-filtered** to `ios/**`,
  `scripts/test-ios.sh`, `scripts/export-ios-data.mjs` and the workflow itself. Runs
  `test-ios.sh`, then repeats the `pluginkit` widget-registration check as its own step.

Opened as **PR #5**. Three things about it that are not obvious, plus one trap:

1. **It must be `macos-26`, not `macos-15`.** `Vote4UActionStyle` calls `.glassProminent` behind
   `if #available(iOS 26, *)`, and availability is a runtime check — the symbol still has to
   exist at compile time, so an Xcode without the iOS 26 SDK fails to build. The pbxproj is also
   `objectVersion = 77` with synchronized groups, which needs Xcode 16+.
2. **The runner's simulators are not this Mac's.** `test-ios.sh` defaults to `DEVICE_TYPE='iPhone 17'`,
   which need not exist there, so the workflow resolves the newest installed iOS runtime and an
   available iPhone in it, and *asserts* rather than falling back to a wrong destination — the
   §5 `-destination` lesson, applied.
3. **`DERIVED` is now overridable in `test-ios.sh`** (it was hardcoded to `$TMPDIR/vote4u-test`).
   `TMPDIR` on a hosted runner is per-process and need not survive into the next workflow step,
   so CI pins it to `$GITHUB_WORKSPACE/DerivedData`, which the widget-check step and the
   failure-artifact upload can both reach. The override was verified locally with a full run.
4. **Merge order does *not* matter** — but only because the first run forced the fix. The
   widget-registration step originally grepped for `Vote4UWidgets.appex` unconditionally and
   went red on a branch cut from `main`. It now gates on the pbxproj, so it is correct on any
   branch, with or without the widget.

**`main`'s `HANDOFF.md` is the pre-rewrite version.** The cold-restart rewrite (`cf7a95f`) is on
the widget branch only, which is why the CI PR carries no handoff changes — they are in PR #4
instead. Anything documenting CI must be written here, not on a branch cut from `main`, or it
conflicts.

**Both workflows have now run and both are green** (PR #5, 2026-09-21). What the first real runs
taught, none of which was predictable from here:

- The runner resolved **Xcode 26.6 / iOS 26.5 / iPhone 17** by itself, so the dynamic simulator
  lookup does its job. `macos-26` exists and works.
- **Web CI takes 2m24s including the full Playwright suite** — and the two specs that hit live
  Google News and Nominatim passed from a GitHub IP on the first attempt. The `--retries=2` hedge
  has not been needed yet.
- The iOS job takes **~24 minutes**, nearly all of it simulator creation and boot. That is the
  argument for keeping it path-filtered.
- **The first iOS run failed, correctly**, on the widget-registration step: that branch is cut
  from `main`, which has no widget target, so there was no `.appex` to find. The 30-vs-41
  unit-test count says the same thing. The fix was to gate the step on the **pbxproj** rather than
  on the build output — no widget target means nothing to check, but a target present with no
  embedded `.appex` is now a hard failure, never a skip, because a build that drops the extension
  is exactly the regression the step exists for. It also polls now, since LaunchServices registers
  plug-ins asynchronously.

**Until PR #5 merges, no other PR gets CI.** A `pull_request` run uses the workflow files on the
PR's own branch, and every other open branch was cut from `main` before CI existed — PR #6 opened
with no checks at all for this reason. Merge #5 and the rest pick it up on their next push.

**Check runs with:** `gh run list --limit 5`, then `gh run view <id> --log-failed`.

The e2e job runs with `--retries=2` on purpose: two specs deliberately hit live upstreams
(Google News RSS and Nominatim) through the local API, and a CI runner's IP gets rate-limited in
ways a laptop does not. A genuine regression still fails all three attempts. If that proves noisy
anyway, the honest fix is a recorded-fixture mode for those two specs, **not** deleting them —
they are the only check that the real upstreams still answer in the shape the UI expects.

### C. Snapshot tests for the electoral map — **DONE 2026-09-21, PR #6**

`ios/Vote4UTests/ElectoralMapRenderTests.swift`, five tests on `test/electoral-map-render`
(cut from `main`; it needs nothing from the widget). `ImageRenderer` plus a bitmap check, no
simulator UI automation — `ElectionCountdownRenderTests.swift` was the template.

Visible, on-canvas, not-squashed, geographically-arranged, and **painted the right party colour**,
that last one sampled from the rendered bitmap at a point inside each state's path.

**Verified by mutation rather than by going green** — this is the part worth copying:

| mutation | result |
|---|---|
| transpose x/y in `SVGPath` | 4 of 5 new tests fail (2 existing `SVGPathTests` also catch it) |
| `.fill(state.party.color)` -> `.fill(.gray)` | **only** the new colour test fails; all 30 pre-existing tests pass a map that paints every state wrong |

The second row is the coverage this actually adds. The first row also shows that *"did it render"*
passes a **fully transposed map**, so a bare render check is close to worthless on its own.

Two facts about the data that only showed up by looking at it first:

- **us-atlas places the Alaska inset partly off-canvas** — bounding box starts at x ~ -58 of a
  975-wide viewBox. Strict containment fails on *correct* data; the web app clips it identically.
  The test asserts overlap plus a 10% margin.
- **A bounding-box centroid is not reliably inside a concave state**, so the colour test scans for
  a point the `Path` actually contains.

No pbxproj edit was needed: `Vote4UTests` is a `PBXFileSystemSynchronizedRootGroup`, so new test
files are picked up automatically. Worth remembering — it makes adding tests cheap.

### D. SwiftLint or swift-format

None exists; 54 Swift files is still small enough that adding one now won't be noisy.

### E. Server odds and ends

- A coordinate-aware cache key so device lookups aren't cache-bypassed.
- Structured logging.
- Wire up `/api/elections` once the Civic key lands, so official-vs-estimated becomes visible.
- **Near-duplicate news headlines.** `dedupeAndSort` matches exact titles only, so two outlets
  covering the same event both appear ("Early voting in Virginia begins ahead of 2026 midterms" /
  "…for 2026 midterms"). Left alone deliberately — normalising harder risks collapsing genuinely
  different stories — but it is visible on the tab that carries the most 4.2.2 risk.

### F. Widget follow-ups (both currently blocked or costly)

- **A saved-polling-place widget** genuinely needs an App Group, so it is blocked on the Team ID.
- **Deep-linking a widget tap to a specific tab** needs `CFBundleURLTypes`, which has no
  `INFOPLIST_KEY_*` equivalent, so it would mean introducing a hand-written Info.plist for the
  **app** target too. Tapping currently opens the app, which is standard.

**Things to verify rather than trust** (I wrote them in one session):
`geocodeService.coordsToZip` edge cases (ZIP+4 narrowing, outside-US); the Coarse-Location-only
privacy label argument in `APP_STORE.md`; whether iPhone-only is right.
*(`ElectionCalendar`'s fidelity to `client/src/lib/format.js` is **verified** — the Swift port
matches the JS line for line, and `nextFederalElectionYear` in `newsService.js` now mirrors it too.)*

---

## 10. Blocked on the owner

- **Apple Developer account is in verification.** No Team ID → no device build, no TestFlight, no
  submission. The owner has confirmed twice that they are still waiting and asked to keep
  progressing until something genuinely needs it. When it clears: Xcode ▸ Settings ▸ Accounts →
  add the account, set the team, or set `DEVELOPMENT_TEAM` and build with
  `-allowProvisioningUpdates`.
- **Rotate the leaked Google Civic key** into Vercel as `GOOGLE_CIVIC_API_KEY`. It was public in
  the removed legacy `index.html` and remains in git history. The old NewsAPI key no longer matters
  here (integration removed) but should be rotated if reused elsewhere.
- **Install the App Store skills** (auto-install was blocked by the permission classifier):
  ```
  ! npx skills add eronred/aso-skills --skill aso-audit -g -a claude-code -y
  ! npx skills add eronred/aso-skills --skill apple-search-ads -g -a claude-code -y
  ! npx skills add truongduy2611/app-store-preflight-skills -g -a claude-code -y
  ! npx skills add https://github.com/code-with-beto/skills --skill app-icon -g -a claude-code -y
  ```

### Still genuinely device-only

A notification **banner actually arriving** at its scheduled time (permission and queuing are
tested; delivery weeks later is unobservable), **real GPS**, **airplane mode**, on-device
permission revocation, and **a widget actually sitting on a Home Screen** (registration and
rendering are both proven in the Simulator; placement is not). That's it — everything else is
testable without hardware.

---

## 11. Working notes on the owner

- Direct, moves fast, says "continue" and "don't wait for me" — **bias toward doing the work and
  reporting, not asking.** But ask before anything irreversible; they say yes quickly when asked.
- **Prefers branch → commit → push → PR.** Offered the choice on 2026-09-21, they picked it over
  committing straight to `main`. Nothing deploys until they merge, which they like.
- Asks sharp clarifying questions that have twice caught my errors. Don't get defensive; check.
- Speech-to-text occasionally inverts meaning ("we're *not* going to develop on this Mac" meant the
  opposite) and drops punctuation. If a message contradicts itself, ask rather than guess.
- Answers terse ("yes", "logged in with gh and set it up, we should be good to go") and expects you
  to carry on without re-confirming.
- Wants Codex treated as a peer, not a subordinate.
- Prefers the full picture including what *didn't* work and what remains unverified. When I
  reported my own bug alongside Codex's good work, the response was to keep going — **accuracy is
  welcome, not punished.**
- Asks for a written handoff before ending a session, and asked for this one to be filled "till you
  can't anymore". Write it as if the next session starts with no memory at all, because it does.
