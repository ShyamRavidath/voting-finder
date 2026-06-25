const express = require('express');
const router = express.Router();
const pool = require('../db/client');
const { fetchAndProcessNews } = require('../services/newsService');

router.get('/', async (req, res) => {
  const forceRefresh = req.query.refresh === 'true';
  const queryKey = 'election-2028';

  try {
    if (!forceRefresh) {
      try {
        const cached = await pool.query(
          'SELECT articles FROM news_cache WHERE query_key = $1 AND expires_at > NOW()',
          [queryKey]
        );
        if (cached.rows.length > 0) {
          return res.json({ articles: cached.rows[0].articles, cached: true });
        }
      } catch (_) {
        // DB unavailable — continue to live fetch
      }
    }

    const apiKey = process.env.NEWS_API_KEY;
    if (!apiKey) return res.status(503).json({ error: 'NewsAPI key not configured' });

    const articles = await fetchAndProcessNews(apiKey);

    try {
      if (articles.length > 0) {
        await pool.query(
          `INSERT INTO news_cache (query_key, articles, expires_at)
           VALUES ($1, $2, NOW() + INTERVAL '14 days')
           ON CONFLICT (query_key) DO UPDATE
           SET articles = $2, cached_at = NOW(), expires_at = NOW() + INTERVAL '14 days'`,
          [queryKey, JSON.stringify(articles)]
        );
      }
    } catch (_) {
      // Cache write failed — still return articles
    }

    res.json({ articles, cached: false });
  } catch (err) {
    console.error('News route error:', err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
