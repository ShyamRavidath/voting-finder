const { fetchWithTimeout } = require('../lib/fetchWithTimeout');

const NEWS_BASE = 'https://newsapi.org/v2/everything';
const GOOGLE_NEWS_RSS = 'https://news.google.com/rss/search';
// Watchlist of potential 2028 candidates. An article's party badge comes only from a matched
// candidate, so a story that merely mentions a sitting official isn't labeled partisan.
const CANDIDATES = [
  { name: 'Gavin Newsom', match: ['gavin newsom', 'newsom'], party: 'Democrat' },
  { name: 'Gretchen Whitmer', match: ['gretchen whitmer', 'whitmer'], party: 'Democrat' },
  { name: 'A. Ocasio-Cortez', match: ['ocasio-cortez', 'aoc'], party: 'Democrat' },
  { name: 'Pete Buttigieg', match: ['buttigieg'], party: 'Democrat' },
  { name: 'Kamala Harris', match: ['kamala harris'], party: 'Democrat' },
  { name: 'Josh Shapiro', match: ['josh shapiro'], party: 'Democrat' },
  { name: 'Wes Moore', match: ['wes moore'], party: 'Democrat' },
  { name: 'Andy Beshear', match: ['beshear'], party: 'Democrat' },
  { name: 'JB Pritzker', match: ['pritzker'], party: 'Democrat' },
  { name: 'JD Vance', match: ['jd vance', 'j.d. vance', 'vance'], party: 'Republican' },
  { name: 'Marco Rubio', match: ['marco rubio', 'rubio'], party: 'Republican' },
  { name: 'Ron DeSantis', match: ['desantis'], party: 'Republican' },
  { name: 'Glenn Youngkin', match: ['youngkin'], party: 'Republican' },
  { name: 'Josh Hawley', match: ['josh hawley', 'hawley'], party: 'Republican' },
  { name: 'Nikki Haley', match: ['nikki haley'], party: 'Republican' },
  { name: 'Tim Scott', match: ['tim scott'], party: 'Republican' },
];
const MAX_ARTICLES = 15;
const EXCLUDED_DOMAINS = 'biztoc.com,freerepublic.com';

function findCandidate(title, desc) {
  const text = `${title} ${desc}`.toLowerCase();
  return CANDIDATES.find((c) => c.match.some((m) => new RegExp(`(^|[^a-z])${m.replace(/\./g, '\\.')}([^a-z]|$)`).test(text))) || null;
}

function detectParty(title, desc) {
  return findCandidate(title, desc)?.party || null;
}

function toArticle({ title, description, url, publishedAt, source, imageUrl }) {
  const match = findCandidate(title, description || '');
  const candidate = match?.name || null;
  const party = match?.party || null;
  if (!candidate && !party && !title.toLowerCase().includes('2028')) return null;
  return {
    id: url,
    candidate: candidate || '2028 Election',
    title,
    excerpt: description || null,
    date: publishedAt,
    source: source || 'News Source',
    url,
    category: party ? 'Campaign' : 'General',
    party,
    imageUrl: imageUrl || null,
  };
}

function dedupeAndSort(articles) {
  const seen = new Set();
  return articles
    .filter(Boolean)
    .sort((a, b) => new Date(b.date) - new Date(a.date))
    .filter((a) => {
      const key = a.title.toLowerCase();
      if (!a.url || seen.has(a.url) || seen.has(key)) return false;
      seen.add(a.url);
      seen.add(key);
      return true;
    })
    .slice(0, MAX_ARTICLES);
}

async function fetchFromNewsAPI(query, apiKey) {
  const url = `${NEWS_BASE}?q=${encodeURIComponent(query)}&sortBy=publishedAt&language=en&pageSize=20&excludeDomains=${EXCLUDED_DOMAINS}`;
  const res = await fetchWithTimeout(url, { headers: { 'X-Api-Key': apiKey, 'User-Agent': 'Vote4U/1.0' } });
  const data = await res.json().catch(() => ({}));
  if (!res.ok || data.status === 'error') throw new Error(`NewsAPI ${res.status}: ${data.message || data.code || 'error'}`);
  return data.articles || [];
}

async function fetchNewsAPIArticles(apiKey) {
  const queries = [
    '"2028 election" OR "2028 presidential"',
    '(Newsom OR Whitmer OR "Ocasio-Cortez" OR Buttigieg OR Shapiro OR Vance OR Rubio OR DeSantis) AND 2028',
  ];
  const results = await Promise.allSettled(queries.map((q) => fetchFromNewsAPI(q, apiKey)));
  const raw = [];
  results.forEach((r, i) => {
    if (r.status === 'fulfilled') raw.push(...r.value);
    else console.error(`NewsAPI query failed: ${queries[i]}:`, r.reason.message);
  });
  return raw
    .filter((a) => a.title && a.url && !a.title.includes('[Removed]'))
    .map((a) =>
      toArticle({
        title: a.title,
        description: a.description,
        url: a.url,
        publishedAt: a.publishedAt,
        source: a.source?.name,
        imageUrl: a.urlToImage,
      })
    );
}

const ENTITIES = { amp: '&', lt: '<', gt: '>', quot: '"', apos: "'", nbsp: ' ' };
function decodeEntities(str) {
  return str
    .replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, '$1')
    .replace(/&#x([0-9a-f]+);/gi, (_, h) => String.fromCodePoint(parseInt(h, 16)))
    .replace(/&#(\d+);/g, (_, d) => String.fromCodePoint(Number(d)))
    .replace(/&([a-z]+);/gi, (m, n) => ENTITIES[n.toLowerCase()] ?? m);
}

function tag(xml, name) {
  const m = xml.match(new RegExp(`<${name}[^>]*>([\\s\\S]*?)</${name}>`));
  return m ? decodeEntities(m[1]).trim() : '';
}

// Keyless fallback: Google News RSS search. Used when NewsAPI is unconfigured, over quota, or down.
async function fetchGoogleNewsArticles() {
  const q = encodeURIComponent('"2028 election" OR "2028 presidential race" when:14d');
  const res = await fetchWithTimeout(`${GOOGLE_NEWS_RSS}?q=${q}&hl=en-US&gl=US&ceid=US:en`, {
    headers: { 'User-Agent': 'Vote4U/1.0' },
  });
  if (!res.ok) throw new Error(`Google News RSS HTTP ${res.status}`);
  const xml = await res.text();
  const items = xml.match(/<item>[\s\S]*?<\/item>/g) || [];
  return items.map((item) => {
    const source = tag(item, 'source');
    let title = tag(item, 'title');
    if (source && title.endsWith(` - ${source}`)) title = title.slice(0, -(source.length + 3));
    return toArticle({
      title,
      description: null,
      url: tag(item, 'link'),
      publishedAt: new Date(tag(item, 'pubDate')).toISOString(),
      source,
    });
  });
}

async function fetchAndProcessNews(apiKey) {
  if (apiKey) {
    try {
      const articles = dedupeAndSort(await fetchNewsAPIArticles(apiKey));
      if (articles.length > 0) return { articles, provider: 'newsapi' };
    } catch (err) {
      console.error('NewsAPI failed, falling back to Google News:', err.message);
    }
  }
  const articles = dedupeAndSort(await fetchGoogleNewsArticles());
  return { articles, provider: 'google-news' };
}

module.exports = { fetchAndProcessNews, decodeEntities, detectParty };
