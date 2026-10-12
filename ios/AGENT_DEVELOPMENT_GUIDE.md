# Vote4U iOS development: agent operating guide

Audited October 11, 2026. For Claude Code, Codex, and an agent receiving a file bundle.
Read alongside [the complete tooling inventory](../docs/AGENT_TOOLING_INVENTORY.md).
The inventory lists every discovered skill entry point, plugin, and MCP definition with a
source location, availability status, and smoke-test recipe. This guide explains how to use
the relevant ones together. A smoke-test recipe is a proposed check unless marked **run**.

## 1. Start here and establish the actual checkout

Read, in order:

1. [AGENTS.md](../AGENTS.md): project instructions and product commitments.
2. [HANDOFF.md](../HANDOFF.md): newest opening update, then §5 (failures) and §7 (rules).
3. [CODEX_HANDOFF.md](../CODEX_HANDOFF.md): useful implementation history; dated status is historical.
4. `CLAUDE.md`: local architecture notes, **gitignored**, available only if supplied separately.
5. [docs/OPUS_RELEASE_REVIEW.md](../docs/OPUS_RELEASE_REVIEW.md): unresolved release findings.
6. `docs/RELEASE_TRUST_FIXES.md`, if present on your branch: integrated fix/evidence ledger.
7. [ios/RELEASE_VALIDATION.md](RELEASE_VALIDATION.md) and [ios/APP_STORE.md](APP_STORE.md):
   release evidence and listing drafts, with dates and remaining limitations.

Use the newest evidence for status, actual source/build settings for implementation, and
AGENTS.md plus the owner's instructions for constraints. Historical files describe earlier
branches: statements such as “widget only exists on PR #4” and “Team ID unavailable” are no
longer safe assumptions. The old [IOS_DEVELOPMENT_GUIDE.md](IOS_DEVELOPMENT_GUIDE.md) remains
third-party inspiration and is not the operating procedure.

Before editing, run from the repository root:

```bash
git status --short
git branch --show-current
git log -1 --format='%h %s'
git worktree list
rg --files --hidden ios scripts .github docs -g '!screenshots/**'
rg -n 'IPHONEOS_DEPLOYMENT_TARGET|SWIFT_VERSION|TARGETED_DEVICE_FAMILY|DEVELOPMENT_TEAM' \
  ios/Vote4U.xcodeproj/project.pbxproj
xcodebuild -version
xcrun swift --version
xcrun simctl list runtimes
xcrun simctl list devices available
```

Record what succeeded and what failed. Simulator discovery failing with “Operation not
permitted” under a sandbox is not proof that no runtimes are installed. Use the connected
XcodeBuildMCP discovery tools or an approved shell escalation.

**Audit checkout:** this documentation branch was created from `docs/opus-release-review`
at `71f4ab9`. The pre-existing `HANDOFF.md` edit was preserved. The newest handoff describes
newer integrated code elsewhere; this checkout does not contain every fix it mentions, or
`ios/.swift-format`. Do not develop new app features on this older base. Verify/fetch
`origin/main`, then create an isolated feature branch/worktree from it, preserving other
agents' work. Documentation here is useful even when the code checkout is older.

## 2. Project contract and architecture

| Item | Inspected project setting / workflow |
| --- | --- |
| Project and scheme | `ios/Vote4U.xcodeproj`, shared scheme `Vote4U` |
| App bundle | `com.shyamravidath.Vote4U` |
| Widget bundle | `com.shyamravidath.Vote4U.Widgets` |
| Deployment target | iOS 17.0 |
| Swift language mode | Swift 5.0; installed compiler version is a separate fact |
| Hardware families | App: iPhone; widget extension: iPhone and iPad |
| Installed toolchain at audit | Xcode 27.0 (27A266a), Swift 6.4 |
| Discovered runtimes at audit | iOS 17.5 and iOS 27.0, via XcodeBuildMCP |
| App dependencies | Native Apple frameworks; no third-party app dependencies in inspected project |
| Required iOS runner | `scripts/test-ios.sh` |
| Backend and web | Express API plus React/Vite website; native app uses the same backend |

Do not upgrade the deployment target, language mode, architecture, or introduce a paid
service just because a skill uses newer defaults. Preserve iOS 17 behavior. The project
aims to stay free apart from Apple Developer membership.

Product requirements apply to every screen and every output:

