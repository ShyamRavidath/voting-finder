import { Link } from 'react-router-dom';
import Icon from '../components/Icon';
import { nextFederalElection } from '../lib/format';
import { usePageTitle } from '../hooks/usePageTitle';

export default function HomePage() {
  usePageTitle(null);
  const next = nextFederalElection();
  const dateLabel = next.date.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric', year: 'numeric' });

  return (
    <div className="fade-in mx-auto flex max-w-3xl flex-col items-center py-6 text-center sm:py-16">
      <p className="inline-flex items-center gap-2 rounded-full border border-slate-200 bg-white px-3 py-1.5 text-left text-sm text-slate-700">
        <Icon name="calendar" className="size-4 text-blue-600" />
        <span>
          {next.kind}: <strong className="font-semibold text-slate-900">{dateLabel}</strong>
          {' · '}
          {next.daysAway === 0 ? 'today' : `${next.daysAway} day${next.daysAway === 1 ? '' : 's'} away`}
        </span>
      </p>

      <h1 className="mt-6 text-5xl font-bold leading-[1.05] tracking-tight sm:text-7xl">
        Ready for <br />
        <span className="text-red-600">November</span> <span className="text-blue-600">2028?</span>
      </h1>
      <p className="mt-6 max-w-xl text-lg leading-relaxed text-slate-600 sm:text-xl">
        The next generation of leadership starts with your vote. Find where to vote, see how the
        electoral map stacks up, and keep up with the 2028 race, all in one nonpartisan place.
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
      <Link to="/news" className="mt-5 inline-flex min-h-11 items-center gap-1 font-semibold text-blue-700 hover:text-blue-800">
        Read the latest 2028 election news <span aria-hidden="true">→</span>
      </Link>
    </div>
  );
}
