# Vote4U — Handoff

Last updated: 2026-09-20. Owner: Shyam Ravidath (ShyamRavidath/voting-finder).

> **2026-09-20 pivot.** Development moved from a Windows PC to a Mac (Apple Silicon,
> macOS 27), and the iOS approach changed from **Expo / React Native** to **native
> Swift / SwiftUI in Xcode**. Expo was only ever chosen because there was no Mac; that
> constraint is gone. Sections 1, 3, 7, 8, 9 and 10 were rewritten for this. Sections 2,
> 4, 5 and 6 are unchanged and still accurate.

## 1. The goal

Ship **Vote4U** as an iOS App Store app, built **natively in Swift / SwiftUI**, while keeping
the existing website running. Everything stays free except the Apple Developer Program fee
(account already active under `ravidath@gmail.com`).

Decisions made:

| Decision | Choice | When |
|---|---|---|
| Dev machine | This Mac (Apple Silicon, macOS 27). Repo at `~/voting-finder`. | 2026-09-20 |
| Mobile approach | **Native Swift / SwiftUI, built in Xcode.** The Express API is reused as-is. | 2026-09-20 |
| Build pipeline | **Xcode locally** → Archive → App Store Connect. No EAS, no cloud builds. | 2026-09-20 |
| v1 native features | Local election reminders; "use my location" instead of typing a ZIP. | 2026-09-19 |
| Submission timing | Submit as soon as the app is solid; iterate after review feedback. | 2026-09-19 |
| Apple account | Existing paid account, `ravidath@gmail.com` (not the Claude-associated address). | 2026-09-19 |
| Web app | Stays live and maintained. Two UIs, one backend. | 2026-09-19 |

## 2. Current state of the code

**The website is live, healthy, and fully fixed** at https://vote4ucyl.vercel.app

Re-verified in production on **2026-09-20** from the Mac:
- `/api/health` → 200 `{"status":"ok"}`
- `/api/polling?zip=90210` → 200, real locations (Beverly Hills Public Library, …)
- `/api/news` → 200, articles served by the **Google News RSS fallback**
- `/api/elections` → **503 "Election data is not configured."**

That 503 means `GOOGLE_CIVIC_API_KEY` is **still not set in Vercel**. The app is designed to work
without it, so nothing is broken — it just isn't using the better source. See §8.

News is served by Google News RSS by design: **NewsAPI was removed on 2026-09-20** (see §6).

Architecture (see `CLAUDE.md` for the detailed version):

```
voting-finder/
├── api/index.js     Vercel serverless entry → exports the Express app
├── server/          Express 5 API (runs standalone locally on :3001)
│   ├── app.js, routes/{news,polling,elections}.js, services/, lib/, test/
├── client/          React 19 + Vite + Tailwind v4 web app (the current UI)
├── tests/e2e/       Playwright, 3 device profiles, axe accessibility checks
├── scripts/         generate-icons.mjs (PWA + 1024px App Store icon)
├── assets/          app-icon-1024.png
└── vercel.json      build, /api rewrite, SPA fallback, security headers
```

Hosting: frontend and API deploy together on **Vercel free Hobby**. Railway is gone.
Response `Cache-Control: s-maxage` headers put Vercel's CDN in front of every upstream API.

Test status on the Mac (2026-09-20), everything green and matching the old machine's numbers:

| Suite | Result |
|---|---|
| `npm test --prefix server` | **19 pass, 0 fail** (13 before the lat/lng work) |
| `npm run test:e2e` | **87 passed, 9 skipped** |
| `BASE_URL=https://vote4ucyl.vercel.app npx playwright test` | **88 passed, 8 skipped** |

Note on flakes: `playwright.config.js` sets `retries: 0` locally, so a flake shows as a hard
failure. One parallel run produced two `browserContext.close: ENOENT … .playwright-artifacts-*`
trace-writer errors; the same specs passed serially and the next full run was clean at 87. If
you see that error, re-run before investigating — it is not an assertion failure.

## 3. What carries over to the SwiftUI app

The native rewrite changes what "reuse" means. Nothing in `client/` is reusable as *code* — but
the **data and the logic rules** port directly, and the API contract is unchanged.

