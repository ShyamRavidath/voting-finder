import Icon from './Icon';
import { directionsUrl, formatMiles } from '../lib/format';

export default function PollingLocationCard({ location, number, selected, onShowOnMap }) {
  const { name, addr, type, hours, distance, isEstimated, lat, lng } = location;
  const official = !isEstimated;
  const hasCoords = lat != null && lng != null;

  return (
    <li
      className={`rounded-2xl border bg-white p-4 transition-colors sm:p-5 ${
        selected ? 'border-blue-500 ring-2 ring-blue-500/20' : 'border-slate-200'
      }`}
    >
      <div className="flex gap-3">
        <span
          className={`flex size-7 shrink-0 items-center justify-center rounded-full text-sm font-bold text-white ${
            official ? 'bg-emerald-600' : 'bg-blue-600'
          }`}
          aria-hidden="true"
        >
          {number}
        </span>
        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-x-2 gap-y-1 text-xs font-semibold">
            <span className="text-slate-600">{type}</span>
            {official ? (
              <span className="inline-flex items-center gap-0.5 rounded-full bg-emerald-50 px-2 py-0.5 text-emerald-700">
                <Icon name="check" className="size-3.5" strokeWidth={2.5} /> Official
              </span>
            ) : (
              <span className="rounded-full bg-amber-50 px-2 py-0.5 text-amber-800">Not confirmed</span>
            )}
            {distance != null && <span className="font-medium text-slate-500">{formatMiles(distance)}</span>}
          </div>
          <h3 className="mt-1 text-lg leading-snug font-semibold text-slate-900">{name}</h3>
          <p className="mt-0.5 text-[15px] text-slate-600">{addr}</p>
          {hours && (
            <p className="mt-2 text-sm text-slate-600">
              <span className="font-semibold text-slate-700">Hours:</span> {hours}
            </p>
          )}
          <div className="mt-3 flex flex-wrap gap-2">
            <a
              href={directionsUrl(location)}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex min-h-10 items-center gap-1.5 rounded-lg bg-slate-900 px-3.5 text-sm font-semibold text-white hover:bg-slate-700"
            >
              <Icon name="directions" className="size-4" />
              Directions
              <span className="sr-only"> to {name} (opens maps)</span>
            </a>
            {hasCoords && onShowOnMap && (
              <button
                type="button"
                onClick={onShowOnMap}
                className="inline-flex min-h-10 items-center gap-1.5 rounded-lg border border-slate-300 px-3.5 text-sm font-semibold text-slate-800 hover:bg-slate-50"
              >
                <Icon name="map" className="size-4" />
                Show on map
              </button>
            )}
          </div>
        </div>
      </div>
    </li>
  );
}
