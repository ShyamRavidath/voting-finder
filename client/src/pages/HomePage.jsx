import { Link } from 'react-router-dom';
import Icon from '../components/Icon';
import { nextFederalElection } from '../lib/format';
import { usePageTitle } from '../hooks/usePageTitle';

export default function HomePage() {
  usePageTitle(null);
  const next = nextFederalElection();
  const dateLabel = next.date.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric', year: 'numeric' });

  return (
    <div className="fade-in mx-auto flex max-w-4xl flex-col items-center py-6 text-center sm:py-12">
      <p className="inline-flex items-center gap-2 rounded-full border border-slate-200 bg-white px-3 py-1.5 text-left text-sm text-slate-700">
        <Icon name="calendar" className="size-4 text-blue-600" />
        <span>
          {next.kind}: <strong className="font-semibold text-slate-900">{dateLabel}</strong>
          {' · '}
          {next.daysAway === 0 ? 'today' : `${next.daysAway} day${next.daysAway === 1 ? '' : 's'} away`}
        </span>
      </p>

      <h1 className="mt-6 text-5xl font-bold leading-[1.05] tracking-tight sm:text-7xl">
        Make your <br />
        <span className="text-blue-600">voting plan.</span>
      </h1>
      <p className="mt-6 max-w-xl text-lg leading-relaxed text-slate-600 sm:text-xl">
        Start with your ZIP code. Explore nearby locations, then confirm your assigned polling place with your state or county election office.
      </p>

      <div className="mt-8 flex w-full flex-col gap-3 sm:w-auto sm:flex-row">
        <Link
          to="/tools?tab=booths"
          className="inline-flex min-h-12 items-center justify-center gap-2 rounded-xl bg-blue-600 px-7 text-lg font-semibold text-white shadow-sm transition-colors hover:bg-blue-700"
        >
          <Icon name="pin" />
          Find my polling place
        </Link>
        <Link
          to="/tools?tab=map"
          className="inline-flex min-h-12 items-center justify-center gap-2 rounded-xl border border-slate-300 bg-white px-7 text-lg font-semibold text-slate-900 transition-colors hover:bg-slate-50"
        >
          <Icon name="map" />
          Electoral map
        </Link>
      </div>
      <div className="mt-8 grid w-full gap-3 text-left sm:grid-cols-3">
        {[["01", "Search nearby", "Enter a ZIP code. No location permission needed."], ["02", "Check the source", "Unconfirmed venues are clearly labelled. Always verify before you go."], ["03", "Plan your visit", "Check official hours and directions before Election Day."]].map(([step, title, body]) => (
          <section key={step} className="rounded-2xl border border-slate-200 bg-white p-5">
            <span className="text-sm font-semibold text-blue-700">{step}</span>
            <h2 className="mt-2 text-lg font-semibold">{title}</h2>
            <p className="mt-1 text-sm leading-relaxed text-slate-600">{body}</p>
          </section>
        ))}
      </div>
      <Link to="/news" className="mt-5 inline-flex min-h-11 items-center gap-1 font-semibold text-blue-700 hover:text-blue-800">
        Read the latest election news <span aria-hidden="true">→</span>
      </Link>
    </div>
  );
}
