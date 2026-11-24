#!/usr/bin/env node
// Run explicitly to renew the offline snapshot from public Portland sources.
const fs = require('node:fs/promises');
const path = require('node:path');
const { createLocalFeedService } = require('../server/services/localFeedService');
(async () => {
  const feed = await createLocalFeedService()();
  for (const key of ['services', 'meetings', 'actions']) {
    if (feed[key].source !== 'live') throw new Error(`Could not refresh ${key}; snapshot left unchanged`);
  }
  const text = JSON.stringify(feed, null, 2) + '\n';
  for (const target of ['server/data/local-feed.json', 'ios/Vote4U/Resources/local-feed.json']) {
    const file = path.join(__dirname, '..', target);
    await fs.writeFile(file + '.tmp', text);
    await fs.rename(file + '.tmp', file);
  }
  console.log(`Updated ${feed.services.items.length} services, ${feed.meetings.items.length} meetings, ${feed.actions.items.length} council actions.`);
})().catch(error => { console.error(error.message); process.exitCode = 1; });
