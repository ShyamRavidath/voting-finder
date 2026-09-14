// Vercel serverless entry point. vercel.json rewrites every /api/* request here,
// and the Express app routes on the original URL.
module.exports = require('../server/app');
