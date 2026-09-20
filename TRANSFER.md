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
- `npm test --prefix server` — **13 pass, 0 fail** on Node 26.
- Live production API probed directly: `/api/health` 200, `/api/polling?zip=90210` 200 with real
  locations, `/api/news` 200 (RSS fallback), `/api/elections` 503 (keys still unset, as expected).

## Files that were hand-carried (not in git) and where they ended up

| File | Status |
|---|---|
| `CLAUDE.md` | In the repo root. Still gitignored — it is local-only by design. |
| `MEMORY.md`, `vote4u-ios-app-goal.md`, `vote4u-leaked-api-keys.md` | Arrived in the repo root by mistake; **moved on 2026-09-20** to their correct home, `~/.claude/projects/-Users-shyamravidath-voting-finder/memory/`. |
| `server/.env` | **Deliberately not carried.** The keys are being rotated, not migrated — see below. |

## Still outstanding

1. **Rotate the leaked API keys.** The old Google Civic and NewsAPI keys were committed in the
   removed legacy `index.html` and remain in git history, so they must be replaced regardless of
   the move.
   - Google Cloud Console → regenerate the Civic Information API key, restrict it to that API.
   - newsapi.org → regenerate the key.
   - Add both to **Vercel → Settings → Environment Variables** as `GOOGLE_CIVIC_API_KEY` and
     `NEWS_API_KEY`, then redeploy. This turns `/api/elections` back on and moves news off the
     Google News RSS fallback.
   - Locally: `cp .env.example server/.env` and paste the same values. (`server/.env` does not
     exist on the Mac yet.)
   The app is built to run without any keys, so nothing breaks while this is pending.
2. **Playwright browsers are not installed on the Mac.** `npx playwright install chromium webkit`
   (~400 MB), then confirm `npm run test:e2e` → 87 passed and
   `BASE_URL=https://vote4ucyl.vercel.app npx playwright test` → 88 passed, 8 skipped.
3. **Xcode is not installed** — Command Line Tools only. See `HANDOFF.md` §8 step 1.

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
