const BASE = import.meta.env.VITE_API_URL || '';

async function get(path) {
  const res = await fetch(`${BASE}${path}`);
  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    throw new Error(body.error || `HTTP ${res.status}`);
  }
  return res.json();
}

export const api = {
  getNews: (refresh = false) => get(`/api/news${refresh ? '?refresh=true' : ''}`),
  getPolling: (zip) => get(`/api/polling?zip=${zip}`),
  getElections: () => get('/api/elections'),
};
