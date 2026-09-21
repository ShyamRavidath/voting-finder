const { fetchWithTimeout } = require('../lib/fetchWithTimeout');

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
const EXCLUDED_DOMAINS = ['biztoc.com', 'freerepublic.com'];

function findCandidate(title, desc) {
  const text = `${title} ${desc}`.toLowerCase();
  return CANDIDATES.find((c) => c.match.some((m) => new RegExp(`(^|[^a-z])${m.replace(/\./g, '\\.')}([^a-z]|$)`).test(text))) || null;
}

function detectParty(title, desc) {
  return findCandidate(title, desc)?.party || null;
}

// A defensive relevance gate. The RSS query already constrains the corpus, so this only has to
// catch stray syndication — but it used to require the literal string "2028" in the title, which
// silently discarded every midterm story the widened query now returns ("Early voting begins in
// U.S. midterm elections" has no year in its headline at all). Match the vocabulary instead.
// Word-bounded on purpose: a bare substring test matches "pollution" for "poll".
const ELECTION_TERMS =
  /\b(elections?|midterms?|primar(?:y|ies)|ballots?|voters?|voting|caucus(?:es)?|campaigns?|polls?|polling)\b/;

function isElectionRelevant(title, from = new Date()) {
  const text = String(title || '').toLowerCase();
  const year = nextFederalElectionYear(from);
  if (text.includes(String(year)) || text.includes(String(year + 2))) return true;
  return ELECTION_TERMS.test(text);
}

function toArticle({ title, description, url, publishedAt, source, imageUrl }) {
  const match = findCandidate(title, description || '');
  const candidate = match?.name || null;
  const party = match?.party || null;
  if (!candidate && !party && !isElectionRelevant(title)) return null;
  return {
    id: url,
    // Null when no watchlist candidate is named. This used to be the placeholder string
    // "2028 Election", which the web client then had to compare against by hand to hide it.
    candidate,
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
    .filter((a) => !EXCLUDED_DOMAINS.some((d) => a.url.includes(d)))
    .slice(0, MAX_ARTICLES);
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

// The next federal election year. Federal elections fall on the Tuesday after the first Monday
// in November of even years — the same arithmetic as `nextFederalElection` in
// client/src/lib/format.js and its Swift port, kept in step deliberately.
function nextFederalElectionYear(from = new Date()) {
  const today = new Date(from.getFullYear(), from.getMonth(), from.getDate());
  for (let year = today.getFullYear(); ; year++) {
    if (year % 2 !== 0) continue;
    const nov1 = new Date(year, 10, 1);
    const firstMonday = 1 + ((8 - nov1.getDay()) % 7);
    if (new Date(year, 10, firstMonday + 1) >= today) return year;
  }
}

// The search terms, derived from the calendar rather than hardcoded so the feed doesn't go stale
// the morning after an election.
//
// The old query was `"2028 election" OR "2028 presidential race"`, which is not US-scoped in any
// meaningful way: `hl`/`gl`/`ceid` bias the *edition*, not the subject, so Turkey's April 2028
// election and the Philippines' 2028 race led the tab. Naming the election explicitly fixes that
// and, as a bonus, surfaces the early-voting and mail-in-ballot coverage a voting app should
// carry — which is also the 4.2.2 argument that this is an election tool, not an aggregator.
function newsQuery(from = new Date()) {
  const year = nextFederalElectionYear(from);
  const terms =
    year % 4 === 0
      ? [
          `"${year} presidential election"`,
          `"${year} presidential race"`,
          `"${year} general election"`,
          `"${year} Democratic primary"`,
          `"${year} Republican primary"`,
        ]
      : [
          `"${year} midterm elections"`,
          `"${year} midterms"`,
          // The presidential race two years out is the other thing voters follow.
          `"${year + 2} presidential race"`,
          `"${year + 2} presidential election"`,
          `"${year + 2} Democratic primary"`,
          `"${year + 2} Republican primary"`,
        ];
  return `(${terms.join(' OR ')}) when:14d`;
}

// Google News RSS search — the only news source, and keyless.
//
// NewsAPI was removed on 2026-09-20: its free plan is development-only under its own terms, which
// makes shipping an app on it an App Store guideline 5.2.2 problem, and production had always run
// on this path anyway. Don't reintroduce it without a paid plan that permits production use.
async function fetchGoogleNewsArticles() {
  const q = encodeURIComponent(newsQuery());
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

async function fetchAndProcessNews() {
  const articles = dedupeAndSort(await fetchGoogleNewsArticles());
  return { articles, provider: 'google-news' };
}

module.exports = {
  fetchAndProcessNews,
  decodeEntities,
  detectParty,
  newsQuery,
  nextFederalElectionYear,
  isElectionRelevant,
};
