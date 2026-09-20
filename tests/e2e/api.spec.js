const { test, expect } = require('@playwright/test');

// API contract checks through the same origin the browser uses. Run once (not per device).
test.describe('API', () => {
  test.skip(({ isMobile }) => isMobile, 'device-independent; runs on desktop only');

  test('health and error contracts', async ({ request }) => {
    const health = await request.get('/api/health');
    expect(health.status()).toBe(200);
    expect(await health.json()).toEqual({ status: 'ok' });

    const bad = await request.get('/api/polling?zip=abc');
    expect(bad.status()).toBe(400);
    expect((await bad.json()).error).toMatch(/5-digit/);

    const missing = await request.get('/api/does-not-exist');
    expect(missing.status()).toBe(404);
    expect(missing.headers()['content-type']).toMatch(/json/);
  });

  test('news returns articles with the fields the app renders', async ({ request }) => {
    const res = await request.get('/api/news');
    expect(res.status()).toBe(200);
    const { articles } = await res.json();
    expect(articles.length).toBeGreaterThan(0);
    for (const a of articles) {
      expect(a.title).toBeTruthy();
      expect(a.url).toMatch(/^https?:\/\//);
      expect(Number.isNaN(new Date(a.date).getTime())).toBe(false);
      expect([null, 'Democrat', 'Republican']).toContain(a.party);
    }
  });

  test('polling returns a well-formed payload', async ({ request }) => {
    const res = await request.get('/api/polling?zip=90210');
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(['official', 'estimated', 'none']).toContain(body.dataSource);
    expect(body.place).toMatchObject({ city: 'Beverly Hills', stateAbbr: 'CA' });
    for (const loc of body.locations) {
      expect(loc.name).toBeTruthy();
      expect(loc.addr).toBeTruthy();
      expect(loc.isSample).toBeUndefined();
    }
  });

  test('deployed site sends security + caching headers', async ({ request }) => {
    test.skip(!process.env.BASE_URL, 'only meaningful against Vercel');
    const page = await request.get('/');
    expect(page.headers()['x-content-type-options']).toBe('nosniff');
    expect(page.headers()['referrer-policy']).toBe('strict-origin-when-cross-origin');
    // Vercel's CDN consumes s-maxage/stale-while-revalidate and rewrites the client-facing
    // Cache-Control, so assert the CDN actually handled the response instead.
    const news = await request.get('/api/news');
    expect(news.headers()['cache-control']).toMatch(/public/);
    expect(news.headers()['x-vercel-cache']).toBeDefined();
  });
});