| Source | Carries over as | Effort |
|---|---|---|
| `server/` (the whole API) | **Unchanged.** The app is just another HTTP client. | None |
| `client/src/data/stateData.js` | 50 states + DC, 538 electoral votes, verified correct → bundle as a JSON resource, decode into a Swift `struct State: Codable`. | Mechanical |
| `client/src/data/officialLinks.js` | USA.gov / NASS / Vote.gov links → a Swift `enum` of URLs. | Mechanical |
| `client/src/lib/format.js` | `nextFederalElection()` is the rule that drives both the countdown **and** the reminder schedule. Port to Swift with `Calendar`/`DateComponents`. `timeAgo` → `RelativeDateTimeFormatter`. `formatMiles`, `directionsUrl` → trivial. | Small, **port the tests too** |
| `client/src/lib/api.js` | Reimplement as `URLSession` + `Codable` + `async/await`. Keep the same timeout and friendly-error behaviour. | Small |
| Electoral map SVG paths | The `us-atlas` states are **pre-projected** (Albers) and convert to 108 KB of plain SVG path strings for all 51. Bundle that JSON and render with SwiftUI `Path` — needs a small SVG-path-command parser (~150 lines, `M/L/Q/C/Z`). No tiles, no API key, works offline. | Medium — the one real port |
| Every screen/component in `client/src/pages`, `client/src/components` | **Rebuilt from scratch in SwiftUI.** DOM + Tailwind, nothing portable. | The bulk of the work |

**The `shared/` extraction from the old Expo plan is cancelled.** It only existed so JS could be
shared between `client/` and an RN app. With Swift on the other side there is nothing to share,
so do not refactor the web app — leave `client/` alone. This removes the riskiest step of Phase 0.

## 4. Server work the mobile app needs — **DONE (2026-09-20)**

`GET /api/polling` now accepts `?lat=&lng=` alongside `?zip=`. It reverse-geocodes the
coordinates through Nominatim (keyless) to a ZIP, then runs the identical pipeline, so both
entry points share the same data tiers and the same "never invent a location" guarantee.

Behaviour the app can rely on:
- Coordinates are **rounded to 3 decimals (~110 m)** before being sent upstream or echoed back.
  The device's exact position never leaves this server.
- Distances are measured **from the device** when coordinates are given, from the ZIP centroid
  when a ZIP is. Verified live: `?lat=34.0736&lng=-118.4004` returns Beverly Hills Public
  Library at **0.1 km**.
- Response adds `zip`, `place.zip`, and the rounded `device: { lat, lng }`.
- **Device lookups bypass the ZIP Postgres cache** — its stored distances are centroid-relative
  and writing device-relative ones back would poison later ZIP requests.
- Errors: non-numeric or out-of-range → 400; outside the US → 404 "Vote4U only covers United
  States elections."; US but no ZIP resolvable → 404 telling the user to type one (so the app
  can fall back to the ZIP field); Nominatim down → 502, `Cache-Control: no-store`.

Six tests cover this in `server/test/api.test.js`; the suite is **19/19**.

CORS already allows Capacitor origins. A native iOS app sends **no `Origin` header**, so CORS is
a non-issue for it — but don't remove those entries, the web app still needs the Vercel ones.

## 5. What was tried and failed (don't repeat these)

- **Railway backend** — the old deployment is dead ("Application not found") and the free tier
  is gone. Do not try to revive it; the API now lives in `api/index.js` on Vercel.
- **CARTO basemap tiles** — now stamp "API KEY REQUIRED" across every tile. Replaced with an
  SVG choropleth (electoral map) and OpenStreetMap tiles (results map). OSM's tile policy
  discourages heavy app use, which is why the **iOS app uses MapKit** (first-party, free, no
  key) rather than OSM tiles.
- **Sample/fabricated polling locations** — the old code invented addresses like "123 Main St".
  Removed deliberately. Never reintroduce: it misleads voters and is an App Store risk.
- **Google Civic API with a ZIP-only address** — always returns zero polling locations
  ("Failed to parse address" without an election ID; empty results with one). Official data
  only appears close to an election and generally needs a street address.
- **Google's "VIP Test Election" (id 2000)** — returns fake test locations that would have been
  labeled "Official". Explicitly excluded.
- **React 19 crash traps** (both caused blank-page crashes in production): an effect or ref
  callback must use a block body. `useEffect(() => window.scrollTo(0,0))` returns Chromium's
  new scroll Promise and React treats it as a cleanup function; `ref={(el) => (x = el)}` returns
  the element. *Web-only concern now — irrelevant to SwiftUI, but still live in `client/`.*
