# Device transfer — completed 2026-09-20

The move off the Windows PC is **done**. This file is now a record of what happened and what is
still outstanding, not a set of instructions. For *what the work is*, read `HANDOFF.md`.

## What moved

| From | To |
|---|---|
| Windows PC, `C:\Users\nooby\Downloads\voting-finder-main` | **Mac (Apple Silicon, macOS 27)**, `~/voting-finder` |
| Node 22.18.0 | **Node 26.0.0 / npm 11.12.1** |
| No Mac → Expo / EAS cloud builds | **Xcode locally** — see the pivot note at the top of `HANDOFF.md` |

The clone is current with `origin/main` (`9dcb25b` at the time of the move). Nothing was left
uncommitted or unpushed on the old machine.

## Verified on the Mac (2026-09-20)

- `npm run install:all` — clean, 0 vulnerabilities.
- `npm test --prefix server` — **19 pass, 0 fail** on Node 26 (13 before the lat/lng work).
- `npm run test:e2e` — **87 passed, 9 skipped**.
- `BASE_URL=https://vote4ucyl.vercel.app npx playwright test` — **88 passed, 8 skipped**.

Both Playwright numbers match what the old Windows machine produced on 2026-09-19, so the move
is verified end to end.
- Live production API probed directly: `/api/health` 200, `/api/polling?zip=90210` 200 with real
  locations, `/api/news` 200 (RSS fallback), `/api/elections` 503 (keys still unset, as expected).

## Files that were hand-carried (not in git) and where they ended up

| File | Status |
|---|---|
| `CLAUDE.md` | In the repo root. Still gitignored — it is local-only by design. |
| `MEMORY.md`, `vote4u-ios-app-goal.md`, `vote4u-leaked-api-keys.md` | Arrived in the repo root by mistake; **moved on 2026-09-20** to their correct home, `~/.claude/projects/-Users-shyamravidath-voting-finder/memory/`. |
| `server/.env` | **Deliberately not carried.** The keys are being rotated, not migrated — see below. |

## Still outstanding

1. **Rotate the leaked Google Civic API key.** It was committed in the removed legacy
   `index.html` and remains in git history, so it must be replaced regardless of the move.
   - Google Cloud Console → regenerate the Civic Information API key, restrict it to that API.
   - Add it to **Vercel → Settings → Environment Variables** as `GOOGLE_CIVIC_API_KEY`, then
     redeploy. This turns `/api/elections` back on.
   - Locally: `cp .env.example server/.env` and paste the same value. (`server/.env` does not
     exist on the Mac yet.)
   The old NewsAPI key was leaked too, but **NewsAPI was removed from this project on
   2026-09-20**, so it no longer needs rotating here — do it anyway if that key was reused
   elsewhere. The app is built to run without any keys, so nothing breaks while this is pending.
2. ~~Playwright browsers~~ **installed and both suites verified** (see above).
3. **Xcode.app is installed, but `xcode-select` still points at the Command Line Tools.** Until
   that is switched there is no `xcodebuild` and no `simctl`:
   ```
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -license accept
   xcodebuild -runFirstLaunch
   ```
   (Or Xcode ▸ Settings ▸ Locations ▸ Command Line Tools.) The iOS **Simulator runtimes** are a
   separate ~7–10 GB download from Xcode ▸ Settings ▸ Components.

## Accounts needed on this Mac

- **GitHub** — push access to `ShyamRavidath/voting-finder`. Working.
- **Vercel** — deploys from `main` automatically; the dashboard is only needed for env vars.
- **Apple Developer** (`ravidath@gmail.com`) — paid, active. Add it in Xcode ▸ Settings ▸
  Accounts once Xcode is installed.
- **Expo / EAS** — **no longer needed.** The native plan does not use it.

## Old-machine notes that no longer apply

- "Put the clone on D:, not C:" — a Windows disk-space problem. The Mac has 127 GB free.
- "No Mac is required at any point — EAS builds and submits iOS apps from Windows." — true, but
  moot. Builds are local now.
