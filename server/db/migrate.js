const fs = require('node:fs/promises');
const path = require('node:path');
const { Pool } = require('pg');

require('dotenv').config({ path: path.join(__dirname, '../.env'), quiet: true });

async function migrate(client) {
  const schema = await fs.readFile(path.join(__dirname, 'schema.sql'), 'utf8');
  const migration = await fs.readFile(
    path.join(__dirname, 'migrations/2026-09-21-polling-cache-key.sql'), 'utf8'
  );
  await client.query('BEGIN');
  try {
    await client.query(schema);
    await client.query(migration);
    await client.query('COMMIT');
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  }
}

if (require.main === module) {
  if (!process.env.DATABASE_URL) {
    console.error('DATABASE_URL is required for the polling cache migration.');
    process.exitCode = 1;
  } else {
    const pool = new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
    });
    pool.connect()
      .then(async (client) => {
        try {
          await migrate(client);
          console.log('Polling cache migration complete.');
        } finally {
          client.release();
        }
      })
      .catch((error) => {
        // Do not print the Error object: some connection errors embed the database URL.
        console.error(`Polling cache migration failed (${error.code || 'unknown'}).`);
        process.exitCode = 1;
      })
      .finally(() => pool.end());
  }
}

module.exports = { migrate };
