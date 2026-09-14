const path = require('path');
// Local dev only; on Vercel the env vars come from the project settings and no .env file exists.
require('dotenv').config({ path: path.join(__dirname, '.env'), quiet: true });
const express = require('express');
const corsMiddleware = require('./middleware/cors');
const rateLimit = require('./middleware/rateLimit');

const app = express();

// Behind Vercel's (or Railway's) proxy: trust the first hop so rate limiting keys on the real client IP.
app.set('trust proxy', 1);
app.disable('x-powered-by');

app.use(corsMiddleware);
app.use(express.json());
app.use('/api', rateLimit);

app.use('/api/news', require('./routes/news'));
app.use('/api/polling', require('./routes/polling'));
app.use('/api/elections', require('./routes/elections'));

app.get('/api/health', (_, res) => res.set('Cache-Control', 'no-store').json({ status: 'ok' }));

app.use('/api', (req, res) => res.status(404).json({ error: 'Not found' }));

// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Something went wrong. Please try again.' });
});

module.exports = app;
