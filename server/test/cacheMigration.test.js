const { test } = require('node:test');
const assert = require('node:assert/strict');
const { migrate } = require('../db/migrate');

test('migration wraps schema and old/new-column upgrade in one transaction', async () => {
  const calls = [];
  await migrate({ query: async (sql) => { calls.push(sql); } });
  assert.equal(calls[0], 'BEGIN');
  assert.match(calls[1], /CREATE TABLE IF NOT EXISTS polling_cache/);
  assert.match(calls[2], /ALTER TABLE polling_cache RENAME COLUMN zip_code TO cache_key/);
  assert.match(calls[2], /column_name = 'cache_key'/);
  assert.match(calls[2], /END;\s*\$migration\$;/);
  assert.match(calls[2], /DELETE FROM polling_cache WHERE expires_at <= NOW\(\)/);
  assert.equal(calls[3], 'COMMIT');
});

test('migration rolls back rather than leaving a partly updated schema', async () => {
  const calls = [];
  await assert.rejects(migrate({ query: async (sql) => {
    calls.push(sql);
    if (sql.includes('ALTER TABLE polling_cache RENAME COLUMN')) throw new Error('migration failed');
  } }), /migration failed/);
  assert.equal(calls.at(-1), 'ROLLBACK');
  assert.equal(calls.includes('COMMIT'), false);
});
