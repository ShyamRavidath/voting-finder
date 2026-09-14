const { test, expect } = require('@playwright/test');
const { trackErrors, expectNoHorizontalScroll } = require('./helpers');

test.describe('news', () => {
  test('loads real headlines that open on the publisher site', async ({ page }) => {
    const errors = trackErrors(page);
    await page.goto('/news');
    const articles = page.getByRole('article');
    await expect(articles.first()).toBeVisible({ timeout: 30_000 });
    expect(await articles.count()).toBeGreaterThan(0);

    const link = articles.first().getByRole('link');
    await expect(link).toHaveAttribute('href', /^https?:\/\//);
    await expect(link).toHaveAttribute('target', '_blank');
    await expect(link).toHaveAttribute('rel', /noopener/);
    await expectNoHorizontalScroll(page);
    expect(errors).toEqual([]);
  });

  test('refresh keeps the list usable', async ({ page }) => {
    await page.goto('/news');
    await expect(page.getByRole('article').first()).toBeVisible({ timeout: 30_000 });
    await page.getByRole('button', { name: 'Refresh news' }).click();
    await expect(page.getByRole('button', { name: 'Refresh news' })).toBeEnabled({ timeout: 30_000 });
    await expect(page.getByRole('article').first()).toBeVisible();
  });

  test('outage shows an error with a working retry', async ({ page }) => {
    let fail = true;
    await page.route('**/api/news*', (route) =>
      fail
        ? route.fulfill({ status: 502, contentType: 'application/json', body: JSON.stringify({ error: 'News sources are unavailable right now.' }) })
        : route.fulfill({
            status: 200,
            contentType: 'application/json',
            body: JSON.stringify({
              articles: [
                { id: 'x', title: 'Test headline about 2028', url: 'https://example.com/x', source: 'Example', date: new Date().toISOString(), party: null, candidate: '2028 Election' },
              ],
            }),
          })
    );
    await page.goto('/news');
    await expect(page.getByRole('alert')).toContainText('News sources are unavailable');
    fail = false;
    await page.getByRole('button', { name: 'Try again' }).click();
    await expect(page.getByRole('article')).toHaveText(/Test headline about 2028/);
    await expect(page.getByRole('alert')).toHaveCount(0);
  });

  test('empty feed shows a friendly message', async ({ page }) => {
    await page.route('**/api/news*', (route) => route.fulfill({ status: 200, contentType: 'application/json', body: '{"articles":[]}' }));
    await page.goto('/news');
    await expect(page.getByText('No headlines right now')).toBeVisible();
  });

  test('broken thumbnails are hidden instead of showing a broken image', async ({ page }) => {
    await page.route('**/api/news*', (route) =>
      route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          articles: [{ id: 'y', title: 'Headline with bad image 2028', url: 'https://example.com/y', source: 'Ex', date: new Date().toISOString(), imageUrl: 'https://127.0.0.1:1/nope.jpg' }],
        }),
      })
    );
    await page.goto('/news');
    await expect(page.getByRole('article')).toBeVisible();
    await expect(page.getByRole('article').locator('img')).toHaveCount(0);
  });
});
