const { randomUUID } = require('node:crypto');

const LEVELS = { debug: 10, info: 20, warn: 30, error: 40 };

function scrubText(value) {
  let text = String(value);
  const civicKey = process.env.GOOGLE_CIVIC_API_KEY;
  if (civicKey) text = text.replaceAll(civicKey, '[REDACTED_KEY]');
  return text
    .replace(/https?:\/\/[^\s"'<>]+/gi, '[REDACTED_URL]')
    .replace(/\b(?:\d{1,3}\.){3}\d{1,3}\b/g, '[REDACTED_IP]')
    .replace(/\b(?:[a-f0-9]{1,4}:){2,}[a-f0-9:]{1,4}\b/gi, '[REDACTED_IP]')
    .replace(/\b\d{5}(?:-\d{4})?\b/g, '[REDACTED_ZIP]')
    .replace(/\b(lat|latitude|lng|lon|longitude|zip|postcode|postalcode|key|token|ip)\s*[:=]\s*[^\s&,;}]+/gi,
      '$1=[REDACTED]')
    .replace(/[-+]?\d{1,3}(?:\.\d+)?\s*,\s*[-+]?\d{1,3}(?:\.\d+)?/g, '[REDACTED_COORDS]')
    .replace(/[-+]?\d{1,3}\.\d+/g, '[REDACTED_COORD]');
}

function sensitiveKey(key) {
  const parts = key.replace(/([a-z])([A-Z])/g, '$1_$2').toLowerCase().split(/[^a-z]+/);
  const joined = parts.join('');
  return parts.some((part) => [
    'lat', 'latitude', 'lng', 'lon', 'longitude', 'zip', 'postcode', 'postalcode',
    'coord', 'coordinates', 'ip', 'address', 'addr', 'url', 'uri', 'token', 'secret',
    'authorization', 'cookie', 'password', 'credential',
  ].includes(part)) || joined.includes('cachekey') || joined.includes('apikey');
}

function scrub(value, seen = new WeakSet()) {
  if (typeof value === 'string') return scrubText(value);
  if (value instanceof Error) {
    if (seen.has(value)) return '[CIRCULAR]';
    seen.add(value);
    return { name: scrubText(value.name), message: scrubText(value.message),
      ...(value.cause ? { cause: scrub(value.cause, seen) } : {}) };
  }
  if (!value || typeof value !== 'object') return value;
  if (seen.has(value)) return '[CIRCULAR]';
  seen.add(value);
  if (Array.isArray(value)) return value.map((item) => scrub(item, seen));
  return Object.fromEntries(Object.entries(value).map(([key, item]) =>
    [scrubText(key), sensitiveKey(key) ? '[REDACTED]' : scrub(item, seen)]));
}

function log(level, event, fields = {}) {
  if (process.env.NODE_ENV === 'test') return;
  const threshold = LEVELS[process.env.LOG_LEVEL?.toLowerCase()] ?? LEVELS.info;
  if (LEVELS[level] < threshold) return;
  const line = JSON.stringify(scrub({ ...fields, level, event }));
  if (level === 'error') console.error(line);
  else console.log(line); // Vercel marks console.warn as error on non-streaming functions.
}

function requestId(req) {
  return typeof req.headers['x-vercel-id'] === 'string' && req.headers['x-vercel-id']
    ? req.headers['x-vercel-id'] : randomUUID();
}

module.exports = { log, requestId, scrub };
