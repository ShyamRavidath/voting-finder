const { test, expect } = require('@playwright/test');
const { isMobile } = require('./helpers');

test('primary navigation reaches every section', async ({ page }, testInfo) => {
  await page.goto('/');
  const nav = page.getByRole('navigation', { name: 'Main' });
  await expect(nav).toBeVisible();

  const mobile = isMobile(testInfo);
  if (mobile) {
    // Bottom tab bar sits at the bottom edge of the viewport with thumb-sized targets
    const box = await nav.boundingBox();
    const viewport = page.viewportSize();
    expect(box.y + box.height).toBeGreaterThan(viewport.height - 2);
    for (const link of await nav.getByRole('link').all()) {
      const b = await link.boundingBox();
      expect(b.height).toBeGreaterThanOrEqual(44);
    }
  }

  const destinations = [
    { name: mobile ? 'Vote' : 'Voting Tools', url: /\/tools/, h1: 'Voting tools' },
    { name: 'News', url: /\/news$/, h1: '2028 election news' },
    { name: 'About', url: /\/about$/, h1: 'About Vote4U' },
    { name: 'Home', url: /\/$/, h1: /Ready for/ },
  ];
  for (const d of destinations) {
    await nav.getByRole('link', { name: d.name, exact: true }).click();
    await expect(page).toHaveURL(d.url);
    await expect(page.getByRole('heading', { level: 1 })).toHaveText(d.h1);
    await expect(nav.getByRole('link', { name: d.name, exact: true })).toHaveAttribute('aria-current', 'page');
  }
});

test('home page calls to action lead to the tools', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByText(/(Midterm elections|Presidential election):/)).toBeVisible();

  await page.getByRole('link', { name: 'Find my polling place' }).click();
  await expect(page).toHaveURL(/\/tools\?tab=booths/);
  await expect(page.getByRole('tab', { name: 'Polling places' })).toHaveAttribute('aria-selected', 'true');

  await page.goto('/');
  await page.getByRole('link', { name: 'Electoral map' }).click();
  await expect(page).toHaveURL(/\/tools\?tab=map/);
  await expect(page.getByRole('tab', { name: 'Electoral map' })).toHaveAttribute('aria-selected', 'true');
});

test('404 page offers a way back', async ({ page }) => {
  await page.goto('/no/such/page');
  await page.getByRole('link', { name: 'Go home' }).click();
  await expect(page).toHaveURL(/\/$/);
});

test('footer links to privacy policy', async ({ page }) => {
  await page.goto('/');
  await page.getByRole('contentinfo').getByRole('link', { name: 'Privacy' }).click();
  await expect(page.getByRole('heading', { level: 1 })).toHaveText('Privacy policy');
});
