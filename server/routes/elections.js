const express = require('express');
const router = express.Router();
const { fetchWithTimeout } = require('../lib/fetchWithTimeout');
const logger = require('../lib/logger');

router.get('/', async (req, res) => {
  const apiKey = process.env.GOOGLE_CIVIC_API_KEY;
  if (!apiKey) return res.status(503).json({ error: 'Election data is not configured.' });

  try {
    const response = await fetchWithTimeout(`https://www.googleapis.com/civicinfo/v2/elections?key=${apiKey}`);
    const data = await response.json();
    if (!response.ok) throw new Error(data.error?.message || `HTTP ${response.status}`);
    const elections = (data.elections || []).filter((e) => e.id !== '2000');
    res.set('Cache-Control', 'public, max-age=300, s-maxage=21600, stale-while-revalidate=86400');
    res.json({ elections });
  } catch (err) {
    logger.log('error', 'elections.upstream_failed', { requestId: req.requestId, error: err });
    res.set('Cache-Control', 'no-store');
    res.status(502).json({ error: 'Election data is unavailable right now.' });
  }
});

module.exports = router;
