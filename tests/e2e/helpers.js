const { expect } = require('@playwright/test');

// Collects anything a user could hit as an error: uncaught exceptions, console errors from our own
// origin, and failed/5xx requests to our own origin. Third-party images/tiles are out of our control.
function trackErrors(page) {
  const errors = [];
  const ownOrigin = (url) => {
    try {
      return new URL(url).origin === new URL(page.url() || 'http://x').origin;
    } catch {
      return false;
    }
  };
  page.on('pageerror', (err) => errors.push(`pageerror: ${err.message}`));
  page.on('console', (msg) => {
    if (msg.type() !== 'error') return;
    const src = msg.location()?.url || '';
    if (src && !ownOrigin(src)) return;
    errors.push(`console: ${msg.text()}`);
  });
  page.on('requestfailed', (req) => {
    if (ownOrigin(req.url()) && req.failure()?.errorText !== 'net::ERR_ABORTED') {
      errors.push(`requestfailed: ${req.url()} ${req.failure()?.errorText}`);
    }
  });
  page.on('response', (res) => {
    if (ownOrigin(res.url()) && res.status() >= 500) errors.push(`HTTP ${res.status()}: ${res.url()}`);
  });
  return errors;
}

async function expectNoHorizontalScroll(page) {
  const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
  expect(overflow, 'page should not scroll sideways').toBeLessThanOrEqual(0);
}

const isMobile = (testInfo) => testInfo.project.name !== 'desktop-chrome';

module.exports = { trackErrors, expectNoHorizontalScroll, isMobile };
