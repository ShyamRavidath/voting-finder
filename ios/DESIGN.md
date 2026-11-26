---
name: Vote4U native iPhone
description: Native civic tools with clear actions, readable system type, and an established blue accent.
colors:
  action-blue: "rgb(14.9% 38.8% 85.1%)"
  accent-light: "rgb(14.9% 38.8% 85.1%)"
  accent-dark: "rgb(37.6% 64.7% 98%)"
typography:
  countdown:
    fontFamily: "SF Pro Rounded"
    fontSize: "60pt"
    fontWeight: 700
  title:
    fontFamily: "SF Pro"
    fontWeight: 700
  headline:
    fontFamily: "SF Pro"
    fontWeight: 600
  body:
    fontFamily: "SF Pro"
  supporting:
    fontFamily: "SF Pro"
  caption:
    fontFamily: "SF Pro"
rounded:
  card: "16pt"
  compact: "14pt"
  local-search: "12pt"
spacing:
  section: "24pt"
  content: "12pt"
  row: "6pt"
components:
  primary-action:
    backgroundColor: "{colors.action-blue}"
  surface-card:
    rounded: "{rounded.card}"
  zip-field:
    rounded: "{rounded.compact}"
    height: "50pt"
  directory-field:
    rounded: "{rounded.local-search}"
    height: "48pt"
  meeting-follow:
    height: "44pt"
---

# Design System: Vote4U native iPhone

## Overview

**Creative North Star: "A clear civic companion"**

This describes the native implementation in this checkout, extending the existing identity under the owner's direction: “less boring, but not too complicated.” System typography, SF Symbols, standard navigation, blue actions, and grouped surfaces make public information easier to use. The phrase above describes that existing direction; it is not a new brand or approved visual comp.

The native system owns appearance, text scaling, control states, and navigation behavior. Content supplies the character: a prominent election countdown, useful service titles, dated meetings, and direct action labels. This document applies to the iPhone app with iOS 17 minimum. It does not redesign the web app or widget.

**Key Characteristics:**

- Familiar native navigation and adaptive controls.
- Blue actions on semantic grouped surfaces.
- Strong headings, open section spacing, and concise copy.
- Visible source context and accessible alternatives.

Source authority: [theme](Vote4U/Design/Vote4UTheme.swift), [action styles](Vote4U/Design/Vote4UActionStyle.swift), [accent asset](Vote4U/Assets.xcassets/AccentColor.colorset/Contents.json), and [app root](Vote4U/Vote4UApp.swift). Product direction is in [PRODUCT.md](../PRODUCT.md) and [BRIEF.md](../docs/local-overhaul/BRIEF.md). Evidence and outstanding review limits remain in [REVIEW.md](../docs/local-overhaul/REVIEW.md); data freshness and action meaning remain in [DATA.md](../docs/local-overhaul/DATA.md). This source extraction is not a visual approval or release receipt. The matching [.impeccable/design.json](.impeccable/design.json) holds extension metadata and illustrative browser specimens. Its synthesized tonal ramps are panel aids, not native palette additions; its CSS approximates controls only for preview and does not override SwiftUI geometry or behavior.

## Colors

An established blue accent gives actions emphasis; adaptive neutral surfaces and text carry most content.

### Primary

- **Action blue** is `Vote4UTheme.actionBlue`, the fixed fill for prominent actions in both appearances.
- **Light accent** and **dark accent** are the existing `AccentColor` asset variants. `RootView` explicitly applies `Color("AccentColor")` as its tint. Links, inline actions, selected navigation, and tinted meeting dates inherit this adaptive accent.

### Neutral

Native semantic colors have no single normative CSS color value. Use these UIKit/SwiftUI roles rather than copying resolved screenshot colors into the palette:

- `systemGroupedBackground`: page ground, through `Vote4UTheme.pageBackground`.
- `secondarySystemGroupedBackground`: content cards and grouped content surfaces.
- `Color.primary`: principal text. `Vote4UTheme.supportingText` is primary at 72% opacity, rather than a fixed gray.
- `tertiarySystemFill`: the Local directory search field. ZIP input uses `.background` with a secondary-color outline.
- `Vote4UTheme.heroBackground`: adaptive accent at 10% opacity, used behind the countdown.

**The Two Blue Roles Rule.** Use the adaptive asset tint for inline actions and the fixed action blue for prominent filled controls. Do not substitute one role for the other across the app.

The initial review found insufficient dark-mode caption-link contrast under a fixed tint. The explicit adaptive root tint is implemented. The final dark recapture resolves the contrast finding at 6.69:1; the inline scoring pass and its limits are recorded in REVIEW.md. The failed contrast is not a system token or accepted exception.

## Typography

**Display Font:** native SF Pro Rounded for the countdown only.
**Body Font:** native SF Pro via SwiftUI semantic text styles.

System fonts and SF Symbols are required parts of this native identity. Do not replace them with a web font pairing or imported icon library.

### Hierarchy

- **Countdown:** the frontmatter size is a base point size, scaled with `@ScaledMetric(relativeTo: .largeTitle)`. Bold rounded numerals use monospaced digits, a single line, and minimum scale factor 0.55. The number caps at accessibility2; its combined accessibility label speaks the full countdown.
- **Title:** `.title.bold()` for meeting detail and electoral tally; `.title2.bold()` for Local section content; native navigation titles remain system-managed.
- **Headline:** `.headline` for service names, meeting titles, and actionable card headings. `.title3.bold()` also introduces the voting-plan card.
- **Body:** default body text for explanation and official records.
- **Supporting:** `.subheadline` for summaries, `.footnote` for source checks and notices, using the semantic supporting-text color where specified.
- **Caption:** `.caption` for compact source/context text, not essential actions hidden by size.

