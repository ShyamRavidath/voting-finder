# Vote4U — independent pre-submission review (Opus)

Review date: **2026-10-11** (UTC 15:53–16:50). Reviewer: Claude Opus 5.5, executing `OPUS_REVIEW_REQUEST.md`.
This document is a technical recommendation, not owner approval. Nothing was merged, deployed,
uploaded or submitted, and no credentials were read or rotated.

---

## 1. Executive decision: **NOT READY** (neither for submission nor for a "validated TestFlight" claim)

**Evidence scope.** The review covered the release candidate `e39eeeb` (`origin/release/ios-signing-validation`) and production (`vote4ucyl.vercel.app`, deployed from `4f104f3`). The two trees have identical server code. The candidate was checked by:
- static review across server, web and iOS
- server tests and the full Playwright suite
- an independent Playwright exploration at 320, 390, 768 and 1440 px
- the mandatory iOS runner on iPhone SE (3rd gen) / iOS 17.5 (§4.3): 69 passed, 0 skipped
- inspection of the historical archives, IPAs and store screenshots
- about 25 bounded read-only production requests

Not covered: physical-device runs, VoiceOver, TestFlight and App Store Connect.

**Top blockers.** Each is detailed in §3.

| # | Blocker | Kind | Fix needs a new build? |
|---|---|---|---|
| 1 | The location permission prompt says the location "is never stored or shared". This is false: coordinates go to Nominatim, Vercel URL logs, the CDN and a 1-day Postgres key (OPUS-3) | defect | **yes** |
| 2 | The app has no in-app privacy-policy link, which guideline 5.1.1(i) requires (OPUS-4) | defect | **yes** |
| 3 | Live results label buildings "Likely Polling Place" / "Likely Early Voting" with no voting evidence, e.g. a concert hall in ZIP 10001 (OPUS-2) | voter-safety product risk | server + saved data |
| 4 | Metadata and Review Notes promise official polling data, but production runs without a Civic key and returns only guesses (OPUS-5) | product risk | no (metadata or key) |
| 5 | Re-enabling the Civic key would show a ZIP-level Civic answer as "Official ✓" (OPUS-6). This interacts with blocker 4: the key cannot simply be turned on | latent voter-safety risk | server |
| 6 | No archive is tied to a commit. Build 2 was archived from an uncommitted tree; there is no upload, processing or TestFlight evidence (OPUS-7, OPUS-8) | evidence gap | yes (build 3) |
| 7 | `main` and production lack PR #14, which is the reviewed release-candidate UI (OPUS-1, PR #16) | release integrity | — |

**Smallest route to submission.** Fix blockers 1–3, choose a path for 4/5, merge #16 and the fix PRs, build 3 from a clean checkout of the merged SHA, upload it, and repeat the critical paths on the processed TestFlight build (§8).

---

## 2. Source / deployment / artifact matrix

Captured 2026-10-11 15:53Z after `git fetch origin`. Toolchain: Node 26.0.0, Xcode 27.0 (27A266a), and the iOS 17.5 (21F79) and iOS 27.0 (24A434) simulator runtimes.

