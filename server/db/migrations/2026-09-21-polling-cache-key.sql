-- Widen the polling cache key so device lookups can be cached too.
--
-- Before: zip_code CHAR(5) UNIQUE, and device lookups bypassed the cache entirely, because their
-- distances are measured from the phone rather than the ZIP centroid and would have poisoned the
-- ZIP rows. After: cache_key holds the ZIP for a ZIP lookup and "@lat,lng" for a device one,
-- so the two cannot collide.
--
-- Existing rows keep working untouched: their keys are already bare ZIPs. This migration is
-- idempotent so it can run on an old table or one already created by schema.sql. Do not deploy
-- the new route against an existing database without running npm run db:migrate first.

DO $migration$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_schema = current_schema() AND table_name = 'polling_cache'
               AND column_name = 'zip_code') THEN
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema = current_schema() AND table_name = 'polling_cache'
                 AND column_name = 'cache_key') THEN
      RAISE EXCEPTION 'polling_cache contains both zip_code and cache_key; manual review required';
    END IF;
    ALTER TABLE polling_cache RENAME COLUMN zip_code TO cache_key;
  END IF;
END;
$migration$;

ALTER TABLE polling_cache ALTER COLUMN cache_key TYPE VARCHAR(32);

CREATE INDEX IF NOT EXISTS polling_cache_expires_at_idx ON polling_cache (expires_at);

-- Remove rows whose serving TTL has passed, including legacy ZIP rows.
DELETE FROM polling_cache WHERE expires_at <= NOW();
