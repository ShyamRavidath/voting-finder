const { test, expect } = require('@playwright/test');

test('voting tools remain usable without news navigation or requests', async ({ page }) => {
  const newsRequests = [];
  page.on('request', (request) => {
    if (new URL(request.url()).pathname === '/api/news') newsRequests.push(request.url());
  });
  await page.goto('/');
  await expect(page.getByRole('heading', { level: 1 })).toHaveText(/Make your voting plan/);
  await expect(page.getByRole('link', { name: /news/i })).toHaveCount(0);
  await page.getByRole('link', { name: 'Electoral map', exact: true }).click();
  await expect(page.getByRole('tab', { name: 'Electoral map' })).toHaveAttribute('aria-selected', 'true');
  await page.goto('/news');
  await expect(page.getByRole('heading', { level: 1 })).toHaveText("We couldn't find that page");
  await page.getByRole('link', { name: 'Go home' }).click();
  await expect(page).toHaveURL(/\/$/);
  expect(newsRequests).toEqual([]);
});
