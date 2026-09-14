import { lazy, Suspense, useRef } from 'react';
import { useSearchParams } from 'react-router-dom';
import Icon from '../components/Icon';
import PollingFinder from '../components/PollingFinder';
import { usePageTitle } from '../hooks/usePageTitle';

const ElectoralMap = lazy(() => import('../components/ElectoralMap'));

const TABS = [
  { id: 'booths', label: 'Polling places', icon: 'pin' },
  { id: 'map', label: 'Electoral map', icon: 'map' },
];

export default function ToolsPage() {
  const [searchParams, setSearchParams] = useSearchParams();
  const activeTab = searchParams.get('tab') === 'map' ? 'map' : 'booths';
  const tabRefs = useRef({});
  usePageTitle(activeTab === 'map' ? 'Electoral map' : 'Find your polling place');

  const selectTab = (id) =>
    setSearchParams(
      (prev) => {
        const next = new URLSearchParams(prev);
        next.set('tab', id);
        return next;
      },
      { replace: true }
    );

  const onKeyDown = (e) => {
    if (e.key !== 'ArrowRight' && e.key !== 'ArrowLeft') return;
    const idx = TABS.findIndex((t) => t.id === activeTab);
    const next = TABS[(idx + (e.key === 'ArrowRight' ? 1 : TABS.length - 1)) % TABS.length];
    selectTab(next.id);
    tabRefs.current[next.id]?.focus();
  };

  return (
    <div className="fade-in space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight sm:text-4xl">Voting tools</h1>
        <p className="mt-1 text-slate-600">Find where to vote and see how the electoral map stacks up.</p>
      </div>

      <div role="tablist" aria-label="Voting tools" className="grid grid-cols-2 gap-1 rounded-xl bg-slate-200/70 p-1 sm:inline-grid">
        {TABS.map((tab) => {
          const active = tab.id === activeTab;
          return (
            <button
              key={tab.id}
              ref={(el) => {
                tabRefs.current[tab.id] = el;
              }}
              id={`tab-${tab.id}`}
              role="tab"
              type="button"
              aria-selected={active}
              aria-controls={`panel-${tab.id}`}
              tabIndex={active ? 0 : -1}
              onClick={() => selectTab(tab.id)}
              onKeyDown={onKeyDown}
              className={`inline-flex min-h-11 items-center justify-center gap-2 rounded-lg px-4 text-[15px] font-semibold transition-colors sm:px-6 ${
                active ? 'bg-white text-blue-700 shadow-sm' : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              <Icon name={tab.icon} className="size-5" />
              {tab.label}
            </button>
          );
        })}
      </div>

      <div
        id={`panel-${activeTab}`}
        role="tabpanel"
        aria-labelledby={`tab-${activeTab}`}
        className="rounded-3xl border border-slate-200 bg-white p-4 sm:p-8"
      >
        {activeTab === 'booths' ? (
          <PollingFinder />
        ) : (
          <div className="space-y-4">
            <div>
              <h2 className="text-2xl font-bold">Electoral College baseline</h2>
              <p className="mt-1 text-slate-600">How each state's electoral votes lean heading into 2028.</p>
            </div>
            <Suspense fallback={<div className="skeleton aspect-[975/610] w-full rounded-2xl" />}>
              <ElectoralMap />
            </Suspense>
          </div>
        )}
      </div>
    </div>
  );
}
