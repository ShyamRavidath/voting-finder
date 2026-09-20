# Moving this project to another device

Written 2026-09-19. Read `HANDOFF.md` for *what the work is*; this file is only *how to move it*.

## Short version

GitHub has everything that matters. `git clone` on the new device gets you 100% of the code.
**Three files live only on the old machine** and are not in the repo — handle them below.

```
git clone https://github.com/ShyamRavidath/voting-finder.git D:\dev\voting-finder
```

Current `main` = `857d01d`. Nothing is uncommitted or unpushed.

## 1. Before you wipe the old machine

Copy these somewhere you'll still have (USB, private cloud folder, password manager):

| What | Path on the old machine | Why |
|---|---|---|
| `CLAUDE.md` | `C:\Users\nooby\Downloads\voting-finder-main\CLAUDE.md` | Project instructions for Claude Code. **Gitignored, so cloning will not bring it.** No secrets in it — you can also just commit it (`git add -f CLAUDE.md`) and skip the copy. |
| Claude memory | `C:\Users\nooby\.claude\projects\C--Users-nooby-Downloads-voting-finder-main\memory\` | 3 small notes (`MEMORY.md`, `vote4u-ios-app-goal.md`, `vote4u-leaked-api-keys.md`) that give a new session context. Optional — losing them costs a little re-explaining. |
| API keys | `server\.env` | **Don't copy these values — rotate them instead** (see section 3). Copy the file only if you want the variable names as a template; `.env.example` already has those. |

Nothing else is worth moving. `.playwright-mcp/` is scratch output from an old session.

## 2. Don't copy these

`node_modules/` (all three), `client/dist/`, `playwright-report/`, `test-results/`, and the
Playwright browser cache in `%LOCALAPPDATA%\ms-playwright`. All are rebuilt by the install step
and they're most of the disk footprint. Copying them across machines usually breaks native
binaries anyway.

**Put the clone on D:, not C:.** C: filled to 100% on the old machine mid-session and the
symptom was bizarre test failures (`ENOSPC`), not an obvious disk error.

## 3. Secrets: rotate, don't migrate

The old Google Civic and NewsAPI keys were committed in a legacy file and are still in git
history, so they must be replaced regardless of the move:

1. Google Cloud Console → regenerate the Civic Information API key, restrict it to that API.
2. newsapi.org → regenerate the key.
3. Put the new values in **Vercel → Settings → Environment Variables** as `GOOGLE_CIVIC_API_KEY`
   and `NEWS_API_KEY`, then redeploy. This is what turns `/api/elections` back on and moves the
   news feed off the free Google News fallback.
4. On the new device, `cp .env.example server/.env` and paste the same new values for local dev.

The app is built to run without any keys, so nothing breaks while you do this.

## 4. New device setup

Prerequisites: **Node 22** (old machine ran 22.18.0), Git, and a GitHub login with push access
to `ShyamRavidath/voting-finder`. VS Code and Claude Code optional but assumed.

```bash
git clone https://github.com/ShyamRavidath/voting-finder.git D:/dev/voting-finder
cd D:/dev/voting-finder
npm run install:all          # root + client + server
npx playwright install chromium webkit   # ~400 MB, needed for the test suite
cp .env.example server/.env  # then paste the rotated keys
```

Then restore `CLAUDE.md` into the repo root (copied in section 1).

## 5. Verify the move worked

Run these on the new device. The expected results are what the old machine produced on
2026-09-19, so any difference is a real problem, not drift.

| Command | Expect |
|---|---|
| `npm test --prefix server` | `# pass 13`, `# fail 0` |
| `npm run dev` | API on :3001, Vite on :5173, home page loads |
| `npm run test:e2e` | `87 passed` (builds the client and starts both servers itself) |
| `BASE_URL=https://vote4ucyl.vercel.app npx playwright test` | `88 passed, 8 skipped` — this one tests the **live site**, so it works even before local setup is finished |

If the live-site run passes but the local run doesn't, the problem is the new machine's setup,
not the code.

## 6. Accounts you'll need signed in on the new device

- **GitHub** — push access to the repo.
- **Vercel** — the project deploys from `main` automatically; you only need the dashboard for
  environment variables.
- **Apple Developer** (`ravidath@gmail.com`) — paid, active. Needed when iOS work starts.
- **Expo / EAS** — not created yet. Free account; needed for the first iOS build. Nothing to
  migrate.

No Mac is required at any point — EAS builds and submits iOS apps from Windows.

## 7. Where the work stands

- **Live site is fixed and verified**: https://vote4ucyl.vercel.app — 88/88 production tests pass.
- **Not done yet**: rotate + install the API keys (section 3), install the five App Store skills
  (commands in `HANDOFF.md` §8), and Phase 0 of the iOS plan (extract `shared/`, add `?lat=&lng=`
  to `/api/polling`, then scaffold the Expo app in `app/`).
- Full context, decisions, dead ends, and the phased plan: **`HANDOFF.md`**.
