# Release trust and privacy fixes — October 11, 2026

This is the first implementation batch following `docs/OPUS_RELEASE_REVIEW.md` on PR #15.
Base: reviewed candidate `e39eeeb` (includes PR #14). Work is isolated on
`fix/release-trust-and-privacy` at `/private/tmp/vote4u-release-fixes`.
The original documentation checkout and ultrareview worktree remain untouched.

## Changes

- **OPUS-2 / OPUS-10:** No search keyword creates a voting-role label. Building kinds come
  from returned OpenStreetMap tags, otherwise the label is “Nearby building”. Entertainment
  venues are rejected. Results require their own state to match the search state; missing
  state evidence is rejected rather than filled in from the ZIP. Both search tiers apply this.
- Both clients lead fallback results with official lookup links, state that there is no
  voting evidence, and separate nearby buildings from voting recommendations. Empty results
  no longer falsely claim that official data was checked when the deployment is keyless.
- Cache payload version 2 causes existing database rows to be refreshed before serving them.
  Old CDN labels and saved iPhone labels are neutralized at display/share time. The cache-key
  format and existing retention/cleanup mechanism are unchanged; no SQL migration is needed.
- **OPUS-3 / OPUS-4:** The permission string explains server/OpenStreetMap transmission,
  caching and hosting logs, with ZIP as an alternative. Home provides Privacy policy and
  Support links. The policy now names Neon and explains device-centered bounding-box searches.
  Support uses the existing GitHub Issues destination, which still requires an account to post.
- **OPUS-5:** Store description/review notes and the web About page describe the keyless
  behavior. The existing store screenshots are explicitly marked for replacement after deploy.
- **OPUS-13, partial hardening:** A nonofficial response cannot become confirmed through
  conflicting per-location flags. Decoded native results and web results normalize that
  evidence before rendering/saving. This does not establish ZIP-level assignment for Civic.
- **OPUS-17:** Offline availability uses a neutral storage glyph instead of a green check.
- **UR-1 / UR-2:** Preserved the ultrareview's popup-width helper and distinct denied-reminder
  warning. Copied the exact two edits from its dirty worktree; did not reset or commit that tree.
- **OPUS-26:** Ignore superseded web results after body decoding as well as during fetching.

## Verification

- Server: 55 passed, 0 failed/skipped, with stubbed upstreams and database.
- Mutation checks in a separate temporary server copy: restoring a misleading library label
  fails the API assertion; removing the state guard fails both out-of-state and missing-state
  tests. No deliberate mutation was applied to the candidate.
- Full Playwright: 96 passed, 9 deliberate skips (mobile duplicate API checks and deployed
  headers). Fresh servers from this worktree; no reuse of pre-existing servers. The suite
  still uses its configured relaxed local rate limit, so this does not validate production
  rate limiting. After final wording changes, polling/static-page checks: 57 passed.
- Production client build and the configured client linter (`oxlint`) passed. Phone (390 px) and desktop (1440 px) screenshots visually
  inspected after animations settled. They use clearly identified QA fixtures, not store art.
- Native iPhone SE (3rd generation), iOS 17.5: mandatory runner passed 72 tests
  (57 unit + 13 smoke + allow + deny), zero failures/skips. Release stub and widget-family
  checks passed. The Home privacy control was tapped successfully and opened Safari; its
  screenshot, the saved-card warning, and the largest-text result were visually inspected.
- Native iPhone 17 / iOS 27: mandatory runner passed the same 72 tests, zero failures/skips;
  Release stub and widget-family checks passed. Runs were sequential with separate DerivedData.
- Strict swift-format passed for all 12 changed Swift files using the existing 4-space configuration from PR #9;
  this is not a claim that the entire branch passes strict lint.

### Failed attempts and limitations

- Server tests could not open a loopback listener in the sandbox; the escalated run passed.
- First iOS 17.5 attempt passed 57 unit tests and 12 existing smoke tests, but the new privacy
  test incorrectly queried the SwiftUI control as an XCTest `Link`. Changed to its exact
  accessibility identifier. That failed run did not reach denial or Release checks.
- The initial browser screenshot was captured during the fade animation; recaptured after
  settling and inspected both widths.
- No production deployment, database inspection, App Store upload, or TestFlight test happened.

Local evidence: `/private/tmp/vote4u-release-server-final.log`,
`/private/tmp/vote4u-release-web.log`, `/private/tmp/vote4u-release-web-final.log`,
`/private/tmp/vote4u-release-ios175-final.log`, `/private/tmp/vote4u-release-ios27.log`.
The isolated DerivedData directories are `/private/tmp/vote4u-release-fix-se175` and
`/private/tmp/vote4u-release-fix-ios27`. The earlier failed selector log is preserved at
`/private/tmp/vote4u-release-ios175-selector-failure.log`.

## Integration and remaining release gates

The fix branch contains `e39eeeb`, so it includes the polish missing from main. Merge PR #16
first, then the fix PR into main. Both target main; this avoids repeating the earlier mistake
of merging new work into a release branch after its integration PR had already merged.
No merge or production configuration change is authorized by this document.

Keep Google Civic disabled. OPUS-6/11/12 (assignment, date boundary and cache/error behavior)
still block enabling it. The “official” per-location contract should be strengthened as part
of that work; this batch only hardens nonofficial responses.

Next code work: Home Election Day wording, reminder foreground/2028 rollover and revocation,
real-clock-safe notification tests, and the safe database pool error listener. Preserve the
remaining Opus ledger, including news-source/party-label concerns, routing, latency and weak
test assertions; this batch does not claim to resolve the whole review.

After owner merges: verify the actual deployed SHA and version-2 payloads (including CDN-served responses), inspect Vercel's
routing incident/cron history and retention, refresh affected store images from real data,
finalize listing/privacy answers, bump the build number and create a fresh archive from a clean
commit. Preserve old archives as evidence. Upload/process/install via TestFlight, then record
physical-device denial/revocation, saved-place cold launch offline, delivered notification,
widget and accessibility checks. Local test passes are not submission approval.
