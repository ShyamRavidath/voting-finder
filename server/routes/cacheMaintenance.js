const crypto = require('node:crypto');
const express = require('express');
const pool = require('../db/client');

const router = express.Router();

router.get('/', async (req, res) => {
  res.set('Cache-Control', 'no-store');
  // The CDN-only deployment has no stored rows to clean; avoid a daily false alarm.
  if (!process.env.DATABASE_URL) return res.status(204).end();
  const secret = process.env.CRON_SECRET;
  if (!secret) return res.status(503).json({ error: 'Cache maintenance is not configured.' });

  const supplied = Buffer.from(req.get('authorization') || '');
  const expected = Buffer.from(`Bearer ${secret}`);
  if (supplied.length !== expected.length || !crypto.timingSafeEqual(supplied, expected)) {
    return res.status(401).json({ error: 'Unauthorized.' });
  }

  try {
    await pool.query('DELETE FROM polling_cache WHERE expires_at <= NOW()');
    return res.status(204).end();
  } catch (_) {
    // Never log a DB error object: it can contain connection details or query parameters.
    return res.status(503).json({ error: 'Cache maintenance failed.' });
  }
});

module.exports = router;
