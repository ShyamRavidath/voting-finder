const { test, expect } = require('@playwright/test');
const { trackErrors } = require('./helpers');

test.describe('electoral map', () => {
  test('draws all 50 states + DC and the tally adds up to 538', async ({ page }) => {
    const errors = trackErrors(page);
    await page.goto('/tools?tab=map');
    const map = page.getByRole('img', { name: /Map of U.S. states/ });
    await expect(map).toBeVisible();
    await expect(map.locator('path')).toHaveCount(51);

    const tally = page.getByRole('region', { name: 'Electoral vote tally' });
    const numbers = await tally.locator('dd').allTextContents();
    expect(numbers.map(Number).reduce((a, b) => a + b, 0)).toBe(538);
    await expect(page.getByText('270 electoral votes needed to win')).toBeVisible();
    expect(errors).toEqual([]);
  });

  test('tapping a state or list chip shows its details', async ({ page }) => {
    await page.goto('/tools?tab=map');
    const details = page.locator('[aria-live="polite"]').filter({ hasText: /Tap a state|electoral votes/ });

    await page.getByRole('button', { name: /^California 54$/ }).click();
    await expect(details).toContainText('California · 54 electoral votes · Leans Democratic');
    await expect(page.getByRole('button', { name: /^California 54$/ })).toHaveAttribute('aria-pressed', 'true');

    await page.getByRole('button', { name: /^District of Columbia 3$/ }).click();
    await expect(details).toContainText('District of Columbia · 3 electoral votes');

    // Tap the Texas shape on the map itself
    await page.locator('svg path').filter({ has: page.locator('title', { hasText: /^Texas:/ }) }).click();
    await expect(details).toContainText('Texas · 40 electoral votes · Leans Republican');
  });

  test('no map tile service is required (no third-party tile requests)', async ({ page }) => {
    const tileRequests = [];
    page.on('request', (r) => /basemaps|tile\./.test(r.url()) && tileRequests.push(r.url()));
    await page.goto('/tools?tab=map');
    await expect(page.getByRole('img', { name: /Map of U.S. states/ })).toBeVisible();
    expect(tileRequests).toEqual([]);
  });
});
