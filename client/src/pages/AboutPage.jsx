import { useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import { usePageTitle } from '../hooks/usePageTitle';

const TABS = [
  { id: 'why', label: 'Why' },
  { id: 'goal', label: 'Our goal' },
  { id: 'what', label: 'What is voting?' },
];

const SOURCES = [
  ['Polling places', "Google Civic Information API (Voting Information Project) when official data is published; otherwise nearby public buildings from OpenStreetMap."],
  ['ZIP code lookup', 'Zippopotam.us'],
  ['Maps', 'U.S. state shapes from the U.S. Census Bureau (via us-atlas); street maps © OpenStreetMap contributors.'],
  ['News', 'Google News headlines, linked to the original publishers.'],
  ['Electoral votes', 'Electoral College allocation for the 2024 and 2028 elections, based on the 2020 Census.'],
];

export default function AboutPage() {
  usePageTitle('About');
  const [tab, setTab] = useState('why');
  const tabRefs = useRef({});

  const onKeyDown = (e) => {
    if (e.key !== 'ArrowRight' && e.key !== 'ArrowLeft') return;
    const idx = TABS.findIndex((t) => t.id === tab);
    const next = TABS[(idx + (e.key === 'ArrowRight' ? 1 : TABS.length - 1)) % TABS.length];
    setTab(next.id);
    tabRefs.current[next.id]?.focus();
  };

  return (
    <div className="fade-in mx-auto max-w-3xl space-y-8">
      <div>
        <h1 className="text-3xl font-bold tracking-tight sm:text-4xl">About Vote4U</h1>
        <p className="mt-1 text-lg text-slate-600">Empowering the next generation of voters.</p>
      </div>

      <div>
        <div role="tablist" aria-label="About Vote4U" className="flex gap-1 overflow-x-auto rounded-xl bg-slate-200/70 p-1">
          {TABS.map((t) => (
            <button
              key={t.id}
              ref={(el) => {
                tabRefs.current[t.id] = el;
              }}
              id={`about-tab-${t.id}`}
              role="tab"
              type="button"
              aria-selected={tab === t.id}
              aria-controls="about-panel"
              tabIndex={tab === t.id ? 0 : -1}
              onClick={() => setTab(t.id)}
              onKeyDown={onKeyDown}
              className={`min-h-11 flex-1 rounded-lg px-3 text-[15px] font-semibold whitespace-nowrap transition-colors ${
                tab === t.id ? 'bg-white text-blue-700 shadow-sm' : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              {t.label}
            </button>
          ))}
        </div>

        <div
          id="about-panel"
          role="tabpanel"
          aria-labelledby={`about-tab-${tab}`}
          className="mt-4 rounded-3xl border border-slate-200 bg-white p-5 sm:p-10"
        >
          {tab === 'why' && (
            <div className="space-y-4 text-lg leading-relaxed text-slate-700">
              <h2 className="text-2xl font-bold text-slate-900 sm:text-3xl">Why this matters</h2>
              <p>
                Voting is one of the most crucial civil liberties granted in the United States. It embodies the
                freedom to improve the future of society for the betterment of the public as a whole.
              </p>
              <p>
                Suffrage allows American citizens to retain the freedoms stated in the Constitution and its
                amendments, a gift many around the world are denied. Voting is more than checking a box on a piece of
                paper; it is the ability to influence and change the political landscape that shapes our daily lives.
              </p>
              <p className="border-t border-slate-200 pt-4 text-slate-600 italic">
                Every vote cast is a voice heard, and every voice heard is a future shaped.
              </p>
            </div>
          )}
          {tab === 'goal' && (
            <div className="space-y-4 text-lg leading-relaxed text-slate-700">
              <h2 className="text-2xl font-bold text-slate-900 sm:text-3xl">Our goal</h2>
              <p>
                Vote4U addresses low young-adult voter turnout across the United States, from local to national
                elections. Young adults are a crucial demographic in shaping our world, yet they often feel
                disconnected from voting and government.
              </p>
              <p>
                The main reasons people ages 18–22 don't vote are a lack of resources, knowledge, and confidence. This
                app works to close that gap with accessible, nonpartisan civic information.
              </p>
              <p>We focus on helping people who haven't had access to clear civic information and education.</p>
            </div>
          )}
          {tab === 'what' && (
            <div className="space-y-4 text-lg leading-relaxed text-slate-700">
              <h2 className="text-2xl font-bold text-slate-900 sm:text-3xl">What is voting?</h2>
              <p>
                Voting is the foundation of democracy: the process through which citizens have a direct say in shaping
                their communities, states, and nation.
              </p>
              <p>
                Every ballot cast, whether for a city measure or the presidency, is a step toward making sure every
                voice is heard.
              </p>
              <p className="border-t border-slate-200 pt-4 font-semibold text-blue-700">
                Ready to make your voice heard?{' '}
                <Link to="/tools?tab=booths" className="underline underline-offset-2">
                  Find your polling place
                </Link>
                .
              </p>
            </div>
          )}
        </div>
      </div>

      <section aria-labelledby="sources-heading" className="space-y-3">
        <h2 id="sources-heading" className="text-xl font-bold">
          Where our information comes from
        </h2>
        <dl className="divide-y divide-slate-200 rounded-2xl border border-slate-200 bg-white">
          {SOURCES.map(([term, desc]) => (
            <div key={term} className="grid gap-1 p-4 sm:grid-cols-[10rem_1fr] sm:gap-4">
              <dt className="font-semibold text-slate-900">{term}</dt>
              <dd className="text-slate-600">{desc}</dd>
            </div>
          ))}
        </dl>
        <p className="text-sm text-slate-600">
          Vote4U is an independent, nonpartisan project. It is not affiliated with, endorsed by, or operated by any
          government agency, election office, campaign, or political party. Always confirm voting details with your
          state or local election office. See our <Link to="/privacy" className="font-semibold text-blue-700 underline underline-offset-2">privacy policy</Link>.
        </p>
      </section>
    </div>
  );
}
