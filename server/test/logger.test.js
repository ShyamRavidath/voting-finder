const { test } = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');

process.env.NODE_ENV = 'test';
process.env.DATABASE_URL = '';
process.env.GOOGLE_CIVIC_API_KEY = '';

const logger = require('../lib/logger');
const app = require('../app');

test('logs a request id and polling shape without its ZIP or coordinates', async () => {
  const savedEnvironment = process.env.NODE_ENV;
  const savedLog = console.log;
  const savedFetch = global.fetch;
  const lines = [];
  process.env.NODE_ENV = 'production';
  console.log = (line) => lines.push(line);

  let server;
  try {
    global.fetch = async (url, options) => {
      const target = String(url);
      if (target.startsWith('http://127.0.0.1:')) return savedFetch(url, options);
      if (target.includes('zippopotam')) {
        return new Response(JSON.stringify({ places: [{
          'place name': 'Dover', state: 'Delaware', 'state abbreviation': 'DE',
          latitude: '39.15', longitude: '-75.52',
        }] }), { status: 200 });
      }
      if (target.includes('nominatim') && target.includes('reverse')) {
        return new Response(JSON.stringify({ address: { postcode: '19901', country_code: 'us' } }), { status: 200 });
      }
      if (target.includes('nominatim')) return new Response('[]', { status: 200 });
      throw new Error('Unexpected upstream request');
    };
    server = http.createServer(app);
    await new Promise((resolve) => server.listen(0, resolve));
    const base = `http://127.0.0.1:${server.address().port}`;
    const response = await savedFetch(`${base}/api/polling?zip=19901`, {
      headers: { 'x-vercel-id': 'sfo1::request-123' },
    });
    assert.equal(response.status, 200);
    await response.text();
    const deviceResponse = await savedFetch(`${base}/api/polling?lat=39.158&lng=-75.522`, {
      headers: { 'x-vercel-id': 'sfo1::device-456' },
    });
    assert.equal(deviceResponse.status, 200);
    await deviceResponse.text();

    const requests = lines.map((line) => JSON.parse(line)).filter((line) => line.event === 'request.complete');
    const request = requests.find((line) => line.requestId === 'sfo1::request-123');
    assert.equal(request.requestId, 'sfo1::request-123');
    assert.equal(request.endpoint, 'polling');
    assert.equal(request.mode, 'zip');
    assert.equal(request.stateAbbr, 'DE');
    assert.equal(request.dataSource, 'none');
    assert.equal(request.cacheHit, false);
    assert.equal(request.locationCount, 0);
    assert.equal(typeof request.upstreamMs, 'number');
    assert.equal(typeof request.latencyMs, 'number');
    assert.equal(requests.find((line) => line.requestId === 'sfo1::device-456').mode, 'device');
    assert.doesNotMatch(lines.join('\n'), /19901|39\.15|-75\.52|39\.158|-75\.522|zippopotam/);
  } finally {
    await new Promise((resolve) => server?.close(resolve) || resolve());
    global.fetch = savedFetch;
    console.log = savedLog;
    process.env.NODE_ENV = savedEnvironment;
  }
});

test('scrubs Error objects, nested keys and free text before emitting one JSON line', () => {
  const savedEnvironment = process.env.NODE_ENV;
  const savedKey = process.env.GOOGLE_CIVIC_API_KEY;
  const savedError = console.error;
  const lines = [];
  process.env.NODE_ENV = 'production';
  process.env.GOOGLE_CIVIC_API_KEY = 'secret-for-logger-test';
  console.error = (line) => lines.push(line);
  try {
    logger.log('error', 'privacy.probe', {
      lat: 39.158,
      zip: '19901',
      deviceCacheKey: '@39.158,-75.522',
      place: { lng: -75.522, zip: '19901' },
      error: new Error('No address found for 39.158,-75.522; zip=19901; https://example.test/?key=secret-for-logger-test'),
    });
    assert.equal(lines.length, 1);
    assert.doesNotMatch(lines[0], /39\.158|-75\.522|19901|secret-for-logger-test|example\.test/);
    const record = JSON.parse(lines[0]);
    assert.equal(record.level, 'error');
    assert.equal(record.lat, '[REDACTED]');
    assert.equal(record.place.lng, '[REDACTED]');
    assert.match(record.error.message, /REDACTED/);
  } finally {
    console.error = savedError;
    process.env.NODE_ENV = savedEnvironment;
    process.env.GOOGLE_CIVIC_API_KEY = savedKey;
  }
});

test('warn uses stdout and LOG_LEVEL filters lower levels', () => {
  const savedEnvironment = process.env.NODE_ENV;
  const savedLevel = process.env.LOG_LEVEL;
  const savedLog = console.log;
  const savedError = console.error;
  const stdout = [];
  const stderr = [];
  process.env.NODE_ENV = 'production';
  process.env.LOG_LEVEL = 'warn';
  console.log = (line) => stdout.push(line);
  console.error = (line) => stderr.push(line);
  try {
    logger.log('info', 'filtered');
    logger.log('warn', 'fallback');
    assert.equal(stdout.length, 1);
    assert.equal(stderr.length, 0);
    assert.equal(JSON.parse(stdout[0]).level, 'warn');
  } finally {
    console.log = savedLog;
    console.error = savedError;
    process.env.NODE_ENV = savedEnvironment;
    if (savedLevel === undefined) delete process.env.LOG_LEVEL;
    else process.env.LOG_LEVEL = savedLevel;
  }
});
