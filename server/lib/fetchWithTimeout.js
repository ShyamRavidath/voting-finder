// Native fetch with a hard timeout so a slow upstream can't hang a serverless function.
async function fetchWithTimeout(url, options = {}, ms = 8000) {
  return fetch(url, { ...options, signal: AbortSignal.timeout(ms) });
}

module.exports = { fetchWithTimeout };
