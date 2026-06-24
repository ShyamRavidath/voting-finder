export default function NewsCard({ article, index }) {
  const partyClass =
    article.party === 'Democrat'
      ? 'bg-blue-100 text-blue-700'
      : article.party === 'Republican'
      ? 'bg-red-100 text-red-700'
      : 'bg-slate-100 text-slate-700';

  return (
    <div
      className="bg-white p-8 rounded-2xl border border-slate-200 shadow-sm hover:shadow-md transition-all news-card fade-in"
      style={{ animationDelay: `${index * 0.1}s` }}
    >
      <div className="flex items-start gap-6">
        <div className="flex-1">
          <div className="flex items-center gap-3 mb-3 flex-wrap">
            {article.party && (
              <span className={`text-xs font-bold uppercase px-3 py-1 rounded-full ${partyClass}`}>
                {article.party}
              </span>
            )}
            <span className="text-xs font-medium text-slate-500 uppercase tracking-wide">{article.category}</span>
            <span className="text-xs text-slate-400">•</span>
            <span className="text-xs text-slate-400">{article.timeAgo || article.date}</span>
          </div>
          <h3 className={`text-2xl font-bold mb-2 transition ${article.url ? 'text-slate-900 hover:text-blue-600' : 'text-slate-900'}`}>
            {article.url ? (
              <a href={article.url} target="_blank" rel="noopener noreferrer" className="hover:underline">
                {article.title}
              </a>
            ) : (
              article.title
            )}
          </h3>
          <p className="text-slate-600 leading-relaxed mb-4">{article.excerpt}</p>
          <div className="flex items-center gap-4 text-sm">
            <span className="font-semibold text-slate-900">{article.candidate}</span>
            <span className="text-slate-400">•</span>
            <span className="text-slate-500">{article.source}</span>
            {article.url && (
              <>
                <span className="text-slate-400">•</span>
                <a href={article.url} target="_blank" rel="noopener noreferrer" className="text-blue-600 hover:text-blue-700 font-semibold">
                  Read more →
                </a>
              </>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
