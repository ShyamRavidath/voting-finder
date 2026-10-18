# App Store Connect — submission material

Draft copy for the Vote4U App Store listing. Paste into App Store Connect; nothing here is
wired into the build. Updated 2026-10-18 for the keyless release without aggregated news. Not yet submitted.

Account: `ravidath@gmail.com` (individual). An individual account publishes under your personal
legal name — that name appears on the store page as the seller.

## Owner form-entry checklist

App record: [Vote4U in App Store Connect](https://appstoreconnect.apple.com/apps/6821803665/distribution).
Listing text, contact, copyright, free US-only availability, manual release, support URL and
the earlier screenshots were saved in App Store Connect. This no-news revision needs matching
text/categories and replacement three-tab screenshots before submission.

- Version 1.0: paste Description, Promotional text, Keywords and Notes for Review from
  the fenced blocks below. Enter the Support URL from the identity table.
- App Review Information: turn off **Sign-in required**. Supply your actual contact
  first/last name, email and reachable phone number; no demo credentials are needed.
- Copyright: enter the correct year and rights-holder name. Review content-rights and
  account declarations yourself; the app still uses third-party map and geographic data.
- Pricing: Free; United States only (owner selected).
- Version release: select **Manually release this version** to retain control after review.
- Screenshots: replace the old four-tab images with reviewed three-tab captures from this branch.
- Privacy and age ratings: use the drafts below for review, and confirm hosting retention
  before saving final privacy answers. Accessibility claims need actual device evidence.
- Build selection, TestFlight and **Add for Review / Submit** remain later release steps.

No terminal commands are needed for these fields.

## Identity

| Field | Value |
|---|---|
| Name (30 char max) | `Vote4U: Polling Place Finder` (28) |
| Subtitle (30 char max) | `Find where and when to vote` (27) |
| Bundle ID | `com.shyamravidath.Vote4U` |
| Primary category | Reference |
| Secondary category | None |
| Age rating | Determined by the current App Store Connect questionnaire; see draft answers below |
| Price | Free |
| Privacy policy URL | `https://vote4ucyl.vercel.app/privacy` |
| Support URL | `https://vote4ucyl.vercel.app/privacy#support` (verify the support email is live after deployment before saving) |

**On the category choice:** Reference describes the voting tools. This release has no news feed.
Its native utility includes local reminders, an Election Countdown widget, offline saved locations,
and a bundled interactive electoral map. These support the 4.2 utility case; approval is not guaranteed.

## Keywords (100 characters max, comma-separated, no spaces)

```
ballot,voter,midterm,electoral,register,precinct,elections,reminder,countdown,civic,democracy
```

93 characters. Avoids words already indexed in the name and subtitle.

## Description

```
Vote4U helps you find where to vote, see what is coming, and keep track of Election Day.

FIND YOUR POLLING PLACE
Type a ZIP code or optionally use your location to look up your area.
Official lookup links help you find your assigned polling place and hours.
Nearby buildings from OpenStreetMap are shown separately, with no claim
that they offer voting. Vote4U cannot confirm your assigned polling place.

NEVER MISS ELECTION DAY
A countdown to the next federal election, plus optional reminders one week
before and on Election Day morning. Reminders are scheduled on your iPhone —
there is no account and nothing to sign up for.

SAVE A LOCATION
Keep a location on your device for offline reference. Unconfirmed locations
keep their warning when saved or shared. Confirm with your election office
before making a voting plan.

ELECTORAL MAP
An interactive map of all 50 states and DC with electoral vote counts,
the 270-vote threshold and a link to the National Archives source.
Counts reflect the 2020 Census allocation for the 2024 and 2028 presidential
elections; the map does not forecast winners.

BUILT TO BE TRUSTED
Vote4U is independent and nonpartisan. It is not affiliated with any government
agency, election office, campaign or party. There are no accounts, no ads and
no tracking. When we cannot confirm a polling location, we say so and link you
to official lookup resources. Nearby-building results are not voting recommendations.

Always confirm your polling place with your state or county election office
before you go.
```

**The last two paragraphs are load-bearing.** 5.2.1/5.2.4 (do not imply government affiliation)
and 1.1.6 (no false information) are the guidelines they answer, and they say out loud what the
code actually does.

## Promotional text (170 char max, editable without a new build)

```
Plan for Election Day with official lookup links, optional reminders, offline saved locations and an electoral map. Independent, nonpartisan, no ads.
```

## Notes for Review (guideline 2.3.1(a))

```
Vote4U is an independent, nonpartisan voter-information app. It is not
affiliated with, endorsed by, or operated by any government agency, election
office, political party, campaign or candidate.

WHERE THE DATA COMES FROM
- This release uses no Google Civic key and does not provide verified polling
  assignments. ZIP/location search resolves the area and returns nearby
  buildings from OpenStreetMap. These are not voting recommendations.
- Official lookup links are the primary route to an assigned polling place.
- Any location not confirmed by an official source is labelled "Not confirmed"
  in the UI, and the app always links to USA.gov, Vote.gov and the National
  Association of Secretaries of State for the authoritative lookup. The app
  never fabricates an address or a coordinate.
- Map: neutral state electoral-vote totals from the National Archives, with
  a note explaining Maine and Nebraska district allocation; no predictions.
- This release does not fetch or display aggregated news.

NATIVE UTILITY
- Election Countdown Home Screen widget (small and medium sizes).
- Optional local election reminders, without an account or push server.
- Saved locations available offline, with unconfirmed warnings preserved.
- Bundled interactive electoral map and searchable state vote counts.

LOCATION
Location is optional and used to resolve the user's ZIP code and find nearby
locations, with distances measured from the rounded device position. Coordinates are rounded to roughly 110 metres
before leaving the device. They are sent to our server and OpenStreetMap for
ZIP resolution and nearby-building searches, are cached by Vercel and Neon, and
can appear in Vercel request logs. Hosting and database retention details
are being verified before submission. If the user declines the permission, ZIP code entry remains
fully available — you can test the whole app without granting location.

NOTIFICATIONS
Optional. Scheduled locally with UNUserNotificationCenter; there is no push
server. Two reminders: one week before the next federal election and on
Election Day morning.

NO ACCOUNT NEEDED
There is no sign-in, so no demo account is required. Every feature is
reachable immediately on launch.

HOW TO TEST
1. Vote tab: enter ZIP 90210 (or allow location) and tap Search.
2. Follow an official lookup link to confirm your assigned polling place.
   Nearby building cards are unconfirmed; Save preserves that warning offline.
   Directions opens Apple Maps but does not imply the building offers voting.
3. Map tab: tap any state, or use the list below the map.
4. Home tab: toggle "Remind me about Election Day".
```

**Release configuration gate:** Keep Google Civic disabled until the assignment, election-date
and cache findings in OPUS-6/11/12 are fixed. This copy describes the keyless candidate.

## Privacy nutrition labels (App Store Connect → App Privacy)

Proposed answer: **"Yes, we collect data from this app"**. The following are conservative
draft disclosures for owner review, not approved or saved App Store Connect answers.
Confirm actual host retention and linkage before finalizing them:

| Data type | Linked to identity | Used for tracking | Purpose |
|---|---|---|---|
| **Precise Location** (three-decimal coordinates from "Use my location") | **Yes** | **No** | App Functionality |
| **Coarse Location** (searched ZIP) | **Yes** | **No** | App Functionality |
| **Search History** (polling lookups in request URLs) | **Yes** | **No** | App Functionality |
| **Other Diagnostic Data** (host request logs) | **Yes** | **No** | App Functionality |

No contact information, account identifiers, purchases, or tracking data are collected. In
particular:

- The saved polling place and the reminder setting never leave the device, so they are **not
  collected** — on-device-only data is explicitly excluded from the labels.
- ZIP codes and rounded device coordinates are request search parameters. Vercel's Runtime Logs
  display those parameters alongside request metadata; our own application logging cannot remove
  them from the platform view. A coordinate-aware database cache, if enabled, serves a
  three-decimal coordinate key for one day and deletes expired rows daily. Physical retention is
  normally less than two days, but failed cleanup can extend it.
- The host may associate request parameters with IP or other request metadata. Until that
  retention is audited, answer "linked" conservatively rather than asserting anonymity.

Apple defines **Precise Location** as latitude and longitude with **three or more decimal
places**. Rounding to three decimals (roughly 110 m) is still Precise Location under that
definition. `kCLLocationAccuracyHundredMeters` limits the requested fix but does not change the
classification of the transmitted coordinates. See [Apple's App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)
and [Vercel's Runtime Logs](https://vercel.com/docs/logs/runtime). Recheck the final production
configuration before submission; do not paste the old Coarse-Location-only answer.

## Screenshots

The prepared **iPhone with Dynamic Island (medium display)** set uses
1206 × 2622 portrait pixels. Find the available medium captures in
`ios/screenshots/medium/` and large captures in `ios/screenshots/`
(1320 × 2868). The included captures are opaque JPEGs. iPad is not required because the containing
app is iPhone-only (`TARGETED_DEVICE_FAMILY = 1`). Confirm the media manager accepts
both sets before submission. Recheck Apple's current specifications and media-manager requirements:
[Apple screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/).

### iPad scope for version 1

Keep the containing app iPhone-only for the first submission. The current three-tab layout uses
single-column Home and Vote screens, a 220-point polling map, and a full-width electoral map;
turning on native iPad support would need deliberate wide/landscape layouts, map-and-results
placement, resizing and accessibility checks, plus iPad screenshots. Adding iPad device support
alone does not add the functionality Apple asks for in guideline 4.2. Apple says iPhone apps
should run on iPad where possible (2.4.1). On 2026-09-24 the iPhone-only build installed and
launched on an iOS 17.5 iPad Pro 11-inch simulator: the Map view rendered in Apple's centered,
scaled iPhone compatibility canvas with wide black margins, not a native iPad layout. This is a
functional spot-check, not a full iPad interaction or accessibility test. The **widget extension
has its own device-family requirement**:
Apple's [App Extension Programming Guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/ExtensionCreation.html)
says extensions must target both iPhone and iPad even when the containing app is iPhone-only.

Capture from the final candidate with live production data after the backend changes deploy:

```bash
./scripts/capture-screenshots.sh
DEVICE='iPhone 17' OUT="$PWD/ios/screenshots/medium" ./scripts/capture-screenshots.sh
```

The script sets 9:41/full bars/light appearance and uses DEBUG navigation arguments only.
It does not use fabricated polling fixtures. Review every image after capture; a fixed
wait does not prove a successful live request. Four voting-tool images are sufficient:
results with cautious labels, Home countdown, sourced electoral map and official lookup
links. Replace all previously uploaded images: they show the removed News tab.
The complete four-view set remains a release gate where simulator capture fails visual review.

## Age-rating questionnaire draft

Do not assume the historical 4+ answer is still correct. News and the in-app publisher browser
have been removed. Official lookup, privacy/support and attribution links still open external
websites. Review the current questionnaire against this final build; do not automatically
reuse the earlier news-based unrestricted-web-access or content-frequency answers.
The app has no app-owned messaging, user-generated posting, advertising, gambling, loot boxes,
contests, medical/treatment advice, or parental-control/age-assurance feature.

The local candidate has no content-rating filter and should not claim one. Record the saved
questionnaire and Apple's resulting rating in the release ledger before submission. Sources:
[Set an app age rating](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating/),
[Apple age-rating definitions](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions/).

## Pre-submission checklist

- [x] Apple Developer account/team configured; team `M6L74ZB5KS`
- [x] App record `6821803665` verified with bundle ID `com.shyamravidath.Vote4U`, SKU `vote4u-ios`
- [x] Candidate build settings are version 1.0 build 3
- [ ] Build 3 archived from clean integrated source, with provenance recorded
- [ ] Reminder verified firing on a real device
- [ ] Airplane-mode and permission-denied paths checked on a real device
- [x] Aggregated news removed from the native app, website and serving API for version 1.0
- [ ] Confirm remaining third-party map/data license and attribution obligations
- [x] Privacy route responds 200; source includes native-app disclosures
- [ ] Recapture/review both screenshot sizes without the News tab, using live keyless polling data
- [ ] Verify screenshot acceptance in App Store Connect and source/deployment parity after merge
- [ ] Clean committed archive, export and signature/profile verification
- [ ] TestFlight upload, processing and physical-device critical paths
- [ ] Final privacy/age-rating answers and review contact information
- [ ] Owner authorizes App Review submission
