# Version 1 without aggregated news — October 18, 2026

The owner selected removal of aggregated news for version 1 rather than shipping without
established redistribution permission. Apple 4.2 requires adequate utility and 4.3 discourages
indistinguishable apps, but neither requires news; 4.2.2 specifically cautions against apps
primarily made of aggregated content. Approval remains Apple's determination.

Native utility remains: local election reminders, Election Countdown widget, offline saved
locations with warnings preserved, and the bundled interactive electoral map. ZIP lookup
continues to work without location permission. Nearby buildings remain unconfirmed and are
not asserted to be assigned polling places.

## Change

- Native app has Home, Vote and Map tabs. News views, API client, models, fixtures and in-app
  article browser are removed; no hidden switch can reactivate the feed.
- Website removes News navigation, page, homepage link and marketing claims. An old `/news`
  bookmark reaches the normal not-found page with a route back to the voting tools.
- `/api/news` remains for older clients, returning an empty `articles` array and `no-store`.
  It neither fetches publisher content nor reads stored headlines, including refresh requests.
  The unused database table is not dropped; old data deletion is separate operational work.
- Listing draft removes the News category and claims, and explains native utility to review.
  No age/privacy/content-rights declarations are automatically changed: remaining map/data
  sources and external links still need truthful final answers.

## Release checks remaining after merge

Verify deployed `/api/news` (including refresh) returns no articles and no stale CDN content.
Finish saving the no-news App Store description/review notes and remove secondary News category.
Remove all eight previously uploaded four-tab screenshots and upload reviewed three-tab captures.
Only visually accepted captures belong in this branch; complete any missing views before submission.
Review age/content-rights declarations against this final app, preserving actual privacy facts.
Archive clean integrated source; verify signing/widget/Release exclusions; upload with owner
approval, verify processing and test the distributed TestFlight build on the owner's iPhone.
This PR does not submit or release the app.

## Browser work

PR21 support email is live and the Support URL was saved/reloaded successfully in App Store
Connect. Contact/copyright, free US-only availability, manual release, prior screenshots and
listing text were previously saved. During the no-news metadata update, active user browsing
interrupted the Sol agent: Description was edited but not saved, Notes unverified, secondary
category unchanged. Inspect the pending form before any further navigation or save.

## Validation

Server: 52 passed. Browser: 83 passed, 7 expected skips. Client lint/build passed.
Required native runner: 80 passed on iOS 17.5 with Release fixture/widget checks.
iOS 27 passed allow, 66 unit and 12 smoke tests, but Xcode diagnostics timed out and
the deny test runner crashed before bootstrap; no full pass or iOS 27 Release check.

Screenshot capture intermittently produced black images or missing status bars. Reboot and
settling delays helped only intermittently. Rejected captures are excluded, not edited to
simulate a correct UI. Four large captures and medium Home/Vote captures passed visual review.
Missing medium Map/official-source views remain to be captured.

Results are also recorded in the PR and the current HANDOFF checkpoint. Test logs are temporary
under `/private/tmp/vote4u-no-news-*`; do not confuse simulator validation with TestFlight proof.
