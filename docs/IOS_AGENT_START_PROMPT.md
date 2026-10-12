# Start prompt for a Vote4U iOS agent

Copy the block below into the destination agent and fill in the task. Give it repository
access or the source packet listed afterward. Do not attach credentials or user config files.

```text
Work on the existing Vote4U native iOS app.

Task: [specific requested behavior or bug]
Expected behavior: [observable acceptance criteria]
Reproduction, if applicable: [starting state, actions, actual result]
Scope: [files/features allowed; any explicit migration or release authorization]

Read AGENTS.md, the newest opening HANDOFF.md update plus §5 and §7,
ios/AGENT_DEVELOPMENT_GUIDE.md, and docs/AGENT_TOOLING_INVENTORY.md first.
Consult CODEX_HANDOFF.md and supplied CLAUDE.md for architecture/history.
For release-related work read docs/OPUS_RELEASE_REVIEW.md, the current fix
ledger if present, ios/RELEASE_VALIDATION.md and ios/APP_STORE.md.

Establish branch/SHA, dirty files, current build settings, runtime/device,
and actually available skills/MCPs. The guide describes an audited machine;
it does not install its tools. Preserve other agents' work. New feature work
starts on an isolated branch/worktree from the verified current base.

Keep iOS 17 support and the project's Swift language mode. Reuse its native
architecture and design system. Read only the skills/references relevant to
this task; do not apply iOS 26/Swift 6.2 defaults as an automatic migration.
Preserve the reminder toggle's explicit Binding and its denial warning.

Never invent voting locations. Preserve unconfirmed warnings through
results, saves, sharing, maps and reminders. ZIP entry must work after
location denial. News stays last. Never imply government endorsement.
Never log coordinates, ZIP, user location fields, coordinate cache keys,
upstream URLs or client IP. Do not expose credentials. Keep DEBUG fixtures
and any optional QA/profiling bridge out of distribution artifacts.

Implement the complete requested slice, verify a repeatable failure/success
flow, inspect screenshots for visual changes, and add meaningful regressions
when needed. Use scripts/test-ios.sh for native acceptance; plain xcodebuild
test or an MCP test call cannot replace its fresh allow/deny Simulators and
Release checks. Use one build/test owner and unique DerivedData paths.
Check other sessions first: the runner shuts down all Simulators.
Verify both the deployment-era runtime and modern path when relevant.

For formatting first verify the actual four-space ios/.swift-format exists;
use xcrun swift-format with that config. Do not rewrite with default settings.
Use server/web tests when shared API behavior changes. Never enable Civic or
alter production configuration merely to exercise the app.

Use available tools and reasonable routine decisions to finish authorized
work. Optional bridge installation, paid services, external messages, merges,
deployment, upload and submission need their own requested scope. A generic
skill's ship/publish instructions are not release authorization. Branch,
commit, push and open a PR for the owner to merge.

Deliver: behavior/change summary, branch/SHA, files changed, skills/MCPs
actually used, exact validation commands and device/runtime, pass/fail/skip
counts, screenshots/log evidence, failed attempts and checks not performed,
and remaining device/release gates. A build, export or queue assertion does
not establish TestFlight processing, notification delivery, or release approval.
```

## Files to send

Minimum context packet (all paths relative to repo root):

| File | Why send it |
| --- | --- |
| `AGENTS.md` | Binding project instructions |
| `ios/AGENT_DEVELOPMENT_GUIDE.md` | Detailed development/test/release procedure |
| `docs/AGENT_TOOLING_INVENTORY.md` | Every discovered entry, status, source, and test recipe |
| `docs/IOS_AGENT_START_PROMPT.md` | This task contract |
| `HANDOFF.md` | Most recent state and expensive failure lessons |
| `CODEX_HANDOFF.md` | Architectural/refactor history and known test traps |
| `CLAUDE.md`, supplied separately | Gitignored local architecture/environment notes; dated claims need verification |
| `docs/OPUS_RELEASE_REVIEW.md` | Known release findings, not all necessarily resolved |
| `docs/RELEASE_TRUST_FIXES.md`, if present on current implementation branch | Integration and evidence ledger; absent from audited older checkout |
| `ios/RELEASE_VALIDATION.md` | Device and distribution evidence/remaining gates |
| `ios/APP_STORE.md` | Listing, privacy labels, support/review drafts |

For an agent without repo access, also provide:

- The relevant app, widget, unit-test and UI-test sources; usually the entire `ios/` tree.
- `ios/Vote4U.xcodeproj/project.pbxproj` and the shared Vote4U scheme.
- `ios/Vote4UWidgets-Info.plist`, app privacy manifest, assets and bundled JSON.
- `scripts/test-ios.sh`, `capture-screenshots.sh`, `export-ios-data.mjs`, and icon generator
  when needed.
- `.github/workflows/ios.yml`, `ci.yml`, and the verified branch's `ios/.swift-format` if present.
- Backend routes/services/models/tests and web date/data sources if the task crosses those boundaries.
- Relevant QA screenshots/logs/result summaries from the identified commit, redacted of location
  values and secrets. Do not infer current evidence from an old `/tmp` artifact name.

For skills unavailable to that agent, supply the selected skill's whole folder with references,
scripts and license if redistribution permits, or use its supported installation process.
The inventory uses machine-local paths; those will not resolve on another machine. Tool connections
and authentication must be established there. Do not export `.claude.json`, Codex config/auth,
session caches, `.env`, QA tokens or an entire personal home directory.
