// End-to-end tests. Local: builds the client and runs it against the local API.
// Deployed site: BASE_URL=https://vote4ucyl.vercel.app npm run test:e2e
const { defineConfig, devices } = require('@playwright/test');

const remote = Boolean(process.env.BASE_URL);

module.exports = defineConfig({
  testDir: './tests/e2e',
  timeout: 60_000,
  expect: { timeout: 15_000 },
  fullyParallel: true,
  workers: remote ? 4 : 2,
  retries: remote ? 1 : 0,
  reporter: [['list'], ['html', { open: 'never', outputFolder: 'playwright-report' }]],
  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:4173',
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
  },
  projects: [
    { name: 'desktop-chrome', use: { ...devices['Desktop Chrome'] } },
    { name: 'iphone-safari', use: { ...devices['iPhone 13'] } },
    { name: 'android-chrome', use: { ...devices['Pixel 7'] } },
  ],
  webServer: remote
    ? undefined
    : [
        {
          command: 'node server/index.js',
          url: 'http://localhost:3001/api/health',
          env: { RATE_LIMIT_MAX: '5000' },
          reuseExistingServer: true,
        },
        {
          command: 'npm run build --prefix client && npm run preview --prefix client -- --port 4173 --strictPort',
          url: 'http://localhost:4173',
          reuseExistingServer: true,
          timeout: 120_000,
        },
      ],
});
