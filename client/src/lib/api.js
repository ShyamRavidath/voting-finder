// Web builds call the same-origin /api (served by the Vercel function). Native app builds have no
// same-origin server, so they set VITE_API_BASE to the deployed site, e.g. https://vote4ucyl.vercel.app
const BASE = (import.meta.env.VITE_API_BASE || '').replace(/\/$/, '');
const TIMEOUT_MS = 25000;

export class ApiError extends Error {
  constructor(message, status) {
    super(message);
    this.status = status;
  }
}

async function get(path, { signal } = {}) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(new DOMException('Request timed out', 'TimeoutError')), TIMEOUT_MS);
  const onAbort = () => controller.abort(signal.reason);
  signal?.addEventListener('abort', onAbort);

  let res;
  try {
    res = await fetch(`${BASE}${path}`, { signal: controller.signal, headers: { Accept: 'application/json' } });
  } catch (err) {
    if (signal?.aborted) throw err;
    if (err?.name === 'TimeoutError' || controller.signal.reason?.name === 'TimeoutError') {
      throw new ApiError('This is taking longer than usual. Please try again.', 0);
    }
    throw new ApiError("Can't reach Vote4U right now. Check your connection and try again.", 0);
  } finally {
    clearTimeout(timer);
    signal?.removeEventListener('abort', onAbort);
  }

  const isJson = res.headers.get('content-type')?.includes('application/json');
  const body = isJson ? await res.json().catch(() => null) : null;
  if (!res.ok) {
    throw new ApiError(body?.error || 'Something went wrong on our end. Please try again.', res.status);
  }
  if (!body) throw new ApiError('Received an unexpected response. Please try again.', res.status);
  return body;
}

export const api = {
  getNews: (refresh = false, opts) => get(`/api/news${refresh ? '?refresh=true' : ''}`, opts),
  getPolling: (zip, opts) => get(`/api/polling?zip=${encodeURIComponent(zip)}`, opts),
  getElections: (opts) => get('/api/elections', opts),
};
