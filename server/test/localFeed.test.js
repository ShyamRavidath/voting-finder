const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { parseServices, parseMeetings, parseActions, portlandTime, fetchHTML, createLocalFeedService } = require('../services/localFeedService');
const fixture = name => fs.readFileSync(path.join(__dirname, 'fixtures/local-feed', name + '.html'), 'utf8');
const fallback = require('../data/local-feed.json');
const html = text => new Response(text, { headers: { 'content-type': 'text/html' } });

test('real city directory exposes 25 distinct entries and all 23 pages', () => {
  const result = parseServices(fixture('services'));
  assert.equal(result.items.length, 25);
  assert.equal(result.lastPage, 22);
  assert.equal(new Set(result.items.map(i => i.id)).size, 25);
  assert.ok(result.items.some(i => /Contact an elected official/.test(i.title)));
  assert.throws(() => parseServices('<html>temporarily unavailable</html>'));
  assert.throws(() => parseServices(fixture('services').replace('href="/police/alarm-payment-submission', 'href="https://evil.test/')));
});

test('real meeting pages exclude recess and private sessions, preserve cancellations and Pacific time', () => {
  const meetings = parseMeetings(fixture('events'));
  const publicSafety = meetings.find(m => m.title.includes('Community and Public Safety'));
  assert.equal(publicSafety.startsAt, '2026-12-01T17:30:00Z');
  assert.equal(publicSafety.endsAt, '2026-12-01T20:30:00Z');
  assert.ok(meetings.every(m => !/recess|executive session/i.test(m.title)));
  const cancelled = parseMeetings(fixture('events').replace('Community and Public Safety Committee Meeting', 'Community and Public Safety Committee Meeting (Cancelled)'));
  assert.equal(cancelled.find(m => m.id === publicSafety.id).status, 'cancelled');
  assert.equal(portlandTime('2026-07-01', '9:30 am'), '2026-07-01T16:30:00Z');
  assert.throws(() => portlandTime('2026-12-01', '24:99 pm'));
  assert.throws(() => portlandTime('2026-02-30', '9 am'));
  assert.throws(() => parseMeetings(fixture('events').replaceAll('9:30 am', 'time unavailable')));
});

test('recorded action is not silently promoted to approval and has dated agenda and recording', () => {
  const items = parseActions(fixture('agenda'), new Date('2026-11-24T00:00:00Z'));
  const street = items.find(i => i.id === '2026-401');
  assert.equal(street.action, 'Passed to second reading');
  assert.equal(street.meetingAt, '2026-11-19T02:00:00Z');
  assert.match(street.notes, /December 2, 2026/);
  assert.equal(street.agendaURL, 'https://www.portland.gov/council/agenda/2026/11/18');
  assert.equal(street.videoURL, 'https://www.youtube.com/watch?v=fEGn7l2iGrA');
  assert.throws(() => parseActions('<html>maintenance</html>'));
});

test('offline native snapshot matches server and includes actual drug service', () => {
  const native = fs.readFileSync(path.join(__dirname, '../../ios/Vote4U/Resources/local-feed.json'), 'utf8');
  assert.equal(native, fs.readFileSync(path.join(__dirname, '../data/local-feed.json'), 'utf8'));
  assert.equal(fallback.services.items.length, 567);
  assert.ok(fallback.services.items.some(i => i.url === 'https://www.portland.gov/police/drug-complaint'));
});

test('fetcher rejects oversized HTML, non-HTML and unsuccessful upstream responses', async () => {
  await assert.rejects(fetchHTML('/services', async () => new Response('{}')));
  await assert.rejects(fetchHTML('/services', async () => new Response('no', { status: 503 })));
  await assert.rejects(fetchHTML('/services', async () => html('x'.repeat(2_000_001))));
});

test('failed upstream keeps original evidence date and uses last good feed', async () => {
  let failing = false, calls = 0;
  let clock = new Date('2026-11-25T00:00:00Z');
  const fetcher = async url => {
    calls++;
    if (failing) throw new Error('Offline');
    if (url.endsWith('/services')) return html(fixture('services').replace('567 services and resources found', '25 services and resources found').replaceAll('class="pagination', 'class="disabled-pagination'));
    if (url.endsWith('/events/past')) return html(fixture('past'));
    if (url.endsWith('/events')) return html(fixture('events'));
    if (url.endsWith('/agenda')) return html(fixture('agenda'));
    throw new Error('Unexpected page');
  };
  const get = createLocalFeedService({ fetcher, now: () => clock, fallback });
  const [first, concurrent] = await Promise.all([get(), get()]);
  assert.equal(first.meetings.source, 'live');
  assert.deepEqual(first, concurrent);
  const count = calls; await get(); assert.equal(calls, count, 'warm cache avoids another scrape');
  failing = true; clock = new Date('2026-11-27T00:00:00Z');
  const offline = await get();
  assert.equal(offline.meetings.source, 'saved');
  assert.equal(offline.meetings.fetchedAt, first.meetings.fetchedAt);
  assert.deepEqual(offline.meetings.items, first.meetings.items);
});

test('cold source outage uses explicitly dated bundled snapshot', async () => {
  const get = createLocalFeedService({ fetcher: async () => { throw new Error('Offline'); }, fallback });
  const result = await get();
  for (const key of ['services', 'meetings', 'actions']) {
    assert.equal(result[key].source, 'saved');
    assert.equal(result[key].fetchedAt, fallback[key].fetchedAt);
  }
});


test('new unpublished agenda preserves the latest recorded actions through actual archive links', async () => {
  const old = fixture('agenda');
  const future = old.replaceAll('2026-11-19T', '2026-12-19T').replaceAll('2026-11-18T', '2026-12-18T')
    .replaceAll('/council/agenda/2026/11/18', '/council/agenda/2026/12/18')
    + '<a href="/council/agenda/2026/11/18">Previous agenda</a>';
  const clock = new Date('2026-11-24T00:00:00Z');
  assert.deepEqual(parseActions(future, clock), []);
  assert.throws(() => parseActions(old.replaceAll('/council/agenda/2026/11/18', '/council/agenda'), clock));
  const get = createLocalFeedService({ now: () => clock, fallback, fetcher: async url => {
    if (url.endsWith('/council/agenda')) return html(future);
    if (url.endsWith('/council/agenda/2026/11/18')) return html(old);
    throw new Error('Other collection unavailable');
  }});
  const result = await get();
  assert.equal(result.actions.source, 'live');
  assert.equal(result.actions.items.length, 6);
  assert.equal(result.actions.items.find(i => i.id === '2026-401').action, 'Passed to second reading');
});
