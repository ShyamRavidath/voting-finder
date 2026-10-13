const { test, expect } = require('@playwright/test');
const { trackErrors } = require('./helpers');

test.describe('electoral map', () => {
  test('draws all 50 states + DC with neutral allocations and a 538 total', async ({ page }) => {
    const errors = trackErrors(page);
    await page.goto('/tools?tab=map');
    const map = page.getByRole('img', { name: /Map of U.S. states/ });
    await expect(map).toBeVisible();
    await expect(map.locator('path')).toHaveCount(51);

    const tally = page.getByRole('region', { name: 'Electoral vote tally' });
    const numbers = await tally.locator('dd').allTextContents();
    expect(numbers).toEqual(['538', '270']);
    expect(await map.locator('path').evaluateAll((paths) => [...new Set(paths.map((p) => p.getAttribute('fill')))])).toEqual(['#64748b']);
    await expect(page.getByText('270 electoral votes needed to win')).toBeVisible();
    expect(errors).toEqual([]);
  });

  test('tapping a state or list chip shows its details', async ({ page }) => {
    await page.goto('/tools?tab=map');
    const details = page.locator('[aria-live="polite"]').filter({ hasText: /Tap a state|electoral votes/ });

    await page.getByRole('button', { name: /^California 54$/ }).click();
    await expect(details).toContainText('California · 54 electoral votes');
    await expect(page.getByRole('button', { name: /^California 54$/ })).toHaveAttribute('aria-pressed', 'true');

    await page.getByRole('button', { name: /^District of Columbia 3$/ }).click();
    await expect(details).toContainText('District of Columbia · 3 electoral votes');

    // Tap the Texas shape on the map itself
    await page.locator('svg path').filter({ has: page.locator('title', { hasText: /^Texas:/ }) }).click();
    await expect(details).toContainText('Texas · 40 electoral votes');
  });

  test('lists states alphabetically with sourced and dated allocation context', async ({ page }) => {
    await page.goto('/tools?tab=map');
    const states = page.getByRole('region', { name: 'Electoral votes by state' }).getByRole('button');
    await expect(states).toHaveCount(51);
    const names = (await states.allTextContents()).map((s) => s.replace(/\s+\d+$/, ''));
    expect(names).toEqual([...names].sort((a, b) => a.localeCompare(b)));
    const votes = (await states.allTextContents()).map((s) => Number(s.match(/\d+$/)[0]));
    expect(votes.reduce((sum, votes) => sum + votes, 0)).toBe(538);
    await expect(page.getByRole('link', { name: 'National Archives' })).toHaveAttribute(
      'href', 'https://www.archives.gov/electoral-college/allocation');
    await expect(page.getByText(/Allocations for the 2024 and 2028 presidential elections/)).toBeVisible();
    await expect(page.getByText(/Verified October 11, 2026/)).toBeVisible();
    await expect(page.getByText(/Maine and Nebraska each award two votes/)).toBeVisible();
    await expect(page.getByText(/Leans Democratic|Leans Republican|Toss-up|projected lean/)).toHaveCount(0);
  });

  test('no map tile service is required (no third-party tile requests)', async ({ page }) => {
    const tileRequests = [];
    page.on('request', (r) => /basemaps|tile\./.test(r.url()) && tileRequests.push(r.url()));
    await page.goto('/tools?tab=map');
    await expect(page.getByRole('img', { name: /Map of U.S. states/ })).toBeVisible();
    expect(tileRequests).toEqual([]);
  });
});
