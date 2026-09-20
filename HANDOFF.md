# Vote4U — Handoff

Last updated: 2026-09-19. Owner: Shyam Ravidath (ShyamRavidath/voting-finder).

## 1. The goal

Ship **Vote4U** as an iOS App Store app, built with **Expo / React Native**, while keeping the
existing website running. Everything must stay free except the Apple Developer Program fee
(account already active under `ravidath@gmail.com`).

Decisions already made (2026-09-19):

| Decision | Choice |
|---|---|
| Mobile approach | Expo / React Native rewrite of the UI. The Express API is reused as-is. |
| v1 native features | Local election reminders; "use my location" instead of typing a ZIP. |
| Submission timing | Submit as soon as the app is solid; iterate after review feedback. |
| Apple account | Existing paid account, `ravidath@gmail.com` (not the Claude-associated address). |
| Web app | Stays live and maintained. Two UIs, one backend. |

## 2. Current state of the code

**The website is live, healthy, and fully fixed** at https://vote4ucyl.vercel.app
(repo `main`, merged in PR #1, commit `e2f9734`).

Verified in production on 2026-09-19:
- `/` 200, `/api/health` 200, `/api/polling?zip=90210` → `estimated`, 3 locations,
  `/api/polling?zip=10001` → `estimated`, 5 locations, `/api/news` → 15 articles.
- News is served by the **Google News RSS fallback** and `/api/elections` returns
  **503 "Election data is not configured"**. That means `NEWS_API_KEY` and
  `GOOGLE_CIVIC_API_KEY` are **not set in Vercel** yet (the app is designed to work without
  them, so nothing is broken — it just isn't using the better sources).

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

Test status, all green: **13/13** server tests (`npm test --prefix server`), **87/87**
Playwright tests locally (`npm run test:e2e`), and **88/88 against the live production site**
(`BASE_URL=https://vote4ucyl.vercel.app npx playwright test`, run 2026-09-19). Security headers
verified live (`nosniff`, `strict-origin-when-cross-origin`, `DENY`, geolocation=self).

## 3. What carries over to the Expo app

Reusable almost verbatim (pure JS, no DOM):
- `client/src/lib/format.js` — `nextFederalElection()` (drives both the countdown and the
  notification schedule), `timeAgo`, `formatMiles`, `directionsUrl`.
- `client/src/data/stateData.js` — 50 states + DC, 538 electoral votes, verified correct.
- `client/src/data/officialLinks.js` — USA.gov / NASS / Vote.gov links.
- `client/src/lib/api.js` — fetch client; only the base URL changes
  (`EXPO_PUBLIC_API_BASE=https://vote4ucyl.vercel.app`).
- The whole `server/` API — unchanged, already CORS-allows `capacitor://localhost` etc.

Verified portable: the electoral map's state shapes convert to plain SVG path strings
(108 KB for all 51), which `react-native-svg` renders directly — no tiles, no API key,
works offline.

Must be rebuilt in React Native: every screen and component in `client/src/pages` and
`client/src/components` (they are DOM/Tailwind).

## 4. Server work the mobile app needs

`GET /api/polling` currently accepts **only** `?zip=`. "Use my location" needs coordinates.
Confirmed working and keyless: OpenStreetMap Nominatim reverse geocoding
(`/reverse?lat=&lon=&format=json&addressdetails=1`) returned `90210 / Beverly Hills / California`
for `34.0736,-118.4004`. So the change is to accept `?lat=&lng=`, reverse-geocode to a ZIP,
then run the existing pipeline.

## 5. What was tried and failed (don't repeat these)

- **Railway backend** — the old deployment is dead ("Application not found") and the free tier
  is gone. Do not try to revive it; the API now lives in `api/index.js` on Vercel.
- **CARTO basemap tiles** — now stamp "API KEY REQUIRED" across every tile. Replaced with an
  SVG choropleth (electoral map) and OpenStreetMap tiles (results map). Note that OSM's tile
  policy discourages heavy app use, which is why the **mobile app should use `react-native-maps`
  (Apple Maps on iOS, free, no key)** rather than OSM tiles.
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
  the element. Same rule applies in the React Native app.
- **Installing the five App Store skills automatically** — blocked by the permission classifier.
  They must be installed by the user with `! npx skills add ...` (commands in section 8).
- **Playwright run on 2026-09-19 reporting 17 failures against production** — a red herring:
  the machine's C: drive was 100% full (`ENOSPC`), so Playwright couldn't write traces. Disk
  now has ~19 GB free. Future project work should live on the **D: drive**.

## 6. Known gaps / risks to watch

- API keys are **not** in Vercel, and the old keys were leaked in the removed legacy
  `index.html` (still in git history) — they need rotating before being reused anywhere.
- NewsAPI's free plan is development-only per its terms; the Google News RSS fallback is what
  production is actually using.
- Vercel's free Hobby plan is non-commercial use only.
- Apple guideline 4.2 (minimum functionality) is the main App Store risk for any app derived
  from a website; the reminders and location features exist largely to answer it.

## 7. The iOS plan (Expo / React Native)

### Repo shape

Add a third workspace next to `client/` and `server/`. The web app is untouched.

```
voting-finder/
├── app/       NEW — Expo (expo-router, React Native)
├── shared/    NEW — plain JS used by both web and app
│              (format.js, stateData.js, officialLinks.js, api client)
├── client/    existing web UI (imports from shared/)
└── server/    existing API (unchanged except the new lat/lng support)
```

Do the extraction into `shared/` **first**, with the web app's Playwright suite as the safety
net — if 87 web tests still pass, the refactor didn't break anything.

### Screens (four tabs, mirroring the web IA)

1. **Home** — next-Election-Day countdown (from `nextFederalElection()`), two large actions.
2. **Vote** — polling place finder: "Use my location" button + ZIP field, result cards with
   Directions (opens Apple Maps), and a `react-native-maps` map (Apple Maps on iOS: free, no
   key, no OSM tile-policy problem). Saved polling place persists on device.
3. **Map** — electoral map as `react-native-svg` paths (verified: 108 KB of path data),
   tap a state for its electoral votes, 538 tally with the 270 line.
4. **News** — headline list, opens articles in an in-app browser (`expo-web-browser`).

### Native features for v1

- **Election reminders** (`expo-notifications`, local only — no push server, no cost):
  opt-in toggle; schedules "Election Day is in 7 days" and a morning-of "polls open" reminder
  that names the saved polling place. Dates come from the same `nextFederalElection()` rule,
  so they never go stale.
- **Use my location** (`expo-location`): foreground permission → coordinates → new server
  endpoint → ZIP → existing polling pipeline. ZIP entry stays as the fallback and for people
  who decline the permission.
- Supporting polish: `expo-haptics` on key actions, offline-readable saved polling place,
  native share of a polling place.

### Phases

| Phase | Work | Done when |
|---|---|---|
| 0. Setup | Move the repo to **D:**; `shared/` extraction; add `?lat=&lng=` to `/api/polling` with tests; rotate + install API keys in Vercel | Web tests still green; `/api/polling?lat=&lng=` returns results |
| 1. Scaffold | `create-expo-app` in `app/`, expo-router tabs, shared API client, app icon + splash from `assets/app-icon-1024.png` | App runs on a real iPhone via Expo Go |
| 2. Screens | Build the four tabs against the live API | Every web feature has a native equivalent |
| 3. Native | Notifications, location, offline save, haptics | Reminder fires on a real device; location finds a polling place |
| 4. Hardening | Empty/offline/error states, VoiceOver labels, Dynamic Type, dark mode decision, device testing | Works on a real iPhone with airplane mode and with permissions denied |
| 5. Store prep | Screenshots, description, keywords, privacy nutrition labels, review notes | App Store Connect record complete |
| 6. Ship | Build, TestFlight, submit | Approved |

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

Do these in order. Steps 1–3 are the user's; step 4 is where the code work resumes.

1. **Rotate the leaked keys and install them in Vercel.** The old Google Civic and NewsAPI keys
   were public in the removed legacy `index.html` and remain in git history. Regenerate both
   (restrict the Google key to the Civic Information API), then add `GOOGLE_CIVIC_API_KEY` and
   `NEWS_API_KEY` in Vercel → Settings → Environment Variables and redeploy. This turns
   `/api/elections` back on and moves news off the RSS fallback.
2. **Move the working copy to the D: drive.** C: hit 100% mid-session and broke a test run.
   `git clone https://github.com/ShyamRavidath/voting-finder.git D:\dev\voting-finder`.
3. **Install the App Store skills** (the automatic install was blocked):
   ```
   ! npx skills add eronred/aso-skills --skill aso-audit -g -a claude-code -y
   ! npx skills add eronred/aso-skills --skill apple-search-ads -g -a claude-code -y
   ! npx skills add truongduy2611/app-store-preflight-skills -g -a claude-code -y
   ! npx skills add https://github.com/code-with-beto/skills --skill app-icon -g -a claude-code -y
   ! npx skills add https://github.com/expo/skills --skill building-native-ui -g -a claude-code -y
   ```
4. **Phase 0 code work** — the first task of the next session:
   - Create `shared/` and move `format.js`, `stateData.js`, `officialLinks.js` into it; repoint
     `client/` imports; run `npm run test:e2e` (87 tests must still pass).
   - Add `?lat=&lng=` support to `GET /api/polling` using Nominatim reverse geocoding
     (confirmed working keyless), with tests in `server/test/api.test.js` alongside the existing
     stubbed-upstream tests.
   - Then `create-expo-app` in `app/` and get an empty tab shell running on the iPhone.

## 9. Environment and gotchas for whoever picks this up

- Windows machine, Git Bash available, Node 22. **No Mac** — iOS builds must go through Expo's
  cloud build service; nothing about this plan assumes local Xcode.
- Keep work on **D:**; C: has repeatedly run out of space and that surfaces as bizarre test
  failures (`ENOSPC`), not obvious disk errors.
- `CLAUDE.md` (gitignored, local only) carries the architecture notes and the React 19 traps.
- Never commit keys. `server/.env` is local only; Vercel holds production values.
- The rule that matters most in this codebase: **never show a voter a location the data doesn't
  support.** Unofficial results are labeled "not confirmed", and "no results" links to official
  state lookups instead of inventing something.