- **Installing the five App Store skills automatically** — blocked by the permission classifier.
  They must be installed by the user with `! npx skills add ...` (commands in §8).
- **Playwright reporting 17 failures against production on 2026-09-19** — a red herring: the old
  Windows machine's C: drive was 100% full (`ENOSPC`). Not a code problem. *Moot on the Mac,
  which has 127 GB free.*

## 6. Known gaps / risks to watch

- API keys are **not** in Vercel, and the old keys were leaked in the removed legacy
  `index.html` (still in git history) — they need rotating before being reused anywhere.
- ~~NewsAPI's development-only free plan~~ **RESOLVED 2026-09-20 by removing NewsAPI entirely.**
  Its free plan was development-only under its own terms, which made shipping an app on it a
  guideline 5.2.2 violation, and production had always run on Google News RSS anyway. The code
  path, the `NEWS_API_KEY` variable and its docs are gone. Do not reintroduce it without a paid
  plan that permits production use.
- Vercel's free Hobby plan is non-commercial use only.
- Apple guideline 4.2 (minimum functionality). **Going native materially lowers this risk** —
  see §10 — but a news feed is still a 4.2.2 trigger, so News stays the last tab.

## 7. The iOS plan (Swift / SwiftUI)

### Repo shape

Add one workspace next to `client/` and `server/`. **The web app is untouched.**

```
voting-finder/
├── ios/       NEW — Vote4U.xcodeproj, Swift package-free, SwiftUI
│   └── Vote4U/
│       ├── Vote4UApp.swift          @main, TabView root
│       ├── Models/                  PollingLocation, Article, ElectionState (Codable)
│       ├── Services/                APIClient, LocationManager, NotificationScheduler
│       ├── Features/{Home,Vote,Map,News}/
│       ├── Resources/               states.json, statePaths.json, Assets.xcassets
│       └── Vote4U.entitlements
├── client/    existing web UI (unchanged)
└── server/    existing API (unchanged except the new lat/lng support)
```

Keep it in the same repo: one git history, and the API change and the app that needs it land
together. Add `ios/build/`, `*.xcuserdatad`, `DerivedData/` to `.gitignore`.

### Target and toolchain

- **Minimum deployment target: iOS 17.** Covers ~95%+ of active devices and unlocks
  `@Observable`, `.sensoryFeedback`, `ContentUnavailableView`, and the modern `MapKit` SwiftUI
  API — all of which this app uses. Do not target iOS 26-only APIs.
- **Swift 6 language mode**, strict concurrency. Start in Swift 5 mode if it fights you; the
  networking layer is `async/await` either way.
- **No third-party dependencies.** Everything needed is first-party (below). This is a real
  advantage over the Expo plan — no supply chain, no version drift, nothing to audit for 5.2.2.

| Need | Framework |
|---|---|
| UI | SwiftUI |
| Networking | `URLSession` + `Codable` |
| Map of polling results | **MapKit** (`Map`, `Marker`) — Apple Maps, free, no key |
| Directions | `MKMapItem.openInMaps` |
| Electoral map | SwiftUI `Path` from bundled SVG path data |
| Location | **CoreLocation** (`CLLocationManager`, when-in-use only) |
| Reminders | **UserNotifications** (`UNCalendarNotificationTrigger`, local only — no push server, no cost) |
| Article viewer | `SFSafariViewController` (wrapped in `UIViewControllerRepresentable`) |
| Saved polling place | `Codable` → JSON in Application Support (or `@AppStorage` for the simple case) |
| Haptics | `.sensoryFeedback` |

### Screens (four tabs, mirroring the web IA)

1. **Home** — next-Election-Day countdown (from the ported `nextFederalElection()`), two large
   actions.
2. **Vote** — polling place finder: "Use my location" button + ZIP field, result cards with a
   Directions button (opens Apple Maps), and a MapKit map. Saved polling place persists on
   device and is readable offline.
3. **Map** — electoral map as SwiftUI `Path`s, tap a state for its electoral votes, 538 tally
   with the 270 line.
4. **News** — headline list, opens articles in `SFSafariViewController`.

### Info.plist keys you will need (get these right the first time)

- `NSLocationWhenInUseUsageDescription` — "Vote4U uses your location only to find polling
  places near you. It is never stored or shared." A vague string is a common rejection.
