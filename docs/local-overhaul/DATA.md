# Portland directory and meetings

`GET /api/local-feed` serves three independently dated collections. It fetches only fixed
`https://www.portland.gov` paths. User search terms, following choices, ZIPs, and coordinates
are not part of this request. Search matches titles and descriptions locally, including simple
plural handling and ordinary filler words. It is a directory search, not an AI diagnosis or a
promise that an agency will resolve a concern. The 311 and official search links remain available.

- Services: `/services`, all numbered pages (currently 23, 567 records). In-memory cache: 24h.
  Pagination is bounded to 40 pages, four concurrent page requests, complete-count and duplicate
  checks. A partial crawl never replaces the last complete directory.
- Meetings: `/council/events` and `/council/events/past`; recent public listings only, not a complete
  historical archive. Recesses and executive sessions are excluded. The official full calendar
  is linked. In-memory cache: 15m.
- Actions: `/council/agenda`; recorded council actions and notes from the latest completed sessions, with
  dated agenda, document and available recording links. This does not cover every committee or
  infer final approval from a scheduled meeting or second reading. If the current agenda has no
  recorded past action yet, the adapter tries up to three previous dated links published on that
  page. It retains one latest recorded step per document. In-memory cache: 15m.

The old `/api/local-civic` endpoint and catalog remain for older app versions and the three
explanatory guides. New meeting and outcome screens use the live feed. Existing saved guides
are retained. Their editorial check dates are not advanced by the importer.

Each import has a 22-second deadline, 2 MB per HTML page limit, HTTPS/host checks and no redirect
following. Responses use a 1-minute client cache and 15-minute shared CDN cache, with up to one hour
of stale-while-revalidate. Original source dates remain visible. See [Vercel caching](https://vercel.com/docs/caching/cache-control-headers). Concurrent requests in an instance share
one import. These caches are per server instance; no new database or paid service is required.
A cold service starts from `server/data/local-feed.json` if sources fail. Both server and iPhone
preserve the original `fetchedAt`, mark saved data, and avoid overwriting newer sections with an
older copy. A parser failure does not mean the city has no meetings.

Calendar saving requires a currently listed, scheduled, future meeting checked within 24 hours.
Past, cancelled, postponed, unlisted, future-dated or stale records cannot create events. A saved
calendar event is a copy and does not update. Followed meetings remain on-device after they leave
the recent listing, with their original source link and calendar saving disabled until listed again.

## Renewing the offline snapshot

Run `node scripts/update-local-feed.js` from the repository root. All three collections must
succeed before the script writes either JSON copy. Review the diff, run server tests and the
native runner, and commit both copies together. Source titles/descriptions are attributed to
Portland.gov through each record's direct link. `server/test/fixtures/local-feed/` contains
public markup extracted November 24, 2026, without global scripts or tracking settings.

First live import: 567 services, 35 public meetings, 6 council actions in about 11 seconds.
The source explicitly recorded Stark/Washington as “Passed to second reading,” with a December 2
reading. The previous static record's November 19 schedule is not current evidence.

## Deployment

The backend endpoint becomes public only after the owner merges/deploys the PR. A native test
build against the existing production URL uses its bundled snapshot until that happens, and
reports the failed refresh. Do not claim that a local server test proves production refresh.
The fallback allows browsing, search and local following offline. No App Store upload or release
is included in this change.
