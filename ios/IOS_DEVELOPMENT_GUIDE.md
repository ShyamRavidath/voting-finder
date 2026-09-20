# iOS Development with Codex: Working Guide

This reference distills the user-supplied article, “Summary of Prompts for iOS App Development with Codex,” into a practical workflow. The source was an AI-translated summary, so verify version-sensitive APIs and platform requirements against current Apple documentation before shipping.

## Project quick reference

| Item | Value |
| --- | --- |
| Project | `ios/Vote4U.xcodeproj` |
| Scheme | `Vote4U` |
| Bundle ID | `com.shyamravidath.Vote4U` |
| Current deployment target | iOS 17.0 |
| Current Swift language setting | Swift 5 |
| Full test script | `./scripts/test-ios.sh` |
| Screenshot script | `./scripts/capture-screenshots.sh` |

Do not assume the article's iOS 26 and Swift 6.2 recommendations already apply to this repository. Treat those as explicit migrations and preserve the current iOS 17 fallback until the project requirements change.

## 1. The development loop

Use the smallest reliable loop that proves the current change:

1. Inspect the repository and reuse its existing models, navigation, services, conventions, and scripts.
2. Confirm the project or workspace, scheme, deployment target, and intended simulator.
3. Implement one cohesive slice rather than several unrelated features.
4. Run the narrowest meaningful build, test, preview, or simulator flow.
5. Expand validation only when the change's risk justifies it.
6. Report the exact scheme, simulator, commands, and results.

Prefer CLI-driven work because it keeps discovery, editing, building, testing, and diagnosis in one repeatable loop. Move to simulator automation when visual state, interaction, logs, screenshots, or debugger state matter.

### Useful CLI commands

Discover schemes:

```sh
xcodebuild -list -project ios/Vote4U.xcodeproj
```

Build for an available simulator:

```sh
xcodebuild \
  -project ios/Vote4U.xcodeproj \
  -scheme Vote4U \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build
```

Run a focused unit test:

```sh
xcodebuild test \
  -project ios/Vote4U.xcodeproj \
  -scheme Vote4U \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:Vote4UTests/FormattingTests
```

Run the repository's complete iOS test loop:

```sh
./scripts/test-ios.sh
```

The full script creates fresh simulators for notification allow and deny paths because notification authorization persists on a simulator. Use a focused `xcodebuild` command during iteration and the full script before handing off notification-sensitive or release-bound work.

## 2. Choosing tools and skills

Start with `xcodebuild` and the repository's scripts. Add specialized guidance or automation when the task demands it.

| Need | Preferred capability |
| --- | --- |
| Broad SwiftUI implementation or review | `swiftui-expert-skill` |
| Comprehensive modern API, accessibility, and maintainability review | `swiftui-pro` |
| iOS 26 Liquid Glass adoption | `swiftui-liquid-glass` |
| Slow rendering, janky scrolling, broad invalidation, or layout churn | `swiftui-performance-audit` |
| Actor isolation, `Sendable`, data-race, or async/await diagnostics | `swift-concurrency-expert` |
| Breaking up and cleaning a large SwiftUI screen | `swiftui-view-refactor` |
| Navigation, state, bindings, responsive layout, and component patterns | `swiftui-ui-patterns` |
| Simulator build, run, UI interaction, screenshots, logs, and LLDB | Build iOS Apps plugin / XcodeBuildMCP workflows |

Tuist can be useful when a team deliberately wants generated project structure. Do not introduce it merely to replace a functioning checked-in Xcode project.

## 3. Prompt contract for feature work

A strong request states:

- whether this is a new app or an existing project;
- the exact feature or screen in scope;
- the supported devices and deployment target;
- architecture and behavior that must remain intact;
- the expected verification loop;
- the evidence required at handoff.

Reusable prompt:

```text
Add [feature] to this existing SwiftUI app.

Constraints:
- Reuse existing models, navigation patterns, services, and shared utilities.
- Preserve support for [deployment target] on [devices].
- Keep the implementation limited to this feature slice.
- Discover and report the project, scheme, and simulator used.
- Use the smallest build or test loop that proves each meaningful change.
- Use simulator screenshots or UI inspection when visual behavior matters.

Deliver:
- implementation summary
- important data-flow or architecture decisions
- exact validation commands and results
- known limitations or follow-up work
```

## 4. Safe SwiftUI refactoring

The goal of a refactor is easier review and maintenance without changing behavior, layout, navigation, persistence, or business rules.

### Default approach

- Prefer MV-style SwiftUI before adding MVVM layers.
- Try `@State`, `@Environment`, `@Query`, `.task`, `.task(id:)`, and `onChange` before introducing a view model.
- Keep business logic in services or domain models, not in `body`.
- Retain a view model only when the feature has a clear need for one.
- For an owned `@Observable` reference on iOS 17+, store it in `@State`.
- Use legacy observable wrappers only when the deployment target requires them.

### Organize a view from top to bottom

1. Environment dependencies
2. Immutable inputs
3. State and other stored properties
4. Computed non-view state
5. Initializer
6. `body`
7. Small view helpers
8. Action and async helper methods

### Extract useful boundaries

- Split meaningful sections into dedicated `View` types.
- Pass the smallest interface: immutable values, narrowly scoped `@Binding`s, and purpose-specific callbacks.
- Do not pass the entire parent model when a child needs only two values and one action.
- Avoid replacing one enormous `body` with a long collection of enormous computed `some View` properties.
- Move non-trivial button work and side effects into named methods.
- Keep the root view tree stable; localize conditional content and modifiers instead of swapping the whole root with top-level `if/else` branches.

### Refactor validation

After each meaningful extraction, run the smallest build or test that can expose a wiring error. At handoff, list both what changed structurally and what intentionally did not change.

## 5. Liquid Glass migration

Treat Liquid Glass as an iOS 26 and Xcode 26 migration, not as a cosmetic modifier to scatter throughout the app.

### Audit before editing

Classify each surface:

- System chrome or interactive controls that could use native glass
- Existing custom blur or material stacks that glass could replace
- Buttons, chips, sheets, and toolbars that need system treatment
- Plain content surfaces that should stay plain for readability

### Implementation rules

- Prefer native `glassEffect`, `GlassEffectContainer`, `.buttonStyle(.glass)`, and `.buttonStyle(.glassProminent)` over custom blur layers.
- Apply `glassEffect` after layout and visual modifiers so it wraps the intended shape.
- Group related glass surfaces in `GlassEffectContainer`.
- Use `.interactive()` only for elements that actually react to input.
- Use `glassEffectID` with `@Namespace` only when a real morphing transition improves the interaction.
- Keep shapes, tint, spacing, and prominence consistent within a flow.
- Do not turn every content card into glass; glass is primarily a control layer over content.

### Availability and validation

If the app still supports iOS 17, isolate iOS 26 APIs:

```swift
if #available(iOS 26, *) {
    content
        .glassEffect()
} else {
    content
        .background(.ultraThinMaterial)
}
```

Build both the modern and fallback paths. Run the migrated flow in an iOS 26 simulator, capture screenshots, and separately verify that the pre-iOS 26 build remains valid.

## 6. App Intents

Design the first intent surface around useful verbs and minimal entities, not around mirroring every screen or persistence model.

### Select the first intents

Look for actions users genuinely want outside the full app, such as:

- Create
- Open
- Search
- Filter
- Start or continue
- Inspect or summarize

Decide whether each action should run without opening the app or deep-link into a specific state.

### Keep the system-facing model small

- Define an `AppEntity` only for data Siri, Shortcuts, Spotlight, widgets, controls, or another system surface must understand.
- Expose identifiers, display representation, and lookup behavior without duplicating the entire internal data model.
- Add `AppShortcutsProvider` entries for the highest-value actions.
- Write titles, phrases, and display representations that make sense outside the app.
- Centralize the handoff into the main scene when an intent must open a tab or workflow.

### App Intent deliverables

Document:

1. The chosen intents and why they are valuable
2. The minimal entity surface
3. Which intents run headlessly and which open the app
4. How scene routing consumes the handoff
5. Which system experiences are supported now
6. The build and runtime checks performed

## 7. Simulator-driven debugging

Debug one failure mode per run. Convert a vague report into a repeatable script and collect evidence before changing code.

### Reproduction loop

1. Discover or confirm the project, scheme, simulator, and bundle ID.
2. Reuse that configuration for the full session.
3. Build, install, and launch the app.
4. Confirm the starting screen with an accessibility snapshot or screenshot.
5. Reproduce the exact taps, typing, scrolling, and swipes.
6. Prefer accessibility labels or identifiers over raw coordinates.
7. Re-read the UI hierarchy whenever the layout changes.
8. Capture screenshots, relevant logs, and LLDB frames or variables for crashes and hangs.
9. Make the smallest fix supported by the evidence.
10. Repeat the same path and compare the result.

If stable accessibility identifiers are missing and coordinate taps are necessary, record that as a UI-testability issue.

### Debugging prompt

```text
Use the Build iOS Apps plugin and XcodeBuildMCP to reproduce and fix this bug in Simulator.

Expected: [expected behavior]
Actual: [actual behavior]
Setup: [screen, account, fixture, or deep link]

Requirements:
- Discover and reuse the correct project, scheme, simulator, and bundle ID.
- Confirm the starting UI before interacting.
- Follow the exact reproduction path using accessibility identifiers where possible.
- Capture screenshots, logs, and debugger evidence appropriate to the failure.
- Make the smallest code change that fixes the root cause.
- Repeat the same flow and report exact verification results.
```

## 8. Performance workflow

Begin with code review, then profile when inspection cannot establish the cause.

Check first for:

- observation that invalidates too much of the tree;
- unstable `ForEach` or list identity;
- expensive work inside `body`;
- excessive `GeometryReader` or preference chains;
- image decoding or resizing on the main thread;
- animation applied to overly broad hierarchies;
- memory growth or retained models.

When runtime evidence is needed, record the device, OS, configuration, exact interaction, and baseline. Compare the same flow after the fix using CPU, frame drops or hitches, and memory peak. Distinguish trace-backed findings from code-level suspicions.

## 9. Concurrency changes

For Swift concurrency diagnostics:

1. Record the exact compiler message and offending declaration.
2. Confirm the Swift language mode, strict concurrency setting, and default actor isolation.
3. Determine whether the code is UI-bound or should execute away from the main actor.
4. Apply the smallest behavior-preserving isolation fix.
5. Rebuild, then run relevant tests because concurrency changes can compile cleanly and still alter runtime behavior.

Prefer correct value semantics and explicit isolation. Add `Sendable` only when it is true, and avoid `@unchecked Sendable` unless thread safety is proven. Moving this repository from Swift 5 to Swift 6.2 should be planned and validated as a separate migration.

## 10. Definition of done

A Codex-assisted iOS change is complete when:

- The requested behavior is implemented without unrelated scope expansion.
- Existing architecture and behavior were preserved unless a change was explicitly justified.
- Availability matches the deployment target.
- Accessibility and UI testability were considered.
- The narrow verification loop passed.
- Broader tests were run when risk warranted them.
- Visual work was checked in the relevant simulator.
- The handoff names the scheme, simulator, commands, evidence, and any remaining risks.

For Vote4U, use `./scripts/test-ios.sh` as the release-oriented test loop and regenerate `ios/screenshots/` with `./scripts/capture-screenshots.sh` after user-visible UI changes that affect App Store imagery.

## Source notes

- Primary source: the article text supplied in the task, an AI-translated summary attributed to npaka, dated April 30, 2026.
- The source's most durable recommendation is to use small, evidence-producing loops: inspect, make one focused change, build or run the narrowest useful check, and report exactly what was verified.
- Version-sensitive claims—especially iOS 26, Xcode 26, Liquid Glass, Swift 6.2, and App Intents behavior—must be checked against current Apple documentation and the repository's actual deployment constraints before implementation.