- Notifications need **no** Info.plist key, but do need a runtime authorization request.
- `ITSAppUsesNonExemptEncryption = NO` — saves you an export-compliance question on every
  single TestFlight build. Set it now.

### Native features for v1

- **Election reminders** (`UserNotifications`, local only): opt-in toggle; schedules "Election
  Day is in 7 days" and a morning-of "polls open" reminder that names the saved polling place.
  Dates come from the same `nextFederalElection()` rule, so they never go stale.
- **Use my location** (`CoreLocation`): when-in-use permission → coordinates → the new server
  endpoint → ZIP → existing polling pipeline. **ZIP entry stays** as the fallback and for people
  who decline the permission (guideline 5.1.1(iv) requires this).
- Supporting polish: haptics on key actions, offline-readable saved polling place, native
  `ShareLink` for a polling place.

### Phases

| Phase | Work | Done when |
|---|---|---|
| 0. Setup | **DONE** — lat/lng endpoint, Xcode 27 + iOS 27 runtime installed, map/state JSON exported. Only the Vercel API keys remain (user action). **No `shared/` refactor — cancelled.** | ✅ |
| 1. Scaffold | **DONE 2026-09-20** — `ios/Vote4U.xcodeproj`, four tabs, `APIClient`, app icon, and the electoral map already rendering from bundled data | ✅ Builds Debug + Release, runs in the Simulator |
| 2. Screens | Build the four tabs against the live API | Every web feature has a native equivalent |
| 3. Native | Notifications, CoreLocation, offline save, haptics | Reminder fires on a real device; location finds a polling place |
| 4. Hardening | Empty/offline/error states (`ContentUnavailableView`), VoiceOver labels, Dynamic Type, dark mode, device testing | Works on a real iPhone in airplane mode and with permissions denied |
| 5. Store prep | Screenshots, description, keywords, privacy nutrition labels, review notes | App Store Connect record complete |
| 6. Ship | Archive, TestFlight, submit | Approved |

### Privacy labels (App Store Connect)

The app collects no accounts and no analytics. Location is used **only** to look up nearby
polling places and is not stored on the server → declare "Location: App Functionality, not
linked to identity, not used for tracking". The existing `/privacy` page is the privacy policy
URL; it needs one added paragraph about the device location permission and reminders.

### Apple review notes (write these into the submission)

State plainly: independent and nonpartisan; not affiliated with any government agency, election
office, campaign or party; polling data comes from Google's Voting Information Project and
OpenStreetMap and is labeled "not confirmed" when unofficial; the app always links to official
state lookups; news headlines link to their publishers and are not reproduced in full.

## 8. The next step (start here)

> **Phases 0 and 1 are complete as of 2026-09-20.** The app builds and runs. Steps 1–4 below are
> historical except where marked; **the live next task is Phase 2 (§7): build the Vote and News
> tabs.** Everything they need already exists — `APIClient` knows both polling entry points, and
> the API is live.

### Done already

- ✅ Xcode 27.0 installed and selected; iOS 27.0 Simulator runtime present.
- ✅ Playwright verified on the Mac (87 local / 88 production).
- ✅ `GET /api/polling?lat=&lng=` shipped with tests (§4).
- ✅ `ios/` scaffolded: four tabs, `APIClient`, `ElectionCalendar`, working electoral map.
- ✅ Phase 2: Vote and News tabs built and verified against production.
- ✅ Phase 3: "use my location", local election reminders, offline saved polling place, share,
  haptics. Verified in the Simulator with a simulated GPS fix (Beverly Hills → ZIP 90212,
  nearest venue 0.1 mi device-relative vs 1.2 mi from the ZIP centroid).

**The live next task is Phase 4 (hardening), and the first item is device testing** — see below.

### Still outstanding (user actions)

1. **Rotate the leaked API keys and install them in Vercel** — see step 1 below. Nothing in the
   iOS work is blocked by this, but `/api/elections` stays 503 until it is done.
2. **Add the Apple Developer account in Xcode ▸ Settings ▸ Accounts** (`ravidath@gmail.com`),
   then set the team on the Vote4U target so it can run on a real iPhone. The Simulator does not
   need this; a physical device does.
3. **Install the App Store skills** — step 4 below.

### What is left before submission — read first

Everything that can be done without hardware is done. Three things remain, and the first two
need your Apple account or your phone:

