const { test, before, after, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const express = require('express');
const { fetchAndProcessNews, newsQuery, nextFederalElectionYear } = require('../services/newsService');

const rows = new Map();
const queryKeys = [];
require.cache[require.resolve('../db/client')] = {
  id: require.resolve('../db/client'), loaded: true,
  exports: { query: async (sql, params) => {
    queryKeys.push(params[0]);
    if (sql.trim().startsWith('SELECT')) return { rows: rows.has(params[0]) ? [rows.get(params[0])] : [] };
    rows.set(params[0], { articles: JSON.parse(params[1]) });
    return { rows: [] };
  } },
};
const router = require('../routes/news');
const app = express();
app.use('/api/news', router);
const realFetch = global.fetch;
let server;
let base;
let feed;
let calls;

const item = ({ title = 'Midterm election updates', url = 'https://example.com/story', date = 'Tue, 03 Nov 2026 12:00:00 GMT', source = 'Wire', publisher = 'https://example.com' } = {}) =>
  `<item><title>${title}</title><link>${url}</link><pubDate>${date}</pubDate><source url="${publisher}">${source}</source></item>`;
const rss = (...items) => `<rss><channel>${items.join('')}</channel></rss>`;

before(async () => {
  server = http.createServer(app);
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  base = `http://127.0.0.1:${server.address().port}`;
  global.fetch = async (url, options) => {
    if (String(url).startsWith(base)) return realFetch(url, options);
    assert.ok(String(url).startsWith('https://news.google.com/rss/search?'));
    calls++;
    return new Response(feed);
  };
});
after(() => { server.close(); global.fetch = realFetch; });
beforeEach(() => { rows.clear(); queryKeys.length = 0; calls = 0; router.clearCache(); feed = rss(item()); });

test('invalid or absent dates skip individual items while valid news still loads', async () => {
  feed = rss(item({ date: 'bad date', url: 'https://example.com/bad' }), item({ date: '', url: 'https://example.com/missing' }), item());
  const response = await fetch(`${base}/api/news`);
  assert.equal(response.status, 200);
  const { articles } = await response.json();
  assert.equal(articles.length, 1);
  assert.equal(articles[0].date, '2026-11-03T12:00:00.000Z');
});

test('only absolute HTTP(S) article URLs survive', async () => {
  const links = ['javascript:alert(1)', 'data:text/html,test', 'file:///tmp/test', '//example.com/path', '/relative', 'not a URL', 'https://example.com/secure', 'http://example.com/plain'];
  feed = rss(...links.map((url, i) => item({ url, title: `Midterm election story ${i}` })));
  assert.deepEqual((await fetchAndProcessNews()).articles.map((a) => a.url), links.slice(-2));
});

test('explicit excluded publishers are filtered by source name, publisher host, and direct article host', async () => {
  const publishers = [
    ['Democracy Forward', 'https://democracyforward.org'], ['Human Rights Campaign', 'https://hrc.org'],
    ['DLCC', 'https://dlcc.org'], ['RSLC', 'https://rslc.gop'],
    ['DNC', 'https://democrats.org'], ['RNC', 'https://gop.com'],
    ['DCCC', 'https://dccc.org'], ['NRCC', 'https://nrcc.org'],
    ['DSCC', 'https://dscc.org'], ['NRSC', 'https://nrsc.org'],
    ['Biztoc', 'https://biztoc.com'], ['Free Republic', 'https://freerepublic.com'],
  ];
  const excluded = publishers.flatMap(([source, publisher], i) => [
    item({ source: ` ${source.toUpperCase()} `, publisher: '', url: `https://news.google.com/rss/articles/name${i}`, title: `Midterm election name ${i}` }),
    item({ source: 'Syndicated', publisher, url: `https://news.google.com/rss/articles/host${i}`, title: `Midterm election host ${i}` }),
    item({ source: 'Syndicated', publisher: '', url: `${publisher}/story`, title: `Midterm election direct ${i}` }),
  ]);
  feed = rss(...excluded, item({ source: 'Wire reporting on DLCC', url: 'https://example.com/dlcc.org' }));
  assert.deepEqual((await fetchAndProcessNews()).articles.map((a) => a.url), ['https://example.com/dlcc.org']);
});

test('drops the observed TCS VVP questionnaire item without dropping election survey reporting', async () => {
  feed = rss(item({ title: 'TCS VVP 2026 Midterm Election Survey Q23', url: 'https://example.com/question' }), item({ title: 'Midterm election survey shows voters preparing to vote' }));
  assert.deepEqual((await fetchAndProcessNews()).articles.map((a) => a.url), ['https://example.com/story']);
});

test('query retains Election Day through US time zones and changes at the UTC−12 boundary', () => {
  for (const iso of ['2026-11-04T00:00:00Z', '2026-11-04T08:00:00Z', '2026-11-04T10:00:00Z', '2026-11-04T11:59:59Z']) {
    assert.equal(nextFederalElectionYear(new Date(iso)), 2026, iso);
    assert.match(newsQuery(new Date(iso)), /2026 midterm elections/);
  }
  assert.equal(nextFederalElectionYear(new Date('2026-11-04T12:00:00Z')), 2028);
  assert.equal(nextFederalElectionYear(new Date('2028-11-08T11:59:59Z')), 2028);
  assert.equal(nextFederalElectionYear(new Date('2028-11-08T12:00:00Z')), 2030);
});

test('old cache rows cannot bypass the current source and URL filters', async () => {
  rows.set('election-2028', { articles: [{ title: 'Old unfiltered article' }] });
  const response = await fetch(`${base}/api/news`);
  assert.equal(response.status, 200);
  assert.equal((await response.json()).articles[0].url, 'https://example.com/story');
  assert.equal(calls, 1);
  assert.ok(queryKeys.every((key) => key === `us-election-v2-${nextFederalElectionYear()}`));
  router.clearCache();
  const cached = await (await fetch(`${base}/api/news`)).json();
  assert.equal(cached.cached, true);
  assert.equal(calls, 1, 'current validated DB cache is reusable');
});

test('Election Day rollover also invalidates the in-memory news cache', async (t) => {
  t.mock.timers.enable({ apis: ['Date'], now: new Date('2026-11-04T11:59:59Z') });
  await fetch(`${base}/api/news`);
  assert.equal(calls, 1);
  t.mock.timers.tick(1000);
  await fetch(`${base}/api/news`);
  assert.equal(calls, 2);
  assert.ok(queryKeys.includes('us-election-v2-2026'));
  assert.ok(queryKeys.includes('us-election-v2-2028'));
});


test('news fetch errors log no upstream URL or free-text error details', async (t) => {
  const logs = [];
  t.mock.method(console, 'error', (...args) => logs.push(args));
  const fetchBeforeTest = global.fetch;
  t.mock.method(global, 'fetch', async (url, options) => {
    if (String(url).startsWith(base)) return fetchBeforeTest(url, options);
    throw new Error('sensitive upstream URL and query');
  });
  const response = await fetch(`${base}/api/news`);
  assert.equal(response.status, 502);
  assert.deepEqual(logs, [['News lookup failed']]);
});