| Thing | SHA / identity | Notes |
|---|---|---|
| `origin/main` | `4f104f3` (merge of #13) | **Lacks #14** (`3f9ab31`) |
| Release candidate | `e39eeeb` (`origin/release/ios-signing-validation`, merge of #14) | Differs from `main` in 52 files, +610/−212; **no server, api or vercel.json changes** |
| Vercel Production | `4f104f3` (GitHub deployment 2026-10-11 02:54:45Z) | Production web is **pre-#14**; the served bundle is `assets/index-DuPDdLZl.js`. The API is identical to the candidate |
| Vercel Preview | `e39eeeb` (02:55:04Z) | Not Production |
| GitHub Pages | `main` root, legacy build | Renders README and HANDOFF.md at `shyamravidath.github.io/voting-finder`. The repo is public anyway, so this is P3 confusion, not exposure |
| Native API base | `https://vote4ucyl.vercel.app` (string in the IPA) | Same backend as Production web |
| Build-2 archive | `/tmp/Vote4U-polished-final.xcarchive` | Created 18:48:45 PDT on 10-10, **13 min before `3f9ab31` was committed**. Built from the working tree; strings match the candidate. Provenance **partial** |
| Build-2 IPA | `/tmp/vote4u-polished-final-export/Vote4U.ipa` | Apple Distribution, no device list, `get-task-allow` false. Matches the archive |
| Other archives | `/tmp/Vote4U-polished.xcarchive` (also 1.0 (2)); `/tmp/Vote4U-release.xcarchive` and its IPA (1.0 (1), old UI) | Superseded. Two archives claim build 2, which is ambiguous |
| Database | Neon Postgres, live | `cached:true` on a CDN miss (10001, 59001), so `cache_key` has been migrated |

### Branches / PRs

| PR / branch | Purpose | Base | State and checks | Disposition |
|---|---|---|---|---|
| #13 `release/ios-signing-validation` | Signing, trust-preserving saves | main | Merged 02:54:21Z | Integrated |
| #14 `feat/visual-ux-polish` | UI polish, build 2 | **release branch** | Merged 02:54:36Z into the release branch, not main | **Integrate via #16** |
| **#16** (opened by this review) | Release branch → main, no new code | main | Merges cleanly; merged tree is byte-identical to `e39eeeb` | **Owner: merge**, ideally together with the fix PRs |
| #15 `docs/opus-release-review` | This review | main | Open | Merge after reading |
| #12 `docs/handoff-2026-10-10` | Handoff refresh | main | Open, 1 unique commit, not a draft | Superseded in part by HANDOFF §13/14 on the release branch; reconcile, then merge or close |
| #10 `feat/structured-logging` | Request logging | main @ `e282e30` (32 behind) | Draft; conflicts in `app.js`, `package.json` and `polling.js` | **Defer.** Not needed for privacy (§3, SRV verified-correct list). A careless resolution would reintroduce week-long stale-while-revalidate on device URLs. Rework later with allowlisted fields |
| #9 `chore/swift-format` | 4-space config + strict CI lint | main (old) | Draft | **Defer.** With its config the candidate has 215 lint findings (mostly `APIStub.swift` `#if DEBUG` indentation). Cosmetic, not a release gate |
| `fix/ios-test-runner-and-live-api-decoupling` | — | — | Ancestor of main | Already integrated; the stale local branch can be deleted by the owner |
| Ultrareview fixes | Popup width helper; reminder-denied styling | uncommitted in another session's worktree on `feat/visual-ux-polish` (already merged) | — | Must go to a **new** branch/PR on the release branch or main; see §6 |

---

## 3. Findings ledger

Severity: **P1** = blocks a core flow, materially misleads a voter, or invalidates the release. **P2** = significant but bounded. **P3** = minor.
Baseline is `e39eeeb` unless stated. Source IDs refer to the working notes: CIV = civic chain, SRV = server, IOS = native, REL = release package, WEB = lead's web QA.
Repro scripts are kept in the reviewer scratchpad, not in the repo.

### 3.1 P1

```text
OPUS-1 / main and Production do not contain the reviewed release candidate (PR #14)
Type: defect (release integrity) · Severity: P1 · Confidence: confirmed
Baseline: origin/main 4f104f3, Production 4f104f3, RC e39eeeb
User consequence: The web app in Production is the pre-polish UI. Any approval of "the RC" approves a tree that is not deployed or integrated.
Reproduction: git log origin/main..origin/release/ios-signing-validation → 3f9ab31, e39eeeb. GitHub deployments: Production sha 4f104f3.
Evidence: §2.
Fix: merge PR #16 (no new code; merged tree == e39eeeb).
Release-blocking: yes, as a gate. Build 3 must come from main after #16 and the fixes.
Status: PR #16 open, owner merges.
```

```text
OPUS-2 / Tier-1 venue labels assert a voting role with no evidence ("Likely Polling Place", "Likely Early Voting")
Type: product risk (voter safety) · Severity: P1 · Confidence: confirmed (live)
Baseline: Production 2026-10-11 15:57Z, and RC (same server)
User consequence: Any voter whose ZIP has no official data (all of them while keyless).
  Live 10001 returned "The Town Hall" (a Manhattan concert venue) as "Likely Early Voting".
  It returned the Schwarzman library and the NYPL Performing Arts library as "Likely Polling Place".
  90210 returns the Margaret Herrick film library.
  "Likely Early Voting" is a specific, usually false claim: early voting is often at county offices only.
Reproduction: GET /api/polling?zip=10001 → type "Likely Early Voting", isEstimated:true.
Expected vs actual: The type should describe what the building is. Instead it names a voting function chosen only by the Nominatim search keyword.
Evidence: server/services/geocodeService.js:88-90.
  Flows into: PollingLocationCard.jsx:26, PollingLocationCard.swift:12, SavedPlace.swift:31,
  iOS share text, and store screenshot 1-vote-results.jpg.
Mitigations already present: "Not confirmed" badge, amber banner, official links.
  They help, but the type label is the first and largest text on the card, and the badge contradicts it.
Fix: Neutral building-kind labels for tier 1 (e.g. "Public library", "Community center", "Town hall") and keep "Not confirmed".
  Reserve "Polling Place" / "Early Voting" / "Drop-off" for Civic data.
  Optionally map legacy saved strings on iOS display.
  Consider also rejecting amenity=theatre/arts_centre/cinema (the denylist already rejects 'tourism').
  Small server change; re-shoot screenshot 1.
Regression test: server test asserting no tier-1/2 type contains "Polling" or "Voting".
Release-blocking: yes. AGENTS rule 1 ("never show a location the data does not support"); guideline 1.1.6 risk.
Related: CIV-7 (agent rated P2; raised to P1 here on live evidence of a concert hall labelled early voting).
```

```text
OPUS-3 / Location permission purpose string is false
Type: defect · Severity: P1 · Confidence: confirmed
Baseline: RC ios/Vote4U.xcodeproj/project.pbxproj:406 and :432. Present in both IPAs.
Text: "Vote4U uses your location only to find polling places near you. It is never stored or shared."
Actual: Coordinates rounded to 3dp are:
  - sent to nominatim.openstreetmap.org for the reverse geocode and up to 7 bounding-box searches (polling.js:85,118-146)
  - logged in Vercel URL logs
  - used as a CDN cache key (s-maxage 86400)
  - stored as a Postgres cache key for 1 day (pollingCacheKey.js:21-24)
  The app's own /privacy page and APP_STORE.md ("Precise Location collected, linked") say so.
User consequence: An OS-level privacy claim that contradicts the published policy; guideline 5.1.1(ii)/5.1.2(i) rejection risk.
Fix (one line, both configs): e.g. "Vote4U uses your location to find voting locations near you. Rounded coordinates are sent to our server and OpenStreetMap to look up your area, and are briefly cached."
Release-blocking: yes (needs build 3).
Related: IOS-1, REL-2.
```

```text
OPUS-4 / No privacy-policy (or contact) link inside the iOS app
Type: defect · Severity: P1 · Confidence: confirmed
Evidence: No "privacy" string in ios/Vote4U/** apart from comments; 0 "privacy" strings in the IPA binary.
  officialLinks.json holds only USA.gov / NASS / Vote.gov.
Requirement: Guideline 5.1.1(i): "All apps must include a link to their privacy policy in the App Store Connect metadata field and within the app in an easily accessible manner."
  Guideline 1.5 asks for an easy way to contact you. The support URL (GitHub Issues) needs an account.
Fix: Add "Privacy policy" (https://vote4ucyl.vercel.app/privacy, returns 200) and a support/contact link in SFSafariViewController, next to NonpartisanNotice.
Release-blocking: yes (needs build 3).
Related: REL-1, REL-12.
```

```text
OPUS-5 / Listing promises official polling data; Production is keyless
Type: product risk · Severity: P1 · Confidence: confirmed (backend); reviewer reaction is a prediction
Evidence: /api/elections → 503 "Election data is not configured." (15:57Z, again 16:05Z).
  The route returns 503 only when GOOGLE_CIVIC_API_KEY is unset.
  Every polling result is estimated, nearby or none.
  APP_STORE.md Review Notes cite Google Civic and suggest testing 90210.
Fix: Either (a) reword the description and Review Notes to "suggests nearby public buildings (unconfirmed) and links to official lookups",
  or (b) restore a rotated key, but only after OPUS-6 and CIV-2 are fixed.
Release-blocking: recommended yes (guideline 2.3.1(a)/1.1.6 risk). Option (a) needs no build.
Owner action: confirm the leaked key is deleted in Google Cloud before creating a new one (SRV-13).
```

```text
OPUS-6 / A ZIP-level Civic answer would be shown, saved and notified as "Official ✓"
Type: product risk (latent; becomes live the moment the key is set) · Severity: P1 · Confidence: strongly supported (static + node)
Evidence: polling.js:128 sends "City, ST ZIP" as the voter address.
  civicService.js:8-27 marks every pollingLocation isReal:true.
  Web PollingLocationCard.jsx:27-30 and iOS PollingResultsView.swift:57-60 show green "Official".
  iOS saves it as confirmed and names it in the Election-morning notification.
  A ZIP typically spans several precincts, so the centroid precinct's site is presented as everyone's.
Fix: Treat ZIP-level pollingLocations as unconfirmed ("may not be your assigned site"); keep earlyVote/dropOff official.
  Long-term: ask for a street address for official lookups.
Release-blocking: blocks enabling the Civic key. It does not block a keyless release.
Related: CIV-1, IOS-13. Also fix CIV-2, SRV-3 and CIV-12 before enabling the key.
```

```text
OPUS-7 / Build provenance not established; two archives claim 1.0 (2)
Type: evidence gap · Severity: P1 · Confidence: confirmed
Evidence: §2.
  The dSYM source paths point at the working tree. All 3f9ab31 UI strings are present and removed ones absent, but non-string edits between 18:48 and 19:01 cannot be excluded.
  ExportOptions has manageAppVersionAndBuildNumber=true, so App Store Connect may renumber.
Fix: Bump to build 3. Archive from a clean checkout of the final merged SHA, record the SHA in the release notes, and delete the stale /tmp archives.
Release-blocking: yes (build 3 is needed for OPUS-3/4 anyway).
```

```text
OPUS-8 / Nothing past local export is evidenced
Type: evidence gap · Severity: P1 (gate) · Confidence: confirmed
Evidenced: local archive and local App Store export.
Not evidenced: upload, processing, TestFlight install, review, approval.
  The 10-10 device install was a development-signed derived-data build, not the IPA.
Required before submission: processed TestFlight build passing the critical paths in §8.
```

### 3.2 P2

| ID | Finding | Type / confidence | Evidence | Smallest fix | Blocks? |
|---|---|---|---|---|---|
| OPUS-9 (SRV-1) | **Production mis-routed every rewritten `/api/*` for about 2 s.** 16:00:36–38Z: health/elections → 404, `polling?zip=10001` → 400 "valid ZIP". Healthy at 15:57Z, 16:05Z and 16:38Z, including requests with `Origin` (lead recheck, 4/4 200). | evidence gap, confirmed symptom, unknown cause | `vercel.json:13` → `api/index.js:7-13` shim. Vercel request IDs `pdx1::iad1::86ng4-1791734436567-fcd6bea7e6c6`, `pdx1::iad1::v9mmx-1791734437339-02422effa0b4` | Owner: inspect those IDs in Vercel runtime logs and any deploy/config event near 16:00Z. Code: catch-all `api/[...path].js` or a defensive shim. Add a post-deploy smoke check | Recheck immediately before submission; P0 if it recurs |
| OPUS-10 (CIV-3) | Widened tier returns **out-of-state** buildings: 98660 (WA) → North Portland Library, OR, 8.7 km. A voter can never vote in another state | defect, confirmed node | `geocodeService.js:146-149` | Drop venues whose `addr.state` differs from the ZIP's state | No; first fix release |
| OPUS-11 (CIV-4, SRV-3) | Caching: estimated/nearby rows live 7 d in Postgres plus CDN 1 d with 7 d stale-while-revalidate. Civic errors are swallowed (`res.ok` not checked) and downgrade silently to estimated, then get cached. Official rows never re-check the election date | product risk, confirmed node | `polling.js:17,164-175`; `civicService.js:31-34` | Throw on `!res.ok`; short TTL (≈6 h) for non-official rows when keyed; expire on election passage | Before enabling the key |
| OPUS-12 (CIV-2) | Civic `electionDay >= today` uses the **UTC** date, so the official tier vanishes at 4 pm PT on Election Day | defect, confirmed node (latent) | `civicService.js:40,45` | Compare against now−12 h or the Pacific/Honolulu date | Before enabling the key |
| OPUS-13 (CIV-5) | "Official" hinges on a single flag. The server sets `isReal:true` on every OSM venue; cards ignore `dataSource`. `{isEstimated:false}` alone, `{isReal:false,isEstimated:false}` and `isEstimated:"true"` (string) all render "Official" on web. Lead reproduced `isEstimated:false` with `dataSource:'nearby'` → "Official" badge in Chromium | product risk, confirmed | `client/src/lib/format.js:49-51`; `PollingResult.swift:17`; `geocodeService.js:162-163` | Server emits `isOfficial:true` only in `parseLocations`; clients require `isOfficial===true && dataSource==='official'` | No (no emitter today) |
| OPUS-14 (IOS-2) | Home hero card says **"0 days"** on Election Day (widget says "Today"); VoiceOver says "in 1 days"; hourly refresh can lag past midnight | defect, confirmed swift-run | `ElectionCountdownCard.swift:8,24-33,51` | Reuse `countdownPhrase` / `spokenSummary()` | Fix before 11-03 |
| OPUS-15 (IOS-3) | Reminders never roll forward to 2028; the toggle stays ON with nothing queued after 11-03 | product risk, confirmed static | `HomeView.swift:81`, `VoteViewModel.swift:84`, contradicts `ReminderScheduler.swift:3-5` | Call `schedule()` on foreground when enabled and authorized | No |
| OPUS-16 (IOS-10) | `ReminderSchedulerTests` fixes `now` while notification triggers fire against the real clock, so expected counts should break from **2026-10-27 09:00** | evidence gap, strongly supported | `ReminderSchedulerTests.swift:45-62,114-140` | Inject a clock, or compute dates relative to `Date()` | Breaks CI in 16 days |
| OPUS-17 (CIV-9, REL-9) | iOS Home shows a green `checkmark.circle.fill` ("Available offline") beside "Not confirmed" saved places, the same glyph used for confirmed on the map | product risk, confirmed | `HomeSavedPlaceCard.swift:23-27`; visible in `docs/ui-review/ios-qa-saved-place-home.png` | Neutral glyph or a text "Offline" badge | No (bundle into build 3) |
| OPUS-18 (SRV-2) | The pg Pool has no `'error'` listener. A Neon idle disconnect crashes the function, and the crash dump prints DB user/host/name (not the password) | defect, confirmed node | `server/db/client.js:5-10` | `pool.on('error', e => console.warn('Postgres idle client error', e.code))` | No; ship with release |
| OPUS-19 (SRV-4, SRV-5) | Nominatim budget and latency. Pacing is per request only; 8–9 calls per miss; device cells defeat the caches; per-instance limiter. The weak path has a 6 s sleep floor and 8–9 sequential calls against the iOS 15 s timeout and `maxDuration` 30 s | product risk, strongly supported / hypothesis | `geocodeService.js:189-196`; `APIClient.swift:31` | Venue search from the ZIP centroid (cached), device distance only; stop on 429; route deadline about 10 s; iOS polling timeout 25–30 s. Measure p95 for a tier-2 ZIP | No, but Election Day risk |
| OPUS-20 (REL-7 + lead) | News and nonpartisanship. Live feed and screenshot 5 include advocacy and party-committee sources (Democracy Forward ×2, DLCC, HRC) and a junk survey item ("TCS VVP … Q23"). Party chips come from the named candidate, so an anti-Trump Democracy Forward piece carries a red **"Republican"** chip (live 16:38Z, web `NewsCard.jsx:18-19` and iOS `NewsView.swift:65-68`). "Across the political spectrum" in the listing has no code backing | product risk, confirmed | `newsService.js` watchlist; live `/api/news` | Rename the chip to "Mentions: <party>" or drop it; denylist party committees/advocacy orgs; drop the listing phrase; re-shoot or drop screenshot 5 | No |
| OPUS-21 (REL-8, IOS-14) | The electoral map shows unsourced, undated presidential "Leans" ratings in a midterm year; Maine and Nebraska are treated as winner-take-all. Data parity web ↔ iOS is byte-identical and the apportionment is correct (538) | product risk, confirmed | `client/src/data/stateData.js`; `ElectoralMapLegend.swift` | Attribute and date the ratings, or reframe as "electoral votes by state" with a neutral fill | No |
| OPUS-22 (REL-3) | Apple's screenshot spec (fetched 2026-10-11) lists **iPhone Dynamic Island (medium display)** (1206×2622 / 1179×2556) as required; the candidate only has 1320×2868 | evidence gap | `ios/screenshots/*`; `APP_STORE.md:163` | Check App Store Connect at upload; if not satisfied by scaling, capture a 6.3" set | Conditional |
| OPUS-23 (SRV-13) | The leaked Civic key is still in public git history (2 commits; value not printed); deletion is not evidenced | evidence gap | `git log --all -S` | Owner confirms deletion in Google Cloud Console | Before re-enabling Civic |

### 3.3 P3

| ID | Finding | Evidence |
|---|---|---|
| OPUS-24 (UR-2, IOS-4) | Notifications-denied text lost its warning colour in `3f9ab31`. Also, revoking permission in Settings silently flips the toggle off, with no message and no `cancelAll()` | `ElectionReminderCard.swift:20-22`; `HomeView.swift:61-63` |
| OPUS-25 (UR-1) | The popup max-width formula is duplicated. Maintainability only: lead web QA shows correct bounds initially and after a 1440→320 resize | `PollingMap.jsx:55,90` |
| OPUS-26 (CIV-11) | Web race in a narrow window. `api.get` removes its abort listener once headers arrive, so a superseded body can overwrite a newer search (node replay). The lead's browser tests with whole-response delays passed | `usePolling.js:27-37`; `api.js:28-34`; fix: `if (controllerRef.current !== controller) return;` |
| OPUS-27 (IOS-5) | The ZIP field accepts non-ASCII digits (Arabic-Indic, fullwidth, ½, ²), leading to a server 400; pasting "1600 Penn Ave, DC 20500" searches 16002 | `VoteViewModel.swift:23` |
| OPUS-28 (IOS-6) | Off-by-one in zones where DST starts at midnight (Santiago, Havana, Beirut, Cairo); US zones unaffected | `ElectionCalendar.swift:57,65,86-91` |
| OPUS-29 (IOS-7) | All location errors show one generic panel; the tailored messages are unused; there is no Settings path | `LocationManager.swift:14-23` |
| OPUS-30 (IOS-8, IOS-9) | Reminder toggle ON→OFF during the auth await can schedule after `cancelAll` (hypothesis); `LocationManager` re-entrancy (unreachable today) | `HomeView.swift:66-82` |
| OPUS-31 (IOS-11) | The Release stub check is mostly blind. Swift literals of 15 bytes or less are inline immediates, so `-stubPolling`/`-startTab` can never match. Only "Roxbury Community Center" is effective, and the appex is not scanned. The dSYM file list (no `APIStub.swift`) is stronger evidence | `scripts/test-ios.sh` |
| OPUS-32 (IOS-12) | UI tests weaker than their names. The location-denial test proceeds if no alert appears and accepts any `LocationError`; stubs bypass JSON decoding; there is no official-tier stub; the persistence test does not assert Remove; there is no location-granted UI test | `ios/Vote4UUITests/*` |
| OPUS-33 (CIV-6) | "Widened to about 16 miles" overstates the search: the box reaches about 8–11 km on-axis | `PollingFinder.jsx:83-85`; `PollingResultsView.swift:84` |
| OPUS-34 (CIV-8, 10, 12–16) | Latent and polish items:<br>• Civic election with no sites falls through to OSM<br>• saved places never age, and the notification puts the warning last<br>• DC `district:dc` filter miss<br>• duplicate Civic `name\|addr` ids<br>• iOS drops `hours`/`election`<br>• no Civic filter tests<br>• official links are national only, while iOS calls usa.gov a "state lookup" | see `findings-civic` notes |
| OPUS-35 (SRV-6–12, 14) | Server and privacy:<br>• malformed JSON body → 500 and raw body logged (`express.json()` unused)<br>• one bad `pubDate` → `/api/news` 502<br>• `javascript:` article URLs pass through (iOS `SFSafariViewController` would throw)<br>• CORS regex admits third-party `vote4ucyl-*.vercel.app`, and the preflight advertises write methods<br>• `rejectUnauthorized:false` unless `sslmode` is set<br>• the privacy policy omits device-coordinate bounding-box searches and doesn't name Neon<br>• whitespace coordinates are read as (0,0)<br>• cleanup cron recurrence not shown | `app.js:15,29-32`; `newsService.js:167`; `cors.js:15`; `db/client.js:6-9`; `polling.js:42-47` |
| OPUS-36 (IOS-15) | The news year flips at UTC midnight (7 pm ET on Election Day) | `newsService.js` |
| OPUS-37 (REL-10, REL-13, IOS-16) | `PrivacyInfo.xcprivacy` has no `NSPrivacyCollectedDataTypes`. `APP_STORE.md` is stale: checklist, keywords, the 6.9" claim, and the age-rating questionnaire answers are not recorded | `ios/APP_STORE.md` |
| OPUS-38 | GitHub Pages publishes repo docs as a second "Vote4U" site | Pages API: legacy build from `main /` |

### 3.4 Verified correct (credited)

**Civic chain**
- Civic test election 2000 is excluded, and elections are filtered by state.
- No coordinates or hours are fabricated; OSM venues always carry `isEstimated:true` and never `hours`.
- The widened tier is labelled "Civic Building" (prod-confirmed).
- `none` results are never DB-cached.
- ZIP and device cache keys cannot collide.
- Coordinates are rounded to 3dp on the device and on the server.
- Web and iOS use the identical confirmation rule.
- Legacy and malformed saved records decode as unconfirmed or nil, with no crash.
- iOS share text and the notification carry "Not confirmed" plus usa.gov.
- Empty results lead to official links on both platforms.
- The popup uses `textContent`.

**Server**
- Validation: arrays, ZIP+4, NaN, Infinity, out-of-range values and 5 KB strings all get 400 JSON; leading zeros work.
- Cleanup endpoint: GET, `timingSafeEqual`, fails closed without `CRON_SECRET`.
- The migration is idempotent and transactional.
- `trust proxy 1`; HSTS, XFO, nosniff, Referrer-Policy and Permissions-Policy are live.
- No secrets at HEAD or in `client/dist`.
- No coordinate, ZIP, URL, key or IP reaches application logs on any realistic error path, so **PR #10 is not a privacy prerequisite**.

**Dates**
- Swift, client JS and server JS agree for 2026–2036: 2026-11-03, 2028-11-07, 2030-11-05, 2032-11-02, 2034-11-07, 2036-11-04.
- Boundaries (23:59 → "Tomorrow", 00:00 → "Today", the next day → 734 days) are correct in NY, Honolulu, Adak, Kiritimati, Tokyo, London, LA and UTC; leap day and US DST also pass.
- Widget entries land at local midnight; reminders fire 10-27 09:00 and 11-03 07:00.
- No copy claims that polls are open or gives poll hours.

**Native and packaging**
- There is no iOS response race, because controls are disabled while busy, and every load resolves (15 s timeout, JSON error bodies).
- Widget plist nesting and embedding, families (app iPhone; extension iPhone and iPad), and iOS 17.0 are consistent.
- Version 1.0 (2) is consistent across targets.
- The build-2 IPA:
  - is Apple Distribution, with no device list and `get-task-allow` false
  - has an opaque 1024 icon and declares no non-exempt encryption
  - contains no stub, fixture, localhost or preview URLs
  - has a correct UserDefaults required reason (CA92.1), and the widget needs no manifest
- Electoral data web ↔ iOS is byte-identical when freshly exported, and the apportionment is correct.
- Xcode 27 / iOS 27 SDK uploads are accepted (App Store Connect release notes, 2026-09-14).

**Web**
- Popups stay within the map with the warning visible at 320, 390, 768 and 1440 px, and after resizing with a popup open.
- No horizontal document overflow.
- Slow-A/fast-B and back-navigation stale responses do not overwrite newer results.

---

## 4. Claim ledger and test matrix

### 4.1 Claims

| Claim (source) | Applies to | Independent check | Result | Status |
|---|---|---|---|---|
| Server 50 passed (HANDOFF §13/14) | RC | `npm test --prefix server`, 2026-10-11, Node 26, exit 0 | 50 pass / 0 fail / 0 skip | **verified** (stubbed upstreams only) |
| Web 93 passed, 9 skips (§14) | RC | `npx playwright test`, 15:56Z, exit 0 | 93 / 9 skips: 6 = desktop-only API specs on mobile, 3 = header test needs `BASE_URL` | **verified**. Limitation: reused an existing local API on :3001 (identical server tree) with `RATE_LIMIT_MAX=5000`, so rate limiting was **not** validated |
| Later 54-pass subset | RC | — | Superseded by the full run above | stale |
| iOS 69 passed on SE 3 / iOS 17.5 (§14) | build-2 era working tree | Mandatory runner on RC `e39eeeb`, 16:38–16:43Z, exit 0 | 69 passed (55 unit + 12 smoke + allow + deny), 0 skipped; Release and family checks ok | **verified** for the simulator; see OPUS-31/32 |
| Real device install 1.0 (2) | dev-signed derived-data build | Artifact inspection | Not the exported IPA; not TestFlight | **partial** (true locally; generalized to distribution) |
| Widget works on Home Screen | owner device | Owner report only | Cannot re-verify here | partial, owner evidence |
| Offline works | owner device | Owner did not Save | Persisted-offline path unproven on device; the UI test proves relaunch persistence on the simulator | **partial** |
| Visual QA completed | selected sizes | Lead web QA plus agent screenshot review | The web is fine. The native Home green check (OPUS-17) and store screenshot content (OPUS-20/21) were missed | partial |
| Store images refreshed, 1320×2868, no alpha | `ios/screenshots` | `sips` plus visual inspection | True; but screenshot 1 shows the "Likely Polling Place" label, 5 shows partisan sources, and the medium size may be required | **partial** |
| Local distribution export succeeded | build-2 IPA | Signature/profile inspection | True; provenance partial; no upload | partial |
| Production elections 503 | Production | Live 15:57Z | 503 "Election data is not configured." The cause is a missing key (code path) | **verified** |
| Strict formatting (one known finding) | RC | `xcrun swift-format lint --strict` with #9's config | **215 findings**; the RC has no `.swift-format` config | **contradicted** (cosmetic) |
| Toolchain accepted | Xcode 27.0 | Apple App Store Connect release notes | Xcode 27 uploads accepted since 2026-09-14 | verified (family), package unverified |
| "Location never stored or shared" (Info.plist) | RC/IPA | Data-flow trace | False | **contradicted** (OPUS-3) |
| Privacy policy claims (`/privacy`) | Production | Data-flow trace | Supported, except the omission of device bounding-box searches and Neon (OPUS-35) | partial |

### 4.2 Review matrix

| Area | Result | Evidence / reason |
|---|---|---|
| Integration | **FAIL → PR #16** | §2 |
| Search (web) | PASS: ZIP, leading zero (server), slow, out-of-order, 404/500/offline/non-JSON (e2e), 429 not exercised | e2e log; `webqa/explore.spec.js` |
| Search (iOS) | Runner + static; denied GPS → ZIP covered by UI test (weak, OPUS-32); revoked GPS, approximate location, no fix: **NOT RUN** (device) | §4.3 |
| Truth | **FAIL** (OPUS-2, OPUS-6, OPUS-13); conflicting-flags injection run on web | `webqa` conflicting-flags test |
| Offline | Simulator relaunch persistence PASS (runner); airplane-mode cold launch on device **NOT RUN** | owner action |
| Dates | PASS (computed, 3 implementations) except OPUS-14 (Home "0 days") and OPUS-28 | `ios-work/cal` |
| Reminders | Allow/deny PASS (runner); revoke, delivered banner **NOT RUN**; rollover FAIL (OPUS-15) | |
| Widget | Registration/family PASS (runner, static); placement owner-reported; tap/refresh **NOT RUN** | |
| Native UX | Largest-text reachability test in runner; VoiceOver, dark-mode device, reduced motion **NOT RUN** | |
| Web UX | Four widths PASS, resize PASS, axe in e2e PASS; manual keyboard/screen reader **NOT RUN** | |
| Backend | Cache separation PASS (tests + live `cached:true`); upstream failures partially FAIL (OPUS-11); cleanup recurrence **BLOCKED** (Vercel access) | |
| Privacy | Logs PASS; disclosures FAIL (OPUS-3) / partial (OPUS-35); host retention **BLOCKED** (account) | |
| Release | **FAIL**: provenance, no in-app policy, no TestFlight | §3.1 |

### 4.3 iOS runner (mandatory)

| Field | Value |
|---|---|
| SHA | `e39eeeb`, clean worktree (only untracked `node_modules` symlinks) |
| Command | `DEVICE_TYPE='iPhone SE (3rd generation)' RUNTIME='com.apple.CoreSimulator.SimRuntime.iOS-17-5' DERIVED=<scratchpad>/dd-ios17 ./scripts/test-ios.sh` |
| Time | 2026-10-11 16:38:21Z – 16:43:16Z; macOS 27, Xcode 27.0 (27A266a), iOS 17.5 (21F79) |
| Exit | 0 |
| Result | **69 passed, 0 failed, 0 skipped**:<br>• notification allow 1<br>• unit 55<br>• UI smoke 12<br>• notification deny 1<br>Also:<br>• Release stub check printed `ok`<br>• widget iPhone+iPad family check passed (Debug and Release) |
| Ran alone? | Yes. The other session's iOS 27 run had finished before this started |
| Limitations | Simulator only.<br>• The Release stub grep is weaker than it looks (OPUS-31)<br>• UI tests are weaker than their names (OPUS-32)<br>• Reminder tests become time-dependent on 2026-10-27 (OPUS-16)<br>• Not run on the iOS 27 runtime for this SHA. The other session's iOS 27 pass was on a different, dirty tree<br>• No VoiceOver, no device, no TestFlight |

---

## 5. MVP assessment

**The promise, in plain language:**

> "Type your ZIP code (no location needed) and Vote4U shows the official places to vote if they are published, otherwise tells you honestly that it doesn't know and sends you to your official election office. It also tells you how long until Election Day and can remind you."

**Does current behavior meet it?** Partly.
- **Met:**
  - ZIP works without GPS.
  - Empty results lead to official sources.
  - Dates are correct.
  - Uncertainty survives sharing, saving and notifications.
  - Nothing is fabricated.
- **Not met:**
  - With no Civic key, the app *never* shows official data.
  - Its main result, in its largest type, names arbitrary buildings "Likely Polling Place / Likely Early Voting". The amber banner and "Not confirmed" chip hedge this, but a first-time voter reading the card title will reasonably believe the app has some evidence. It has none beyond the building category.
  - Official links are national, not state-specific, so "find your official authority" takes extra steps.

**Smallest change that makes the MVP honest:**
1. Relabel tier 1 and tier 2 as building kinds (OPUS-2) and filter out-of-state venues (OPUS-10).
2. Lead the result screen with "We can't confirm your polling place. Check your official lookup" (button first), with the buildings below as "Public buildings nearby".
3. Keep Civic off until OPUS-6/12/11 are fixed. Then enable it with ZIP-level results unconfirmed.

A safer variant is to hide the suggestions behind "Show nearby public buildings". It is the more defensible choice for App Review, and costs little utility. This is the owner's product decision.

---

## 6. Ultrareview reconciliation

The concurrent ultrareview's output was available only as the two findings relayed by the owner. Its working tree is an uncommitted edit in another session's worktree, on `feat/visual-ux-polish` at `3f9ab31`. That tree ran the iOS runner on iOS 27 and passed (its log: unit + 12 smoke + allow/deny + Release check). **That run validates neither the RC nor main.**

| Ultrareview finding | Mapping | Status here |
|---|---|---|
| UR-1 popup max-width formula duplicated (`PollingMap.jsx:55,90`) | OPUS-25 | **Supported by static evidence**; no user-visible defect reproduced (four widths plus resize PASS). Maintainability P3 |
| UR-2 reminder-denied warning not distinct (`ElectionReminderCard.swift:19-20`) | OPUS-24 | **Independently reproduced statically** (iOS agent found it before reading the relay). Extra: revocation in Settings flips the toggle silently with no `cancelAll()` |

**Shared blind spots.** Neither review exercised any of the following:
- the official Civic tier against real data, since production is keyless and all evidence is stubs or static (OPUS-6/11/12)
- a physical device, VoiceOver, a delivered banner, or TestFlight
- App Store Connect, Vercel logs or the cron history

**Integration note.** The ultrareview's fixes target a branch that is already merged. They need a new branch off the release branch or main, and the combined tree (#16 + UR fixes + any OPUS fixes) must be re-run through server, e2e and `test-ios.sh` before build 3. Two separately green trees do not validate their combination.

---

## 7. Fixes made, attempts and failures

- **No code fixes were made by this review.** The P1 fixes (OPUS-2/3/4) are small, but they change product wording and the build, so they are left for the owner's go-ahead.
- PR #16 was opened (integration only, no code).
- Failed or aborted attempts:
  - **Web popup check.** The first Playwright check of popup bounds at 320 and 390 px failed. The cause was the measurement: it was taken during the scroll/auto-pan animation, not a real clipping problem. After an 800 ms settle, bounds are correct and the screenshot confirms the full popup and warning are visible.
  - **Lint baseline.** The first lint attempt used swift-format's default config (3379 findings, meaningless); it was rerun with #9's config (215).
  - **Production routing.** One agent's production probes landed in the SRV-1 window, so its cleanup-route 401 check is inconclusive.
  - **Agent output.** The review agents could not write their files; the lead saved their reports to the scratchpad.

---

## 8. Release gates and owner actions (in order)

| # | Action | Who | Success criterion |
|---|---|---|---|
| 1 | Check Vercel runtime logs for the two SRV-1 request IDs and any event near 2026-10-11 16:00Z | owner | Cause identified, or no recurrence in 24 h of `/api/health` checks |
| 2 | Decide the Civic path: keyless (reword listing/notes) **or** keyed (only after OPUS-6/11/12 are fixed). Confirm the leaked key is deleted in Google Cloud | owner | Decision recorded; old key shows deleted |
| 3 | Approve fix PRs: OPUS-2 labels + OPUS-10 state filter (server); OPUS-3 purpose string; OPUS-4 privacy/support link; OPUS-17 icon; OPUS-14 "0 days"; OPUS-18 pool listener; OPUS-16 test clock; UR-1/UR-2 from the ultrareview | owner/agent | PRs green on CI; deliberate-mutation proof for the label and state-filter tests |
| 4 | Merge #16 (+ fixes) to main | owner | Production deployment SHA == main HEAD; `/api/polling?zip=10001` shows no "Likely … Voting" type |
| 5 | Full suites on the merged SHA: server, `npm run test:e2e`, `test-ios.sh` (SE/17.5 and newest runtime) | agent | All pass; skips are only the 9 documented ones |
| 6 | Bump to build 3; archive from a **clean checkout** of the merged SHA; record the SHA; delete stale `/tmp` archives | owner (Xcode) | Archive Info.plist build 3; SHA in release notes |
| 7 | Re-shoot screenshots 1 (new labels) and 5 (or drop it); check whether App Store Connect requires a 6.3" set | owner/agent | The App Store Connect media manager shows no missing required size |
| 8 | Update `APP_STORE.md`: description (no "official"/"across the spectrum" over-claims), Review Notes, age-rating answers, privacy labels | owner | Listing matches keyless behavior |
| 9 | Upload build 3; wait for processing; install via TestFlight | owner | Build shows "Ready to Test"; installs on the iPhone 15 |
| 10 | On TestFlight:<br>• deny location → ZIP → official link<br>• allow location → result<br>• revoke in Settings → ZIP<br>• Save → force quit → airplane mode → cold launch: address, type, warning<br>• notifications allow → delivered banner (controlled test)<br>• widget placement + tap<br>• VoiceOver across the 4 tabs<br>• largest text | owner | Each recorded with device, iOS version, build and date |
| 11 | Re-check production: health, polling (one tier-1 ZIP, one widened ZIP), news, privacy, cron history shows 204s | agent/owner | All 200; cron history shows successful runs |
| 12 | Submit | owner | — |

---

## 9. Next-session handoff

- **Candidate:** `e39eeeb` (RC). Integration PR #16. Production `4f104f3`.
- **Working notes:** under the reviewer scratchpad. `findings-{civic,server,ios,release}.md`, `webqa/` (Playwright exploration spec and screenshots), `e2e.log`, `server-test.log`, `ios-se175.log`. Agents' node and Swift experiments are in `civic-work/`, `server-work/exp/`, `ios-work/` and `pkg/`. These are temporary; re-derive if gone.
- **Commands:**
  - `npm test --prefix server`
  - `npx playwright test`; beware `reuseExistingServer`, which silently reuses whatever is on :3001
  - ``DEVICE_TYPE='iPhone SE (3rd generation)' RUNTIME='com.apple.CoreSimulator.SimRuntime.iOS-17-5' DERIVED=<own dir> ./scripts/test-ios.sh``
- **Remaining work:**
  - §8 gates 3–11
  - OPUS-19 load/latency measurement
  - VoiceOver
  - TestFlight
- **Account blockers:** Vercel (logs, cron history, env scope), Google Cloud (key deletion), App Store Connect (record, screenshots, privacy answers, upload).