1. **Device testing.** Nothing has run on real hardware yet. Specifically unverified:
   - **A notification actually firing.** The scheduling logic and its date arithmetic are checked
     (rolls to Nov 7 2028 after the 2026 election, skips odd years), but the Simulator cannot be
     granted notification permission from the command line, so no reminder has ever been
     delivered. This is Phase 3's stated exit criterion.
   - Airplane mode, and denying/revoking the location permission on a real device.
   - Real GPS rather than a simulated fix.
   - Also note the Simulator only has an **iOS 27** runtime, while the deployment target is
     **iOS 17** — nothing has been run against an older OS.
2. **Apple account setup.** Add `ravidath@gmail.com` in Xcode ▸ Settings ▸ Accounts and set the
   team on the Vote4U target. Required before the app can run on a phone at all.
3. **Screenshots**, then paste `ios/APP_STORE.md` into App Store Connect.

There is **no test target** in the Xcode project. `ElectionCalendar` and `SVGPath` are the two
things most worth unit-testing if one is added — both are pure logic with no UI.

### General notes

- `PRODUCT_BUNDLE_IDENTIFIER` is `com.shyamravidath.Vote4U`. Change it now if you want something
  else — it is fixed once the App Store Connect record exists.
- `TARGETED_DEVICE_FAMILY = 1` (iPhone only). That is deliberate: it avoids having to produce and
  maintain iPad screenshots. Flip to `1,2` only if you decide to support iPad.
- `SWIFT_VERSION = 5.0`. The code is written to be Swift 6 clean; switching is a one-line build
  setting change once there is more concurrency in play.
- The project uses a **file-system-synchronized root group**, so adding a `.swift` file to
  `ios/Vote4U/` is enough — no `project.pbxproj` edit, and no merge conflicts in it.
- Re-run `node scripts/export-ios-data.mjs` whenever `client/src/data/*` changes.
- Known rough edge: DC is a few pixels wide on the map, so it is effectively untappable. Phase 4
  should add the state list as the accessible way to select one, as the web app does.

### Historical checklist

1. **Install Xcode.** *Not yet installed on this Mac* — only the Command Line Tools are
   (`xcode-select -p` → `/Library/Developer/CommandLineTools`). Install from the **Mac App
   Store** (free, ~17 GB, signed in with any Apple ID — it does not have to be the developer
   account). Then:
   ```
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -license accept
   xcodebuild -runFirstLaunch
   ```
   Verify with `xcodebuild -version`. See §9 for what Xcode actually is and how it's used.
2. ~~**Re-run the Playwright suites on the Mac**~~ **done 2026-09-20** — 87 local, 88 production,
   both matching the old machine. See §2.
3. **Rotate the leaked Google Civic key and install it in Vercel.** It was public in the removed
   legacy `index.html` and remains in git history. Regenerate it (restrict it to the Civic
   Information API), then add `GOOGLE_CIVIC_API_KEY` in Vercel → Settings → Environment
   Variables and redeploy. This turns `/api/elections` back on. The old NewsAPI key no longer
   needs rotating for this project — that integration is gone — but rotate it anyway if it was
   reused anywhere else.
4. **Install the App Store skills** (the automatic install was blocked):
   ```
   ! npx skills add eronred/aso-skills --skill aso-audit -g -a claude-code -y
   ! npx skills add eronred/aso-skills --skill apple-search-ads -g -a claude-code -y
   ! npx skills add truongduy2611/app-store-preflight-skills -g -a claude-code -y
   ! npx skills add https://github.com/code-with-beto/skills --skill app-icon -g -a claude-code -y
   ```
   *(The fifth, `expo/skills --skill building-native-ui`, is no longer relevant — it is Expo-specific.)*
5. **Phase 0 code work** — does not need Xcode:
   - ~~Add `?lat=&lng=` support to `GET /api/polling`~~ **done 2026-09-20, see §4.**
   - Export the electoral-map state paths to `ios/Vote4U/Resources/statePaths.json` and the
     state data to `states.json` (a script in `scripts/`). **← next**
   - Then, once Xcode is in, scaffold `ios/` and get the four-tab shell on the iPhone.

## 9. Environment and gotchas for whoever picks this up

- **Mac, Apple Silicon, macOS 27 (Darwin 27.0.0).** Repo at `~/voting-finder`. 127 GB free.
- **Node 26.0.0 / npm 11.12.1.** Note the old machine ran Node 22 and `HANDOFF` used to say so.
  The server suite passes 13/13 on Node 26; the Playwright suites are unverified on it (§8 step 2).
