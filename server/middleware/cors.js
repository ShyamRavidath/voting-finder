const cors = require('cors');

const allowedOrigins = [
  'http://localhost:5173',
  'http://localhost:4173',
  // Capacitor / native WebView origins for the future mobile app
  'capacitor://localhost',
  'ionic://localhost',
  'https://localhost',
  'http://localhost',
  process.env.CLIENT_URL,
].filter(Boolean);

// Production + preview deployments of this project on Vercel
const vercelOrigin = /^https:\/\/(vote4ucyl|voting-finder)[a-z0-9-]*\.vercel\.app$/;

module.exports = cors({
  origin: (origin, cb) => {
    // Same-origin requests and non-browser clients send no Origin header
    if (!origin) return cb(null, true);
    // Unknown origins get no CORS headers (browser blocks them) instead of a 500
    cb(null, allowedOrigins.includes(origin) || vercelOrigin.test(origin));
  },
});
