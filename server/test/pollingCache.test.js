const { test, describe, before, after, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');

// Hermetic, like api.test.js: no real keys, no network. The difference is that this file runs
// *with* a database — a fake one, installed into the require cache before the app is loaded,
// because the cache path is otherwise dead code in tests (pool.query returns no rows when
// DATABASE_URL is unset, so every request looks like a miss).
process.env.GOOGLE_CIVIC_API_KEY = '';
process.env.DATABASE_URL = '';

const { pollingCacheKey } = require('../lib/pollingCacheKey');

// A stand-in for polling_cache: enough of Postgres to answer the two statements the route runs.
const rows = new Map();
const queries = [];
const fakePool = {
  query: async (sql, params) => {
    queries.push(sql);
    if (/^SELECT/.test(sql.trim())) {
      const row = rows.get(params[0]);
      return { rows: row ? [row] : [] };
    }
    if (/^INSERT/.test(sql.trim())) {
      rows.set(params[0], { locations: JSON.parse(params[1]), data_source: params[2], ttl: params[3] });
      return { rows: [] };
    }
    throw new Error(`Unexpected SQL in test: ${sql}`);
  },
};
require.cache[require.resolve('../db/client')] = {
  id: require.resolve('../db/client'),
  filename: require.resolve('../db/client'),
  loaded: true,
  exports: fakePool,
};

const app = require('../app');

const realFetch = global.fetch;
let upstream;
let server;
let base;
let upstreamCalls;

const json = (body) => new Response(JSON.stringify(body), { status: 200, headers: { 'content-type': 'application/json' } });

before(async () => {
  global.fetch = async (url, opts) => {
    const u = String(url);
    if (u.startsWith(base)) return realFetch(url, opts);
    upstreamCalls++;
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
  rows.clear();
  queries.length = 0;
  upstreamCalls = 0;

  // Dover, DE with one library nearby, plus reverse geocoding for the device path.
  upstream = (u) => {
    if (u.includes('zippopotam'))
      return json({ places: [{ 'place name': 'Dover', state: 'Delaware', 'state abbreviation': 'DE', latitude: '39.15', longitude: '-75.52' }] });
    if (u.includes('nominatim') && u.includes('reverse'))
      return json({ address: { postcode: '19901', country_code: 'us' } });
    if (u.includes('nominatim') && u.includes('library'))
      return json([{ name: 'Dover Public Library', lat: '39.158', lon: '-75.522', display_name: 'Dover Public Library, Dover', address: { city: 'Dover', postcode: '19901' } }]);
    if (u.includes('nominatim')) return json([]);
  };
});

describe('polling cache key', () => {
  test('a ZIP lookup is keyed by the ZIP alone', () => {
    assert.equal(pollingCacheKey('19901', null), '19901');
  });

  // Deliberately no ZIP: including one would force a reverse geocode before the cache could be
  // read, which is the very request a hit is supposed to save.
  test('a device lookup is keyed by the origin alone, with no ZIP', () => {
    assert.equal(pollingCacheKey('19901', { lat: 39.158, lng: -75.522 }), '@39.158,-75.522');
  });

  test('the key keeps three decimals even when the coordinate has fewer', () => {
    // Postgres compares the string, so 39.1 and 39.100 must not become two different rows.
    assert.equal(pollingCacheKey('19901', { lat: 39.1, lng: -75.5 }), '@39.100,-75.500');
  });

  test('two devices in the same ZIP do not share a key', () => {
    const a = pollingCacheKey('19901', { lat: 39.158, lng: -75.522 });
    const b = pollingCacheKey('19901', { lat: 39.191, lng: -75.553 });
    assert.notEqual(a, b);
    assert.notEqual(a, '19901');
  });

  test('every key fits the column', () => {
    const longest = pollingCacheKey('19901', { lat: -89.123, lng: -179.987 });
    assert.ok(longest.length <= 32, `${longest} is ${longest.length} characters`);
  });
});

describe('polling cache behaviour', () => {
  test('a repeated ZIP lookup is served from the cache without hitting upstream', async () => {
    const first = await fetch(`${base}/api/polling?zip=19901`);
    const firstBody = await first.json();
    assert.equal(firstBody.cached, false);
    assert.equal(firstBody.dataSource, 'estimated');
    const afterFirst = upstreamCalls;
    assert.ok(afterFirst > 0, 'the first lookup should reach upstream');

    const second = await fetch(`${base}/api/polling?zip=19901`);
    const secondBody = await second.json();
    assert.equal(secondBody.cached, true);
    assert.equal(secondBody.dataSource, 'estimated');
    assert.deepEqual(secondBody.locations, firstBody.locations);
    assert.equal(upstreamCalls, afterFirst, 'a cache hit must not reach upstream');
  });

  test('a repeated device lookup is cached too — it used to bypass the cache entirely', async () => {
    const q = 'lat=39.158&lng=-75.522';
    const first = await fetch(`${base}/api/polling?${q}`);
    const firstBody = await first.json();
    assert.equal(firstBody.cached, false);
    assert.deepEqual(firstBody.device, { lat: 39.158, lng: -75.522 });
    const afterFirst = upstreamCalls;

    const second = await fetch(`${base}/api/polling?${q}`);
    const secondBody = await second.json();
    assert.equal(secondBody.cached, true);
    assert.deepEqual(secondBody.device, { lat: 39.158, lng: -75.522 });
    // Including the reverse geocode: the key needs no ZIP, so a hit costs nothing upstream.
    assert.equal(upstreamCalls, afterFirst, 'a cache hit must not reach upstream');
    // The ZIP still reaches the caller, recovered from the cached payload rather than the key.
    assert.equal(secondBody.zip, '19901');
  });

  // The whole point of the key. A device row holds distances measured from the phone; serving it
  // to a ZIP lookup would report distances from somewhere the caller never said they were.
  test('a device row is never served to a ZIP lookup, or the other way round', async () => {
    await fetch(`${base}/api/polling?lat=39.158&lng=-75.522`);
    assert.equal(rows.size, 1);
    assert.ok(rows.has('@39.158,-75.522'));
    assert.equal(rows.has('19901'), false);

    const byZip = await fetch(`${base}/api/polling?zip=19901`);
    const body = await byZip.json();
    assert.equal(body.cached, false, 'the ZIP lookup must not reuse the device row');
    assert.equal(rows.size, 2);
    assert.ok(rows.has('19901'));
  });

  test('two devices a mile apart in one ZIP get their own rows', async () => {
    await fetch(`${base}/api/polling?lat=39.158&lng=-75.522`);
    const second = await fetch(`${base}/api/polling?lat=39.191&lng=-75.553`);
    assert.equal((await second.json()).cached, false);
    assert.equal(rows.size, 2);
  });

  test('device rows expire in a day, ZIP rows in a week', async () => {
    await fetch(`${base}/api/polling?zip=19901`);
    await fetch(`${base}/api/polling?lat=39.158&lng=-75.522`);
    assert.equal(rows.get('19901').ttl, '7 days');
    assert.equal(rows.get('@39.158,-75.522').ttl, '1 day');
  });

  test('an empty result is never cached, so a later lookup can still find something', async () => {
    upstream = (u) => {
      if (u.includes('zippopotam'))
        return json({ places: [{ 'place name': 'Dover', state: 'Delaware', 'state abbreviation': 'DE', latitude: '39.15', longitude: '-75.52' }] });
      if (u.includes('nominatim')) return json([]);
    };
    const res = await fetch(`${base}/api/polling?zip=19901`);
    assert.equal((await res.json()).dataSource, 'none');
    assert.equal(rows.size, 0);
  });
});