- Never invent venues. Only `APIStub` may contain invented QA venues, behind `#if DEBUG`.
- Preserve the strength of evidence through results, saved records, sharing, maps, and
  notifications. Weaker evidence requires more cautious language. An unconfirmed building
  must not acquire a voting-role label simply because it was saved.
- Keep ZIP entry usable after location denial or revocation; empty results lead to official sources.
- Keep News last. Never imply government affiliation or endorsement.
- Never commit credentials or capture them in docs, screenshots, shell output, or logs.
- Never log location values: coordinates, ZIP, `place` location fields, client IP, coordinate
  cache keys, or upstream URLs containing keys/coordinates. Allow only documented shape
  fields such as mode, state abbreviation, data source, radius, cache hit, upstream duration,
  and count. Error objects/messages can also contain location values.
- DEBUG fixture screenshots are QA evidence, never App Store marketing.

Useful implementation boundaries:

| Area | Files to inspect before changing it |
| --- | --- |
| App entry / tabs | `ios/Vote4U/Vote4UApp.swift` |
| Design system / availability | `ios/Vote4U/Design/Vote4UTheme.swift`, `Vote4UActionStyle.swift` |
| Search and permission state | `Features/Vote/VoteViewModel.swift`, `VoteView.swift`, `Services/LocationManager.swift` |
| Transport / decoding / test fixtures | `Services/APIClient.swift`, `Services/APIStub.swift`, `Models/PollingResult.swift` |
| Saved data / trust wording | `Services/SavedPlace.swift`, both saved-place cards, `SavedPlaceTrustTests.swift` |
| Reminder scheduling / toggle | `Services/ReminderScheduler.swift`, `Features/Home/ElectionReminderCard.swift`, `HomeView.swift`, reminder tests |
| Election dates | `Models/ElectionCalendar.swift`, `client/src/lib/format.js`, corresponding tests |
| Electoral map | `Features/Map/`, bundled JSON, `SVGPathTests.swift`, `ElectoralMapRenderTests.swift` |
| Widget logic and views | `Vote4UWidgets/`, `Vote4U/Features/Widget/`, `Vote4UWidgets-Info.plist`, countdown tests |
| News | `Features/News/`, decoding tests, `server/services/newsService.js` |
| Shared API contracts | `server/routes/polling.js`, `server/services/`, `server/test/`, `server/lib/` |

Paths in the feature rows are relative to `ios/Vote4U/` unless fully qualified.
Resolve exact current paths with `rg --files`; a filename in a handoff is not proof it exists.

## 3. How skills, plugins, and MCPs fit together

A **skill** is guidance in a `SKILL.md` plus its references/scripts. A **plugin** bundles
skills, tools, and/or connector capabilities. An **MCP server** exposes executable tools.
Having a skill on disk does not establish that its referenced tools are connected.

The repo has no checked-in `.claude/`, `.codex/`, `.agents/`, or `.mcp.json` tooling
configuration at audit. Installed tools live under `~/.claude/` and `~/.codex/`.
Sending this repository to another agent does not install those tools.

