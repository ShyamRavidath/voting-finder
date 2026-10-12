# Vote4U visual review — 2026-10-10

Branch: `feat/visual-ux-polish`, based on `release/ios-signing-validation` (PR #13).
The owner merges these changes before deployment.

## Findings and changes, by impact

1. **Location denial looked like the whole search was broken.** iOS now explains that location
   access is optional and points directly to ZIP entry. The new UI regression denies the system
   prompt, enters a ZIP, searches, and checks the unconfirmed result label.
2. **Saving was undiscoverable.** The owner found the widget but could not find Save. Result maps
   now expand on demand; each iOS result has a full-width “Save for offline” action. Home explains
   the flow; saved cards say “Saved for offline” and retain the warning and official lookup.
3. **Warnings lacked contrast and consistent evidence.** iOS uses primary text on a pale amber
   background. Web cards, map pins and popups require explicit confirmation evidence. Missing
   flags remain unconfirmed. The estimated-source notice no longer assumes official data has
   not been published.
4. **Mobile map popups clipped.** Width follows the map container; recentering finishes before
   popup auto-pan. Controls moved to the lower right and have 44-pixel touch targets. A new
   browser regression checks that the complete popup fits within the map.
5. **Web hierarchy and dates were inconsistent.** Home now prioritizes a voting plan and uses
   the existing live election countdown. News has a year-neutral heading. The 2028 Electoral
   College baseline remains explicitly a static illustration. News is the last navigation item.
6. **Dark appearance and supporting copy.** A lighter dark-mode accent improves link visibility;
   primary actions retain a separate blue fill. Supporting text in the revised cards has higher
   opacity.
7. **Largest accessibility text.** The first small-phone screenshot exposed a hyphenated
   “Not confirmed” badge despite a passing reachability test. At accessibility sizes the badge
   now uses the full width and action labels omit decorative icons to preserve word fit.
8. **Layout and action hierarchy.** Search and official sources sit alongside each other on
   desktop and stack on phones. Native search/actions stack at accessibility text sizes, and
   ZIP entry includes a keyboard Done action. Countdown art is smaller and uses a calendar.

## Visual method

Used the requested Imagegen skill for a labelled design exploration, then inspected the generated
concept and actual application screenshots. The concept informed blue action hierarchy, calm
amber warnings and grouping. No generated account controls, fictional venues, editorial imagery
or bitmap UI shipped. Production UI remains native SwiftUI/HTML/CSS.

Local web captures: 320, 390, 768 and 1440 pixels, including Home, Vote, Map, News, real ZIP search
and map popup interaction. All four widths had no horizontal document overflow. The screenshot
loop caught popup clipping and control overlap; both were revised and rechecked. Full-page
mobile captures show the fixed bottom navigation at the original viewport boundary; content
continues to scroll behind it with bottom clearance.

Selected captures:

- [Final native Home](../ios/screenshots/2-home-countdown.jpg)
- [Final native dark Vote](ui-review/ios-vote-dark.jpg)
- [Desktop Home](ui-review/web-home-desktop.png)
- [Desktop search](ui-review/web-vote-desktop.png)
- [Mobile results](ui-review/web-results-mobile.png)
- [Small-phone popup](ui-review/web-popup-small.png)
- [iPhone SE result actions — QA fixture](ui-review/ios-qa-result-save-action.png)
- [iPhone SE saved warning — QA fixture](ui-review/ios-qa-saved-place-home.png)
- [Largest accessibility text — QA fixture](ui-review/ios-qa-accessibility-result-actions.png)

The three native QA captures above use DEBUG test fixtures and are **not App Store images**.
The final largest-text screenshot was inspected: the warning keeps whole words, Save wraps at
word boundaries, Directions fits, and all controls remain reachable by scrolling.

## Validation record

- Server: 50 tests passed.
- Strict Swift formatting passed for the revised files except the existing URL retroactive
  Identifiable conformance in NewsView.swift; this pre-existing lint rule remains reported.
  Four-space formatting is preserved.
- Initial browser run exposed stale Home headline assertions and was built before the final
  popup warning implementation. Assertions were updated; a fresh final run follows below.
- iOS simulator location denial → ZIP search and saved-place warning after relaunch passed.
- Full browser suite: 93 passed, 9 expected skips. Final polling/accessibility subset: 54 passed.
- A repeated local run hit HTTP 429 after intensive QA (8 failures); restarting the local server
  with the suite's RATE_LIMIT_MAX=5000 resolved it. Production rate limits were not changed.
- Popup resize from desktop to 320 pixels passed with a QA-only response. A live resize attempt
  had no popup because the upstream search returned an honest empty result; it was not treated
  as visual proof.
- Initial iPhone 15 Pro / iOS 17.5 runner: 55 unit + 11 smoke + 2 permission tests passed;
  Release stub exclusion and widget device-family checks passed.
- Final iPhone SE (3rd generation), iOS 17.5 runner: 55 unit + 12 smoke + 2 permission tests
  passed (69 total), with Release stub exclusion and widget-family checks.

## Owner device observations

The owner confirmed real Home Screen widget placement. A ZIP search returned cautiously labelled
approximate venues. Returning in airplane mode preserved the current screen, but Save had not
been tapped; this does not prove saved-place persistence after force quit. Test the new explicit
Save action, force quit, enable airplane mode and relaunch. Official lookup and directions still
require network/service availability.

## Delivery

Build 1.0 (2) is installed on the owner’s iPhone. The final signed archive and distribution IPA
are recorded in `ios/RELEASE_VALIDATION.md`. Five new live-data JPEG store captures were
visually checked and verified at 1320 × 2868 without alpha. No upload, submission, or publication
has occurred; owner-controlled merges and the remaining release checklist still apply.
