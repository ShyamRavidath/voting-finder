import { useNews } from '../hooks/useNews';
import NewsCard from '../components/NewsCard';

export default function NewsPage() {
  const { articles, loading, error, refresh } = useNews();

  return (
    <div className="space-y-8 fade-in">
      <div className="text-center mb-10">
        <div className="flex items-center justify-between mb-3">
          <div className="flex-1">
            <h1 className="text-5xl font-bold mb-2">2028 Election News</h1>
            <p className="text-slate-600 text-lg">Latest updates on top prospects and key developments</p>
          </div>
          <button
            onClick={refresh}
            disabled={loading}
            className="bg-blue-600 text-white px-6 py-3 rounded-xl font-semibold hover:bg-blue-700 transition disabled:opacity-50 disabled:cursor-not-allowed whitespace-nowrap"
          >
            {loading ? 'Loading...' : '↺ Refresh'}
          </button>
        </div>
      </div>

      {loading && articles.length === 0 && (
        <div className="text-center py-12">
          <div className="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mb-4" />
          <p className="font-semibold text-blue-600">Fetching latest election news...</p>
        </div>
      )}

      {error && (
        <div className="bg-amber-50 border-2 border-amber-200 rounded-xl p-6 mb-6">
          <h3 className="font-bold text-amber-900 mb-2">News unavailable</h3>
          <p className="text-sm text-amber-800">{error}</p>
        </div>
      )}

      {!loading && !error && articles.length === 0 && (
        <div className="text-center py-12 bg-slate-50 rounded-2xl">
          <p className="text-slate-600 mb-4">No articles found. Try refreshing.</p>
          <button onClick={refresh} className="bg-blue-600 text-white px-6 py-2 rounded-lg font-semibold hover:bg-blue-700 transition">
            Try Again
          </button>
        </div>
      )}

      <div className="grid gap-6">
        {articles.map((article, i) => (
          <NewsCard key={article.id} article={article} index={i} />
        ))}
      </div>

      {articles.length > 0 && (
        <div className="text-center pt-8 border-t border-slate-200">
          <p className="text-slate-500 text-sm">
            News is cached for 14 days. Click Refresh to fetch the latest.
            <br />
            <span className="text-xs mt-2 block">Powered by NewsAPI · Articles open in new tab</span>
          </p>
        </div>
      )}
    </div>
  );
}
