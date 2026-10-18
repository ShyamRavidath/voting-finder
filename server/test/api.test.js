const { test, describe, before, after, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');

// Keep tests hermetic: no real keys, no DB, no network.
process.env.GOOGLE_CIVIC_API_KEY = '';
process.env.DATABASE_URL = '';
require('dotenv').config = () => ({});

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
});

const json = (body, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json' } });

// Real rows from Nominatim. Every rejected one was being shown to voters as a polling place.
describe('geocodeService.isPlausibleVenue', () => {
  const { isPlausibleVenue } = require('../services/geocodeService');

  test('rejects things a voter cannot walk into', () => {
    assert.ok(!isPlausibleVenue({ class: 'highway', type: 'bus_stop' }), 'bus stop named "…Town Hall"');
    assert.ok(!isPlausibleVenue({ class: 'amenity', type: 'public_bookcase' }), 'Little Free Library');
    assert.ok(!isPlausibleVenue({ class: 'amenity', type: 'recycling' }), 'Community Compost Center');
    assert.ok(!isPlausibleVenue({ class: 'leisure', type: 'garden' }));
  });

  test('keeps real civic buildings, including the loosely tagged ones', () => {
    assert.ok(isPlausibleVenue({ class: 'amenity', type: 'library' }));
    assert.ok(isPlausibleVenue({ class: 'amenity', type: 'townhall' }));
    assert.ok(isPlausibleVenue({ class: 'amenity', type: 'community_centre' }));
    assert.ok(isPlausibleVenue({ class: 'amenity', type: 'school' }));
    assert.ok(isPlausibleVenue({ class: 'amenity', type: 'fire_station' }));
    // A denylist, not an allowlist: real community centers are often only tagged building=yes.
    assert.ok(isPlausibleVenue({ class: 'building', type: 'yes' }));
    assert.ok(isPlausibleVenue({}), 'a row with no class/type at all is not evidence against it');
  });
});

describe('geocodeService.coordsToZip', () => {
  const { coordsToZip, OutsideUsError, ZipNotFoundError } = require('../services/geocodeService');

  test('accepts a complete US ZIP+4 and narrows it to five digits', async () => {
    upstream = (u) => u.includes('/reverse')
      ? json({ address: { postcode: ' 19901-1234 ', country_code: 'US' } }) : undefined;
    assert.equal(await coordsToZip(39.158, -75.522), '19901');
  });

  test('rejects an ambiguous postcode rather than extracting an unsupported ZIP', async () => {
    upstream = (u) => u.includes('/reverse')
      ? json({ address: { postcode: '19901 / 19902', country_code: 'us' } }) : undefined;
    await assert.rejects(coordsToZip(39.158, -75.522), ZipNotFoundError);
  });

  test('a non-US country wins even when its postcode looks like a US ZIP', async () => {
    upstream = (u) => u.includes('/reverse')
      ? json({ address: { postcode: '19901', country_code: 'mx' } }) : undefined;
    await assert.rejects(coordsToZip(19.43, -99.13), OutsideUsError);
  });

  test('missing country evidence cannot turn five digits into a US location', async () => {
    upstream = (u) => u.includes('/reverse')
      ? json({ address: { postcode: '19901' } }) : undefined;
    await assert.rejects(coordsToZip(39.158, -75.522), ZipNotFoundError);
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

  test('CORS rejects lookalike deployments and advertises read-only methods', async () => {
    for (const origin of ['https://vote4ucyl-attacker.vercel.app', 'https://voting-finder-attacker.vercel.app']) {
      const res = await fetch(`${base}/api/health`, { headers: { Origin: origin } });
      assert.equal(res.headers.get('access-control-allow-origin'), null);
    }
    const res = await fetch(`${base}/api/health`, { method: 'OPTIONS', headers: { Origin: 'https://vote4ucyl.vercel.app' } });
    assert.equal(res.headers.get('access-control-allow-methods'), 'GET,HEAD,OPTIONS');
  });

  test('unused malformed JSON bodies are not parsed or logged', async () => {
    const logs = [];
    const original = console.error;
    console.error = (...args) => logs.push(args);
    try {
      const res = await fetch(`${base}/api/nope`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{"private-input":',
      });
      assert.equal(res.status, 404);
      assert.deepEqual(logs, []);
    } finally { console.error = original; }
  });

  test('upstream errors cannot disclose request values through application logs', async () => {
    const logs = [];
    const original = console.error;
    console.error = (...args) => logs.push(args);
    upstream = () => { throw new Error('sensitive-upstream-url-and-location'); };
    try {
      const res = await fetch(`${base}/api/polling?zip=19901`);
      assert.equal(res.status, 502);
      assert.deepEqual(logs, [['ZIP lookup failed']]);
    } finally { console.error = original; }
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
    assert.equal(body.searchRadiusKm, null);
    assert.equal(body.place.stateAbbr, 'DE');
    assert.match(res.headers.get('cache-control'), /s-maxage=3600/);
  });

  test('polling returns estimated venues from OpenStreetMap', async () => {
    upstream = (u) => {
      if (u.includes('zippopotam'))
        return json({ places: [{ 'place name': 'Dover', state: 'Delaware', 'state abbreviation': 'DE', latitude: '39.15', longitude: '-75.52' }] });
      if (u.includes('nominatim') && u.includes('library'))
        return json([{ name: 'Dover Public Library', lat: '39.158', lon: '-75.522', display_name: 'Dover Public Library, Dover', address: { state: 'Delaware', house_number: '35', road: 'Loockerman Plaza', city: 'Dover', postcode: '19901' } }]);
      if (u.includes('nominatim')) return json([]);
    };
    const res = await fetch(`${base}/api/polling?zip=19901`);
    const body = await res.json();
    assert.equal(body.dataSource, 'estimated');
    assert.equal(body.locations[0].name, 'Dover Public Library');
    assert.equal(body.locations[0].addr, '35 Loockerman Plaza, Dover, Delaware, 19901');
    assert.ok(body.locations[0].isEstimated);
    assert.doesNotMatch(body.locations[0].type, /polling|voting/i);
    assert.equal(body.searchRadiusKm, 10);
  });

  // Tier 1 puts the city and state in the query text; tier 2 drops them and leans on the
  // bounding box, because Nominatim's text index for a given place comes and goes (see HANDOFF
  // §4). A stub that answers only the bare query is exactly that failure mode.
  test('polling widens to nearby civic buildings when the tight search finds nothing', async () => {
    upstream = (u) => {
      if (u.includes('zippopotam'))
        return json({ places: [{ 'place name': 'Dover', state: 'Delaware', 'state abbreviation': 'DE', latitude: '39.15', longitude: '-75.52' }] });
      if (!u.includes('nominatim')) return undefined;
      if (u.includes('Dover')) return json([]); // every tier-1, place-scoped query
      if (u.includes('q=school'))
        return json([{ name: 'Dover High School', lat: '39.19', lon: '-75.55', display_name: 'Dover High School, Dover', address: { state: 'Delaware', house_number: '1', road: 'Pat Lynn Drive', city: 'Dover', postcode: '19904' } }]);
      return json([]);
    };
    const res = await fetch(`${base}/api/polling?zip=19901`);
    const body = await res.json();
    assert.equal(body.dataSource, 'nearby');
    assert.equal(body.searchRadiusKm, 25);
    assert.equal(body.locations.length, 1);
    assert.equal(body.locations[0].name, 'Dover High School');
    // Rule #1: a weaker source must be labelled more cautiously, never less.
    assert.equal(body.locations[0].type, 'Nearby building');
    assert.ok(body.locations[0].isEstimated);
    assert.doesNotMatch(body.locations[0].type, /polling|voting/i);
    assert.match(res.headers.get('cache-control'), /s-maxage=86400/);
  });

  test('polling prefers the tight tier and never widens when it already has results', async () => {
    upstream = (u) => {
      if (u.includes('zippopotam'))
        return json({ places: [{ 'place name': 'Dover', state: 'Delaware', 'state abbreviation': 'DE', latitude: '39.15', longitude: '-75.52' }] });
      if (u.includes('nominatim') && u.includes('Dover') && u.includes('library'))
        return json([{ name: 'Dover Public Library', lat: '39.158', lon: '-75.522', display_name: 'Dover Public Library, Dover', address: { state: 'Delaware', city: 'Dover', postcode: '19901' } }]);
      if (u.includes('nominatim') && u.includes('Dover')) return json([]);
      // A bare (tier-2) query reaching Nominatim at all would mean we widened unnecessarily.
      if (u.includes('nominatim')) throw new Error('tier 2 must not run when tier 1 found venues');
    };
    const res = await fetch(`${base}/api/polling?zip=19901`);
    const body = await res.json();
    assert.equal(body.dataSource, 'estimated');
    assert.equal(body.searchRadiusKm, 10);
  });

  test('polling drops widened venues that are beyond the widened radius', async () => {
    upstream = (u) => {
      if (u.includes('zippopotam'))
        return json({ places: [{ 'place name': 'Dover', state: 'Delaware', 'state abbreviation': 'DE', latitude: '39.15', longitude: '-75.52' }] });
      if (!u.includes('nominatim')) return undefined;
      if (u.includes('Dover')) return json([]);
      // ~55 km north of the ZIP centroid — inside the wider viewbox, outside the 25 km cap.
      return json([{ name: 'Far Away Library', lat: '39.65', lon: '-75.52', display_name: 'Far Away Library, Somewhere', address: { city: 'Somewhere', postcode: '19700' } }]);
    };
    const res = await fetch(`${base}/api/polling?zip=19901`);
    const body = await res.json();
    assert.equal(body.dataSource, 'none');
    assert.deepEqual(body.locations, []);
  });

  test('polling rejects malformed coordinates', async () => {
    for (const q of ['lat=&lng=', 'lat=abc&lng=-75.5', 'lat=39.15', 'lng=-75.5', 'lat=91&lng=0', 'lat=0&lng=181', 'lat=%20&lng=%20', 'lat=1&lat=2&lng=3']) {
      const res = await fetch(`${base}/api/polling?${q}`);
      assert.equal(res.status, 400, q);
      assert.match((await res.json()).error, /latitude and longitude/);
    }
  });

  test('polling reverse-geocodes coordinates to a ZIP and runs the same pipeline', async () => {
    let reverseUrl;
    upstream = (u) => {
      if (u.includes('nominatim') && u.includes('/reverse')) {
        reverseUrl = u;
        return json({ address: { postcode: '19901-1234', country_code: 'us' } });
      }
      if (u.includes('zippopotam'))
        return json({ places: [{ 'place name': 'Dover', state: 'Delaware', 'state abbreviation': 'DE', latitude: '39.15', longitude: '-75.52' }] });
      if (u.includes('nominatim') && u.includes('library'))
        return json([{ name: 'Dover Public Library', lat: '39.158', lon: '-75.522', display_name: 'Dover Public Library, Dover', address: { state: 'Delaware', house_number: '35', road: 'Loockerman Plaza', city: 'Dover', postcode: '19901' } }]);
      if (u.includes('nominatim')) return json([]);
    };

    const res = await fetch(`${base}/api/polling?lat=39.1582345&lng=-75.5219876`);
    assert.equal(res.status, 200);
    const body = await res.json();

    // ZIP+4 is narrowed to the 5-digit form the rest of the pipeline expects.
    assert.equal(body.zip, '19901');
    assert.equal(body.place.zip, '19901');
    assert.equal(body.dataSource, 'estimated');
    assert.equal(body.locations[0].name, 'Dover Public Library');

    // Coordinates are rounded to ~110 m before being sent upstream or echoed back.
    assert.deepEqual(body.device, { lat: 39.158, lng: -75.522 });
    assert.match(reverseUrl, /lat=39\.158&lon=-75\.522/);
  });

  test('polling measures distance from the device, not the ZIP centroid', async () => {
    const stub = (u) => {
      if (u.includes('nominatim') && u.includes('/reverse')) return json({ address: { postcode: '19901', country_code: 'us' } });
      if (u.includes('zippopotam'))
        return json({ places: [{ 'place name': 'Dover', state: 'Delaware', 'state abbreviation': 'DE', latitude: '39.15', longitude: '-75.52' }] });
      if (u.includes('nominatim') && u.includes('library'))
        return json([{ name: 'Dover Public Library', lat: '39.158', lon: '-75.522', display_name: 'Dover Public Library, Dover', address: { state: 'Delaware', road: 'Loockerman Plaza', city: 'Dover', postcode: '19901' } }]);
      if (u.includes('nominatim')) return json([]);
    };

    upstream = stub;
    const byZip = await (await fetch(`${base}/api/polling?zip=19901`)).json();

    upstream = stub;
    // Standing essentially on top of the library, so the device distance must be ~0.
    const byCoords = await (await fetch(`${base}/api/polling?lat=39.158&lng=-75.522`)).json();

    assert.ok(byZip.locations[0].distance > 0.5, `ZIP centroid distance was ${byZip.locations[0].distance}`);
    assert.equal(byCoords.locations[0].distance, 0);
  });

  test('polling tells the user plainly when coordinates are outside the US', async () => {
    upstream = (u) =>
      u.includes('/reverse') ? json({ address: { postcode: 'SW1A 1AA', country_code: 'gb' } }) : undefined;
    const res = await fetch(`${base}/api/polling?lat=51.5&lng=-0.14`);
    assert.equal(res.status, 404);
    assert.match((await res.json()).error, /United States/);
  });

  test('polling falls back to ZIP entry when coordinates resolve to no ZIP', async () => {
    upstream = (u) => (u.includes('/reverse') ? json({ address: { country_code: 'us' } }) : undefined);
    const res = await fetch(`${base}/api/polling?lat=39.15&lng=-75.52`);
    assert.equal(res.status, 404);
    assert.match((await res.json()).error, /enter one instead/);
  });

  test('polling returns 502 when reverse geocoding is down', async () => {
    upstream = (u) => (u.includes('/reverse') ? new Response('nope', { status: 503 }) : undefined);
    const res = await fetch(`${base}/api/polling?lat=39.15&lng=-75.52`);
    assert.equal(res.status, 502);
    assert.equal(res.headers.get('cache-control'), 'no-store');
  });


});


describe('building evidence', () => {
  const { buildVenue } = require('../services/geocodeService');
  const venue = { name: 'Test building', lat: '39.158', lon: '-75.522',
    address: { state: 'Delaware', city: 'Dover', road: 'Main St' } };
  const build = (value) => buildVenue(value, 'Nearby building', 39.15, -75.52, 'Delaware', 25);

  test('uses map tags, never search keywords, to describe building kinds', () => {
    assert.equal(build({ ...venue, type: 'library' }).type, 'Library');
    assert.equal(build({ ...venue, type: 'yes' }).type, 'Nearby building');
    assert.equal(build({ ...venue, type: 'constructor' }).type, 'Nearby building');
    for (const type of ['library', 'community_centre', 'townhall', 'school', 'fire_station', 'yes']) {
      const result = build({ ...venue, type });
      assert.doesNotMatch(result.type, /polling|voting/i);
      assert.equal(result.isEstimated, true);
    }
  });

  test('rejects out-of-state buildings even within the distance limit', () => {
    assert.equal(build({ ...venue, address: { ...venue.address, state: 'Maryland' } }), null);
    assert.ok(build(venue), 'same-state positive control');
  });

  test('does not fill in missing state evidence from the search area', () => {
    assert.equal(build({ ...venue, address: { city: 'Dover' } }), null);
  });

  test('rejects entertainment venues whose names match civic-building keywords', () => {
    for (const type of ['theatre', 'arts_centre', 'cinema']) {
      assert.equal(build({ ...venue, name: 'The Town Hall', class: 'amenity', type }), null);
    }
  });
});
