const express = require('express');
const router = express.Router();

// Compatibility for older clients. Never fetch or serve cached publisher content:
// news is withdrawn until redistribution permission has been established.
router.get('/', (_req, res) => {
  res.set('Cache-Control', 'no-store');
  res.json({ articles: [], provider: null, unavailable: true });
});

module.exports = router;
