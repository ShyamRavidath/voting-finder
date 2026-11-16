const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const catalog = require('../data/local-civic.json');

test('native offline catalog matches the update feed byte for byte', () => {
  assert.equal(fs.readFileSync(path.join(__dirname, '../data/local-civic.json'), 'utf8'),
    fs.readFileSync(path.join(__dirname, '../../ios/Vote4U/Resources/local-civic.json'), 'utf8'));
});

test('curated catalog has source evidence, bounded review dates, and linked topics', () => {
  assert.equal(catalog.schemaVersion, 1);
  const topics = new Set(catalog.topics.map(t => t.id));
  assert.equal(topics.size, catalog.topics.length);
  for (const record of [...catalog.topics, ...catalog.decisions]) {
    assert.ok(record.sources.length > 0);
    for (const source of record.sources) {
      const url = new URL(source.url);
      assert.equal(url.protocol, 'https:');
      assert.ok(['www.portland.gov', 'trimet.org', 'go.trimet.org'].includes(url.hostname));
    }
    assert.ok(Date.parse(record.reviewBy) > Date.parse(record.checkedAt));
  }
  for (const item of catalog.decisions) {
    assert.ok(topics.has(item.topicID));
    assert.ok(Date.parse(item.reviewBy) - Date.parse(item.checkedAt) <= 7 * 86400000);
    assert.ok(!item.commentDeadline || Date.parse(item.commentDeadline) <= Date.parse(item.meetingAt));
    assert.ok(item.status !== 'decided' || item.outcome?.source);
  }
});
