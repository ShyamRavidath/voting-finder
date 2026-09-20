# App Store Connect — submission material

Draft copy for the Vote4U App Store listing. Paste into App Store Connect; nothing here is
wired into the build. Written 2026-09-20.

Account: `ravidath@gmail.com` (individual). An individual account publishes under your personal
legal name — that name appears on the store page as the seller.

## Identity

| Field | Value |
|---|---|
| Name (30 char max) | `Vote4U: Polling Place Finder` (28) |
| Subtitle (30 char max) | `Find where and when to vote` (27) |
| Bundle ID | `com.shyamravidath.Vote4U` |
| Primary category | Reference |
| Secondary category | News |
| Age rating | 4+ (no objectionable content; news links are third-party) |
| Price | Free |
| Privacy policy URL | `https://vote4ucyl.vercel.app/privacy` |
| Support URL | `https://github.com/ShyamRavidath/voting-finder/issues` |

**On the category choice:** Reference, not News. The 4.2.2 risk is being read as a news
aggregator, and the primary category is part of how Apple reads the app. The voting tools are the
product; headlines are the fourth tab.

## Keywords (100 characters max, comma-separated, no spaces)

```
voting,polling place,election,ballot,voter,vote,midterm,electoral,register,precinct,elections
```

That is 92 characters. Notes: do not repeat words already in the app name or subtitle — Apple
indexes those separately, so "Vote4U", "polling place" and "find" are wasted keyword space, and
the duplication above of "polling place" should be dropped if you keep the current subtitle.
Never use a competitor's or organisation's name.

## Description

```
Vote4U helps you find where to vote, see what is coming, and keep track of Election Day.

FIND YOUR POLLING PLACE
Tap once to use your location, or type a ZIP code. Vote4U shows nearby voting
locations on a map with driving directions, and tells you plainly when a
location is unconfirmed rather than guessing.

NEVER MISS ELECTION DAY
A countdown to the next federal election, plus optional reminders one week
before and on Election Day morning. Reminders are scheduled on your iPhone —
there is no account and nothing to sign up for.

SAVE YOUR POLLING PLACE
Keep your polling place on your device so it is there when you need it, even
without a signal.

ELECTORAL MAP
An interactive map of all 50 states and DC with electoral vote counts and the
270 line.

ELECTION NEWS
Headlines from across the political spectrum, opening on the publisher's own
page.

BUILT TO BE TRUSTED
Vote4U is independent and nonpartisan. It is not affiliated with any government
agency, election office, campaign or party. There are no accounts, no ads and
no tracking. When we cannot confirm a polling location, we say so and link you
to your state's official lookup instead of showing you something we made up.

Always confirm your polling place with your state or county election office
before you go.
```

**The last two paragraphs are load-bearing.** 5.2.1/5.2.4 (do not imply government affiliation)
and 1.1.6 (no false information) are the guidelines they answer, and they say out loud what the
code actually does.

## Promotional text (170 char max, editable without a new build)

```
Find your polling place in one tap, get reminded before Election Day, and follow the race with an interactive electoral map. Independent, nonpartisan, no ads.
```

## Notes for Review (guideline 2.3.1(a))

```
Vote4U is an independent, nonpartisan voter-information app. It is not
affiliated with, endorsed by, or operated by any government agency, election
office, political party, campaign or candidate.

WHERE THE DATA COMES FROM
- Polling locations: Google's Civic Information API (Voting Information
  Project) when official data is available for the user's state, otherwise
  nearby public buildings from OpenStreetMap.
- Any location not confirmed by an official source is labelled "Not confirmed"
  in the UI, and the app always links to USA.gov, Vote.gov and the National
  Association of Secretaries of State for the authoritative lookup. The app
  never fabricates an address or a coordinate.
- News: headlines and links only, from Google News. Article text is not
  reproduced; tapping a headline opens the publisher's own page in an in-app
  Safari view.

LOCATION
Location is optional and used only to resolve the user's ZIP code so we can
look up nearby polling places. Coordinates are rounded to roughly 110 metres
before leaving the device and are not stored on our server. If the user
declines the permission, ZIP code entry remains fully available — you can test
the whole app without granting location.

NOTIFICATIONS
Optional. Scheduled locally with UNUserNotificationCenter; there is no push
server. Two reminders: one week before the next federal election and on
Election Day morning.

NO ACCOUNT NEEDED
There is no sign-in, so no demo account is required. Every feature is
reachable immediately on launch.

HOW TO TEST
1. Vote tab: enter ZIP 90210 (or allow location) and tap Search.
2. Tap Directions on a result to open Apple Maps.
3. Map tab: tap any state, or use the list below the map.
4. Home tab: toggle "Remind me about Election Day".
```

