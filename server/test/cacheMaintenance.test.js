const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');

const originalDatabaseUrl = process.env.DATABASE_URL;
process.env.DATABASE_URL = 'postgres://local-test-only';
const originalSecret = process.env.CRON_SECRET;
const queries = [];
let failDelete = false;
require.cache[require.resolve('../db/client')] = {
  id: require.resolve('../db/client'),
  filename: require.resolve('../db/client'),
  loaded: true,
  exports: {
    query: async (sql) => {
      queries.push(sql);
      if (failDelete) throw new Error('private connection details must not be returned');
      return { rowCount: 2, rows: [] };
    },
  },
};

const app = require('../app');
let server;
let base;

before(async () => {
  server = http.createServer(app);
  await new Promise((resolve) => server.listen(0, resolve));
  base = `http://127.0.0.1:${server.address().port}`;
});
after(() => {
  if (originalDatabaseUrl === undefined) delete process.env.DATABASE_URL;
  else process.env.DATABASE_URL = originalDatabaseUrl;
  if (originalSecret === undefined) delete process.env.CRON_SECRET;
  else process.env.CRON_SECRET = originalSecret;
  server.close();
});

test('CDN-only deployment needs no secret or database cleanup', async () => {
  delete process.env.DATABASE_URL;
  delete process.env.CRON_SECRET;
  queries.length = 0;
  const response = await fetch(`${base}/api/internal/cache-maintenance`);
  assert.equal(response.status, 204);
  assert.equal(queries.length, 0);
  process.env.DATABASE_URL = 'postgres://local-test-only';
});

test('cron is daily and the cleanup route fails closed without a secret', async () => {
  const config = JSON.parse(fs.readFileSync(path.join(__dirname, '../../vercel.json'), 'utf8'));
  assert.deepEqual(config.crons, [{ path: '/api/internal/cache-maintenance', schedule: '0 0 * * *' }]);
  delete process.env.CRON_SECRET;
  queries.length = 0;
  const response = await fetch(`${base}/api/internal/cache-maintenance`);
  assert.equal(response.status, 503);
  assert.equal(response.headers.get('cache-control'), 'no-store');
  assert.equal(queries.length, 0);
});

test('cron rejects a wrong token without touching the database', async () => {
  process.env.CRON_SECRET = 'local-test-secret';
  queries.length = 0;
  const response = await fetch(`${base}/api/internal/cache-maintenance`, {
    headers: { authorization: 'Bearer wrong' },
  });
  assert.equal(response.status, 401);
  assert.equal(queries.length, 0);
});

test('authorized cron deletes expired polling rows, including coordinate keys', async () => {
  process.env.CRON_SECRET = 'local-test-secret';
  queries.length = 0;
  const response = await fetch(`${base}/api/internal/cache-maintenance`, {
    headers: { authorization: 'Bearer local-test-secret' },
  });
  assert.equal(response.status, 204);
  assert.deepEqual(queries, ['DELETE FROM polling_cache WHERE expires_at <= NOW()']);
});

test('cleanup failure reports only a generic error', async () => {
  failDelete = true;
  const response = await fetch(`${base}/api/internal/cache-maintenance`, {
    headers: { authorization: 'Bearer local-test-secret' },
  });
  assert.equal(response.status, 503);
  assert.equal((await response.text()).includes('private connection details'), false);
  failDelete = false;
});
