# TestFlight build 3 — October 18, 2026

Source: merged main `92952d14ffd08d0068057a8eb3da555d98526f1e` (PR22).
The archive was created from a clean detached checkout before this evidence-only branch.
Version 1.0, build 3; Xcode 27.0 (27A266a); iOS deployment target 17.0.

## Validation

PR22 server, client and Playwright checks passed. Local iOS 17.5 mandatory runner passed
80 tests. The earlier local iOS 27 run failed during final runner bootstrap; it is not a pass.
GitHub Actions run 39177563384 used iOS 26.5 / iPhone 17 and passed the mandatory runner,
including both notification decisions, Release fixture exclusion, widget families and registration.
App source is identical between PR head 8212e08 and merged commit 92952d1.

Signed archive and App Store distribution export succeeded. Deep strict signature verification
passed. App and widget versions match (1.0/3); app family is iPhone, widget families iPhone/iPad.
Privacy manifest is present and parses. Exported app/widget profiles belong to M6L74ZB5KS,
exclude development debugging and device restrictions, and expire October 11, 2027.
Release binary excludes APIStub/stubPolling/stubNews/news endpoint/NewsView strings.

Archive: `/private/tmp/Vote4U-main-92952d1-b3.xcarchive`.
Local export: `/private/tmp/vote4u-testflight-export/Vote4U.ipa`.
Local IPA SHA256: `427be6f9d7b3b45a204cd36fdf064a518dc38a696c878ad01df78bdd2d745876`.
Upload uses that archive with automatic signing and automatic build-number changes disabled;
Apple may repackage it, so the local IPA checksum does not identify Apple's processed binary.

## Store state

No-news description and review notes saved; secondary category None saved.
Existing privacy, rights, contact, US-only free pricing and manual-release settings retained.
TestFlight showed No Builds before upload, establishing build 3 was unused.
After processing, build 3 was selected on App Store version 1.0 and saved. Manual release
remains selected; no compliance error was displayed. No review submission was performed.
Production `/api/news` and refresh both return empty articles; response is no-store.

Upload succeeded at 17:51:19 PDT on October 18, 2026. Xcode confirmed the package began
processing. App Store Connect subsequently showed version 1.0 build 3 as Ready to Submit,
expiring in 90 days, with no processing errors. No testers were invited at this point.
All old four-tab screenshot references were removed from the listing. Four large and four
medium three-tab screenshots passed visual review and were uploaded. A final page reload
verified 4/10 medium and 4/10 large, ordered results, Home, Map, official sources. The medium Map came from a fresh simulator.
Repeated headless official-source captures lacked the status bar; these were rejected.
Xcode 27 exposes the simulator through **Device Hub**, not a separate Simulator app here.
Sol selected the booted iPhone 17 in Device Hub, restoring the correct layout/status bar;
a subsequent simctl capture passed review. No image was composited or retouched.

No TestFlight group/testers are configured yet. Owner confirmation for an invitation to
`ravidath@gmail.com` is pending; no invitation was sent.
No App Review submission or public release is authorized by this evidence record.

## Physical-device checks still required

Install the processed build from TestFlight on the owner's iPhone. Check denied/revoked-location
ZIP search, actual GPS, official-source links, saved locations and warning text after an offline
relaunch, widget placement/opening, delivered notifications, large text, dark mode and VoiceOver.
Simulator queue assertions do not prove delivered notifications. Do not submit to App Review
until remaining release declarations and device checks are complete.