Use the host's current skill/tool discovery before invoking a named skill. In Claude Code,
inspect the available slash commands and `/mcp`; in Codex, inspect the session skill list
and MCP tools. These interfaces can change: current official references are
[Codex skills](https://learn.chatgpt.com/docs/build-skills) and
[Codex MCP](https://learn.chatgpt.com/docs/extend/mcp?surface=cli).
Do not assume a Claude slash command is a Codex tool name.

Resolve conflicts explicitly:

| Generic guidance | Vote4U application |
| --- | --- |
| `swiftui-pro` defaults to iOS 26 / Swift 6.2 | Keep iOS 17 / Swift 5; gate APIs and check actual compiler settings |
| Manual bindings should be replaced with `onChange` | Preserve the reminder toggle's explicit Binding: programmatic revert previously erased the denial warning |
| Prefer MV and remove view models | Keep purposeful existing `@Observable`/`@MainActor` models; refactor only the requested boundary |
| XcodeBuildMCP prefers its own test tools | The repo requires `scripts/test-ios.sh`; MCP test calls never replace it |
| gstack shipping may merge/deploy | Stop at branch → commit → push → PR; owner merges |
| gstack live-device QA installs a bridge | Optional integration, not present in Vote4U; assess dependencies, privacy, and release exclusion first |
| Plugin mentions `describe_ui`, tap, logging, LLDB | Verify tools exposed now; this session exposes `snapshot_ui`, but no XcodeBuildMCP tap/log/LLDB tools |
| Build iOS Apps uses `xcodebuildmcp@latest` | Standalone config pins 2.7.0; identify which server is active and avoid duplicate build ownership |
| Skill assumes an SPM app or importable package | Vote4U is an Xcode application; do not run package-specific commands as if it had `Package.swift` |

Read the chosen skill before use, then load only its relevant references. A code review
should cite actual defects and evidence, not impose every stylistic example as a rule.

## 4. Native development skills, one by one

Sources: user skills at `~/.codex/skills/<name>/`; Build iOS Apps skills at
`~/.codex/plugins/cache/openai-curated/build-ios-apps/11c74d6b/skills/<name>/`.
Exact entries and duplicate copies are in the inventory. Plugin skills on disk were not
all advertised in this session; availability must be checked before use.

| Skill | When and how to use | How to test the skill's result |
| --- | --- | --- |
| `swiftui-expert-skill` | General implementation: decide state ownership, small view boundaries, stable identity, accessibility, and supported APIs. Read topic references. | Implement/review one bounded screen; build; inspect its loading/error/empty/content states and large text. Reject any unavailable API or unsolicited glass migration. |
| `swiftui-pro` | Review correctness, navigation, data flow, accessibility, performance, and hygiene; load relevant `references/*.md`. Root copy is v1.1; nested copy is v1.0. | Review a disposable fixture containing an unlabeled icon button and a known state bug; expect file/line findings, no invented issues, and iOS 17-compatible fixes. Preserve the special reminder Binding. |
| `swiftui-view-refactor` | Extract dedicated view types with small inputs, bindings, and callbacks; keep domain logic in services/models and owned observables in `@State`. | Compare before/after screen and behavior, including search, save/remove, reminder denial, and navigation. Build and run relevant regressions through the required runner. |
| `swiftui-ui-patterns` | Consult the component index for navigation, controls, focus, sheets, previews, layout, and async state. Adapt patterns to current architecture. | Exercise keyboard submit, back navigation, sheets, scroll, Dynamic Type, and VoiceOver; confirm state survives intended view updates. |
| `swiftui-liquid-glass` | Only for an explicitly requested glass change or a review of existing glass. Keep native control treatment, modifier order, and availability fallbacks. | Run the changed control on iOS 17.5 and a modern runtime; compare light/dark and reduced transparency/motion. A modern SDK build alone does not test the fallback. |
| `swiftui-performance-audit` | Start with source review of invalidation, identity, body work, images, layout and animation; profile when needed. | Repeat the same measured flow/build/device before and after; report CPU/hitches/memory evidence or label the finding a source-level hypothesis. |
| `swift-concurrency-expert` | Capture diagnostics; check language/isolation settings; make the smallest correct actor/Sendable fix. Read Swift 6.2 references selectively. | Strict-concurrency build in the existing language mode, then cancellation, rapid repeated actions, stale response handling and reminder opt-out tests. Do not silence errors with unjustified `@unchecked Sendable`. |
| `ios-app-intents` | Optional new integration: expose 1–3 useful actions, minimal entities/enums, thin services, and one main-scene handoff. Not currently a shipped feature. | Invoke an actual Shortcut from cold and warm app states; check route, failure/denial behavior, availability, and trust/privacy wording. Compilation is insufficient. |
| `ios-debugger-agent` | Discover simulator/project; configure MCP defaults; reproduce one flow; confirm UI before interactions; collect logs/debugger evidence where available. | Launch the correct bundle, capture a current screenshot/tree, repeat the exact failure and fix flow. Record unavailable tools instead of inventing them. Use the required runner for regression coverage. |
| `ios-simulator-browser` | Optional simulator mirroring with `serve-sim`; separate package-based preview workflow. Pin explicit UDID and clean up helper processes. | Mirror the correct simulator, observe an interaction, and stop the helper. Check preview importability before attempting the separate preview-app route; the Vote4U app module is not automatically an importable Swift package. |
| `ios-ettrace-performance` | Optional instrumented Simulator profiling; temporary ETTrace framework, UUID-matched dSYMs, one focused capture, processed flamegraph JSON. | Confirm startup instrumentation, matching UUIDs and meaningful symbolication; compare the same flow; preserve outputs; remove temporary linkage and rerun the normal build. No conclusion from an unsymbolicated graph. |
| `ios-memgraph-leaks` | Capture a live process memgraph; summarize app-owned leaked types and ownership paths; fix the retaining edge. | Use bundled capture/summary helpers on the same reproduction before/after. Prove the specific type/path disappears, rather than claiming success from smaller total memory. |

For `swiftui-expert-skill` Instruments helpers, read `references/trace-recording.md` and
`trace-analysis.md`. The installed skill warns that the Simulator SwiftUI lane may be empty;
use its Time Profiler route there and a physical-device SwiftUI trace when appropriate.
Check templates/devices locally before recording. Trace capture is not necessary for a
small static layout change. Keep real location data out of recorded diagnostic artifacts.

## 5. Claude native QA and store skills, one by one

gstack lives at `~/.claude/skills/gstack/`. These are skill workflows with a daemon and
generated debug bridge, **not configured iOS MCP servers**. Their Codex-port copies are
inside `gstack/.agents/skills/`, not installed under this repo's `.agents/` directory.

| Skill | Application and prerequisite | Smoke test / acceptance evidence |
| --- | --- | --- |
| `ios-qa` | Live USB iPhone QA. Requires trusted phone, signing, Bun/toolchain, marked observable fields, generated local DebugBridge package, and app wiring. Not installed in Vote4U. | First use a disposable example app. Obtain a screenshot and accessibility tree; use only synthetic snapshot fields; drive a visible action; verify session release, token rotation and Release exclusion. Do not snapshot coordinates, ZIP or saved addresses. |
| `ios-fix` | Built on installed `ios-qa`; requires reproducing state snapshot and screenshot before editing. Restores state after rebuild to verify. | On a disposable synthetic fixture, reproduce → snapshot → fix → restore → compare. Native Vote4U regressions still belong in XCTest and the required runner, not solely a bridge-driven TypeScript fixture. |
| `ios-design-review` | Uses the QA daemon with observe capability; applies typography, spacing, color, touch, state, accessibility, animation and iOS idiom checks. | Review actual light/dark and large-text screenshots plus accessibility hierarchy; report screen coverage and evidence. A numeric score alone is insufficient. Do not cap all accessibility sizes just to satisfy a generic rubric. |
| `ios-sync` | Regenerates an existing bridge/accessor schema after source or gstack updates. | Add a synthetic eligible field in a disposable app; regenerate; confirm only generated files changed; rebuild and verify updated schema. Vote4U has no bridge to sync by default. |
| `ios-clean` | Guided removal of a previously installed bridge. The skill explicitly asks for confirmation of listed removals. | Inventory/dry-run first. On the approved integration remove bridge wiring; verify sources, linked products, app/extension binaries and normal Release build. Do not remove Vote4U's separate DEBUG `APIStub`. |
| `app-store-preflight-skills` | Read `references/guidelines/by-app-type/all_apps.md`, then relevant metadata/privacy/design/entitlement rules. `asc` metadata access is optional for offline source review. | Run against an isolated copy with deliberately missing purpose text or an oversized metadata field, then a corrected copy. Expect detection and successful recheck. Compare claims with current Apple docs; distinguish heuristics from rejection guarantees. |
| `aso-audit` | Optional store-listing audit, separate from release correctness. | Audit supplied `APP_STORE.md` and clearly mark missing live analytics/metadata; verify recommendations preserve nonpartisan, nonofficial wording. |
| `apple-search-ads` | Paid acquisition planning, not part of the free development workflow. | Only if requested: review a hypothetical plan without creating campaigns, spending money, or publishing claims. |
| `app-icon` | Expo/SnapAI workflow; incompatible with Vote4U's native project as written, and provider usage is billed. | Do not run Expo prebuild or apply its transparent-icon instructions here. Inspect the native asset catalog, use `scripts/generate-icons.mjs` when appropriate, and verify the resulting icon/build. A new raster concept can use the available imagegen skill when requested. |
| `graphify` | Optional architecture knowledge graph; not required to read this small native codebase. | Generate/query a disposable minimal source fixture; confirm nodes/paths match actual files and detect stale graph output. Do not treat a graph as more authoritative than current source. |

The gstack QA install skill explicitly asks before adding DebugBridge. This is an optional
dependency and privacy change, not permission implied by routine UI work. Inspect and adapt
its package assumptions to the Xcode project before proposing integration. Its touch layer
uses internal UIKit behavior: prove complete exclusion from all distribution artifacts.
The current Vote4U stub-string grep does **not** establish bridge/ETTrace exclusion.
Generic gstack artifact sync/telemetry also must not receive user location data or credentials.

For additional planning, diagnosis, review, documentation, and web skills, consult the
inventory's individual rows. Particularly useful: gstack `investigate`, `review`, `cso`,
`context-save`/`context-restore`, `plan-eng-review`, and mattpocock-skills `diagnosing-bugs`,
`tdd`, `code-review`, `codebase-design`, `handoff`, and `writing-for-agents`.
Browser QA validates the website, not the native iPhone app. Reviews do not authorize
publishing issues, sending messages, introducing hooks, or deploying code.

## 6. MCPs and plugins: operational tests

The complete inventory includes every configured/cached definition individually, including
disabled Firebase, Sentry, filesystem, GitHub, AppLaunchFlow and ios-simulator integrations,
synced Claude design connectors, and non-iOS plugins. None is necessary to start native work.
Never enable all integrations just to reproduce this guide's environment.

### Xcode MCP (`xcode`, `xcrun mcpbridge`)

At audit the namespace is `mcp__xcode__*`.

1. Call `XcodeListWorkspaces`; verify the project path rather than assuming the frontmost workspace.
2. Pass the returned workspace identifier to `XcodeListSchemes` and `XcodeListTargets`.
3. Verify shared active scheme `Vote4U`, app, unit-test, UI-test, and widget targets.
4. For API questions use `DocumentationSearch`; for code/build work inspect relevant settings
   and diagnostics. Use preview or snippet tools only for a suitable file and known context.
5. Build/run actions must not overlap a shell/MCP build of the same checkout/DerivedData.
   `RunAllTests` and `RunSomeTests` are supplemental, not the project acceptance runner.

**Run during audit:** workspace discovery, scheme discovery, target discovery all passed.
This establishes connection/discovery, not build, test, preview, device control, or app correctness.

### XcodeBuildMCP (`xcodebuild`, standalone version 2.7.0)

At audit the namespace is `mcp__xcodebuild__*`.

1. Call `session_show_defaults` before the first build/run/test. Audit result: all defaults unset.
2. Call `list_sims` and choose an explicit device/runtime. Both 17.5 and 27.0 were returned.
3. Set `projectPath`, `scheme`, `simulatorId`, Debug configuration and a dedicated
   `derivedDataPath` with the exposed `session_set_defaults` schema; reread defaults.
4. Only when app work is requested, build/run and confirm the correct bundle with screenshot
   or `snapshot_ui`. The build/run tool handles simulator startup as documented by the server.
5. Read actual tool schemas before interaction. This session's exposed workflow includes
   discovery, defaults, build/install/launch, screenshot, UI snapshot, video and coverage.
   It does not expose every interaction/logging/debugger tool named by installed skill text.
6. Use Xcode device tools, XCUITest or shell `simctl` as applicable if needed capabilities
   are unavailable. Never pretend a screenshot validates an unperformed tap or permission flow.

**Run during audit:** `session_show_defaults` and `list_sims` passed. No app build or mutation
was performed to test this integration. The Build iOS Apps plugin declares a second server
named `xcodebuildmcp` using `@latest` and additional workflows; its manifest alone does not
prove that server is connected or those workflows are available.

### Host tools and supporting integrations

- `node_repl` / `cua_repl`: host/browser/native UI automation, useful for Xcode/Simulator
  screens when available. Start with its documented state/discovery call. Confirm the
  correct surface before an action, and inspect the resulting screenshot. These are not
  replacements for XCTest assertions or the runner.
- `codex_app` / session `codex_tui`: task/worktree management. Read-only list is a smoke
  test; task creation, delegation or messaging requires a requested workflow.
- `code-review`: plugin-configured reviewer, not advertised as a callable MCP namespace in
  this session. Verify discovery first; compare known read-only fixture findings before use.
- `codex_apps`: connected-service tools, not evidence that each cached plugin is authenticated.
  Test an integration with a read-only list/search on an authorized fixture. Do not send
  Slack/email, create calendar events, publish sites, or alter Drive files as a smoke test.

## 7. Feature implementation procedure

1. State the requested user behavior and observable acceptance criteria. Identify trust,
   privacy, dates, permissions, persistence, and availability affected by the slice.
2. Inspect source and nearest tests. Choose one primary implementation skill and any
   relevant specialist; avoid loading all skills into the agent context.
3. Write down state ownership and dependencies. Reuse existing services/models. Owned
   iOS 17 `@Observable` references belong in `@State`; use `@Bindable` where bindings are
   needed. Preserve existing explicit actor isolation and cancellation behavior.
4. Make a small coherent change. Use stable list IDs, native controls, meaningful accessibility
   identifiers, dynamic fonts, clear loading/error/empty states, and narrow child inputs.
5. Verify APIs against the selected SDK and deployment target. New compiler syntax is a
   language-mode question; new frameworks/methods are also runtime availability questions.
6. Build the changed slice, reproduce it in Simulator, and inspect screenshots. Exercise
   the important failure path and rapidly repeated/cancelled actions when relevant.
7. Add meaningful behavioral regressions for substantive changes. Fixture-driven UI tests
   should be deterministic; model decoding tests must exercise actual JSON field names.
8. Run the required runner at the validation gate; interpret each phase and skip accurately.
9. Review the diff for unrelated changes, privacy leakage, trust wording, unavailable APIs,
   and accidentally linked QA/profiling tooling. Obtain a second review when requested.
10. Commit only your intentional files on the feature branch, push, open a PR for owner
    merge, and report evidence. Never merge or release as part of a generic ship skill.

SwiftUI pitfalls specific to this app:

- Keep reminder toggle Binding behavior; `.onChange` cannot distinguish a user's choice
  from an asynchronous programmatic revert.
- Notification removal is asynchronous. Avoid cancel-then-add races; replacement by stable
  identifier and correct opt-out ordering matter. Test stale authorization completions.
- Election logic uses local calendar boundaries. Test Today/tomorrow/singular text,
  midnight rollover, foreground refresh and next-election transitions with an injected clock.
  Do not rely on fixed fall-2026 dates staying in the future for real queue tests.
- An all-optional Codable model can silently decode wrong field names. Check rendered values
  as well as decoding success. DEBUG typed fixtures do not prove JSON decoder correctness.
- Lazy containers omit off-screen accessibility elements. Scroll and check `isHittable`.
- Map shapes are one summary accessibility element; the state list is the interaction surface.
- Default `searchable` can collapse. Reuse the project's deliberately visible placement.
- Avoid expensive parsing/sorting/formatter work in `body`; preserve identity while extracting views.

## 8. Build, formatting, tests, and visual verification

Use one active build/test owner. Give each run a dedicated DerivedData path. Do not run
two `xcodebuild` processes against the same directory. Check for other agents' Simulator
work before starting the runner: it calls `simctl shutdown all` internally.

### Small build loop

```bash
xcodebuild -list -project ios/Vote4U.xcodeproj
xcodebuild -project ios/Vote4U.xcodeproj -scheme Vote4U \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /private/tmp/vote4u-agent-build build
```

Use a recent SDK containing the glass symbols even though deployment remains iOS 17.
For a concrete destination pin OS as well as name, or use a discovered UDID; a bare
`iPhone 15 Pro` resolves against the newest runtime and fails on this Mac.

### Required acceptance runner

```bash
DEVICE_TYPE='iPhone 15 Pro' \
RUNTIME='com.apple.CoreSimulator.SimRuntime.iOS-17-5' \
DERIVED='/private/tmp/vote4u-agent-tests-175' \
  ./scripts/test-ios.sh

# Run sequentially, after checking this device/runtime pair exists:
DEVICE_TYPE='iPhone 17' \
RUNTIME='com.apple.CoreSimulator.SimRuntime.iOS-27-0' \
DERIVED='/private/tmp/vote4u-agent-tests-modern' \
  ./scripts/test-ios.sh
```

The script builds/warm-launches the app, creates a fresh Simulator, tests notification
allow, runs unit and smoke tests, creates a separate fresh Simulator for deny, then builds
Release and checks stub strings plus widget family declarations. It deletes its temporary
Simulators on exit. Simulator tests need no signing identity.

Check exit status, actual executed count, skips, all phase logs, and final Release result.
If allow fails, later phases have not been validated. Missing permission alerts must fail,
not silently become coverage. A skip is not a pass. `simctl privacy` cannot grant/reset
notifications; uninstalling does not reliably reset that authorization.

The existing Release string check is useful but limited: short Swift literals may not
appear in `strings`, and the extension is not comprehensively scanned. See OPUS-31.
For added instrumentation inspect linked frameworks, symbols, dSYM/source provenance and
both app/extension products. Never describe the grep as complete release-safety proof.

### Formatting

First locate the current branch's `.swift-format`. This audited older checkout has none.
Do not run a default-format rewrite. Inspect the intended four-space configuration on the
current implementation branch before adopting it; do not overwrite another agent's config.

Once `ios/.swift-format` exists, run from `ios/` with its explicit path:

```bash
xcrun swift-format lint --configuration .swift-format --strict --parallel --recursive \
  Vote4U Vote4UTests Vote4UUITests
```

Include `Vote4UWidgets` for widget changes if that target exists. Separate pre-existing
format findings from new ones; fix the changed files rather than rewriting the repository.
SwiftLint is not installed at audit. Re-check actual CI before claiming formatting is a gate.

### Behavior matrix

| Area | Verify |
| --- | --- |
| Vote | ZIP with location denied/revoked; valid/invalid input; loading/error/empty; evidence tiers; official-source links; stale response protection |
| Saved place | Save → relaunch → offline read → remove; conservative legacy decoding; warning survives cards/share/reminder; actual removal assertions |
| Home / reminder | Today/singular/midnight; allow/deny; warning survives reset; opt-out after in-flight authorization; revoked permission and foreground reconciliation |
| Map | 51 entries/538 total/270 threshold; DC reachable by search; map rendering; state list accessible |
| News | JSON decoding, populated time/image fields, failure/retry and refresh; News stays last |
| Visual/accessibility | Small phone and large phone; light/dark; largest accessibility sizes; VoiceOver; Reduce Motion; readable contrast, targets and safe areas |
| Widget | Timeline entries at local midnights; all five supported families; correct margins; registration; physical Home Screen placement/open action |

Use DEBUG launch arguments only in QA: `-startTab home|vote|map|news`, `-startZip 90210`,
`-stubPolling estimated|nearby|empty|error`, `-stubNews sample|error`. Inspect `APIStub.swift`
for the current vocabulary; do not invent an official-tier fixture that does not exist.

For visual inspection, substitute an explicitly selected QA Simulator UDID:

```bash
SIM='<qa-simulator-udid>'
xcrun simctl ui "$SIM" appearance dark
xcrun simctl ui "$SIM" content_size accessibility-extra-extra-extra-large
xcrun simctl launch "$SIM" com.shyamravidath.Vote4U -startTab home
xcrun simctl io "$SIM" screenshot /private/tmp/vote4u-agent-home-dark.png
```

Actually open the image. Restore appearance/text size after the session. Screenshots must
show settled content, not mid-animation frames. Use synthetic data for private-location QA.

### Widget verification beyond the build

Widget views/logic that need unit/render tests remain in the app target and are shared into
the extension, not duplicated. Pass family explicitly in render tests; `widgetFamily` cannot
be assigned by a test. Simulate WidgetKit's content margins before diagnosing overflow.

The extension's real Info.plist belongs outside its synchronized source group. Inspect:
`NSExtension.NSExtensionPointIdentifier = com.apple.widgetkit-extension`, embedded `.appex`,
and extension `UIDeviceFamily` containing both 1 and 2.

After install/launch on a QA device:

```bash
xcrun simctl spawn "$SIM" pluginkit -m -v -p com.apple.widgetkit-extension
```

Expect `com.shyamravidath.Vote4U.Widgets`. Registration can be asynchronous: use the bounded
poll from `.github/workflows/ios.yml`, rather than passing a missing extension as a skip.
Registration plus render tests still do not prove a physical Home Screen placement. Record
the owner/device observation separately. Prior gallery automation attempts were unreliable.

### Backend / web / bundled data

Run when changes affect their shared contracts, or for a release candidate:

```bash
npm test --prefix server
npm run test:e2e
npm run build
node scripts/export-ios-data.mjs  # only after changing the bundled web data sources
```

Inspect generated JSON diffs. Stubbed server tests do not establish production upstream
correctness. Do not enable Civic as part of native development; newest handoff keeps it
disabled pending unresolved assignment/date/cache/error findings.

CI lives in `.github/workflows/ci.yml` and `ios.yml`. The latter uses `macos-26`, discovers
a supported device/runtime, runs the mandatory script, and separately proves widget
registration. It is path-filtered; a Markdown-only docs change may not trigger native CI.

## 9. Release procedure and evidence limits

Finish development and verification before proposing a release action. Use a clean,
integrated checkout with a recorded SHA and a unique build number. Do not reuse `/tmp`
archives solely because their name or version looks right; multiple historical archives
claimed the same build. Preserve provenance for archive, export, processed build and device.

1. Reconcile newest handoff, release findings and fix ledger. Resolve or explicitly disposition
   every remaining gate; do not declare the app ready from a historical green run.
2. Run native regression on the deployment-era and modern runtimes, plus affected shared suites.
3. Verify distribution products: signatures, provisioning, entitlements, privacy manifest,
   icon/resources, embedded widget, family declarations and exclusion of all DEBUG tooling.
4. Review metadata/privacy copy against actual server retention/host logging and app behavior.
   The UserDefaults required-reason declaration does not settle data-collection disclosures.
5. Capture fresh listing screenshots with `scripts/capture-screenshots.sh` only when the
   deployed backend and current app match the candidate. Inspect every output; actual
   results may be empty or change. Never use fabricated venues or misleading labels.
6. Complete physical iPhone checks from `RELEASE_VALIDATION.md`: denied/revoked-location ZIP
   flow, real GPS, offline persistence, visible notification delivery, widget placement,
   accessibility and permissions. Queue assertions do not prove banner delivery.
7. If explicitly authorized, upload the identified archive/build, verify Apple processing,
   install that TestFlight build and repeat critical flows. Export success is not upload
   success, processing success, or on-device validation.
8. Owner approval/merge/publication remains a separate step. Do not submit to App Review,
   deploy, merge, send review messages, or spend on campaigns because a skill suggests it.

Apple's [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
are the current source for submission requirements; preflight skills are heuristics.
Use current [Liquid Glass documentation](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views)
and Xcode documentation search for API adoption, checking availability in the selected SDK.
Do not copy an overly broad privacy-manifest or transparent-icon claim from a third-party skill.

## 10. Handoff packet and completion report

For an agent with repository access, send these three new documents:

- `ios/AGENT_DEVELOPMENT_GUIDE.md` (this procedure).
- `docs/AGENT_TOOLING_INVENTORY.md` (every entry and smoke test).
- `docs/IOS_AGENT_START_PROMPT.md` (copy/paste task contract).

Also send/link `AGENTS.md`, newest `HANDOFF.md`, `CODEX_HANDOFF.md`, `ios/APP_STORE.md`,
`ios/RELEASE_VALIDATION.md`, `docs/OPUS_RELEASE_REVIEW.md`, and the current fix ledger if present.
Supply `CLAUDE.md` separately if appropriate: it is not in git. For an agent without repository
access include the actual relevant source/tests, Xcode project/shared scheme, widget plist,
privacy manifest, test/screenshot/data scripts, CI workflows and verified format configuration.
Documents alone cannot establish behavior or allow a build.

For off-machine skill use send the selected skill's **whole folder** including references,
scripts and license, subject to its redistribution terms. For gstack send a supported
installation/package rather than just symlinked SKILL.md files. Do not attach user config,
auth files, `.env`, session caches, synced tokens or real-location diagnostic captures.
Keep the inventory for tool names/status; let the destination agent establish its own connections.

Every completion report should state:

```text
Outcome: requested behavior and material changes.
Checkout: branch, commit/base SHA, dirty files excluded, relevant build settings.
Tools: skills read; actual MCP tools used; unavailable tools and fallback.
Validation: exact command/tool, configuration, device/runtime, executed/pass/fail/skip counts.
Evidence: current screenshots, logs/result bundles, regression or mutation proof where relevant.
Limits: unperformed checks, failures and downstream phases not reached, device/release gates.
Delivery: commit/PR and owner action still needed; no unsupported deployment/submission claim.
```

**This guide's own validation:** configuration/source inventory and read-only Xcode MCP
discovery were run. No new application build/test suite, physical-device QA, third-party
service login, bridge installation, profiling, store upload, or release action was performed
for this documentation task. Proposed smoke tests in the inventory are not historical passes.
