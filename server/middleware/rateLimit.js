const rateLimit = require('express-rate-limit');

// Per-instance, in-memory limit. Most traffic is absorbed by the CDN cache before reaching here.
module.exports = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: Number(process.env.RATE_LIMIT_MAX) || 100,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: { error: 'Too many requests. Please wait a few minutes and try again.' },
});
