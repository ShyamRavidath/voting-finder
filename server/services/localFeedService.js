// Portland publishes HTML, not a supported JSON API. Keep parsing isolated and fail closed
// when its structure changes. Only fixed official URLs are fetched; no user query is sent.
const { load } = require('cheerio');
const ORIGIN = 'https://www.portland.gov';
const clean = value => value.replace(/\s+/g, ' ').trim();
function officialURL(value) {
  if (typeof value !== 'string' || !value.trim()) throw new Error('Missing source URL');
  const url = new URL(value, ORIGIN);
  if (url.origin !== ORIGIN || url.username || url.password) throw new Error('Unsupported source');
  return url.href;
}
function parseServices(html) {
  const $ = load(html);
  const view = $('.view-id-services_fullindex.view-display-id-page_sitewide_services');
  const rows = view.find('.morsel');
  if (!view.length || !rows.length) throw new Error('Directory structure changed');
  const items = rows.map((_, el) => {
    const row = $(el), link = row.find('h2 a').first();
    const url = officialURL(link.attr('href'));
    const title = clean(link.text());
    if (!title || !link.attr('href')) throw new Error('Incomplete service');
    return { id: new URL(url).pathname, title, summary: clean(row.find('.field--name-field-summary').text()), url };
  }).get();
  const total = Number(clean(view.find('.view-header').text()).match(/^(\d+) services and resources found$/)?.[1]);
  if (!Number.isInteger(total) || total < 1) throw new Error('Directory count unavailable');
  const pages = view.find('.pagination a').map((_, el) => Number(new URL($(el).attr('href'), ORIGIN).searchParams.get('page') || 0)).get();
  return { items, total, lastPage: Math.max(0, ...pages) };
}
// Convert a wall time in Portland using the timezone database, including daylight saving.
function portlandTime(day, clock) {
  const m = /^(\d{1,2})(?::(\d{2}))?\s*(am|pm)$/i.exec(clock);
  if (!/^\d{4}-\d{2}-\d{2}$/.test(day) || !m || +m[1] < 1 || +m[1] > 12 || +(m[2] || 0) > 59) throw new Error('Invalid meeting time');
  const hour = (+m[1] % 12) + (m[3].toLowerCase() === 'pm' ? 12 : 0);
  const wall = Date.parse(`${day}T${String(hour).padStart(2, '0')}:${m[2] || '00'}:00Z`);
  if (!Number.isFinite(wall) || new Date(wall).toISOString().slice(0, 10) !== day) throw new Error('Invalid meeting date');
  const zone = new Intl.DateTimeFormat('en-US', { timeZone: 'America/Los_Angeles', timeZoneName: 'longOffset' });
  const offset = zone.formatToParts(new Date(wall)).find(p => p.type === 'timeZoneName').value;
  const parts = /GMT([+-])(\d{2}):(\d{2})/.exec(offset);
  if (!parts) throw new Error('Invalid time zone');
  const minutes = (+parts[2] * 60 + +parts[3]) * (parts[1] === '+' ? 1 : -1);
  return new Date(wall - minutes * 60000).toISOString().replace(/\.\d{3}Z$/, 'Z');
}
function parseMeetings(html) {
  const $ = load(html);
  const view = $('.view-id-events_index').filter((_, e) => $(e).hasClass('view-display-id-page_group_events') || $(e).find('.row.position-relative h2').length);
  const rows = view.find('.row.position-relative').filter((_, e) => $(e).find('h2 a').length);
  if (!rows.length) throw new Error('Meeting structure changed');
  return rows.map((_, el) => {
    const row = $(el), link = row.find('h2 a').first();
    const title = clean(link.text()), summary = clean(row.find('p').first().text());
    const dateField = row.find('.field-group').first();
    const day = dateField.find('time').first().attr('datetime');
    const timeText = clean(dateField.children('span').eq(1).text());
    const range = /^(\d{1,2}(?::\d{2})?\s*(?:am|pm))\s*(?:(?:to)?\s*[–-]\s*(\d{1,2}(?::\d{2})?\s*(?:am|pm)))?$/i.exec(timeText);
    const clocks = range ? [range[1], range[2]] : [];
    // Recesses and executive sessions are not public participation opportunities.
    if (/recess|executive session/i.test(title)) return null;
    if (!day || !clocks.length) throw new Error('Meeting has no verified start time');
    const url = officialURL(link.attr('href'));
    return { id: new URL(url).pathname, title, summary, url,
      startsAt: portlandTime(day, clocks[0]),
      endsAt: clocks[1] ? portlandTime(dateField.find('time').last().attr('datetime') || day, clocks[1]) : null,
      status: /cancelled|canceled/i.test(row.text()) ? 'cancelled' : /postponed/i.test(row.text()) ? 'postponed' : 'scheduled',
      online: row.find('.field--name-field-is-online').text().includes('Available online') };
  }).get();
}
function agendaPaths(html) {
  const $ = load(html);
  return [...new Set($('a[href]').map((_, el) => $(el).attr('href')).get()
    .filter(path => /^\/council\/agenda\/\d{4}\/\d{1,2}\/\d{1,2}$/.test(path)))];
}
function parseActions(html, now = new Date()) {
  const $ = load(html);
  const agenda = $('.node--type-council-agenda').first();
  if (!agenda.length || !agenda.find('.relation--type-council-session').length) throw new Error('Agenda structure changed');
  const path = agendaPaths(html)[0];
  if (!path) throw new Error('Dated agenda unavailable');
  const agendaURL = officialURL(path);
  const items = agenda.find('.relation--type-agenda-item').map((_, el) => {
    const row = $(el), link = row.find('.council-document__title a').first();
    const number = clean(row.find('.field--name-field-document-number .field__item').first().text());
    if (!/^\d{4}-\d+$/.test(number)) return null;
    const session = row.closest('.relation--type-council-session');
    const meetingAt = session.find('h2 time').attr('datetime');
    const disposition = row.find('.field--name-field-agenda-item-disposition').clone();
    disposition.find('.field__label').remove();
    const title = clean(link.text());
    if (!title || !Number.isFinite(Date.parse(meetingAt))) throw new Error('Incomplete agenda item');
    const action = clean(disposition.text());
    // Upcoming agenda items are not outcomes. Keep only posted actions from past sessions.
    if (!action || Date.parse(meetingAt) > now.getTime()) return null;
    const video = session.find('.field--name-field-council-session-video iframe').attr('src');
    const videoID = video && /^https:\/\/www.youtube.com\/embed\/([\w-]+)(?:\?|$)/.exec(video)?.[1];
    return { id: number, title, url: officialURL(link.attr('href')), agendaURL,
      meetingAt, action,
      notes: clean(row.find('.field--name-field-disposition-notes').text()),
      videoURL: videoID ? `https://www.youtube.com/watch?v=${videoID}` : null };
  }).get();
  // The same document can appear in more than one session; expose its latest recorded step.
  return [...new Map(items.sort((a, b) => a.meetingAt.localeCompare(b.meetingAt)).map(item => [item.id, item])).values()];
}
async function fetchHTML(path, fetcher = fetch, signal) {
  const response = await fetcher(`${ORIGIN}${path}`, { signal, redirect: 'error', headers: { 'User-Agent': 'Vote4U/1.0 (public civic directory; https://vote4ucyl.vercel.app)' } });
  if (!response.ok || !response.headers.get('content-type')?.includes('text/html')) throw new Error('Official source unavailable');
  const reader = response.body.getReader();
  let size = 0; const chunks = [];
  try {
    while (true) { const { done, value } = await reader.read(); if (done) break; size += value.length;
      if (size > 2_000_000) throw new Error('Source too large'); chunks.push(value); }
  } finally { await reader.cancel(); }
  return Buffer.concat(chunks).toString('utf8');
}
function createLocalFeedService({ fetcher = fetch, now = () => new Date(), fallback = require('../data/local-feed.json') } = {}) {
  const cache = new Map(); const pending = new Map();
  async function section(name, ttl, loader) {
    const cached = cache.get(name);
    if (cached && now() - new Date(cached.fetchedAt) < ttl) return { ...cached, source: 'live' };
    if (pending.has(name)) return pending.get(name);
    const task = (async () => {
      try {
        const items = await loader(AbortSignal.timeout(22000));
        const value = { fetchedAt: now().toISOString().replace(/\.\d{3}Z$/, 'Z'), items };
        cache.set(name, value); return { ...value, source: 'live' };
      } catch {
        // Never log URLs, search terms, or whole errors. Do not re-date a saved copy.
        return { ...(cached || fallback[name]), source: 'saved' };
      } finally { pending.delete(name); }
    })();
    pending.set(name, task); return task;
  }
  return async function getFeed() {
    const [services, meetings, actions] = await Promise.all([
      section('services', 86400000, async signal => {
        const first = parseServices(await fetchHTML('/services', fetcher, signal));
        if (first.lastPage > 39) throw new Error('Directory pagination changed');
        const items = [...first.items];
        for (let start = 1; start <= first.lastPage; start += 4) {
          const pages = Array.from({ length: Math.min(4, first.lastPage - start + 1) }, (_, i) => start + i);
          const batches = await Promise.all(pages.map(async page => parseServices(await fetchHTML(`/services?page=${page}`, fetcher, signal)).items));
          items.push(...batches.flat());
        }
        if (items.length !== first.total || new Set(items.map(i => i.id)).size !== items.length) throw new Error('Directory shifted during pagination');
        return items;
      }),
      section('meetings', 900000, async signal => {
        const pages = await Promise.all(['/council/events', '/council/events/past'].map(async path => parseMeetings(await fetchHTML(path, fetcher, signal))));
        return [...new Map(pages.flat().map(item => [item.id, item])).values()].sort((a, b) => a.startsAt.localeCompare(b.startsAt));
      }),
      section('actions', 900000, async signal => {
        const current = await fetchHTML('/council/agenda', fetcher, signal);
        const recorded = parseActions(current, now());
        if (recorded.length) return recorded;
        // When a new agenda replaces the completed one, follow the city's actual archive links.
        for (const path of agendaPaths(current).slice(1, 4)) {
          const items = parseActions(await fetchHTML(path, fetcher, signal), now());
          if (items.length) return items;
        }
        throw new Error('No recent recorded actions available');
      }),
    ]);
    return { schemaVersion: 1, services, meetings, actions };
  };
}
module.exports = { parseServices, parseMeetings, parseActions, portlandTime, fetchHTML, createLocalFeedService };
