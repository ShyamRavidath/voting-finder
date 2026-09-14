# Vote4U

A free, nonpartisan civic-engagement app for U.S. voters, built for the 2028 presidential cycle (and useful for every election before it). Three tools in one place: a polling-place finder, an Electoral College map, and a 2028 election news feed. It's mobile-first and set up to become an iOS app.

Live: https://vote4ucyl.vercel.app

## What it does

- **Polling place finder** (`/tools?tab=booths`): enter a 5-digit ZIP and get nearby voting locations, each with a Directions button (Apple Maps on iOS, Google Maps elsewhere) and a map. Results are shareable via `?zip=`. The server tries, in order:
  1. **Google Civic Information API**: official polling, early-voting, and drop-off locations for upcoming elections in the user's state (usually published a few weeks before an election).
  2. **OpenStreetMap Nominatim**: nearby libraries, community centers, and town halls, clearly labeled *not confirmed*.
  3. **Nothing found**: an honest empty state. The app never invents locations. Official lookup links (USA.gov, NASS, Vote.gov) are always shown.
- **Electoral map** (`/tools?tab=map`): an SVG map of all 50 states + DC (no map-tile service needed), a 538-vote tally with the 270 line, and a tappable state list. Data lives in `client/src/data/stateData.js`.
- **Election news** (`/news`): 2028 headlines from NewsAPI, falling back to Google News RSS (no key needed) if NewsAPI is unconfigured, over quota, or down. Party labels come only from a watchlist of named 2028 candidates.

## Architecture

```
voting-finder/
├── api/index.js     Vercel serverless entry: exports the Express app
├── server/          Express 5 API (also runs standalone for local dev)
│   ├── app.js        app setup: CORS, rate limit, routes, JSON 404/500
│   ├── routes/       news.js, polling.js, elections.js
│   ├── services/     civicService, geocodeService, newsService
│   ├── db/           optional Postgres cache (schema.sql, client.js)
│   └── test/         node:test API tests (upstream APIs stubbed)
├── client/          React 19 + Vite + Tailwind v4 SPA
│   └── src/          pages/, components/, hooks/, lib/, data/
├── tests/e2e/       Playwright tests (desktop Chrome, iPhone Safari, Android Chrome)
├── scripts/         generate-icons.mjs (PWA + App Store icons from the logo)
├── assets/          app-icon-1024.png (App Store icon master)
└── vercel.json      builds client, deploys api/ as a function, SPA rewrites, headers
```

Frontend and API deploy together on Vercel, so the browser calls same-origin `/api/*`. Responses carry `Cache-Control: s-maxage` headers, so Vercel's CDN absorbs traffic and upstream APIs (NewsAPI's 100 requests/day free tier, Nominatim's fair-use policy) see only a trickle.

## Running locally

Requires Node 22.

```bash
npm run install:all
cp .env.example server/.env   # fill in keys (all optional)
npm run dev                   # API on :3001, Vite on :5173 (proxies /api)
```

| Variable (server) | Required | Purpose |
|---|---|---|
| `GOOGLE_CIVIC_API_KEY` | optional | Official polling locations. Without it, OpenStreetMap venues are used. |
| `NEWS_API_KEY` | optional | NewsAPI headlines. Without it, Google News RSS is used. |
| `DATABASE_URL` | optional | Postgres cache (run `server/db/schema.sql`). The CDN cache makes this unnecessary on Vercel. |
| `CLIENT_URL` | optional | Extra allowed CORS origin. |
| `RATE_LIMIT_MAX` | optional | Requests per 15 min per IP (default 100). |

| Variable (client, build time) | Purpose |
|---|---|
| `VITE_API_BASE` | Only for native/mobile builds, which have no same-origin server. Set to the deployed site, e.g. `https://vote4ucyl.vercel.app`. Leave unset for the web. |

## Tests

```bash
npm test --prefix server   # API unit/integration tests (no network)
npm run test:e2e           # builds the client, starts both servers, runs Playwright
BASE_URL=https://vote4ucyl.vercel.app npx playwright test   # same suite against the live site
```

The e2e suite covers every page on three device profiles: no runtime errors, no sideways scrolling, axe WCAG 2.1 AA checks, navigation, search success/empty/error/offline states, the electoral map, and news fallbacks.

## Deployment (free)

Everything runs on Vercel's free Hobby plan: push to `main` and Vercel builds the client and deploys `api/` as a serverless function. In the Vercel project settings, add `GOOGLE_CIVIC_API_KEY` and `NEWS_API_KEY` as environment variables (optional; the app works without them). No separate backend host is needed.
