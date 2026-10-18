const { test } = require('node:test');
const assert = require('node:assert/strict');
const express = require('express');

test('legacy news URLs never fetch upstream or serve stored headlines', async (t) => {
  let upstreamCalls = 0;
  let cacheReads = 0;
  t.mock.method(global, 'fetch', async () => {
    upstreamCalls++;
    throw new Error('News must not be fetched');
  });
  const db = require('../db/client');
  t.mock.method(db, 'query', async () => {
    cacheReads++;
    return { rows: [{ articles: [{ title: 'Previously cached publisher headline' }] }] };
  });
  const app = express();
  app.use('/api/news', require('../routes/news'));
  const server = app.listen(0, '127.0.0.1');
  await new Promise((resolve) => server.once('listening', resolve));
  t.after(() => server.close());
  // Use Node's HTTP client so the upstream-fetch spy covers only the application.
  const http = require('node:http');
  for (const suffix of ['', '?refresh=true']) {
    const response = await new Promise((resolve, reject) => {
      http.get(`http://127.0.0.1:${server.address().port}/api/news${suffix}`, (res) => {
        let body = '';
        res.on('data', (chunk) => { body += chunk; });
        res.on('end', () => resolve({ status: res.statusCode, headers: res.headers, body: JSON.parse(body) }));
      }).on('error', reject);
    });
    assert.equal(response.status, 200);
    assert.equal(response.headers['cache-control'], 'no-store');
    assert.deepEqual(response.body, { articles: [], provider: null, unavailable: true });
  }
  assert.equal(upstreamCalls, 0);
  assert.equal(cacheReads, 0);
});
