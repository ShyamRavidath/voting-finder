import { lazy, Suspense, useEffect, useId, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import Icon from './Icon';
import PollingLocationCard from './PollingLocationCard';
import { usePolling } from '../hooks/usePolling';
import { OFFICIAL_LINKS } from '../data/officialLinks';

const PollingMap = lazy(() => import('./PollingMap'));
const LAST_ZIP_KEY = 'vote4u:lastZip';
const isZip = (v) => /^\d{5}$/.test(v || '');

function readLastZip() {
  try {
    return localStorage.getItem(LAST_ZIP_KEY) || '';
  } catch {
    return '';
  }
}

function OfficialLinks({ heading = 'Always confirm with official sources' }) {
  return (
    <section className="rounded-2xl border border-slate-200 bg-slate-50 p-4 sm:p-5">
      <h3 className="font-semibold text-slate-900">{heading}</h3>
      <p className="mt-1 text-sm text-slate-600">
        Polling places can change between elections. Your state or county election office has the final word.
      </p>
      <ul className="mt-3 space-y-1">
        {OFFICIAL_LINKS.map((link) => (
          <li key={link.href}>
            <a
              href={link.href}
              target="_blank"
              rel="noopener noreferrer"
              className="group flex min-h-11 items-center justify-between gap-3 rounded-lg px-2 py-1.5 -mx-2 hover:bg-white"
            >
              <span>
                <span className="block font-medium text-blue-700 group-hover:underline">{link.label}</span>
                <span className="block text-xs text-slate-600">{link.source}</span>
              </span>
              <Icon name="external" className="size-4 shrink-0 text-slate-500" />
              <span className="sr-only">(opens in a new tab)</span>
            </a>
          </li>
        ))}
      </ul>
    </section>
  );
}

function ResultsSkeleton() {
  return (
    <div className="space-y-3" aria-busy="true" aria-label="Searching for polling locations">
      {[0, 1, 2].map((i) => (
        <div key={i} className="rounded-2xl border border-slate-200 bg-white p-5">
          <div className="skeleton h-3 w-24 rounded" />
          <div className="skeleton mt-3 h-5 w-2/3 rounded" />
          <div className="skeleton mt-2 h-4 w-1/2 rounded" />
        </div>
      ))}
    </div>
  );
}

const SOURCE_NOTICE = {
  official: {
    tone: 'border-emerald-200 bg-emerald-50 text-emerald-900',
    title: 'Official locations',
    body: (election) =>
      `From Google's Voting Information Project${election ? ` for the ${election}` : ''}. Double-check your assigned polling place before you go.`,
  },
  estimated: {
    tone: 'border-amber-200 bg-amber-50 text-amber-900',
    title: 'Likely venues, not confirmed',
    body: () =>
      "Official polling places aren't published for your area yet. These are nearby public buildings (libraries, community centers, town halls) that are often used as polling places.",
  },
  // The weakest tier the server will return. The wording hedges harder than 'estimated' on
  // purpose: these came from a wider sweep with no match in the immediate area.
  nearby: {
    tone: 'border-amber-200 bg-amber-50 text-amber-900',
    title: 'Nothing listed nearby — here are the closest civic buildings',
    body: (_election, radiusKm) =>
      `We couldn't find any polling-type venue in your immediate area, so we widened the search${
        radiusKm ? ` to about ${Math.round(radiusKm * 0.621371)} miles` : ''
      }. These are civic buildings of the kind precincts often use. None of them is a confirmed polling place — check the official links below before you go.`,
  },
};

export default function PollingFinder() {
  const inputId = useId();
  const [searchParams, setSearchParams] = useSearchParams();
  const zipParam = searchParams.get('zip');
  const [zip, setZip] = useState(() => (isZip(zipParam) ? zipParam : readLastZip()));
  const [selected, setSelected] = useState(null);
  const { status, locations, dataSource, place, election, searchRadiusKm, error, search, zip: searchedZip } = usePolling();

  // Run the search whenever the URL's ?zip= changes (form submit, shared link, back/forward).
  useEffect(() => {
    if (!isZip(zipParam)) return;
    setZip(zipParam);
    setSelected(null);
    search(zipParam);
    try {
      localStorage.setItem(LAST_ZIP_KEY, zipParam);
    } catch {
      // storage unavailable (private mode) — fine
    }
  }, [zipParam, search]);

  const submit = (e) => {
    e.preventDefault();
    if (!isZip(zip)) return;
    if (zip === zipParam) search(zip);
    else
      setSearchParams((prev) => {
        const next = new URLSearchParams(prev);
        next.set('zip', zip);
        return next;
      });
  };

  const notice = SOURCE_NOTICE[dataSource];
  const showMap = status === 'success' && locations.some((l) => l.lat != null);

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold">Find your polling place</h2>
        <p className="mt-1 text-slate-600">Enter your ZIP code to see polling and early voting locations near you.</p>
      </div>

      <form onSubmit={submit} className="max-w-xl" role="search" aria-label="Polling place search">
        <label htmlFor={inputId} className="mb-1.5 block text-sm font-semibold text-slate-800">
          ZIP code
        </label>
        <div className="flex gap-2">
          <input
            id={inputId}
            value={zip}
            onChange={(e) => setZip(e.target.value.replace(/\D/g, '').slice(0, 5))}
            placeholder="e.g. 90210"
            inputMode="numeric"
            autoComplete="postal-code"
            enterKeyHint="search"
            pattern="\d{5}"
            maxLength={5}
            aria-describedby={`${inputId}-hint`}
            className="min-h-12 w-full min-w-0 flex-1 rounded-xl border border-slate-300 bg-white px-4 text-base font-medium outline-none placeholder:text-slate-500 focus:border-blue-600 focus:ring-2 focus:ring-blue-600/20"
          />
          <button
            type="submit"
            disabled={!isZip(zip) || status === 'loading'}
            className="inline-flex min-h-12 shrink-0 items-center gap-2 rounded-xl bg-blue-600 px-5 font-semibold text-white transition-colors hover:bg-blue-700 disabled:cursor-not-allowed disabled:bg-blue-600/50"
          >
            <Icon name="search" className="size-5" />
            {status === 'loading' ? 'Searching…' : 'Search'}
          </button>
        </div>
        <p id={`${inputId}-hint`} className="mt-1.5 text-xs text-slate-600">
          5-digit U.S. ZIP code. We only use it to look up nearby locations.
        </p>
      </form>

      <div aria-live="polite" className="space-y-6">
        {status === 'loading' && <ResultsSkeleton />}

        {status === 'error' && (
          <div role="alert" className="flex gap-3 rounded-2xl border border-red-200 bg-red-50 p-4 text-red-900">
            <Icon name="alert" className="size-5 shrink-0" />
            <div>
              <p className="font-semibold">Search didn't work</p>
              <p className="mt-0.5 text-sm">{error}</p>
              {searchedZip && (
                <button
                  type="button"
                  onClick={() => search(searchedZip)}
                  className="mt-2 min-h-10 text-sm font-semibold underline underline-offset-2"
                >
                  Try again
                </button>
              )}
            </div>
          </div>
        )}

        {status === 'success' && locations.length === 0 && (
          <div className="rounded-2xl border border-slate-200 bg-white p-5">
            <p className="font-semibold text-slate-900">
              No locations found near {place ? `${place.city}, ${place.stateAbbr}` : searchedZip} yet
            </p>
            <p className="mt-1 text-sm text-slate-600">
              We checked official data, then nearby public buildings, then widened the search — nothing came back. Official
              polling places are usually published a few weeks before each election. Use the official lookups below in the
              meantime.
            </p>
          </div>
        )}

        {status === 'success' && locations.length > 0 && (
          <div className="fade-in space-y-4">
            <div className="flex flex-wrap items-baseline justify-between gap-2">
              <h3 className="text-lg font-semibold">
                {locations.length} location{locations.length === 1 ? '' : 's'} near{' '}
                {place ? `${place.city}, ${place.stateAbbr}` : searchedZip}
              </h3>
            </div>
            {notice && (
              <div className={`rounded-xl border p-3 text-sm ${notice.tone}`}>
                <strong className="font-semibold">{notice.title}.</strong> {notice.body(election, searchRadiusKm)}
              </div>
            )}
            <div className="grid gap-4 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)] lg:items-start">
              <ol className="space-y-3">
                {locations.map((loc, i) => (
                  <PollingLocationCard
                    key={`${loc.name}-${loc.addr}`}
                    location={loc}
                    number={i + 1}
                    selected={selected === i}
                    onShowOnMap={() => {
                      setSelected(i);
                      document.getElementById('polling-map')?.scrollIntoView({ behavior: 'smooth', block: 'center' });
                    }}
                  />
                ))}
              </ol>
              {showMap && (
                <div id="polling-map" className="lg:sticky lg:top-24">
                  <Suspense fallback={<div className="skeleton h-72 rounded-2xl sm:h-96" />}>
                    <PollingMap locations={locations} center={place} selected={selected} onSelect={setSelected} />
                  </Suspense>
                </div>
              )}
            </div>
          </div>
        )}

        <OfficialLinks heading={status === 'idle' ? 'Prefer to go straight to the source?' : undefined} />
      </div>
    </div>
  );
}
