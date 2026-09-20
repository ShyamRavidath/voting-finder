// Exports the data the iOS app bundles, straight from the same sources the web app uses, so the
// two UIs can never disagree about electoral votes or state shapes.
//
//   node scripts/export-ios-data.mjs
//
// Writes ios/Vote4U/Resources/{states,statePaths,officialLinks}.json. Re-run whenever
// client/src/data/* or the us-atlas dependency changes.
import { createRequire } from 'node:module';
import { writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const outDir = join(root, 'ios/Vote4U/Resources');

// topojson-client and us-atlas are the web app's dependencies, so resolve from client/.
const require = createRequire(join(root, 'client/package.json'));
const { feature } = require('topojson-client');
const us = require('us-atlas/states-albers-10m.json');

const { STATE_DATA } = await import(pathToFileURL(join(root, 'client/src/data/stateData.js')));
const { OFFICIAL_LINKS } = await import(pathToFileURL(join(root, 'client/src/data/officialLinks.js')));

// The "albers" us-atlas files are pre-projected onto a 975x610 canvas, so each ring maps straight
// to an SVG path with no projection maths on the device. Only M, L and Z are emitted — that keeps
// the Swift parser trivial.
const VIEWBOX = { width: 975, height: 610 };

function toPath(geometry) {
  const polygons = geometry.type === 'Polygon' ? [geometry.coordinates] : geometry.coordinates;
  return polygons
    .map((rings) => rings.map((ring) => 'M' + ring.map(([x, y]) => `${x.toFixed(1)},${y.toFixed(1)}`).join('L') + 'Z').join(''))
    .join('');
}

const byName = Object.fromEntries(STATE_DATA.map((s) => [s.name, s]));
const shapes = feature(us, us.objects.states)
  .features.map((f) => ({ name: f.properties.name, d: toPath(f.geometry) }))
  .filter((s) => byName[s.name]);

// Guard rails: a silent drop here would ship a map with a missing state.
const missing = STATE_DATA.filter((s) => !shapes.some((sh) => sh.name === s.name));
if (missing.length) throw new Error(`No shape for: ${missing.map((s) => s.name).join(', ')}`);
if (shapes.length !== 51) throw new Error(`Expected 51 shapes (50 states + DC), got ${shapes.length}`);

const totalEv = STATE_DATA.reduce((n, s) => n + s.ev, 0);
if (totalEv !== 538) throw new Error(`Electoral votes total ${totalEv}, expected 538`);

mkdirSync(outDir, { recursive: true });
const write = (name, data) => {
  const path = join(outDir, name);
  writeFileSync(path, JSON.stringify(data, null, 2) + '\n');
  return `${name} (${(JSON.stringify(data).length / 1024).toFixed(0)} KB)`;
};

console.log('Wrote', [
  write('states.json', STATE_DATA),
  write('statePaths.json', { viewBox: VIEWBOX, shapes }),
  write('officialLinks.json', OFFICIAL_LINKS),
].join(', '));
console.log(`${shapes.length} shapes, ${totalEv} electoral votes.`);
