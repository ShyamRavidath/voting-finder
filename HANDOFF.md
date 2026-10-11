# Vote4U — Handoff

**Audience: the next agent or owner, resuming this project cold.** Updated 2026-10-10.
**Section 0 is authoritative for current status.** Sections 1–12 preserve the earlier record;
claims about branches, blockers, tests and production in those dated sections are historical
unless reconfirmed here. Read §0 first, and §5 and §7 before changing code.

Owner: Shyam Ravidath (`ShyamRavidath/voting-finder`), git user `vote4u`.
Read `CODEX_HANDOFF.md` for the earlier Codex on-ramp and gitignored `CLAUDE.md` for local
architecture notes. `ios/APP_STORE.md` holds draft listing/privacy/review material.
`ios/IOS_DEVELOPMENT_GUIDE.md` is third-party inspiration, not instruction for this iOS 17 app.

> Vote4U has no verified App Store submission or TestFlight upload. **PRs #4, #7 and #11 are
> now merged**; #9 (formatting) and #10 (logging) remain open drafts. `origin/main` is
> `b2209e3`, with successful web and iOS CI. The owner supplied **Team ID `M6L74ZB5KS`** on
> 2026-10-10; it is not yet configured in the checked-in Xcode project. Production database
> caching was observed on 2026-10-03; the owner supplied successful cleanup responses and a
> zero expired-row count. Automatic recurring delivery, actual row deletion, physical-device
> behavior and widget Home Screen placement still need evidence. **Next development action:
> integrate #10 with current main's cache/cleanup routes, then finish #9 over all merged Swift.**

---

## 0. Current handoff — 2026-10-10

### 0A. The goal we are working toward

Ship the free, nonpartisan **native iOS 17+ Swift/SwiftUI Vote4U app** to the App Store while
keeping its Vercel web app and shared Express backend reliable. The voting tools lead; News
stays last. ZIP entry must work when location permission is declined. Official versus
unconfirmed data must remain honest, with more cautious labels for weaker evidence and official
lookup links when nothing is found. Never fabricate a polling venue outside DEBUG-only APIStub,
never imply government endorsement, and never commit credentials or log user location.

Everything stays free except the Apple Developer Program. Use branch → commit → push → PR;
the owner merges, and main deploys. A successful build is insufficient evidence of a working
feature. Distinguish observed results, owner-supplied evidence and remaining uncertainty.

The database setup that blocked #7 has progressed to observed production caching and reported
successful cleanup. The immediate development work is now integrating the two remaining draft
PRs and preparing signing/device validation. Knowing a Team ID removes the old missing-ID
blocker; it does not prove Xcode account access, certificates, provisioning or device installs.

### 0B. Current repository and PR state

Refreshed with `git fetch origin`, GitHub PR reads and main-branch CI reads on 2026-10-10:

