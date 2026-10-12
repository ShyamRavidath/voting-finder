const { test } = require('node:test');
const assert = require('node:assert/strict');
const vm = require('node:vm');
const fs = require('node:fs');
const { EventEmitter } = require('node:events');

test('idle pool errors are handled without logging any error or connection data', async () => {
  const warnings = [];
  let pool;
  class Pool extends EventEmitter {
    constructor() { super(); pool = this; }
    async query() { return { rows: ['still usable'] }; }
  }
  const sandbox = {
    require: () => ({ Pool }),
    process: { env: { DATABASE_URL: 'postgres://private-connection' } },
    console: { warn: (...args) => warnings.push(args) },
    module: { exports: {} },
  };
  vm.runInNewContext(fs.readFileSync(require.resolve('../db/client'), 'utf8'), sandbox);
  const error = Object.assign(new Error('private location and connection details'), {
    code: 'arbitrary sensitive text', detail: 'more private data',
  });
  assert.doesNotThrow(() => pool.emit('error', error));
  assert.deepEqual(warnings, [['Postgres idle client error']]);
  assert.deepEqual(await sandbox.module.exports.query('SELECT 1'), { rows: ['still usable'] });
});
