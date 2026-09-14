const { test, expect } = require('@playwright/test');
const AxeBuilder = require('@axe-core/playwright').default;
const { trackErrors, expectNoHorizontalScroll } = require('./helpers');

const PAGES = [
  { path: '/', h1: /Ready for\s+November 2028\?/, title: /Vote4U/ },
  { path: '/tools', h1: 'Voting tools', title: /Find your polling place · Vote4U/ },
  { path: '/tools?tab=map', h1: 'Voting tools', title: /Electoral map · Vote4U/ },
  { path: '/news', h1: '2028 election news', title: /2028 election news · Vote4U/ },
  { path: '/about', h1: 'About Vote4U', title: /About · Vote4U/ },
  { path: '/privacy', h1: 'Privacy policy', title: /Privacy policy · Vote4U/ },
  { path: '/definitely-not-a-page', h1: "We couldn't find that page", title: /Page not found/ },
];

for (const { path, h1, title } of PAGES) {
  test.describe(`page ${path}`, () => {
    test('loads without errors, fits the screen, and passes accessibility checks', async ({ page }) => {
      const errors = trackErrors(page);
      const res = await page.goto(path);
      expect(res.status(), 'SPA routes (including deep links) must return 200').toBe(200);

      await expect(page.getByRole('heading', { level: 1 })).toHaveText(h1);
      await expect(page).toHaveTitle(title);
      await expect(page.getByRole('heading', { level: 1 })).toHaveCount(1);
      await page.waitForLoadState('networkidle');
      await expectNoHorizontalScroll(page);

      const results = await new AxeBuilder({ page }).withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa']).analyze();
      const serious = results.violations.filter((v) => ['serious', 'critical'].includes(v.impact));
      expect(
        serious.map((v) => `${v.id}: ${v.help} (${v.nodes.map((n) => n.target.join(' ')).slice(0, 3).join(', ')})`),
        'no serious/critical WCAG violations'
      ).toEqual([]);

      expect(errors, 'no runtime errors').toEqual([]);
    });
  });
}

test('static assets and PWA metadata are served', async ({ request }) => {
  for (const asset of ['/favicon.svg', '/manifest.webmanifest', '/icons/icon-192.png', '/icons/icon-512.png', '/icons/apple-touch-icon.png']) {
    const res = await request.get(asset);
    expect(res.status(), asset).toBe(200);
  }
  const manifest = await (await request.get('/manifest.webmanifest')).json();
  expect(manifest.name).toBe('Vote4U');
  expect(manifest.display).toBe('standalone');
});