- `origin/main`: **`b2209e36fa2224b44103b5295142aef83a785d05`** (merge of PR #4).
- Current documentation branch: **`docs/handoff-2026-10-10`**, created from that main.
- Starting checkout was clean on `feat/coordinate-aware-cache` at `63d9b79`; that branch is
  already merged and should not be used for new work. The local `main` branch was not updated;
  use the refreshed `origin/main` when creating the next topic branch.
- This session changes only `HANDOFF.md`. No source implementation or signing configuration
  is in progress. No PR has been merged by Codex.

| PR | Verified GitHub state | What remains |
|---|---|---|
| [#4 widget](https://github.com/ShyamRavidath/voting-finder/pull/4) | MERGED, 2026-10-04 UTC (Oct 3 Pacific) | Widget code and newer historical handoff are on main. Simulator registration/rendering passed; actual Home Screen placement is unverified. |
| [#7 cache](https://github.com/ShyamRavidath/voting-finder/pull/7) | MERGED, 2026-10-04 UTC | Schema, migration, coordinate-aware cache and daily cleanup are on main. Production evidence and limits are in §0D. |
| [#11 privacy](https://github.com/ShyamRavidath/voting-finder/pull/11) | MERGED, 2026-10-04 UTC, before #7 | Strict US geocoding and client rounding are on main. Final App Store privacy answers still need host-retention review. |
| [#9 format](https://github.com/ShyamRavidath/voting-finder/pull/9) | OPEN, DRAFT | Update over main, format the merged widget/map/privacy Swift files, rerun strict lint and the required iOS runner. Old green CI does not validate this integration. |
| [#10 logging](https://github.com/ShyamRavidath/voting-finder/pull/10) | OPEN, DRAFT | Update over main, instrument the new cache and cleanup paths, and rerun privacy/mutation/server/web checks. Platform logging is separate. |

PRs #2, #3, #5, #6 and #8 also remain merged. Only #9 and #10 were open in the refreshed list.
No new integration work was performed on those drafts in this handoff session. Do not mark
those PRs ready based on their September branch checks.

Main at `b2209e3` has completed, successful [web CI](https://github.com/ShyamRavidath/voting-finder/actions/runs/37168366885)
and [iOS CI](https://github.com/ShyamRavidath/voting-finder/actions/runs/37168366863), both
started 2026-10-04 UTC. These results were read on October 10; tests were not rerun locally
for this documentation-only update. They do not prove a signed device build or App Store upload.

`AGENTS.md` and `CLAUDE.md` still contain dated statements that the widget exists only on #4
and that main has no widget. **Those inventory statements are superseded:** #4 is merged.
Their product commitments and test-runner instructions still apply. This update does not edit
those files or `CODEX_HANDOFF.md`.

### 0C. Files actively edited and current code map

**Active edit: `HANDOFF.md` only.** No unfinished source patch, migration or device build needs
to be recovered. Team ID `M6L74ZB5KS` is recorded here as owner-provided metadata; no
`DEVELOPMENT_TEAM` setting was found in main's `ios/Vote4U.xcodeproj/project.pbxproj`.
The app and widget use automatic signing, which still needs the team/account configured.

| Files / area | Current state and traps |
|---|---|
| `api/index.js`, `server/app.js`, `server/index.js` | Shared Express app; Vercel entry exports it, local entry listens on :3001. |
| `server/db/schema.sql`, `server/db/migrate.js`, `server/db/migrations/2026-09-21-polling-cache-key.sql` | On main. Fresh schema has `cache_key VARCHAR(32)`; migration handles old `zip_code`, adds expiry index and removes expired rows. CLI wraps schema+migration in a transaction. Do not rerun production SQL just because old notes say it is pending. |
| `server/lib/pollingCacheKey.js`, `server/routes/polling.js` | ZIP and device keys are distinct; device key is rounded coordinate pair with no ZIP so cache read precedes reverse-geocoding. Device serving TTL is one day, ZIP one week; database errors can fall back live. Device responses have no week-long CDN stale window. |
| `server/routes/cacheMaintenance.js`, `vercel.json` | GET `/api/internal/cache-maintenance`, daily `0 0 * * *`. DB+missing secret → 503; bad/missing Bearer → 401; successful DELETE → 204; absent DB → intentional 204 no-op. Mounted before public rate limiting. |
| `server/db/client.js` | Uses Node pg and `DATABASE_URL`; production code supplies `ssl: { rejectUnauthorized: false }`. URL SSL options can override that object. Review effective TLS configuration alongside the reported compatibility warning; no SSL fix has been made here. |
| `server/services/geocodeService.js`, `server/test/api.test.js` | Requires explicit US country evidence and complete ZIP/ZIP+4. Typed no-ZIP/outside-US errors are handled without inventing a result. Whole Error logging elsewhere remains a privacy-sensitive edge for #10. |
| `ios/Vote4U/Services/APIClient.swift`, `ios/Vote4UTests/APIClientPrivacyTests.swift` | Coordinates round on-device before constructing the URL. Three decimals are still Precise Location for the conservative disclosure draft. |
| `client/src/pages/PrivacyPage.jsx`, `ios/APP_STORE.md` | #11 wording preserved through #7 conflict resolution. Describes platform request logs and cleanup-delay caveat. App Privacy labels remain drafts pending actual host retention/linkage review. |
| `ios/Vote4U.xcodeproj/project.pbxproj`, `ios/Vote4UWidgets-Info.plist`, `ios/Vote4UWidgets/*.swift` | Widget merged. Containing app is iPhone-only; extension targets iPhone+iPad in Debug/Release. Keep extension Info.plist outside its synchronized group. App ID `com.shyamravidath.Vote4U`, widget ID `com.shyamravidath.Vote4U.Widgets`. Both need team configuration for signing. |
| `ios/Vote4U/Models/ElectionCalendar.swift`, `ios/Vote4U/Features/Widget/ElectionCountdownWidgetView.swift`, `ios/Vote4UTests/ElectionCountdown{Tests,RenderTests}.swift` | Shared offline countdown, five widget families and model/render tests. Circular countdown says Today on Election Day. Registration/render tests do not prove Home Screen placement. |
| `scripts/test-ios.sh`, `.github/workflows/ios.yml` | Required runner: warmed throwaway simulators, both notification decisions, unit/UI tests, Release DEBUG-stub grep and widget-family checks. CI uses macos-26 and checks widget registration. Never substitute bare xcodebuild test or run against shared DerivedData concurrently. |
| #9-only `ios/.swift-format`, `.git-blame-ignore-revs`, CI formatting step | Not integrated into main. Use four-space/120-column config from that branch; local formatter is `xcrun swift-format`. Cover `Vote4UWidgets` as well as app/test Swift when finishing the integration. |
| #10-only `server/lib/logger.js`, `server/middleware/requestLog.js`, route instrumentation/tests | Not integrated into main. New polling cache path must be merged carefully; keep cache hits ahead of reverse geocoding and instrument cleanup without leaking Bearer secrets or DB errors. |

For #9/#10 source, read the appropriate branch with `git show <branch>:<path>`; main cannot
show code that remains in a draft. This documentation branch contains no signing, formatting
or logging implementation changes.

### 0D. Production database evidence, Team ID and remaining uncertainty

**Database identity:** owner created Vercel-integrated Neon `neon-almond-flask`
(`shiny-mode-83679617`) and confirmed its Production connection. On 2026-10-03 the owner said
CRON_SECRET was updated in Vercel and SQL was run in Neon SQL Editor. No plaintext database
connection string, password, API key or cron secret was supplied to Codex or written here.

**Owner-supplied schema results:** `news_cache` has id, query_key, articles, cached_at and
expires_at; `polling_cache` has id, cache_key (`character varying`, maximum length 32), locations,
data_source (maximum length 20), cached_at and expires_at. No `zip_code` column appeared.
Indexes returned: `polling_cache_pkey`, `polling_cache_cache_key_key`, and
`polling_cache_expires_at_idx`. This establishes reported schema shape; Codex did not connect
independently to Neon or inspect SQL Editor history. Legacy-schema upgrade on real Postgres
remains untested, even though the reported deployed fresh schema is correct.

**Direct live checks by Codex on 2026-10-03 Pacific, after #7 deployed:**

| Check | Observed result | What it establishes |
|---|---|---|
| `/api/health` | 200, CDN MISS | API responded at that time. |
| Cleanup without Authorization | 401, CDN MISS | In the deployed route, DB and secret were configured and unauthenticated access was rejected. No DELETE was triggered by this check. |
| First public test ZIP search, unique query suffix | 200, CDN MISS, `cached: false`, estimated, 3 locations | Live lookup response; alone this would not prove a DB write. |
| Repeat same public ZIP, different unique suffix | 200, CDN MISS, `cached: true`, estimated, 3 locations | Backend served a DB cache hit rather than a repeated CDN response, supporting read/write operation. |

No raw coordinates, cache keys, client IPs, upstream URLs or credentials were printed by the
check script. Codex did not exercise a real user's location. These are October 3 observations,
**not a new October 10 health or deployment check**. Current production device-mode cache
behavior was not separately exercised; local tests cover it.

**Owner-supplied cleanup evidence:** after seeing the job registered and following guidance to
trigger it, the owner supplied GET 204 logs for `/api/internal/cache-maintenance` at
Oct 3 **18:00:30.70** and **18:10:58.88** on Vercel deployment host
`voting-finder-c0caxnp59-shyamravidaths-projects.vercel.app`. The logs contained a pg SSL
compatibility warning, indicating a DB connection path; combined with the earlier observed
DB cache hit, these support successful authenticated cleanup-query execution. The earlier
Oct 3 **17:49:43.03** GET 401 was likely Codex's unauthenticated check. Its origin was not
confirmed from request details.

The owner then ran this read-only query in Neon and reported **0**:

```sql
SELECT COUNT(*) AS expired_rows
FROM polling_cache
WHERE expires_at <= NOW();
```

This shows no expired rows remained at that moment. No documented before-count or known expired
row establishes physical deletion. No User-Agent evidence distinguishes the two 204 requests
as manual versus scheduled; **automatic recurring delivery is still unverified**. Confirm a
later automatic invocation and aggregate DB state without selecting keys or location payloads.
The daily schedule uses UTC; on Hobby it can run within the scheduled hour rather than at the
exact minute. Do not assume an immediate run when deploying during that window.

**SSL follow-up:** the owner saw the driver's warning about future SSL-mode semantics on both
204 logs. Advice was to explicitly use `sslmode=verify-full` in the Production DATABASE_URL,
keep the remainder private and unchanged, redeploy, and recheck. No completed env edit/redeploy
was confirmed. Review the effective configuration in `server/db/client.js`; do not weaken
verification merely to suppress a warning or print connection details during diagnostics.

**Apple account update, 2026-10-10:** the owner answered that they now have Team ID
**`M6L74ZB5KS`**. The old "waiting for Team ID" blocker is superseded. Xcode account access,
team selection for app and extension, signing certificates, provisioning, physical-device
installation, archive, TestFlight and App Store submission are **not verified**. No project
signing settings were changed in this handoff session.

**Still needed for release:** actual widget gallery/Home Screen placement, real GPS and
permission denial/revocation, offline saved-place behavior, a notification banner delivered on
a real device, current real-data screenshots, final App Store privacy answers based on Vercel
log retention/linkage, and upload/submission evidence. App logs and Vercel platform logs have
different controls: #10 cannot remove coordinates/ZIP from platform request URLs. One-day
serving TTL is not a guaranteed deletion deadline. The Civic key was previously owner-reported
rotated/replaced; `/api/elections` and the official tier were not retested in this session.
Never reuse the leaked old key or rewrite history without an explicit request.

### 0E. What was tried and what failed since the historical §5 record

The old §5 remains the detailed failure ledger for 2026-09-20/21: false “done” claims from
unrun notification paths, skipped tests mistaken for passing, green builds mistaken for working
widgets, wrong widget Info.plist placement and metadata, wrong iOS destination, permission
alert-label theories, concurrent Xcode processes/DerivedData corruption, cold simulator timing,
stale screenshot judgments, unhelpful log suppression, brittle UI accessibility selectors,
reactive state and notification races, live geocoder instability, and direct-to-main commits.
The earlier attempts and limits are preserved here; the October deployment updates are in §0D/§0F:

- **Widget “built, therefore installable” was false.** Original extension family was `1`
  only even though app extensions must support iPhone and iPad. PR #4 changed only the
  extension's Debug/Release family to `1,2`; `scripts/test-ios.sh` now checks the built
  extension plist. Its circular accessory also said “0 days” on Election Day; shared
  `FederalElection.circularCountdown` and a focused test now make it “Today.” One test-script
  run failed with Bash's “unexpected EOF” because the script was edited while it was running;
  `bash -n` was clean afterwards and a **stable full rerun passed**. On iOS 17.5 iPad simulator,
  `pluginkit` registered the extension. Attempts at automated SpringBoard widget-gallery
  placement were unreliable (§5); actual Home Screen placement still has **not** been proven.
- **First coordinate-cache key design missed its point.** It included a ZIP and therefore
  reverse-geocoded **before** checking the cache; a “hit” still made an upstream call. The
  test exposed that. #7's device key is now only rounded `@lat,lng` and the cache read precedes
  reverse geocoding. Do not add ZIP back to the key.
- **Initial #7 migration/deployment plan was insufficient.** `CREATE TABLE IF NOT EXISTS`
  cannot transform an existing `polling_cache(zip_code CHAR(5))`; the old route's broad DB
  catch masked `undefined_column` and would keep serving live lookups. The revised SQL is
  idempotent and transactional; the route emits only a generic one-time legacy-schema warning
  and still falls back live. Before deployment, only fake-client transaction tests had run.
  The owner subsequently applied SQL in Neon and supplied the expected schema shape (§0D).
  That does not exercise the old-column upgrade on a real legacy PostgreSQL database.
- **Initial retention/privacy claim was too strong.** A one-day `expires_at` prevented stale
  reads but never removed device-coordinate rows. #7 added an authenticated daily DELETE
  cron; tests cover authorization, fail-closed missing secret, and delete. A deliberate
  `DELETE`→`SELECT` mutation made the new cron test fail before it was restored. This proves
  the test detects that code regression, not that production cron ran. Wording was changed
  from “stored up to 1 day” to serving TTL plus usually-under-two-days deletion with failure
  caveat. If `CRON_SECRET` is missing, configured-DB cleanup returns 503 and no deletion.
- **The early privacy classification was wrong.** Three-decimal coordinates are not
  automatically “Coarse Location” under Apple's definition, and iOS previously sent full
  precision before server rounding. #11 rounds on the client, but still labels Precise
  Location conservatively. The geocoder had accepted ambiguous country/postcode evidence;
  #11 now requires explicit US country and a complete ZIP/ZIP+4. Removing the new strict
  checks or client rounding in deliberate mutations caused focused tests to fail, then the
  implementation was restored. Vercel's platform logs remain unresolved by app code.
- **Real upstream data invalidated an overly narrow e2e assertion.** A shared-link test
  assumed Dover would always have locations; genuine data can return an empty state. #11's
  test now accepts either legitimate outcome while asserting the URL actually drives the
  search. Deliberately removing URL-driven behavior failed the test, then was restored.
- **Formatting defaults were dangerous.** Bare `swift-format` is not on PATH; Xcode's
  `xcrun swift-format` with default 2-space indent would rewrite the 4-space Swift tree
  (earlier audit: ~2471 findings versus ~228 with repo config). #9 pins configuration,
  separates a mechanical commit, and makes CI strict. Non-strict lint's zero exit despite
  findings was tested; strict lint failed on dirty input and passed on clean input. The
  branch is not ready until incoming Swift files are rebased/formatted.
- **Logging cannot be claimed end-to-end private from an app middleware test.** #10's
  deliberate scrubber bypass exposed ZIP, coordinates, upstream URL and key to the privacy
  test, which failed, and the bypass was reverted. That only covers **application** logs.
  Vercel may separately capture request query parameters. #10 also predates #7's new route,
  so its telemetry must be integrated and retested rather than merged unchanged.
- **Tool/environment failures are not product failures.** One local #10 server test needed
  a sandbox escalation for loopback; the rerun passed. #11's iOS runner initially could not
  reach CoreSimulator from the sandbox; approved reruns passed. Chrome/Vercel UI inspection
  did **not** establish the production env or schema. A read-only `gh pr list` retry on
  2026-10-03 could not reach api.github.com; use the last successful PR snapshot above and
  refresh when network is available. For this handoff edit, `git switch` initially failed to
  create `.git/index.lock` because `.git` was sandbox read-only; an approved scoped retry
  switched to PR #4 successfully. Keep these distinctions in any status report.

New failures and misleading signals from the 2026-10-03 integration session:

- **PR #7 conflicted after #11 merged.** `client/src/pages/PrivacyPage.jsx` and
  `ios/APP_STORE.md` had competing wording for hosting logs and coordinate retention. Merged
  `origin/main` into `feat/coordinate-aware-cache`, kept #11's wording (both resolved files
  matched main), tested, committed `63d9b79`, and pushed to the existing PR. GitHub changed
  from `CONFLICTING` to `MERGEABLE`; the owner then merged it. Do not resolve later conflicts
  by restoring the older anonymity/coarse-location or exact-one-day deletion claims.
- **Sandbox restrictions blocked Git and server tests.** Initial GitHub reads could not reach
  the network; `git switch` could not create `.git/index.lock`; `git merge` could not lock
  `ORIG_HEAD`; server tests failed with `listen EPERM`. Scoped approved retries succeeded.
  These were execution-environment failures, not regressions. Final server result was 50/50.
- **A log filter was mistaken for proof of a cron invocation.** Codex deliberately requested
  cleanup without an Authorization header; it returned 401. The owner then saw that same-path
  401 in Vercel logs. It was likely the test request, not evidence that the scheduled cron
  failed. Codex's test User-Agent was `Vote4U-deployment-check/1.0`; Vercel identifies scheduled
  invocations with `vercel-cron/1.0`. Log lists include all requests to the filtered path.
  Codex should have made that distinction clearer before directing the owner to View Logs.
- **Finding request details did not work for the owner.** The owner could not see a User-Agent
  or another scheduled run in the log view. Guidance switched to manually triggering the job
  from the Production deployment summary, after which the owner supplied two 204 entries.
  Their origin (manual versus automatic) was not independently established. Do not label
  these as proof of recurring scheduled delivery.
- **The database driver emitted an SSL compatibility warning.** The successful cleanup logs
  warned that `prefer`/`require`/`verify-ca` currently alias `verify-full`, with semantics
  changing in future major pg versions. Local dependencies were pg 8.22.0 and
  pg-connection-string 2.14.0. Advice was to make `sslmode=verify-full` explicit in the
  Production connection string and redeploy; the owner has not confirmed doing so. The 204
  remained a successful response. No connection string was requested or exposed.
- **A zero expired-row count is limited evidence.** No expired rows were documented before
  the owner ran the count query. Its zero result shows the database had no expired rows at
  that moment, not that a cleanup invocation physically removed any row.

### 0F. Validation that passed, with dates and limits

- During the October 3 #7/#11 conflict resolution, local server tests passed **50/50**,
  client lint passed, and Playwright built the client and passed **90 tests / 9 skipped** on
  desktop Chrome, iPhone Safari and Android Chrome. No new iOS test run was made by Codex in
  that integration session; #7's refreshed web CI subsequently passed.
- GitHub was checked on October 10: main at `b2209e3` has successful completed web and iOS
  workflows (§0B). No current-main tests were rerun locally for this documentation-only change.
- Production and owner-supplied Neon evidence are explicitly separated in §0D. Codex did not
  run a production migration or an authenticated cleanup request; public test ZIP requests
  exercised the normal cache-write path. The unauthenticated maintenance request was
  deliberately rejected before its DELETE path.

Earlier **isolated-branch evidence recorded before the October integration** is preserved
below. Its counts and branch bases must not be treated as current-main results:

- #4 (after its compatibility fix): required iOS 17.5 script passed notification allow and
  deny on throwaway, warmed simulators, 47 unit tests, 9 UI smoke tests, and Release DEBUG-stub
  grep. Built extension Info.plists identified iPhone **and iPad** in Debug/Release; iOS 17.5
  iPad simulator registered the WidgetKit extension. The widget's actual Home Screen placement,
  a physical device, and live scheduled-notification delivery remain untested.
- #7: local `npm test --prefix server` **46/46**; Playwright **90 passed / 9 expected skipped**;
  mutation proof for deletion as above. CI web/server/e2e/iOS checks last seen green. Database
  test doubles, not a real Neon/Postgres connection. No production SQL or cron had been
  observed at that pre-deployment check.
- #11: server **31/31**, Playwright **90 passed / 9 skipped**, required iOS 17.5 script passed
  31 unit, 9 UI, both notification paths and Release stub grep. Geocode/client privacy
  mutations failed focused tests; a shared-link mutation failed its e2e test. A later docs-only
  patch built the web client; CI last seen green. The iPhone-only Debug app also launched on an
  iOS 17.5 iPad simulator in a centered scaled compatibility canvas with black margins; this
  is **not** native iPad support and not a complete App Review 4.2 answer.
- #9: strict format audit, required iOS runner and PR CI passed on its branch. Its test count
  predates incoming widget/privacy Swift and is **not** a validation of those later files.
- #10: server **30/30**, Playwright **90/9**, mutation-tested scrubber, PR CI green; #7 route
  integration and platform-log behavior remain untested. CI does not run iOS for its
  server-only diff, by workflow path filter.

### 0G. The next step I would take

1. **Integrate draft #10 over refreshed main first.** On `feat/structured-logging`, merge main
   without rewriting published history, resolve `server/routes/polling.js` carefully and add
   shape-only logging for database cache hits/misses and maintenance outcome. Preserve the
   device cache read before reverse-geocoding, TTLs and auth/fail-closed behavior. Never log
   ZIP, lat/lng, place location fields, coordinate cache keys, upstream URLs, Authorization,
   client IP or raw DB Error objects. Cover the new route with privacy tests and a deliberate
   redaction-bypass mutation, restore it, then run server, client and Playwright checks. Push
   to the existing PR, update its description around the final behavior, and leave merge to
   the owner. #10's old green checks are insufficient for the new code.
2. **Finish draft #9 over all merged Swift.** Update `chore/swift-format` over current main,
   preserve its four-space config, format app, widget and both test targets, update strict CI
   coverage and the blame-ignore revision as needed. Inspect the diff for accidental logic
   changes. Run strict `xcrun swift-format` with repo configuration and the full required
   `scripts/test-ios.sh`, including the iOS 17.5 regression. Keep one Xcode process per
   DerivedData directory. Push to the existing PR and make it ready only after current checks.
3. **Prepare signing in a separate code PR.** The owner can add the Apple account in Xcode
   Settings → Accounts and confirm the available team. Set `M6L74ZB5KS` for the Vote4U app and
   Vote4UWidgets extension, ensure compatible automatic signing, and verify bundle IDs and
   signing for the intended build. A Team ID alone is not an installed signing identity.
   Continue with a physical-device install only when the connected device/account are
   available; document the exact outcome rather than claiming a build or upload happened.
4. **Close runtime and production gaps.** Check a genuine automatic cleanup invocation and
   safe aggregate expired-row counts; establish actual deletion with documented before/after
   evidence when expired rows exist. Resolve/verify the SSL warning and review Vercel platform
   log retention/linkage. On device, test ZIP after denied location permission, real GPS,
   offline saved place, notification delivery and widget Home Screen placement.
5. **Then prepare TestFlight/App Store.** Recheck current real-data screenshots and draft
   listing/privacy copy, record signing/archive/upload results, and perform final device QA.
   The owner controls publishing/submission; this handoff request does not authorize an upload
   or submission. Update this record with evidence and failures after each integration.

**Immediate owner tasks:** confirm Xcode sees team `M6L74ZB5KS`, check the next automatic cron
run, and confirm whether the Production SSL-mode update was performed. The owner has already
completed the reported SQL setup and merges #11/#7/#4; do not send them back to repeat those.
The next agent can finish #10 and #9 without waiting for device access when asked to continue.

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

## 2. Historical state at the 2026-09-21 rewrite (superseded by §0)

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
| **#7** | `feat/coordinate-aware-cache` | Device lookups get a real cache (§9E) | OPEN, no checks — see §9B |
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

## 4. Historical file map from 2026-09-21 (current map in §0C)

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

## 9. Historical next steps through 2026-09-24 (current next step in §0G)

**Current status (2026-09-24):** PRs #3 and #6 are merged; #4 remains open, so the
widget lives only on `feat/election-countdown-widget`. After #4 merges, pull `main` and re-run
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

### B2. App Store screenshots — **merged PR #3, 2026-09-24**

The five captured images were opened and reviewed, not merely generated. The Map shot now shows
the pinned search field; the News shot shows US midterm coverage; and the Vote shot shows real
90210 venues with the required “Not confirmed” label. The official-sources image is unchanged.
The capture date and copy in `ios/APP_STORE.md` came from PR #3. Always capture against the
deployed server and real data, never `-stubPolling`; re-check changing locations, countdowns and
headlines shortly before App Store submission. Earlier pre-capture theories in the old `main`
handoff were superseded by opening the actual images and are not carried forward here.

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

**In draft PR #9 (`chore/swift-format`), not merged.** `ios/.swift-format` sets 4 spaces and 120
columns; a separate mechanical commit is listed in `.git-blame-ignore-revs`; the CI job uses
`xcrun swift-format lint --strict` on `macos-26`. Local full iOS tests and PR CI passed. PR #4
and #6 add Swift files after its branch point, so rebase and format those files once they land.
Do not add SwiftLint or use swift-format's 2-space defaults.

### E. Server odds and ends

- ~~A coordinate-aware cache key so device lookups aren't cache-bypassed.~~ **DONE, PR #7.**
  The key is now the bare ZIP for a ZIP lookup and `@lat,lng` (3dp) for a device one, so the two
  kinds of row cannot collide. **The device key carries no ZIP on purpose:** including one forces
  a reverse geocode before the cache can be read, which is the exact request a hit is supposed to
  save. The first version did that and the test caught it — a hit still cost one upstream call.
  The cache read now happens before anything touches an upstream, and the ZIP comes back out of
  the cached payload's `place.zip`. Device rows live a day, ZIP rows a week.
  `zip_code CHAR(5)` became `cache_key VARCHAR(32)`; **existing row values need no rewriting**
  because their keys are already bare ZIPs, but the **schema migration must run before the new
  route is deployed**. On an existing database, `CREATE TABLE IF NOT EXISTS` does not rename the
  column; without the migration, cache queries fail and are silently skipped. Also add a purge
  path for expired device-coordinate rows: expiry currently prevents reads but does not delete
  stored location keys. Both are review blockers on PR #7, along with coordinating privacy copy.
  Migration in `server/db/migrations/`.
  Eleven tests in `server/test/pollingCache.test.js`, which installs a fake pool into the require
  cache before loading the app — without that the cache path is **dead code in tests**, since
  `DATABASE_URL` is unset and every request looks like a miss. `node --test` gives each file its
  own process, so the stub cannot leak into `api.test.js`.
  *Caveat worth keeping in mind:* Vercel's CDN already caches `?lat=&lng=` by URL for 24h, so the
  win is across regions and evictions, and in Nominatim load — the budget that actually binds.
- **Structured logging is in draft PR #10**, not merged. It adds request correlation, latency,
  cache/tier telemetry, and redacts location, key, URL, ZIP and IP from application logs. It
  cannot remove search parameters from Vercel Runtime Logs. PR #7 changes the route being
  instrumented, so integrate/retest after #7 is fixed and merged.
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

**The three earlier "verify rather than trust" items were checked in PR #11** (not merged):
`coordsToZip` now requires unambiguous US country/ZIP evidence, with mutation-tested cases;
the Coarse-Location-only argument was wrong because three-decimal coordinates are still Precise
Location under Apple's definition, and raw coordinates had been sent before server rounding;
and an iPhone-only build did launch in scaled compatibility mode on an iPad simulator. Native
iPad work remains substantial and does not itself solve guideline 4.2. See §12.
*(`ElectionCalendar`'s fidelity to `client/src/lib/format.js` is **verified** — the Swift port
matches the JS line for line, and `nextFederalElectionYear` in `newsService.js` now mirrors it too.)*

---

## 10. Historical owner blockers (verify current status in §0)

- **Apple Developer account is in verification.** No Team ID → no device build, no TestFlight, no
  submission. The owner has confirmed twice that they are still waiting and asked to keep
  progressing until something genuinely needs it. When it clears: Xcode ▸ Settings ▸ Accounts →
  add the account, set the team, or set `DEVELOPMENT_TEAM` and build with
  `-allowProvisioningUpdates`.
- **Google Civic key rotation and App Store skills are done:** the owner reports the key was
  rotated/replaced, and all four requested Claude Code skills were verified installed locally.
  The old key remains in git history; do not reuse it. Production `/api/elections` behavior and
  the upstream credential have not been independently verified here.

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

---

## 12. Codex session, 2026-09-24 — PRs #9–#11 and open-PR review

The owner-provided `~/codex-vote4u-prompt.md` asked for Tasks 1–5 in order, one PR per
implementation task, with no merge by Codex. `AGENTS.md` and §5/§7/§9 above were read first.
`origin/main` contained merged PR #8 at `e282e30` when these branches were cut. **No PR was
merged.** This section is on the newer `feat/election-countdown-widget` branch / PR #4, not on
the older `main` copy of this file; that is deliberate so the notes survive the rewrite.

### Work and evidence

- **Task 1:** The owner confirmed the leaked Civic key was rotated/replaced, installed all four
  App Store skills (verified locally), and merged PRs #3 and #6. No Apple account work was attempted.
- **Task 2 — [PR #9](https://github.com/ShyamRavidath/voting-finder/pull/9), draft:**
  4-space/120-column swift-format config, genuine code fixes for retroactive `URL` conformance
  and extension access, a separate formatting commit (`b16e8228190ffcbe8f6d71450a8b4124b3c10b39`)
  in `.git-blame-ignore-revs`, and a separate strict `macos-26` CI commit. Verified dirty lint
  exits 0 without `--strict` and 1 with it; clean strict lint exits 0. Required iOS script
  passed all notifications, 30 unit and 9 UI tests, and Release stub grep; PR CI is green.
  The bundled tool prints version `main`, so local Xcode 27 vs CI Xcode 26 is an ongoing risk.
  Wait for the new Swift files in PRs #4, #6 and #11, then rebase, format them, rerun.
- **Task 3 — [PR #10](https://github.com/ShyamRavidath/voting-finder/pull/10), draft:**
  dependency-free JSON-line API logging with Vercel request IDs, request timing and polling
  tier/cache telemetry. Application log values and Error objects are scrubbed by key and free
  text; warn goes to stdout; tests are silent under `NODE_ENV=test`. A deliberate bypass of
  the text scrubber failed the privacy test with ZIP, coordinates, URL and key visible; reverted.
  Server tests 30/30, Playwright 90 passed / 9 expected skips, PR CI green. Initial local
  server test was blocked by loopback sandboxing; escalated rerun passed. Vercel independently
  captures query parameters, so the PR **does not** mean location is absent from platform logs.
  Rebase/integrate route instrumentation after PR #7 is fixed and merged.
- **Task 4 — [PR #11](https://github.com/ShyamRavidath/voting-finder/pull/11):**
  `coordsToZip` rejects a missing/non-US country and ambiguous postcodes, accepts a complete US
  ZIP+4; the new hermetic tests failed against deliberate loose-regex and missing-country
  mutations. Native device coordinates had been sent at full precision; `APIClient` now rounds
  to three decimals before constructing the URL, and its test failed against deliberately raw
  coordinates. Updated `ios/APP_STORE.md` and the web privacy page because Vercel logs search
  params and three decimals still meet Apple's **Precise Location** definition. Labels are
  conservative drafts pending production host retention/linkage review. Server tests 31/31,
  Playwright 90 passed / 9 expected skips, required iOS script on iOS 17.5 passed 31 unit,
  9 UI, both notification directions, and Release stub grep. Initial iOS runner could not
  reach CoreSimulator from the sandbox; escalated reruns passed. An iPhone-only Debug build
  installed/launched on an iOS 17.5 iPad Pro 11-inch simulator; Map rendered in a centered,
  scaled iPhone compatibility canvas with wide black margins. Native iPad support would need
  actual layout and accessibility work and does not independently fix App Review 4.2.

### Open PR review (comments already posted on GitHub)

- **#3 screenshots: mergeable.** All five assets opened; real venues are visibly hedged “Not
  confirmed”, Map has the pinned search UI, News remains last. Native `codex review` found no
  actionable issue. Recheck live data, countdown and headlines near App Store submission.
- **#6 electoral-map render tests: mergeable.** The test-only diff, mutation evidence and CI
  are sound. Native review built tests (after a Swift macro sandbox workaround) and found no
  actionable issue, but could not run a simulator there; CI did run them. Formatting will be
  needed for PR #9.
- **#4 widget: hold.** The widget extension targets device family `1` only; Apple's App
  Extension Programming Guide says extensions must target iPhone and iPad even when the app is
  iPhone-only. The circular accessory also displays `0 days` on Election Day while other
  families say `Today`. Fix both and rerun the required iOS script; the widget actually being
  placed on a Home Screen remains unverified. Comments are on PR #4.
- **#7 coordinate-aware cache: hold.** Existing database deployments need the included
  migration **before** the new route; `schema.sql` alone leaves the old column and silently
  disables caching. Expired one-day device-coordinate rows are never deleted. Coordinate keys
  and request params contradict old privacy claims, addressed in PR #11 but requiring merge
  coordination. `codex review` independently found the migration and retention issues.

Suggested owner-controlled order: merge #3 and #6 when convenient; merge #11 before enabling
the coordinate cache; fix and merge #4 and #7 in either order after their blockers clear;
then rebase/format #9 over all incoming Swift files and integrate/retest #10 over #7. Do not
merge #9 or #10 as-is while their dependencies remain open. Do not infer green CI means the
widget can appear or the existing database was migrated.

### Still unverified / owner decisions

- Civic key rotation, Vercel environment setting and any desired history rewrite; until fixed,
  the official tier remains unavailable in production. Never commit the key.
- Actual Vercel log retention/linkage and the final App Store Connect privacy answers; app-level
  redaction cannot alter platform request logs. Any PR #7 coordinate-cache deployment needs a
  migration and deletion/retention verification.
- Apple Developer account, device build, GPS, real scheduled notification delivery, widget Home
  Screen placement, full iPad interactions/accessibility, TestFlight and submission.
- `ios/.swift-format` must be checked again after PR #4/#6/#11 Swift files arrive. Do not run
  the formatter with its 2-space default or replace `scripts/test-ios.sh` with a bare build.
