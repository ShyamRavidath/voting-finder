const express = require('express');
const router = express.Router();
const pool = require('../db/client');
const { fetchAndProcessNews } = require('../services/newsService');
const logger = require('../lib/logger');

const QUERY_KEY = 'election-2028';
// Vercel's CDN caches the response per URL, so Google News sees roughly one request per window
// no matter how many visitors there are. ?refresh=true gets a shorter window so the Refresh
// button can't be used to hammer it.
const CACHE_OK = 'public, max-age=60, s-maxage=1800, stale-while-revalidate=86400';
const CACHE_REFRESH = 'public, max-age=0, s-maxage=300, stale-while-revalidate=3600';
const CACHE_EMPTY = 'public, max-age=0, s-maxage=60';

// Per-instance memory cache: a warm serverless instance (or local dev server) reuses results
// instead of re-fetching. Refresh may bypass it, but only once it's 2+ minutes old.
const MEMO_TTL_MS = 10 * 60 * 1000;
const MEMO_MIN_AGE_FOR_REFRESH_MS = 2 * 60 * 1000;
let memo = null;

router.clearCache = () => {
  memo = null;
};

router.get('/', async (req, res) => {
  const forceRefresh = req.query.refresh === 'true';

  if (memo) {
    const age = Date.now() - memo.at;
    if (age < MEMO_TTL_MS && (!forceRefresh || age < MEMO_MIN_AGE_FOR_REFRESH_MS)) {
      res.set('Cache-Control', forceRefresh ? CACHE_REFRESH : CACHE_OK);
      return res.json({ articles: memo.articles, provider: memo.provider, cached: true });
    }
  }

  if (!forceRefresh) {
    try {
      const cached = await pool.query(
        'SELECT articles FROM news_cache WHERE query_key = $1 AND expires_at > NOW()',
        [QUERY_KEY]
      );
      if (cached.rows.length > 0) {
        res.set('Cache-Control', CACHE_OK);
        return res.json({ articles: cached.rows[0].articles, cached: true });
      }
    } catch (_) {
      // DB unavailable — continue to live fetch
    }
  }

  try {
    const { articles, provider } = await fetchAndProcessNews();

    if (articles.length > 0) {
      memo = { articles, provider, at: Date.now() };
      try {
        await pool.query(
          `INSERT INTO news_cache (query_key, articles, expires_at)
           VALUES ($1, $2, NOW() + INTERVAL '6 hours')
           ON CONFLICT (query_key) DO UPDATE
           SET articles = $2, cached_at = NOW(), expires_at = NOW() + INTERVAL '6 hours'`,
          [QUERY_KEY, JSON.stringify(articles)]
        );
      } catch (_) {
        // Cache write failed — still return articles
      }
    }

    res.set('Cache-Control', articles.length === 0 ? CACHE_EMPTY : forceRefresh ? CACHE_REFRESH : CACHE_OK);
    res.json({ articles, provider, cached: false });
  } catch (err) {
    logger.log('error', 'news.upstream_failed', { requestId: req.requestId, error: err });
    res.set('Cache-Control', 'no-store');
    res.status(502).json({ error: 'News sources are unavailable right now. Please try again in a few minutes.' });
  }
});

module.exports = router;
