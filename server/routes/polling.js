const express = require('express');
const router = express.Router();
const pool = require('../db/client');
const { fetchOfficialLocations } = require('../services/civicService');
const { zipToCoords, findNearbyPollingVenues, generateSampleLocations } = require('../services/geocodeService');

router.get('/', async (req, res) => {
  const { zip } = req.query;
  if (!zip || !/^\d{5}$/.test(zip)) {
    return res.status(400).json({ error: 'Valid 5-digit US zip code required' });
  }

  try {
    const cached = await pool.query(
      'SELECT locations, data_source FROM polling_cache WHERE zip_code = $1 AND expires_at > NOW()',
      [zip]
    );
    if (cached.rows.length > 0) {
      return res.json({ locations: cached.rows[0].locations, dataSource: cached.rows[0].data_source, cached: true });
    }
  } catch (_) {}

  let locations = [];
  let dataSource = 'sample';

  try {
    const coords = await zipToCoords(zip);
    const { city, state, lat, lng } = coords;
    const address = `${city}, ${state} ${zip}`;

    const civicKey = process.env.GOOGLE_CIVIC_API_KEY;
    if (civicKey) {
      try {
        locations = await fetchOfficialLocations(address, lat, lng, civicKey);
        dataSource = 'official';
      } catch (err) {
        console.warn('Civic API failed, trying Nominatim:', err.message);
      }
    }

    if (locations.length === 0) {
      try {
        const nearby = await findNearbyPollingVenues(lat, lng, city, state);
        if (nearby?.length > 0) {
          locations = nearby;
          dataSource = 'estimated';
        }
      } catch (err) {
        console.warn('Nominatim failed, using sample data:', err.message);
      }
    }

    if (locations.length === 0) {
      locations = generateSampleLocations(lat, lng, city, state);
      dataSource = 'sample';
    }

    try {
      await pool.query(
        `INSERT INTO polling_cache (zip_code, locations, data_source, expires_at)
         VALUES ($1, $2, $3, NOW() + INTERVAL '7 days')
         ON CONFLICT (zip_code) DO UPDATE
         SET locations = $2, data_source = $3, cached_at = NOW(), expires_at = NOW() + INTERVAL '7 days'`,
        [zip, JSON.stringify(locations), dataSource]
      );
    } catch (_) {}

    res.json({ locations, dataSource, cached: false });
  } catch (err) {
    console.error('Polling route error:', err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
