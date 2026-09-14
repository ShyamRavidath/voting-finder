// Renders the Vote4U logo into the PNG icon set with Playwright's Chromium.
// Usage: node scripts/generate-icons.mjs
import { chromium } from '@playwright/test';
import { mkdir } from 'node:fs/promises';
import path from 'node:path';

const OUT = path.resolve('client/public/icons');
const APP_STORE_OUT = path.resolve('assets');

const ART = `
  <rect x="21" y="10" width="22" height="27" rx="2.5" fill="#fff"/>
  <path d="m26 23.5 4.5 4.5 8-9" fill="none" stroke="#2563eb" stroke-width="3.4" stroke-linecap="round" stroke-linejoin="round"/>
  <rect x="12" y="34" width="40" height="20" rx="3.5" fill="#fff"/>
  <rect x="19" y="33" width="26" height="3.2" rx="1.6" fill="#1e3a8a"/>
  <rect x="12" y="45" width="40" height="3.2" fill="#dc2626"/>`;

// rounded: favicon-style with transparent corners. square: full-bleed, no transparency (iOS/App Store/maskable).
function svg({ rounded, scale = 1, size }) {
  const t = (64 - 64 * scale) / 2;
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="${size}" height="${size}" style="display:block">
    <rect width="64" height="64" rx="${rounded ? 14 : 0}" fill="#2563eb"/>
    <g transform="translate(${t} ${t}) scale(${scale})">${ART}</g>
  </svg>`;
}

const ICONS = [
  { file: path.join(OUT, 'favicon-32.png'), size: 32, rounded: true },
  { file: path.join(OUT, 'icon-192.png'), size: 192, rounded: true },
  { file: path.join(OUT, 'icon-512.png'), size: 512, rounded: true },
  { file: path.join(OUT, 'apple-touch-icon.png'), size: 180, rounded: false, scale: 0.86 },
  { file: path.join(OUT, 'maskable-512.png'), size: 512, rounded: false, scale: 0.72 },
  { file: path.join(APP_STORE_OUT, 'app-icon-1024.png'), size: 1024, rounded: false, scale: 0.86 },
];

await mkdir(OUT, { recursive: true });
await mkdir(APP_STORE_OUT, { recursive: true });
const browser = await chromium.launch();
const page = await browser.newPage();
for (const icon of ICONS) {
  await page.setViewportSize({ width: icon.size, height: icon.size });
  await page.setContent(
    `<html><body style="margin:0;background:transparent">${svg(icon)}</body></html>`
  );
  await page.screenshot({ path: icon.file, omitBackground: icon.rounded, clip: { x: 0, y: 0, width: icon.size, height: icon.size } });
  console.log('wrote', path.relative(process.cwd(), icon.file));
}
await browser.close();
