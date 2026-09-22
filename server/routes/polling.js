const express = require('express');
const router = express.Router();
const pool = require('../db/client');
const { fetchOfficialLocations } = require('../services/civicService');
const { pollingCacheKey } = require('../lib/pollingCacheKey');
const {
  zipToCoords,
  coordsToZip,
  findNearbyPollingVenues,
  distanceKm,
  roundCoord,
  ZipNotFoundError,
  OutsideUsError,
} = require('../services/geocodeService');

// Cached per ZIP at Vercel's CDN; keeps Nominatim/Civic traffic well inside their fair-use limits.
const CACHE_FOUND = 'public, max-age=300, s-maxage=86400, stale-while-revalidate=604800';
const CACHE_NONE = 'public, max-age=0, s-maxage=3600';

// Accepts either ?zip=XXXXX or ?lat=&lng= (the iOS app's "use my location"). Coordinates are
// reverse-geocoded to a ZIP and then run through the identical pipeline, so both entry points
// share the same cache, the same data tiers, and the same "never invent a location" guarantee.
router.get('/', async (req, res) => {
  const { zip, lat: latParam, lng: lngParam } = req.query;
  const hasCoords = latParam !== undefined || lngParam !== undefined;

  let zipCode;
  let device = null;

  if (hasCoords) {
    const lat = Number(latParam);
    const lng = Number(lngParam);
    const valid =
      latParam !== '' && lngParam !== '' &&
      Number.isFinite(lat) && Number.isFinite(lng) &&
      Math.abs(lat) <= 90 && Math.abs(lng) <= 180;
    if (!valid) {
      return res.status(400).json({ error: 'Please provide a valid latitude and longitude.' });
    }

    device = { lat: roundCoord(lat), lng: roundCoord(lng) };
  } else {
    if (typeof zip !== 'string' || !/^\d{5}$/.test(zip)) {
      return res.status(400).json({ error: 'Please enter a valid 5-digit US ZIP code.' });
    }
    zipCode = zip;
  }

  // Read the cache before anything talks to an upstream. For a device lookup that ordering is
  // the whole benefit: the key needs no ZIP, so a hit costs zero Nominatim requests instead of
  // paying for a reverse geocode it is about to throw away.
  const cacheKey = pollingCacheKey(zipCode, device);
  try {
    const cached = await pool.query(
      'SELECT locations, data_source FROM polling_cache WHERE cache_key = $1 AND expires_at > NOW()',
      [cacheKey]
    );
    if (cached.rows.length > 0) {
      const stored = cached.rows[0].locations;
      // Older cache rows stored a bare array of locations
      const payload = Array.isArray(stored) ? { locations: stored, place: null, election: null } : stored;
      // A device row carries no ZIP in its key, so recover it from the payload.
      const cachedZip = zipCode || payload.place?.zip;
      res.set('Cache-Control', CACHE_FOUND);
      return res.json({ ...payload, zip: cachedZip, device, dataSource: cached.rows[0].data_source, cached: true });
    }
  } catch (_) {
    // DB unavailable — continue to live lookup
  }

  if (device) {
    try {
      zipCode = await coordsToZip(device.lat, device.lng);
    } catch (err) {
      if (err instanceof OutsideUsError) {
        res.set('Cache-Control', 'public, s-maxage=86400');
        return res.status(404).json({ error: 'Vote4U only covers United States elections.' });
      }
      if (err instanceof ZipNotFoundError) {
        res.set('Cache-Control', 'public, s-maxage=3600');
        return res.status(404).json({
          error: "We couldn't find a ZIP code for your location. Please enter one instead.",
        });
      }
      console.error('Reverse geocode error:', err);
      res.set('Cache-Control', 'no-store');
      return res.status(502).json({ error: 'Location lookup is unavailable right now. Please try again shortly.' });
    }
  }

  let place;
  try {
    place = await zipToCoords(zipCode);
  } catch (err) {
    if (err instanceof ZipNotFoundError) {
      res.set('Cache-Control', 'public, s-maxage=86400');
      return res.status(404).json({ error: `We couldn't find ZIP code ${zipCode}. Please check it and try again.` });
    }
    console.error('Zip lookup error:', err);
    res.set('Cache-Control', 'no-store');
    return res.status(502).json({ error: 'Location lookup is unavailable right now. Please try again shortly.' });
  }

  const { city, state, stateAbbr, lat, lng } = place;
  // Measure from where the user actually is when they shared it; the ZIP centroid otherwise.
  const originLat = device ? device.lat : lat;
  const originLng = device ? device.lng : lng;
  let locations = [];
  let dataSource = 'none';
  let election = null;
  let searchRadiusKm = null;

  const civicKey = process.env.GOOGLE_CIVIC_API_KEY;
  if (civicKey) {
    try {
      const official = await fetchOfficialLocations(`${city}, ${stateAbbr} ${zipCode}`, stateAbbr, civicKey);
      if (official.locations.length > 0) {
        locations = official.locations.map((l) => ({
          ...l,
          distance: l.lat != null ? Math.round(distanceKm(originLat, originLng, l.lat, l.lng) * 10) / 10 : null,
        }));
        election = official.election;
        dataSource = 'official';
      }
    } catch (err) {
      console.warn('Civic API failed, trying Nominatim:', err.message);
    }
  }

  // Nominatim runs its own tiers: a tight, place-scoped search first, then a wider civic-building
  // sweep. It reports which one answered so the UI can hedge harder as the data gets weaker.
  if (locations.length === 0) {
    try {
      const nearby = await findNearbyPollingVenues(originLat, originLng, city, state);
      if (nearby.locations.length > 0) {
        locations = nearby.locations;
        dataSource = nearby.dataSource;
        searchRadiusKm = nearby.searchRadiusKm;
      }
    } catch (err) {
      console.warn('Nominatim failed:', err.message);
    }
  }

  const payload = {
    locations,
    place: { city, state, stateAbbr, zip: zipCode, lat, lng },
    election,
    searchRadiusKm,
  };

  if (dataSource !== 'none') {
    // Device rows expire in a day rather than a week: someone who was standing here is unlikely
    // to still be, and a stale device row is far less reusable than a stale ZIP row.
    const ttl = device ? '1 day' : '7 days';
    try {
      await pool.query(
        `INSERT INTO polling_cache (cache_key, locations, data_source, expires_at)
         VALUES ($1, $2, $3, NOW() + $4::interval)
         ON CONFLICT (cache_key) DO UPDATE
         SET locations = $2, data_source = $3, cached_at = NOW(), expires_at = NOW() + $4::interval`,
        [cacheKey, JSON.stringify(payload), dataSource, ttl]
      );
    } catch (_) {
      // Cache write failed — still return results
    }
  }

  res.set('Cache-Control', dataSource === 'none' ? CACHE_NONE : CACHE_FOUND);
  res.json({ ...payload, zip: zipCode, device, dataSource, cached: false });
});

module.exports = router;
