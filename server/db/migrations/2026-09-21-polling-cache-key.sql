-- Widen the polling cache key so device lookups can be cached too.
--
-- Before: zip_code CHAR(5) UNIQUE, and device lookups bypassed the cache entirely, because their
-- distances are measured from the phone rather than the ZIP centroid and would have poisoned the
-- ZIP rows. After: cache_key holds the ZIP for a ZIP lookup and "ZIP@lat,lng" for a device one,
-- so the two cannot collide.
--
-- Existing rows keep working untouched: their keys are already bare ZIPs, which is exactly what
-- the new scheme uses for ZIP lookups. Safe to run on a live database; safe to skip entirely if
-- DATABASE_URL was never configured, since schema.sql now creates the table in its final shape.

ALTER TABLE polling_cache RENAME COLUMN zip_code TO cache_key;
ALTER TABLE polling_cache ALTER COLUMN cache_key TYPE VARCHAR(32);

CREATE INDEX IF NOT EXISTS polling_cache_expires_at_idx ON polling_cache (expires_at);
