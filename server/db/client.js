const { Pool } = require('pg');

let pool = null;

if (process.env.DATABASE_URL) {
  pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
  });
  // Idle disconnects are emitted outside query promises. Never print the error: it can
  // include connection details or user data, even when its code looks innocuous.
  pool.on('error', () => console.warn('Postgres idle client error'));

}

module.exports = {
  query: async (...args) => {
    if (!pool) return { rows: [] };
    return pool.query(...args);
  },
};