## Privacy nutrition labels (App Store Connect → App Privacy)

Answer **"Yes, we collect data from this app"**, then declare exactly one type:

| Data type | Linked to identity | Used for tracking | Purpose |
|---|---|---|---|
| **Coarse Location** | **No** | **No** | App Functionality |

Everything else is **not collected**: no contact info, no identifiers, no usage data, no
diagnostics, no purchases, no search history. Specifically:

- The saved polling place and the reminder setting never leave the device, so they are **not
  collected** — on-device-only data is explicitly excluded from the labels.
- ZIP codes typed into the app are sent to our server but are not associated with a user or
  device identifier. If App Review pushes on this, the honest answer is that it is Search History
  used for App Functionality, not linked to identity and not used for tracking; declaring it that
  way is the safer choice and costs nothing.
- Vercel's routine request logs (IP, user agent) are operational logs held by the host, not data
  the app collects.

**Do not** declare Precise Location. The app requests when-in-use authorisation but immediately
coarsens the coordinate, and "Coarse Location" is the accurate answer.

## Screenshots

Required: **6.9" iPhone** (1320 × 2868 or 1290 × 2796). Apple scales these down for smaller
devices, so one set is enough for an iPhone-only app. iPad is not required — the target is
`TARGETED_DEVICE_FAMILY = 1`.

**Captured 2026-09-20 and committed to `ios/screenshots/`** at 1320 × 2868. Regenerate with:

```
./scripts/capture-screenshots.sh
```

That script builds, boots the simulator, pins the status bar to 9:41 with full bars, and uses
the app's DEBUG-only `-startTab` / `-startZip` launch arguments, so no UI automation is needed.
Re-run it after any UI change.

The order, voting tools first and news last, mirrors the app's own priorities:

1. Vote tab with results for 90210, map and cards visible.
2. Home tab countdown with the reminder toggle.
3. Map tab with a state selected.
4. Vote tab empty state showing the official-source links.
5. News tab.

Use a real search, never a mock-up: screenshots must show the actual app (2.3.3). The committed
set uses live production data for exactly that reason.

**Screenshot 4 is the weakest** — it is mostly empty space. It earns its place by showing that
the app sends people to official sources, which is the trust story, but swap it for a second
Vote-tab shot if you would rather lead with density.

## Pre-submission checklist

- [ ] Apple Developer account added in Xcode ▸ Settings ▸ Accounts, team set on the target
- [ ] Bundle ID confirmed (it is fixed once the App Store Connect record exists)
- [ ] `MARKETING_VERSION` 1.0, `CURRENT_PROJECT_VERSION` bumped for each upload
- [ ] Reminder verified firing on a real device
- [ ] Airplane-mode and permission-denied paths checked on a real device
- [ ] **NewsAPI question resolved** (§6 of HANDOFF) — its free plan is development-only, which
      is a 5.2.2 problem. Production already runs on the Google News RSS fallback, so dropping
      the NewsAPI path entirely is the cleanest answer
- [ ] Privacy policy live at `/privacy` with the app section (done 2026-09-20)
- [x] Screenshots captured (`ios/screenshots/`, regenerate with `scripts/capture-screenshots.sh`)
- [ ] Archive ▸ Distribute ▸ App Store Connect ▸ TestFlight ▸ Submit