The frontmatter deliberately omits fixed sizes and line heights for semantic text roles. The operating system resolves them for the user's content size; the token names are documentation roles, not replacement font constants.

**The Native Type Rule.** Preserve semantic text styles and allow wrapping. At accessibility sizes, change control arrangement before constraining essential text.

## Layout

[Home](Vote4U/Features/Home/HomeView.swift), [Vote](Vote4U/Features/Vote/VoteView.swift), and [Map](Vote4U/Features/Map/ElectoralMapView.swift) use a `NavigationStack`, scrolling content, and a leading-content `LazyVStack` with the section-spacing token and native outer padding. Cards retain their local padding: ordinary cards use native padding; the Vote search form uses 18 points and the countdown uses 20 points. Do not force these into a uniform padding token.

[Local](Vote4U/Features/Local/LocalCivicView.swift) uses native `List` and `Section` grouping. Its three-way segmented control becomes vertically stacked, checkmarked buttons at accessibility text sizes. The ZIP field and Search button similarly change from a horizontal to a vertical arrangement. Local search is at least the documented directory-field height; ZIP input and Follow controls also use minimum heights, not fixed clipping heights.

The Local welcome screen uses 24-point padding and a 600-point maximum content width; this is a local composition, not a desktop breakpoint. Native safe areas, tab bars, navigation bars, and keyboard handling remain platform-owned. No web breakpoint system is introduced.

## Elevation & Depth

The updated pages separate content through grouped backgrounds, spacing, and modest accent tint. The sampled cards and Local groups do not introduce custom drop shadows. Native controls may supply their own material and elevation. The primary action helper uses `.borderedProminent` on iOS 17 and `.glassProminent` when available on iOS 26 and later; this does not turn every content surface into glass.

**The Semantic Surface Rule.** Use semantic grouped surfaces for reading content, with the light accent wash reserved for existing emphasized content such as the countdown. Preserve native control material independently of page material.

## Shapes

Cards use the card radius; compact containers and the ZIP field use the compact radius. Local search has its own smaller radius. These values describe custom SwiftUI shapes, not a mandate to override native list-group, button, tab-bar, or segmented-control geometry. The ZIP field has a one-point secondary-color outline at 30% opacity.

## Components

### Buttons

Prominent actions use the shared action helper or the existing native prominent style, with fixed action blue. Their padding, rounding, pressed state, and disabled appearance remain native. Secondary location search uses `.bordered`; inline Follow uses `.borderless`. Keep labels direct: “Search,” “Use my location,” “Open meeting page.” SF Symbols support labels and never replace an essential accessible name.

### Cards / Containers

Reading surfaces use semantic secondary grouped backgrounds and the documented custom radii. Countdown emphasis comes from scale and a subtle accent surface, with no decorative watermark. Saved polling results may use a light accent surface; retain their truth labels. Do not turn every Local row into a separate bespoke card.

### Inputs / Fields

[VoteSearchForm](Vote4U/Features/Vote/VoteSearchForm.swift) uses a labeled ZIP field, numeric keyboard, postal-code content type, and a Done keyboard action. Local directory search has an inline clear action when populated and hides its decorative magnifying glass at accessibility sizes. Map and full service-directory search use `.searchable` with the navigation-bar drawer always visible. Focus and keyboard behavior remain native, with no fabricated web focus treatment in app code.

### Navigation

`TabView` contains native NavigationStacks; News remains last when enabled. Local uses Get help, Meetings, and Following within its screen. Navigation destinations use ordinary native back navigation. The sidecar previews are illustrative browser specimens and must not become custom tab or picker implementations.

### Meeting rows and details

Date, title, and any non-scheduled status establish row hierarchy; a separate labeled Follow action sits beneath the navigation target. The [detail view](Vote4U/Features/Local/CivicMeetingView.swift) puts title/date and Follow before the official link and eligible Calendar action. Follow state uses both text and bookmark state. Source checks, calendar limits, and unavailable states remain readable, using native sections and footers.

### Countdown and electoral map

The [countdown](Vote4U/Features/Home/ElectionCountdownCard.swift) animates numeric changes with `.snappy` only when Reduce Motion is off. This is a local motion rule, not a new transition vocabulary. The [map shapes](Vote4U/Features/Map/ElectoralStateShapeView.swift) retain the existing neutral geographic fill and selected outline. Their accessible interaction remains the searchable state list; map graphics are not individual VoiceOver targets. Geographic fills are domain-specific and are not promoted to brand tokens.

## Do's and Don'ts

### Do:

- **Do** use native system fonts, SF Symbols, and standard navigation.
- **Do** resolve inline tint through the existing light/dark AccentColor asset.
- **Do** keep prominent action fills on the fixed action blue.
- **Do** preserve Dynamic Type reflow, clear labels, and native control states.
- **Do** keep source links, dates, and uncertainty visible where they affect an action.

### Don't:

- **Don't** replace semantic system surfaces with fixed screenshot colors.
- **Don't** infer government endorsement from blue styling or official-source links.
- **Don't** hide ZIP entry behind location permission or reduce polling caution for visual simplicity.
- **Don't** imply that following sends notifications or that calendar copies update themselves.
- **Don't** promote the failed dark-link contrast or pending review into an accepted visual rule.
