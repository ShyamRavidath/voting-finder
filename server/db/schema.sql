CREATE TABLE IF NOT EXISTS news_cache (
  id SERIAL PRIMARY KEY,
  query_key TEXT NOT NULL UNIQUE,
  articles JSONB NOT NULL,
  cached_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL
);

-- cache_key is the ZIP for a ZIP lookup, or "@lat,lng" (3dp) for a device lookup, because the
-- cached distances are measured from that origin. See server/lib/pollingCacheKey.js.
CREATE TABLE IF NOT EXISTS polling_cache (
  id SERIAL PRIMARY KEY,
  cache_key VARCHAR(32) NOT NULL UNIQUE,
  locations JSONB NOT NULL,
  data_source VARCHAR(20) NOT NULL,
  cached_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS polling_cache_expires_at_idx ON polling_cache (expires_at);
