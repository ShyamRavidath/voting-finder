import { useState } from 'react';
import { feature } from 'topojson-client';
import us from 'us-atlas/states-albers-10m.json';
import { STATE_DATA } from '../data/stateData';

const TOTAL = STATE_DATA.reduce((total, state) => total + state.ev, 0);
const STATES = [...STATE_DATA].sort((a, b) => a.name.localeCompare(b.name));

// us-atlas "albers" files are already projected to a 975x610 canvas, so rings map straight to SVG paths.
function toPath(geometry) {
  const polygons = geometry.type === 'Polygon' ? [geometry.coordinates] : geometry.coordinates;
  return polygons
    .map((rings) => rings.map((ring) => 'M' + ring.map(([x, y]) => `${x.toFixed(1)},${y.toFixed(1)}`).join('L') + 'Z').join(''))
    .join('');
}

const byName = Object.fromEntries(STATE_DATA.map((s) => [s.name, s]));
const SHAPES = feature(us, us.objects.states)
  .features.map((f) => ({ name: f.properties.name, d: toPath(f.geometry), data: byName[f.properties.name] }))
  .filter((s) => s.data);

export default function ElectoralMap() {
  const [selectedName, setSelectedName] = useState(null);
  const selected = selectedName ? byName[selectedName] : null;

  const toggle = (name) => setSelectedName((cur) => (cur === name ? null : name));

  return (
    <div className="space-y-6">
      <section aria-label="Electoral vote tally">
        <dl className="grid grid-cols-2 gap-2 text-center">
          <div>
            <dt className="text-sm font-semibold text-slate-600">Total electoral votes</dt>
            <dd className="mt-1 text-3xl font-bold tabular-nums sm:text-5xl">{TOTAL}</dd>
          </div>
          <div>
            <dt className="text-sm font-semibold text-slate-600">Majority needed</dt>
            <dd className="mt-1 text-3xl font-bold tabular-nums sm:text-5xl">270</dd>
          </div>
        </dl>
        <p className="mt-2 text-center text-xs text-slate-600">270 electoral votes needed to win the presidency</p>
      </section>

      <div>
        <svg viewBox="0 0 975 610" className="h-auto w-full" role="img" aria-labelledby="map-title">
          <title id="map-title">Map of U.S. states and their electoral vote allocations</title>
          <g>
            {SHAPES.map(({ name, d, data }) => (
              <path
                key={name}
                d={d}
                fill="#64748b"
                stroke="#fff"
                strokeWidth={selectedName === name ? 2.5 : 0.8}
                strokeLinejoin="round"
                className="state-shape cursor-pointer"
                opacity={selectedName && selectedName !== name ? 0.45 : 1}
                onClick={() => toggle(name)}
              >
                <title>{`${name}: ${data.ev} electoral votes`}</title>
              </path>
            ))}
          </g>
        </svg>
        <div className="mt-2 min-h-12 rounded-xl bg-slate-50 px-4 py-3 text-center text-sm" aria-live="polite">
          {selected ? (
            <p>
              <strong className="font-semibold text-slate-900">{selected.name}</strong>
              {' · '}
              {selected.ev} electoral votes
            </p>
          ) : (
            <p className="text-slate-600">Tap a state, or pick one from the list below, to see its electoral votes.</p>
          )}
        </div>
      </div>

      <section aria-labelledby="states-heading">
        <h3 id="states-heading" className="text-sm font-semibold text-slate-900">Electoral votes by state</h3>
        <ul className="mt-2 grid gap-1.5 sm:grid-cols-2 lg:grid-cols-3">
          {STATES.map((s) => (
            <li key={s.name}>
              <button
                type="button"
                onClick={() => toggle(s.name)}
                aria-pressed={selectedName === s.name}
                className={`flex min-h-11 w-full items-center justify-between gap-2 rounded-lg px-3 text-left text-sm transition-colors ${
                  selectedName === s.name ? 'bg-slate-900 text-white' : 'bg-slate-100 text-slate-800 hover:bg-slate-200'
                }`}
              >
                {s.name} <span className="tabular-nums">{s.ev}</span>
              </button>
            </li>
          ))}
        </ul>
      </section>

      <div className="space-y-2 text-xs leading-relaxed text-slate-600">
        <p>Allocations for the 2024 and 2028 presidential elections, based on the 2020 Census.
          This map shows electoral vote counts, not a forecast or election result.</p>
        <p>Maine and Nebraska each award two votes to the statewide winner and one to the winner of each
          congressional district. The map shows each state's total allocation.</p>
        <p>Source: <a href="https://www.archives.gov/electoral-college/allocation" target="_blank" rel="noopener noreferrer"
          className="underline hover:text-slate-900">National Archives</a>. Verified October 11, 2026.</p>
      </div>
    </div>
  );
}
