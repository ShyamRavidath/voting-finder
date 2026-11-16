# Local civic decisions pilot

Implemented on `feat/local-civic-decisions`, based on main `b067f77`.

## Scope and experience

Native iOS, iOS 17+. Portland, Oregon is an explicitly selected, limited pilot. The owner
requested the first two ideas from the November 15 handoff; Portland/native-first are
implementation assumptions, not evidence of market validation or a nationwide dataset.
No geolocation or ZIP inference is used. The existing voting features remain available.

1. **Who can actually fix this?** Search three concern guides: street safety, nonprofit
   affordable-housing tax exemptions, and TriMet service. Each explains responsibility,
   jurisdiction limits, the decision process, a legitimate action, and source freshness.
2. **Before they vote.** Follow concerns locally and filter their reviewed agenda summaries.
   Open the proposal, change from existing policy, session start, separately labeled virtual
   sign-up deadline, participation instructions and original documents. Save a session through
   the system Calendar editor. Sourced outcomes can be published in later catalog revisions.

Following delivers an **in-app feed refreshed on opening/pull to refresh**, not background or
push alerts. The screen says this explicitly. No claim of continuous monitoring. Calendar
copies are static and explicitly say they do not update; users confirm the official agenda.
Calendar UI asks the person to save/cancel and never reads their calendar or requests full access.
This follows [Apple’s iOS 17 EventKitUI guidance](https://developer.apple.com/documentation/technotes/tn3152-migrating-to-the-latest-calendar-access-levels).

## Source audit (checked November 15, 2026 Pacific / November 16 UTC)

| Source | Supports | Caveat |
| --- | --- | --- |
| https://www.portland.gov/transportation/823-safe | PBOT non-urgent safety intake, engineering/funding limits | Not an emergency reporting tool |
| https://www.portland.gov/transportation/vision-zero/high-crash-network-streets-and-intersections | Some roads belong to ODOT/County | No address-to-owner resolver |
| https://trimet.org/about/governance.htm | Board policy authority, management role | No reviewed TriMet agenda item in this pilot |
| https://go.trimet.org/pdfs/code/TriMet_Code_Chapter_2.pdf | General manager and Board roles | Check current meeting instructions separately |
| https://www.portland.gov/council/agenda/2026/11/18 | Nov 19 session at 2 p.m. Pacific, listed items | Item order/timing may change |
| https://www.portland.gov/council/documents/ordinance/stark-washington-safety-project | 2026-401 acquisition proposal; Nov 10 rescheduling; Nov 19 listing | Property rights authorization is not project completion |
| https://www.portland.gov/council/documents/ordinance/nplte-code-ordinance | 2026-346 sunset change and committee referral | Recommendation is not final adoption |
| https://www.portland.gov/auditor/council-clerk/engage-council | Participation rules, one-hour virtual sign-up cutoff | Check item eligibility; written testimony deadline differs |

Records use short paraphrases and links, with no redistributed images or full documents.
No commercial API, API key, scraping service, or recurring paid service is introduced.
Public access was verified; broad redistribution rights and automated-access permission have
not been established, so this is a curated link-and-summary feed, not a document mirror/scraper.
The initial set contains selected real items, not synthetic examples or a complete agenda.

## Publishing and maintenance

Canonical content: `server/data/local-civic.json`. `GET /api/local-civic` returns that public,
reviewed catalog with five-minute cache headers and no upstream requests. The same JSON is
bundled at `ios/Vote4U/Resources/local-civic.json` for first launch/offline use. A server test
requires byte-for-byte equality. Refresh downloads the common catalog, never a user's query,
follow list, address or location. Local defaults store the selection, follows and last good feed.
Existing hosting may retain ordinary request diagnostics; this feature adds no request logging.

Maintainer responsibility is **not yet assigned**. Before exposing a fresh catalog, a maintainer
must open the official agenda, original item and participation instructions, resolve conflicts,
then update `checkedAt`, `reviewBy`, `publishedAt`, dates and statuses. Do not simply extend
review dates. Recommended cadence: every business day for near-term items and again on the
meeting day; monthly for authority guides. Actual ongoing editorial effort is unmeasured.

- Decision review windows are capped at 7 days; authority guides at 31 days.
- Passed, cancelled, postponed, future-dated or expired records cannot create calendar events.
- Missing sign-up deadlines stay explicitly unknown; never derive a written deadline from
  the virtual registration cutoff. The initial virtual cutoff is derived from the official
  session start and the explicit one-hour rule, not an estimated item start.
- Update `status` to `cancelled` or `postponed` when appropriate. Publish an outcome only with
  `status: "decided"` plus `outcome: { summary, recordedAt, source: { title, url } }`.
  Distinguish an adoption vote from funding or completion in that summary.
- Keep historical records so the history filter can show them. Recheck outcome sources as
  amendments occur. The app does not let residents invent an official outcome.
- Missing/invalid/older feeds keep the last good catalog and show an explicit refresh warning.
  The client allows only the pilot's official HTTPS source hosts and validates references,
  unique IDs, review windows, timezone and deadline ordering.

After editing, copy the canonical JSON to the iOS resource, run server tests and the required
native runner, then branch → commit → push → PR. Owner merges; no release is implied.
The remote endpoint will not exist on production until this PR is deployed; the app's bundled
fallback works before that and explicitly reports refresh failure.

## Validation

The final iOS 17.5 mandatory runner passed 88 tests (72 unit, 14 UI, allow and deny), with
zero failures/skips; Release stub-string and widget family checks passed. Server tests passed
55/55. Strict formatting on changed Swift files and whitespace checks passed. New tests
cover catalog contracts, stale/cancelled/postponed events, unknown jurisdiction/source rejection,
source-backed outcomes, following persistence, refresh fallback/rollback, native navigation,
large text, calendar cancellation and saving, and API delivery. Calendar delivery to a real account,
physical-device behavior and ongoing editorial maintenance remain separate verification.

## Simulator screen review

Captured from the passing iOS 17.5 UI run on November 15. These use the real, dated pilot
catalog and are development review artifacts, not App Store marketing captures.

[Authority guide](screenshots/local-civic/authority.png) · [Decision explanation](screenshots/local-civic/decision.png)
