export default function PollingLocationCard({ location, onViewMap }) {
  const { name, addr, type, hours, isReal, isEstimated, isSample, lat, lng } = location;

  const borderClass = isReal
    ? 'border-green-200 bg-green-50/50 hover:border-green-300 hover:bg-green-50'
    : 'border-slate-200 bg-slate-50 hover:border-blue-300 hover:bg-white';

  const typeClass =
    type === 'Polling Place'
      ? 'text-blue-600 bg-blue-50'
      : type === 'Early Voting'
      ? 'text-purple-600 bg-purple-50'
      : 'text-slate-600 bg-slate-100';

  return (
    <div className={`p-6 border-2 rounded-2xl fade-in transition-all cursor-pointer ${borderClass}`}>
      <div className="flex items-start justify-between mb-2">
        <div className="flex items-center gap-2">
          <span className={`text-xs font-bold uppercase tracking-widest px-3 py-1 rounded-full ${typeClass}`}>
            {type}
          </span>
          {isReal && !isEstimated && <span className="text-xs text-green-700 font-semibold">✓ Official</span>}
          {isReal && isEstimated && <span className="text-xs text-blue-700 font-semibold">✓ Real Location</span>}
          {isSample && <span className="text-xs text-amber-700 font-semibold">Estimated</span>}
        </div>
        {lat && lng && (
          <button
            onClick={() => onViewMap?.(lat, lng)}
            className="text-xs font-semibold text-blue-600 hover:text-blue-700 whitespace-nowrap"
          >
            View on Map →
          </button>
        )}
      </div>
      <h4 className="font-bold text-xl text-slate-900 mb-1">{name}</h4>
      <p className="text-sm text-slate-600 mb-2">{addr}</p>
      {hours && <p className="text-xs text-slate-500 mt-2"><strong>Hours:</strong> {hours}</p>}
    </div>
  );
}
