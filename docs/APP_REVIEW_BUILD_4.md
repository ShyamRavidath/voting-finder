# App Review preparation — build 4, November 2, 2026

Source: clean merged main `b067f7753e18f9f17d9f8f26ace89d04fd21657a` (PR24).
Version 1.0 (4). Results now precede the optional map, detailed warning and official links.
Per-card, save and share trust warnings remain. Empty-result official guidance is unchanged.
The owner explicitly authorized submission; public release remains manual.

## Validation and upload

Required local iOS 17.5 runner passed 80 tests: 66 unit, 12 smoke, notification allow/deny.
Release fixture exclusions and widget family checks passed. The new smoke assertions verify
that the first result is visible without scrolling and above the detailed warning.
Main web CI 41589407350 passed. Native main CI 41589407365 and PR CI 41589117019 passed on iOS 26.5 / iPhone 17,
including the mandatory runner, Release checks and widget registration. App/test/workflow
source is identical between tested PR head 2bb72f1 and merged b067f77.

Archive: `/private/tmp/Vote4U-main-b067f77-b4.xcarchive`.
Export: `/private/tmp/vote4u-b4-export/Vote4U.ipa`.
SHA256: `63e13f05400011a2a96708e2456691c725d99a8aedfa465252f0f1284b4097ba`.
Apple may repackage the upload; this identifies only the local IPA.
Deep strict signature verification passed outside the keychain-restricted sandbox.
App and widget are 1.0/4; app family iPhone, widget families iPhone/iPad; minimum iOS 17.
Distribution profiles exclude development debugging and device restrictions.
Privacy manifest parses; Release binaries exclude DEBUG polling fixtures and removed news UI.

Initial export was blocked by Apple's updated Program License Agreement. The owner accepted
it, then export succeeded. Upload completed November 2 at 22:28:30 PDT. App Store Connect
processed build 4 to Ready to Submit, UUID `b40674e6-9ddd-4beb-968a-5bcdd3b70118`.
Build 4 was selected and saved on version 1.0; manual release retained. Build 3 remains in
the account. Submission is confirmed below.

## Screenshots

Four screenshots per size, ordered results, Home, Map, official links. Dimensions 1320x2868
and 1206x2622, JPEG without alpha. Updated results/Home/official captures use production data,
not DEBUG fixtures. Unchanged map captures were retained after visual inspection.
Some headless captures omitted the status bar and were rejected. Device Hub captures fixed
those images; only format conversion was applied, without compositing or retouching.
All eight final assets were visually reviewed. Both sets were uploaded; a page reload
verified four medium and four large screenshots in the correct order. Apple initially
blocked Add for Review while screenshot processing was still pending.

## Device evidence limits

Owner tested build 3 on iPhone 15 / iOS 26.6: GPS after retracting the initial complaint,
official links, saved-place relaunch in airplane mode, and Home Screen widget placement.
Build 4 has not been physically tested. Delivered reminders, widget tap-to-open, a full
large-text/dark-mode/VoiceOver pass, and unambiguous denied/revoked-location ZIP retest remain
unconfirmed. Do not convert tentative owner observations into a complete physical QA pass.

## App Privacy questionnaire

Apple also blocked Add for Review because App Privacy had never been completed, despite
the earlier owner report that privacy answers had been reviewed. Filled the four disclosures
from the shipped manifest and conservative listing draft: precise location, coarse location,
search history, other diagnostic data; all App Functionality, linked to identity, no tracking.
The final Publish dialog requires an accuracy/compliance/update attestation. Owner explicitly approved Publish at action time; publication succeeded.
Review notes were saved with the obsolete pre-submission retention-verification sentence
replaced by a reference to the linked privacy policy. No new retention guarantee was asserted.

## Confirmed submission

App Store Connect confirmed **Waiting for Review** for iOS App 1.0 (4), submitted November 2,
2026 at 22:54 PDT. Submission ID `91d5c0f0-0b9c-4a71-bb60-0730146525b2`.
https://appstoreconnect.apple.com/apps/6821803665/distribution/reviewsubmissions/details/91d5c0f0-0b9c-4a71-bb60-0730146525b2

App Privacy publication was confirmed before submission. Screenshot processing cleared,
Add for Review succeeded, then Submit for Review returned “1 Item Submitted”. The detail
page verified both the submission and build 1.0 (4) as Waiting for Review. Manual release
was verified immediately before submission; no public release action was taken.
Next: await Apple's review, address any review feedback, and obtain owner authorization
for public release after approval. Physical-device evidence limits above remain unchanged.
