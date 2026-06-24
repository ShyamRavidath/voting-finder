const NEWS_BASE = 'https://newsapi.org/v2/everything';
const CANDIDATES = [
  'Gavin Newsom', 'Gretchen Whitmer', 'Alexandria Ocasio-Cortez', 'AOC',
  'Pete Buttigieg', 'JD Vance', 'Glenn Youngkin', 'Josh Hawley',
  'Ron DeSantis', 'Tim Scott',
];
const DEMOCRATS = ['newsom', 'whitmer', 'ocasio-cortez', 'aoc', 'buttigieg', 'harris', 'booker', 'warren', 'sanders'];
const REPUBLICANS = ['vance', 'youngkin', 'hawley', 'desantis', 'scott', 'trump', 'pence', 'haley'];

function extractCandidate(title, desc) {
  const text = (title + ' ' + desc).toLowerCase();
  for (const c of CANDIDATES) {
    if (text.includes(c.toLowerCase())) return c === 'AOC' ? 'A. Ocasio-Cortez' : c;
  }
  return null;
}

function detectParty(title, desc, candidate) {
  const text = ((candidate || '') + ' ' + title + ' ' + desc).toLowerCase();
  if (DEMOCRATS.some((d) => text.includes(d))) return 'Democrat';
  if (REPUBLICANS.some((r) => text.includes(r))) return 'Republican';
  return null;
}

function getTimeAgo(dateString) {
  if (!dateString) return 'Recently';
  const diffMs = Date.now() - new Date(dateString).getTime();
  const mins = Math.floor(diffMs / 60000);
  const hours = Math.floor(diffMs / 3600000);
  const days = Math.floor(diffMs / 86400000);
  if (mins < 60) return `${mins} minute${mins !== 1 ? 's' : ''} ago`;
  if (hours < 24) return `${hours} hour${hours !== 1 ? 's' : ''} ago`;
  if (days < 7) return `${days} day${days !== 1 ? 's' : ''} ago`;
  return new Date(dateString).toLocaleDateString();
}

async function fetchFromNewsAPI(query, apiKey) {
  const url = `${NEWS_BASE}?q=${encodeURIComponent(query)}&sortBy=publishedAt&language=en&pageSize=10&apiKey=${apiKey}`;
  const res = await fetch(url);
  if (!res.ok) throw new Error(`NewsAPI HTTP ${res.status}`);
  const data = await res.json();
  if (data.status === 'error') throw new Error(data.message || data.code);
  return data.articles || [];
}

async function fetchAndProcessNews(apiKey) {
  const queries = [
    '2028 election OR 2028 presidential race',
    '(Gavin Newsom OR Gretchen Whitmer OR AOC) AND 2028',
  ];

  const allArticles = [];
  for (const q of queries) {
    try {
      const articles = await fetchFromNewsAPI(q, apiKey);
      await new Promise((r) => setTimeout(r, 500));
      articles.forEach((a) => {
        if (!a.title || a.title.includes('[Removed]')) return;
        const candidate = extractCandidate(a.title, a.description || '');
        const party = detectParty(a.title, a.description || '', candidate);
        if (!candidate && !party && !a.title.toLowerCase().includes('2028')) return;

        allArticles.push({
          id: a.url || Math.random().toString(),
          candidate: candidate || '2028 Election',
          title: a.title,
          excerpt: a.description || a.title.substring(0, 150) + '...',
          date: a.publishedAt,
          timeAgo: getTimeAgo(a.publishedAt),
          source: a.source?.name || 'News Source',
          url: a.url,
          category: party ? 'Campaign' : 'General',
          party,
          imageUrl: a.urlToImage,
        });
      });
    } catch (err) {
      console.error(`NewsAPI query failed: ${q}`, err.message);
    }
  }

  const seen = new Set();
  return allArticles
    .sort((a, b) => new Date(b.date) - new Date(a.date))
    .filter((a) => {
      if (seen.has(a.url)) return false;
      seen.add(a.url);
      return true;
    })
    .slice(0, 15);
}

module.exports = { fetchAndProcessNews };
