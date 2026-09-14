const express = require('express');
const router = express.Router();
const pool = require('../db/client');
const { fetchOfficialLocations } = require('../services/civicService');
const { zipToCoords, findNearbyPollingVenues, distanceKm, ZipNotFoundError } = require('../services/geocodeService');

// Cached per ZIP at Vercel's CDN; keeps Nominatim/Civic traffic well inside their fair-use limits.
const CACHE_FOUND = 'public, max-age=300, s-maxage=86400, stale-while-revalidate=604800';
const CACHE_NONE = 'public, max-age=0, s-maxage=3600';

router.get('/', async (req, res) => {
  const { zip } = req.query;
  if (typeof zip !== 'string' || !/^\d{5}$/.test(zip)) {
    return res.status(400).json({ error: 'Please enter a valid 5-digit US ZIP code.' });
  }

  try {
    const cached = await pool.query(
      'SELECT locations, data_source FROM polling_cache WHERE zip_code = $1 AND expires_at > NOW()',
      [zip]
    );
    if (cached.rows.length > 0) {
      const stored = cached.rows[0].locations;
      // Older cache rows stored a bare array of locations
      const payload = Array.isArray(stored) ? { locations: stored, place: null, election: null } : stored;
      res.set('Cache-Control', CACHE_FOUND);
      return res.json({ ...payload, dataSource: cached.rows[0].data_source, cached: true });
    }
  } catch (_) {
    // DB unavailable — continue to live lookup
  }

  let place;
  try {
    place = await zipToCoords(zip);
  } catch (err) {
    if (err instanceof ZipNotFoundError) {
      res.set('Cache-Control', 'public, s-maxage=86400');
      return res.status(404).json({ error: `We couldn't find ZIP code ${zip}. Please check it and try again.` });
    }
    console.error('Zip lookup error:', err);
    res.set('Cache-Control', 'no-store');
    return res.status(502).json({ error: 'Location lookup is unavailable right now. Please try again shortly.' });
  }

  const { city, state, stateAbbr, lat, lng } = place;
  let locations = [];
  let dataSource = 'none';
  let election = null;

  const civicKey = process.env.GOOGLE_CIVIC_API_KEY;
  if (civicKey) {
    try {
      const official = await fetchOfficialLocations(`${city}, ${stateAbbr} ${zip}`, stateAbbr, civicKey);
      if (official.locations.length > 0) {
        locations = official.locations.map((l) => ({
          ...l,
          distance: l.lat != null ? Math.round(distanceKm(lat, lng, l.lat, l.lng) * 10) / 10 : null,
        }));
        election = official.election;
        dataSource = 'official';
      }
    } catch (err) {
      console.warn('Civic API failed, trying Nominatim:', err.message);
    }
  }

  if (locations.length === 0) {
    try {
      const nearby = await findNearbyPollingVenues(lat, lng, city, state);
      if (nearby.length > 0) {
        locations = nearby;
        dataSource = 'estimated';
      }
    } catch (err) {
      console.warn('Nominatim failed:', err.message);
    }
  }

  const payload = { locations, place: { city, state, stateAbbr, lat, lng }, election };

  if (dataSource !== 'none') {
    try {
      await pool.query(
        `INSERT INTO polling_cache (zip_code, locations, data_source, expires_at)
         VALUES ($1, $2, $3, NOW() + INTERVAL '7 days')
         ON CONFLICT (zip_code) DO UPDATE
         SET locations = $2, data_source = $3, cached_at = NOW(), expires_at = NOW() + INTERVAL '7 days'`,
        [zip, JSON.stringify(payload), dataSource]
      );
    } catch (_) {
      // Cache write failed — still return results
    }
  }

  res.set('Cache-Control', dataSource === 'none' ? CACHE_NONE : CACHE_FOUND);
  res.json({ ...payload, dataSource, cached: false });
});

module.exports = router;