- **Xcode is not installed yet** — Command Line Tools only. This is the single blocker for any
  iOS work. Everything else (API changes, data export, tests) works today.
- Homebrew is at `/opt/homebrew`. `watchman`, `pod`, `eas` and `expo` are absent and **are not
  needed** — the native plan has no JS toolchain and no CocoaPods.
- `CLAUDE.md` (gitignored, local only) carries the web architecture notes and the React 19 traps.
- Claude's memory notes live in `~/.claude/projects/-Users-shyamravidath-voting-finder/memory/`.
  They were copied into the repo root during the transfer and were moved to the correct place on
  2026-09-20.
- Never commit keys. `server/.env` is local only (**not present on this Mac yet** — `cp
  .env.example server/.env`); Vercel holds production values.
- The rule that matters most in this codebase: **never show a voter a location the data doesn't
  support.** Unofficial results are labeled "not confirmed", and "no results" links to official
  state lookups instead of inventing something.

## 10. Build pipeline, cost, and App Store risk

### Shipping from the Mac: simpler and cheaper than the old plan

With a Mac in hand the entire cloud-build apparatus is unnecessary. The pipeline is
**Xcode → Product ▸ Archive → Organizer ▸ Distribute App → App Store Connect → TestFlight →
Submit.** Xcode manages the signing certificate and provisioning profile automatically once you
add the Apple ID in Settings ▸ Accounts.

| Item | Cost |
|---|---|
| Apple Developer Program | **$99/year — the only cost** |
| Xcode, Simulator, TestFlight, App Store Connect | $0 |
| EAS / Expo | **$0 — no longer used at all** |

What the Mac buys over the old Windows + EAS plan: the **iOS Simulator** (instant iteration, no
device needed), **Instruments** for profiling, on-device debugging with breakpoints, unlimited
local builds with no 15-per-month quota and no 90-minute queue, and `xcodebuild` in CI later if
wanted. The old §10 constraints — "EAS Free: 15 builds/month", "no Mac required", App Store
Connect API keys for non-interactive submit — **no longer apply.**

### App Store rules: the politics worry was unfounded; 4.2 is the real risk

*(Research from 2026-09-19 against guidelines last updated June 8, 2026 — still valid.)*

**"Election," "voter," "nonpartisan," and "polling place" appear zero times** in the guidelines.
There is no rule requiring an election or voter-information app to be submitted by a government
entity, political party, or organization. Guideline 5.1.1(ix)'s "highly regulated fields" list
(banking, healthcare, gambling, cannabis, air travel, crypto) **does not include elections**, so
the existing **individual** Apple account is fine. Note only that an individual account
publishes under your personal legal name.

The rules that actually apply:

- **4.2 / 4.2.2** — apps "shouldn't primarily be … content aggregators, or a collection of
  links," and must "elevate beyond a repackaged website." **Building natively is the strongest
  possible answer to this** — there is no web view anywhere in the app. The news feed is still a
  4.2.2 trigger, so **News stays the last tab, never the center of the app**, and the native
  capability has to be real: one-tap Core Location lookup, a MapKit map, an offline-readable
  saved polling place, and local election reminders.
- **5.2.2** — third-party services must permit your use, and "authorization must be provided
  upon request." Still the one to fix before shipping: **NewsAPI's free plan is
  development-only under its terms**, so the shipped app should not depend on it. The OSM tile
  usage policy was the other weak link; MapKit removes it entirely. (Nominatim reverse
  geocoding is still an OSM service — keep the volume low and set a proper `User-Agent`;
  it is called server-side, not from the app.)
- **5.1.1(iv)** — if location permission is declined the app must still work; ZIP entry covers
  this, and it must stay.
- **1.1.6** — no false information. This is the guideline behind "never fabricate locations."
- **5.1.1(i)** — privacy policy link in App Store Connect and in-app. The `/privacy` page exists.
- **5.2.1 / 5.2.4** — don't imply you are, or are endorsed by, a government or election
  authority. The existing "not affiliated with any government agency" line is the right move,
  even though no guideline strictly requires it.
- **2.3.1(a)** — describe everything in the Notes for Review (see §7).

Unverified: any non-public App Review precedent for civic apps.
