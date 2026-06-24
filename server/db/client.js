const { Pool } = require('pg');

let pool = null;

if (process.env.DATABASE_URL) {
  pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
  });
}

module.exports = {
  query: async (...args) => {
    if (!pool) return { rows: [] };
    return pool.query(...args);
  },
};
