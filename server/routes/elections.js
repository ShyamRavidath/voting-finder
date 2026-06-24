const express = require('express');
const router = express.Router();

router.get('/', async (req, res) => {
  const apiKey = process.env.GOOGLE_CIVIC_API_KEY;
  if (!apiKey) return res.status(503).json({ error: 'Civic API key not configured' });

  try {
    const response = await fetch(`https://www.googleapis.com/civicinfo/v2/elections?key=${apiKey}`);
    const data = await response.json();
    res.json(data);
  } catch (err) {
    console.error('Elections route error:', err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
