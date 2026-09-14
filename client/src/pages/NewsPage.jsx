import { useNews } from '../hooks/useNews';
import NewsCard from '../components/NewsCard';
import Icon from '../components/Icon';
import { usePageTitle } from '../hooks/usePageTitle';

function NewsSkeleton() {
  return (
    <ul className="space-y-3" aria-busy="true" aria-label="Loading news">
      {[0, 1, 2, 3, 4].map((i) => (
        <li key={i} className="flex gap-4 rounded-2xl border border-slate-200 bg-white p-5">
          <div className="flex-1">
            <div className="skeleton h-3 w-32 rounded" />
            <div className="skeleton mt-3 h-5 w-full rounded" />
            <div className="skeleton mt-2 h-5 w-3/4 rounded" />
          </div>
          <div className="skeleton size-20 rounded-xl sm:h-24 sm:w-32" />
        </li>
      ))}
    </ul>
  );
}

export default function NewsPage() {
  usePageTitle('2028 election news');
  const { articles, loading, error, refresh, retry } = useNews();

  return (
    <div className="fade-in mx-auto max-w-3xl space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold tracking-tight sm:text-4xl">2028 election news</h1>
          <p className="mt-1 text-slate-600">Latest headlines on the race and the people in it.</p>
        </div>
        <button
          type="button"
          onClick={refresh}
          disabled={loading}
          aria-label="Refresh news"
          className="inline-flex min-h-11 min-w-11 shrink-0 items-center justify-center gap-2 rounded-xl border border-slate-300 bg-white px-3 font-semibold text-slate-800 transition-colors hover:bg-slate-50 disabled:opacity-50 sm:px-4"
        >
          <Icon name="refresh" className={`size-5 ${loading ? 'animate-spin' : ''}`} />
          <span className="hidden sm:inline">{loading ? 'Loading…' : 'Refresh'}</span>
        </button>
      </div>

      <div aria-live="polite">
        {loading && articles.length === 0 && <NewsSkeleton />}

        {error && (
          <div role="alert" className="flex gap-3 rounded-2xl border border-amber-200 bg-amber-50 p-4 text-amber-900">
            <Icon name="alert" className="size-5 shrink-0" />
            <div>
              <p className="font-semibold">News is unavailable right now</p>
              <p className="mt-0.5 text-sm">{error}</p>
              <button type="button" onClick={retry} className="mt-2 min-h-10 text-sm font-semibold underline underline-offset-2">
                Try again
              </button>
            </div>
          </div>
        )}

        {!loading && !error && articles.length === 0 && (
          <div className="rounded-2xl border border-slate-200 bg-white p-6 text-center">
            <p className="font-semibold text-slate-900">No headlines right now</p>
            <p className="mt-1 text-sm text-slate-600">Check back soon, or tap refresh to try again.</p>
          </div>
        )}

        {articles.length > 0 && (
          <ul className={`space-y-3 transition-opacity ${loading ? 'opacity-60' : ''}`}>
            {articles.map((article) => (
              <NewsCard key={article.id} article={article} />
            ))}
          </ul>
        )}
      </div>

      {articles.length > 0 && (
        <p className="border-t border-slate-200 pt-4 text-center text-xs text-slate-600">
          Headlines are gathered automatically from news sources and open on the publisher's site. Party labels reflect
          the candidate a story mentions, not the outlet. Vote4U doesn't endorse any source or candidate.
        </p>
      )}
    </div>
  );
}
