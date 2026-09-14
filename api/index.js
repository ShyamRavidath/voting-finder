// Vercel serverless entry point. vercel.json rewrites /api/<path> to /api?__path=<path>.
// If the function sees the rewritten URL instead of the original, rebuild the original
// so Express can route it; otherwise leave the request untouched.
const app = require('../server/app');

module.exports = (req, res) => {
  const url = new URL(req.url, 'http://localhost');
  const path = url.searchParams.get('__path');
  if (url.pathname === '/api' && path !== null) {
    url.searchParams.delete('__path');
    const query = url.searchParams.toString();
    req.url = `/api/${path}${query ? `?${query}` : ''}`;
  }
  return app(req, res);
};
