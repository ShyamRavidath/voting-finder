import { useState, useMemo, useRef } from 'react';
import { useSearchParams } from 'react-router-dom';
import { STATE_DATA } from '../data/stateData';
import { usePolling } from '../hooks/usePolling';
import PollingLocationCard from '../components/PollingLocationCard';
import ElectoralMap from '../components/ElectoralMap';

export default function ToolsPage() {
  const [searchParams, setSearchParams] = useSearchParams();
  const activeTool = searchParams.get('tab') || 'booths';
  const setActiveTool = (tab) => setSearchParams({ tab });

  const [zip, setZip] = useState('');
  const { locations, dataSource, loading, error, search } = usePolling();
  const mapApiRef = useRef(null);

  const tally = useMemo(
    () =>
      STATE_DATA.reduce(
        (acc, s) => {
          if (s.party === 'blue') acc.blue += s.ev;
          else if (s.party === 'red') acc.red += s.ev;
          else acc.swing += s.ev;
          return acc;
        },
        { blue: 0, red: 0, swing: 0 }
      ),
    []
  );

  const handleSearch = async (e) => {
    e.preventDefault();
    if (zip.length < 5) return;
    await search(zip);
  };

  const handleViewOnMap = (lat, lng) => {
    setActiveTool('map');
    setTimeout(() => mapApiRef.current?.setView([lat, lng], 15), 150);
  };

  return (
    <div className="space-y-8 fade-in">
      <div className="text-center mb-8">
        <h1 className="text-5xl font-bold mb-3">Election Tools</h1>
        <p className="text-slate-600 text-lg">Access real-time electoral data and polling information</p>
      </div>

      <div className="grid grid-cols-3 gap-6 bg-white p-8 rounded-2xl shadow-md border border-slate-100">
        <div className="text-center">
          <p className="text-xs font-bold uppercase text-blue-600 tracking-wider mb-2">Democrat</p>
          <p className="text-5xl font-bold text-blue-600">{tally.blue}</p>
          <p className="text-xs text-slate-500 mt-1">Electoral Votes</p>
        </div>
        <div className="text-center border-x border-slate-200">
          <p className="text-xs font-bold uppercase text-slate-500 tracking-wider mb-2">Swing States</p>
          <p className="text-5xl font-bold text-slate-600">{tally.swing}</p>
          <p className="text-xs text-slate-500 mt-1">Electoral Votes</p>
        </div>
        <div className="text-center">
          <p className="text-xs font-bold uppercase text-red-600 tracking-wider mb-2">Republican</p>
          <p className="text-5xl font-bold text-red-600">{tally.red}</p>
          <p className="text-xs text-slate-500 mt-1">Electoral Votes</p>
        </div>
      </div>

      <div className="flex bg-slate-100 p-1.5 rounded-2xl w-fit mx-auto gap-2">
        {['booths', 'map'].map((tool) => (
          <button
            key={tool}
            onClick={() => setActiveTool(tool)}
            className={`px-8 py-3 rounded-xl font-semibold transition-all ${
              activeTool === tool ? 'bg-white text-blue-600 shadow-md' : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            {tool === 'booths' ? 'Locate Booths' : 'Electoral Map'}
          </button>
        ))}
      </div>

      <div className="bg-white p-8 rounded-3xl shadow-lg border border-slate-100 min-h-[600px]">
        {activeTool === 'booths' ? (
          <div className="max-w-2xl mx-auto space-y-8">
            <div className="text-center mb-6">
              <h3 className="text-2xl font-bold mb-2">Find Your Polling Location</h3>
              <p className="text-slate-600">Enter your zip code to find nearby polling booths and early voting locations</p>
            </div>

            <form onSubmit={handleSearch} className="flex gap-3">
              <input
                value={zip}
                onChange={(e) => setZip(e.target.value.replace(/\D/g, '').slice(0, 5))}
                placeholder="Enter Zip Code (e.g., 90210)"
                className="flex-1 bg-slate-50 border-2 border-slate-200 p-4 rounded-xl font-medium outline-none focus:border-blue-500 focus:bg-white transition"
                maxLength="5"
              />
              <button
                type="submit"
                disabled={zip.length < 5 || loading}
                className="bg-blue-600 text-white px-8 rounded-xl font-semibold hover:bg-blue-700 transition-all shadow-md hover:shadow-lg disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {loading ? 'Searching...' : 'Find'}
              </button>
            </form>

            {loading && (
              <div className="text-center py-8">
                <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mb-3" />
                <p className="font-semibold text-blue-600">Verifying Local Precincts...</p>
              </div>
            )}

            {error && (
              <div className="bg-red-50 border border-red-200 rounded-xl p-4">
                <p className="text-sm text-red-800">{error}</p>
              </div>
            )}

            {!loading && locations.length > 0 && (
              <div className="space-y-3">
                <div className="flex items-center justify-between mb-4">
                  <h4 className="font-bold text-lg text-slate-900">Nearby Polling Locations</h4>
                  {dataSource === 'official' && (
                    <span className="text-xs font-semibold text-green-700 bg-green-50 px-3 py-1 rounded-full">✓ Official Data</span>
                  )}
                  {dataSource === 'estimated' && (
                    <span className="text-xs font-semibold text-blue-700 bg-blue-50 px-3 py-1 rounded-full">Real Locations</span>
                  )}
                  {dataSource === 'sample' && (
                    <span className="text-xs font-semibold text-amber-700 bg-amber-50 px-3 py-1 rounded-full">⚠ Sample Data</span>
                  )}
                </div>

                {dataSource === 'estimated' && (
                  <div className="bg-blue-50 border border-blue-200 rounded-lg p-3 mb-4">
                    <p className="text-xs text-blue-800">
                      <strong>Real Locations Found:</strong> These are actual nearby venues (libraries, schools, community centers) commonly used as polling places. Official 2028 locations will be released closer to election day.
                    </p>
                  </div>
                )}
                {dataSource === 'sample' && (
                  <div className="bg-amber-50 border border-amber-200 rounded-lg p-3 mb-4">
                    <p className="text-xs text-amber-800">
                      <strong>Note:</strong> Official polling location data is not yet available for 2028. Locations are typically released 2 months before election day.
                    </p>
                  </div>
                )}

                {locations.map((loc, i) => (
                  <PollingLocationCard key={i} location={loc} onViewMap={handleViewOnMap} />
                ))}
              </div>
            )}
          </div>
        ) : (
          <div className="space-y-4 h-full">
            <div className="flex items-center justify-between mb-4">
              <div>
                <h3 className="text-2xl font-bold">Electoral College Projection</h3>
                <p className="text-slate-600 mt-1">Current state-by-state electoral vote allocation</p>
              </div>
            </div>
            <ElectoralMap
              pollingLocations={locations}
              onReady={(map) => { mapApiRef.current = map; }}
            />
            {locations.length > 0 && (
              <div className="mt-4 p-4 bg-blue-50 border border-blue-200 rounded-xl">
                <p className="text-sm font-medium text-blue-800">
                  Click markers for location details.
                </p>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
