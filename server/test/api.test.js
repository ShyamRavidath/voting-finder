const { test, describe, before, after, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');

// Keep tests hermetic: no real keys, no DB, no network.
process.env.GOOGLE_CIVIC_API_KEY = '';
process.env.NEWS_API_KEY = '';
process.env.DATABASE_URL = '';
require('dotenv').config = () => ({});

const { decodeEntities, detectParty } = require('../services/newsService');
const { parseLocations } = require('../services/civicService');
const app = require('../app');

const realFetch = global.fetch;
let upstream; // (url) => Response | undefined
let server;
let base;

before(async () => {
  global.fetch = async (url, opts) => {
    const u = String(url);
    if (u.startsWith(base)) return realFetch(url, opts);
    const res = upstream?.(u);
    if (!res) throw new Error(`Unexpected upstream request in test: ${u}`);
    return res;
  };
  server = http.createServer(app);
  await new Promise((r) => server.listen(0, r));
  base = `http://127.0.0.1:${server.address().port}`;
});

after(() => {
  server.close();
  global.fetch = realFetch;
});

beforeEach(() => {
  upstream = undefined;
  require('../routes/news').clearCache();
});

const json = (body, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json' } });

describe('newsService helpers', () => {
  test('decodes XML entities and CDATA', () => {
    assert.equal(decodeEntities('Tom &amp; Jerry &#39;24 &quot;hi&quot; &#x2014;'), `Tom & Jerry '24 "hi" —`);
    assert.equal(decodeEntities('<![CDATA[Raw <b>text</b>]]>'), 'Raw <b>text</b>');
  });

  test('party comes only from a named 2028 candidate', () => {
    assert.equal(detectParty("Democrats Are Laughing at Trump's Midterm Plan", ''), null);
    assert.equal(detectParty('Harrisburg council votes on budget', ''), null);
    assert.equal(detectParty('Newsom weighs 2028 bid', ''), 'Democrat');
    assert.equal(detectParty('AOC tours Midwest', ''), 'Democrat');
    assert.equal(detectParty('JD Vance speaks in Ohio', ''), 'Republican');
  });
});

describe('civicService.parseLocations', () => {
  test('never invents coordinates', () => {
    const locs = parseLocations({
      pollingLocations: [{ address: { locationName: 'City Hall', line1: '1 Main St', city: 'Dover', state: 'DE', zip: '19901' } }],
      earlyVoteSites: [{ address: { line1: '2 Oak St' }, latitude: 39.1, longitude: -75.5 }],
      dropOffLocations: [{ address: {} }],
    });
    assert.equal(locs.length, 2);
    assert.equal(locs[0].lat, null);
    assert.equal(locs[0].addr, '1 Main St, Dover, DE, 19901');
    assert.equal(locs[1].type, 'Early Voting');
    assert.equal(locs[1].lat, 39.1);
  });
});

describe('API routes', () => {
  test('GET /api/health', async () => {
    const res = await fetch(`${base}/api/health`);
    assert.equal(res.status, 200);
    assert.deepEqual(await res.json(), { status: 'ok' });
  });

  test('unknown /api route returns JSON 404', async () => {
    const res = await fetch(`${base}/api/nope`);
    assert.equal(res.status, 404);
    assert.match(res.headers.get('content-type'), /json/);
  });

  test('CORS: allows app + native origins, ignores others without erroring', async () => {
    for (const origin of ['https://vote4ucyl.vercel.app', 'capacitor://localhost', 'https://voting-finder-git-x-shyamravidaths-projects.vercel.app']) {
      const res = await fetch(`${base}/api/health`, { headers: { Origin: origin } });
      assert.equal(res.headers.get('access-control-allow-origin'), origin, origin);
    }
    const evil = await fetch(`${base}/api/health`, { headers: { Origin: 'https://evil.example' } });
    assert.equal(evil.status, 200);
    assert.equal(evil.headers.get('access-control-allow-origin'), null);
  });

  test('polling rejects malformed ZIP codes', async () => {
    for (const zip of ['', 'abc', '1234', '123456', '1234a']) {
      const res = await fetch(`${base}/api/polling?zip=${zip}`);
      assert.equal(res.status, 400, `zip=${zip}`);
      assert.match((await res.json()).error, /5-digit/);
    }
  });

  test('polling returns friendly 404 for a ZIP that does not exist', async () => {
    upstream = (u) => (u.includes('zippopotam') ? new Response('{}', { status: 404 }) : undefined);
    const res = await fetch(`${base}/api/polling?zip=00000`);
    assert.equal(res.status, 404);
    assert.match((await res.json()).error, /couldn't find ZIP code 00000/);
  });

  test('polling returns dataSource "none" (never fake locations) when nothing is found', async () => {
    upstream = (u) => {
      if (u.includes('zippopotam'))
        return json({ places: [{ 'place name': 'Dover', state: 'Delaware', 'state abbreviation': 'DE', latitude: '39.15', longitude: '-75.52' }] });
      if (u.includes('nominatim')) return json([]);
    };
    const res = await fetch(`${base}/api/polling?zip=19901`);
    assert.equal(res.status, 200);
    const body = await res.json();
    assert.equal(body.dataSource, 'none');
    assert.deepEqual(body.locations, []);
    assert.equal(body.place.stateAbbr, 'DE');
    assert.match(res.headers.get('cache-control'), /s-maxage=3600/);
  });

  test('polling returns estimated venues from OpenStreetMap', async () => {
    upstream = (u) => {
      if (u.includes('zippopotam'))
        return json({ places: [{ 'place name': 'Dover', state: 'Delaware', 'state abbreviation': 'DE', latitude: '39.15', longitude: '-75.52' }] });
      if (u.includes('nominatim') && u.includes('library'))
        return json([{ name: 'Dover Public Library', lat: '39.158', lon: '-75.522', display_name: 'Dover Public Library, Dover', address: { house_number: '35', road: 'Loockerman Plaza', city: 'Dover', postcode: '19901' } }]);
      if (u.includes('nominatim')) return json([]);
    };
    const res = await fetch(`${base}/api/polling?zip=19901`);
    const body = await res.json();
    assert.equal(body.dataSource, 'estimated');
    assert.equal(body.locations[0].name, 'Dover Public Library');
    assert.equal(body.locations[0].addr, '35 Loockerman Plaza, Dover, Delaware, 19901');
    assert.ok(body.locations[0].isEstimated);
  });

  test('news falls back to Google News RSS when no NewsAPI key is set', async () => {
    const rss = `<rss><channel>
      <item><title>Newsom eyes 2028 run &amp; more - Example Times</title><link>https://example.com/a</link>
        <pubDate>Sat, 12 Sep 2026 10:00:00 GMT</pubDate><source url="https://example.com">Example Times</source></item>
      <item><title>Local bake sale - Town Crier</title><link>https://example.com/b</link>
        <pubDate>Sat, 12 Sep 2026 09:00:00 GMT</pubDate><source url="https://example.com">Town Crier</source></item>
    </channel></rss>`;
    upstream = (u) => (u.includes('news.google.com') ? new Response(rss, { status: 200 }) : undefined);
    const res = await fetch(`${base}/api/news`);
    assert.equal(res.status, 200);
    const body = await res.json();
    assert.equal(body.provider, 'google-news');
    assert.equal(body.articles.length, 1, 'irrelevant story filtered out');
    assert.equal(body.articles[0].title, 'Newsom eyes 2028 run & more');
    assert.equal(body.articles[0].source, 'Example Times');
    assert.equal(body.articles[0].party, 'Democrat');
  });

  test('news reuses the in-memory cache instead of re-hitting upstream', async () => {
    let calls = 0;
    const rss = `<rss><channel><item><title>2028 race heats up - Wire</title><link>https://example.com/c</link>
      <pubDate>Sat, 12 Sep 2026 10:00:00 GMT</pubDate><source url="https://example.com">Wire</source></item></channel></rss>`;
    upstream = (u) => (u.includes('news.google.com') ? (calls++, new Response(rss, { status: 200 })) : undefined);
    await fetch(`${base}/api/news`);
    const second = await fetch(`${base}/api/news?refresh=true`);
    assert.equal(calls, 1);
    assert.equal((await second.json()).articles.length, 1);
  });

  test('news returns a clean 502 when every source is down', async () => {
    upstream = () => new Response('down', { status: 503 });
    const res = await fetch(`${base}/api/news`);
    assert.equal(res.status, 502);
    assert.match((await res.json()).error, /unavailable/);
    assert.equal(res.headers.get('cache-control'), 'no-store');
  });
});
