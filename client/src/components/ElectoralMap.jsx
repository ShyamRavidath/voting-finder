import { useMemo, useState } from 'react';
import { feature } from 'topojson-client';
import us from 'us-atlas/states-albers-10m.json';
import { STATE_DATA } from '../data/stateData';

const PARTY_META = {
  blue: { label: 'Leans Democratic', short: 'Democratic', fill: 'var(--color-dem)', text: 'text-blue-700', chip: 'bg-blue-50' },
  gray: { label: 'Toss-up', short: 'Toss-up', fill: 'var(--color-swing)', text: 'text-slate-700', chip: 'bg-slate-100' },
  red: { label: 'Leans Republican', short: 'Republican', fill: 'var(--color-gop)', text: 'text-red-700', chip: 'bg-red-50' },
};
const TO_WIN = 270;
const TOTAL = 538;

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

  const tally = useMemo(
    () =>
      STATE_DATA.reduce(
        (acc, s) => {
          acc[s.party] += s.ev;
          return acc;
        },
        { blue: 0, gray: 0, red: 0 }
      ),
    []
  );

  const groups = useMemo(
    () =>
      ['blue', 'gray', 'red'].map((party) => ({
        party,
        states: STATE_DATA.filter((s) => s.party === party).sort((a, b) => b.ev - a.ev),
      })),
    []
  );

  const toggle = (name) => setSelectedName((cur) => (cur === name ? null : name));

  return (
    <div className="space-y-6">
      <section aria-label="Electoral vote tally">
        <dl className="grid grid-cols-3 gap-2 text-center">
          {['blue', 'gray', 'red'].map((party) => (
            <div key={party}>
              <dt className={`text-xs font-semibold sm:text-sm ${PARTY_META[party].text}`}>{PARTY_META[party].label}</dt>
              <dd className={`mt-1 text-3xl font-bold tabular-nums sm:text-5xl ${PARTY_META[party].text}`}>{tally[party]}</dd>
            </div>
          ))}
        </dl>
        <div className="relative mt-4" aria-hidden="true">
          <div className="flex h-3 overflow-hidden rounded-full">
            <div style={{ width: `${(tally.blue / TOTAL) * 100}%`, background: 'var(--color-dem)' }} />
            <div style={{ width: `${(tally.gray / TOTAL) * 100}%`, background: 'var(--color-swing)' }} />
            <div style={{ width: `${(tally.red / TOTAL) * 100}%`, background: 'var(--color-gop)' }} />
          </div>
          <div className="absolute -top-1 left-1/2 h-5 w-0.5 -translate-x-1/2 bg-slate-900" />
        </div>
        <p className="mt-2 text-center text-xs text-slate-600">{TO_WIN} electoral votes needed to win · {TOTAL} total</p>
      </section>

      <div>
        <svg viewBox="0 0 975 610" className="h-auto w-full" role="img" aria-labelledby="map-title">
          <title id="map-title">Map of U.S. states colored by projected lean</title>
          <g>
            {SHAPES.map(({ name, d, data }) => (
              <path
                key={name}
                d={d}
                fill={PARTY_META[data.party].fill}
                stroke="#fff"
                strokeWidth={selectedName === name ? 2.5 : 0.8}
                strokeLinejoin="round"
                className="state-shape cursor-pointer"
                opacity={selectedName && selectedName !== name ? 0.45 : 1}
                onClick={() => toggle(name)}
              >
                <title>{`${name}: ${data.ev} electoral votes, ${PARTY_META[data.party].label.toLowerCase()}`}</title>
              </path>
            ))}
          </g>
        </svg>
        <div className="mt-2 min-h-12 rounded-xl bg-slate-50 px-4 py-3 text-center text-sm" aria-live="polite">
          {selected ? (
            <p>
              <strong className="font-semibold text-slate-900">{selected.name}</strong>
              {' · '}
              {selected.ev} electoral votes{' · '}
              <span className={PARTY_META[selected.party].text}>{PARTY_META[selected.party].label}</span>
            </p>
          ) : (
            <p className="text-slate-600">Tap a state, or pick one from the list below, to see its electoral votes.</p>
          )}
        </div>
      </div>

      <div className="grid gap-4 md:grid-cols-3">
        {groups.map(({ party, states }) => (
          <section key={party} aria-labelledby={`group-${party}`}>
            <h3 id={`group-${party}`} className={`flex items-baseline justify-between text-sm font-semibold ${PARTY_META[party].text}`}>
              <span className="flex items-center gap-2">
                <span className="size-3 rounded-sm" style={{ background: PARTY_META[party].fill }} aria-hidden="true" />
                {PARTY_META[party].label}
              </span>
              <span className="tabular-nums">{tally[party]} EV</span>
            </h3>
            <ul className="mt-2 flex flex-wrap gap-1.5">
              {states.map((s) => (
                <li key={s.name}>
                  <button
                    type="button"
                    onClick={() => toggle(s.name)}
                    aria-pressed={selectedName === s.name}
                    className={`min-h-9 rounded-lg px-2.5 text-sm transition-colors ${
                      selectedName === s.name
                        ? 'bg-slate-900 text-white'
                        : `${PARTY_META[party].chip} text-slate-800 hover:bg-slate-200`
                    }`}
                  >
                    {s.name} <span className="tabular-nums opacity-70">{s.ev}</span>
                  </button>
                </li>
              ))}
            </ul>
          </section>
        ))}
      </div>

      <p className="text-xs leading-relaxed text-slate-600">
        This is a static baseline for illustration, not a live forecast or poll average. Maine and Nebraska split
        some electoral votes by district; they are shown here by statewide lean.
      </p>
    </div>
  );
}
