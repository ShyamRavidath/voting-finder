# Local overhaul

Owner request: make Local useful, clear, and less generic; fix search limited to three examples,
old meeting data, buried links, redundant warnings, and unclear following. Apply clearer copy
and a consistent native design to the other pages. Confirmed preference: “less boring, but not
too complicated.” Humanizer supplied by the owner: https://github.com/blader/humanizer.

## Direction

Keep the existing native iPhone navigation and blue action color. Give the work three clear
places: Get help, Meetings, Following. Use semantic surfaces, stronger headings, generous
spacing, and concise action labels. Replace the washed-out page gradients and decorative
countdown watermark. No new branding, custom navigation, illustrations, or web-like controls.
This extends the native identity; the separate web redesign checkout is untouched.

First viewport: Portland title, three-way native section control, a usable directory search and
real service links. Meetings puts upcoming/past selection and recent council actions above the
list; each meeting exposes Follow and a detail screen with the source link and calendar action.
Following keeps saved meetings visible after they roll off the city's recent listing.

The meaningful interaction is following a meeting, then finding it again after relaunch and
seeing changed source details after refresh. It is local storage with foreground refresh;
there are no push notifications or accounts. Search runs entirely on the phone.

## Evidence and boundaries

The public Portland directory and calendar are actual data sources. The legacy documented
council API no longer resolves. The HTML adapter fails closed on missing markup, dates, page
counts, unsupported links, and duplicate directory records. Original titles and council actions
remain sourced; a procedural step is never promoted to final approval.

The app is iPhone-only, with iOS 17 minimum. The existing widget supports iPhone/iPad and is
not redesigned. Verify iPhone light/dark and largest text; use the mandatory simulator runner.
Preserve polling warnings, ZIP entry, results ordering, offline saving, and reminder allow/deny.
Review is code-led; no visual comp was approved. Native review skips the HTML/CSS detector.
