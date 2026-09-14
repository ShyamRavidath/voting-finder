import { useState } from 'react';
import { timeAgo } from '../lib/format';

const PARTY_CHIP = {
  Democrat: 'bg-blue-50 text-blue-700',
  Republican: 'bg-red-50 text-red-700',
};

export default function NewsCard({ article }) {
  const [imageOk, setImageOk] = useState(Boolean(article.imageUrl));
  const when = timeAgo(article.date);

  return (
    <li>
      <article className="group relative flex gap-4 rounded-2xl border border-slate-200 bg-white p-4 transition-colors hover:border-slate-300 sm:p-5">
        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-x-2 gap-y-1 text-xs text-slate-600">
            {article.party && (
              <span className={`rounded-full px-2 py-0.5 font-semibold ${PARTY_CHIP[article.party]}`}>{article.party}</span>
            )}
            <span className="font-medium text-slate-700">{article.source}</span>
            {when && (
              <>
                <span aria-hidden="true">·</span>
                <time dateTime={article.date}>{when}</time>
              </>
            )}
          </div>
          <h3 className="mt-1.5 text-[17px] leading-snug font-semibold text-slate-900 group-hover:text-blue-700 sm:text-lg">
            <a href={article.url} target="_blank" rel="noopener noreferrer" className="after:absolute after:inset-0 after:rounded-2xl">
              {article.title}
              <span className="sr-only"> (opens in a new tab)</span>
            </a>
          </h3>
          {article.excerpt && <p className="mt-1.5 line-clamp-2 text-[15px] text-slate-600 sm:line-clamp-3">{article.excerpt}</p>}
          {article.candidate && article.candidate !== '2028 Election' && (
            <p className="mt-2 text-xs font-semibold text-slate-700">{article.candidate}</p>
          )}
        </div>
        {imageOk && (
          <img
            src={article.imageUrl}
            alt=""
            loading="lazy"
            decoding="async"
            referrerPolicy="no-referrer"
            onError={() => setImageOk(false)}
            className="size-20 shrink-0 rounded-xl bg-slate-100 object-cover sm:h-24 sm:w-32"
          />
        )}
      </article>
    </li>
  );
}
