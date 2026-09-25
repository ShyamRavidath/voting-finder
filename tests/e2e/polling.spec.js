const { test, expect } = require('@playwright/test');
const { trackErrors, expectNoHorizontalScroll } = require('./helpers');

const zipInput = (page) => page.getByLabel('ZIP code');
const searchButton = (page) => page.getByRole('button', { name: /^Search/ });

test.describe('polling place finder', () => {
  test('input only accepts 5 digits and gates the search button', async ({ page }) => {
    await page.goto('/tools?tab=booths');
    const input = zipInput(page);
    await expect(input).toHaveAttribute('inputmode', 'numeric');
    await expect(input).toHaveAttribute('autocomplete', 'postal-code');

    await input.fill('');
    await expect(searchButton(page)).toBeDisabled();
    await input.pressSequentially('9a0-2 1x0999');
    await expect(input).toHaveValue('90210');
    await expect(searchButton(page)).toBeEnabled();
  });

  test('real search returns locations (or an honest empty state) with directions', async ({ page }) => {
    const errors = trackErrors(page);
    await page.goto('/tools?tab=booths');
    await zipInput(page).fill('90210');
    await searchButton(page).click();

    await expect(page).toHaveURL(/zip=90210/);
    const results = page.getByRole('heading', { name: /locations? near Beverly Hills, CA/ });
    const empty = page.getByText(/No locations found near/);
    await expect(results.or(empty)).toBeVisible({ timeout: 30_000 });

    if (await results.isVisible()) {
      const cards = page.locator('ol > li');
      await expect(cards.first()).toBeVisible();
      const directions = cards.first().getByRole('link', { name: /Directions/ });
      await expect(directions).toHaveAttribute('href', /^https:\/\/(maps\.apple\.com|www\.google\.com\/maps)/);
      await expect(directions).toHaveAttribute('target', '_blank');
      // Unconfirmed venues must be labeled as such
      await expect(page.getByText(/Likely venues, not confirmed|Nothing listed nearby|Official locations/)).toBeVisible();
      await expect(page.getByRole('region', { name: 'Map of nearby locations' })).toBeVisible();

      await cards.first().getByRole('button', { name: 'Show on map' }).click();
      await expect(page.locator('.leaflet-popup-content')).toBeVisible();
    }

    await expect(page.getByRole('link', { name: /Find your official polling place/ })).toHaveAttribute('href', 'https://www.usa.gov/find-polling-place');
    await expectNoHorizontalScroll(page);
    expect(errors).toEqual([]);
  });

  test('shared link with ?zip= runs the search automatically and remembers it', async ({ page }) => {
    await page.goto('/tools?tab=booths&zip=19901');
    await expect(zipInput(page)).toHaveValue('19901');
    const results = page.getByRole('heading', { name: /locations? near Dover, DE/ });
    const empty = page.getByText('No locations found near Dover, DE yet');
    await expect(results.or(empty)).toBeVisible({ timeout: 30_000 });

    // The last ZIP is pre-filled on the next visit
    await page.goto('/tools?tab=booths');
    await expect(zipInput(page)).toHaveValue('19901');
  });

  test('unknown ZIP shows a clear error', async ({ page }) => {
    await page.goto('/tools?tab=booths&zip=00000');
    await expect(page.getByRole('alert')).toContainText("couldn't find ZIP code 00000");
  });

  test('server error shows a retryable message', async ({ page }) => {
    let fail = true;
    await page.route('**/api/polling*', (route) =>
      fail
        ? route.fulfill({ status: 500, contentType: 'application/json', body: JSON.stringify({ error: 'Upstream exploded' }) })
        : route.fulfill({
            status: 200,
            contentType: 'application/json',
            body: JSON.stringify({ locations: [], dataSource: 'none', place: { city: 'Testville', stateAbbr: 'TX', lat: 30, lng: -97 } }),
          })
    );
    await page.goto('/tools?tab=booths&zip=73301');
    await expect(page.getByRole('alert')).toContainText('Upstream exploded');
    fail = false;
    await page.getByRole('button', { name: 'Try again' }).click();
    await expect(page.getByText('No locations found near Testville, TX yet')).toBeVisible();
    await expect(page.getByRole('link', { name: /Find your official polling place/ })).toBeVisible();
  });

  // The widened tier (dataSource 'nearby'). Mocked rather than live because whether a given ZIP
  // widens depends on Nominatim's index that day — the lesson that made the iOS UI tests stubbed.
  test('a widened search says so and hedges harder than the tier above it', async ({ page }) => {
    await page.route('**/api/polling*', (route) =>
      route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          dataSource: 'nearby',
          searchRadiusKm: 25,
          zip: '83428',
          place: { city: 'Irwin', state: 'Idaho', stateAbbr: 'ID', zip: '83428', lat: 43.3861, lng: -111.2527 },
          locations: [
            {
              name: 'Swan Valley Elementary School',
              addr: 'Swan Valley Highway, Irwin, Idaho, 83428',
              type: 'Civic Building',
              lat: 43.4058,
              lng: -111.2932,
              distance: 3.9,
              isEstimated: true,
            },
          ],
        }),
      })
    );
    await page.goto('/tools?tab=booths&zip=83428');

    await expect(page.getByText('Nothing listed nearby')).toBeVisible();
    // 25 km, reported to the reader in miles.
    await expect(page.getByText(/widened the search to about 16 miles/)).toBeVisible();
    await expect(page.getByText(/None of them is a confirmed polling place/)).toBeVisible();
    // Rule #1: every venue in the weakest tier still carries the per-card disclaimer.
    await expect(page.getByText('Not confirmed')).toBeVisible();
    await expect(page.getByRole('link', { name: /Find your official polling place/ })).toBeVisible();
  });

  test('offline / unreachable API gives a connection message, not a crash', async ({ page }) => {
    await page.route('**/api/polling*', (route) => route.abort('internetdisconnected'));
    await page.goto('/tools?tab=booths&zip=10001');
    await expect(page.getByRole('alert')).toContainText("Can't reach Vote4U");
  });

  test('a non-JSON response (e.g. misrouted HTML) is handled gracefully', async ({ page }) => {
    await page.route('**/api/polling*', (route) => route.fulfill({ status: 200, contentType: 'text/html', body: '<!doctype html><p>hi</p>' }));
    await page.goto('/tools?tab=booths&zip=10001');
    await expect(page.getByRole('alert')).toContainText('unexpected response');
  });

  test('tab switching keeps the searched ZIP', async ({ page }) => {
    await page.goto('/tools?tab=booths&zip=90210');
    await page.getByRole('tab', { name: 'Electoral map' }).click();
    await expect(page).toHaveURL(/tab=map/);
    await expect(page).toHaveURL(/zip=90210/);
    await page.getByRole('tab', { name: 'Polling places' }).click();
    await expect(zipInput(page)).toHaveValue('90210');
  });
});
