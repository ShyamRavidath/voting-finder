const { fetchWithTimeout } = require('../lib/fetchWithTimeout');

// Nominatim's usage policy requires an identifying User-Agent and at most 1 request/second.
const USER_AGENT = 'Vote4U-PollingFinder/1.1 (+https://vote4ucyl.vercel.app)';

class ZipNotFoundError extends Error {}
class OutsideUsError extends Error {}

// Coordinates are rounded before they leave this server: ~110 m is far more precision than a
// ZIP lookup needs, it keeps the CDN cache key space bounded, and it means we never forward a
// device's exact position to a third party.
const COORD_PRECISION = 3;

function roundCoord(n) {
  return Math.round(n * 10 ** COORD_PRECISION) / 10 ** COORD_PRECISION;
}

// Reverse-geocode a device location to the ZIP code that the rest of the polling pipeline needs.
// Keyless, same Nominatim service the venue search already uses.
async function coordsToZip(lat, lng) {
  const url =
    `https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lng}` +
    '&format=json&addressdetails=1&zoom=18';

  const res = await fetchWithTimeout(url, { headers: { 'User-Agent': USER_AGENT, 'Accept-Language': 'en' } }, 5000);
  if (!res.ok) throw new Error(`Reverse geocode failed: HTTP ${res.status}`);

  const data = await res.json();
  const addr = data?.address;
  if (!addr) throw new ZipNotFoundError(`No address found for ${lat},${lng}`);

  // Nominatim reports the country even when it has no postcode, so check it first: being outside
  // the US is a different answer to the user than being somewhere we simply couldn't resolve.
  const country = (addr.country_code || '').toLowerCase();
  if (country && country !== 'us') throw new OutsideUsError(`Coordinates are in ${country.toUpperCase()}, not the US`);

  // Postcodes come back as either "19901" or ZIP+4 ("19901-1234"); the pipeline wants the 5-digit form.
  const zip = String(addr.postcode || '').match(/\b(\d{5})\b/)?.[1];
  if (!zip) throw new ZipNotFoundError(`No US ZIP code found for ${lat},${lng}`);

  return zip;
}

async function zipToCoords(zip) {
  const res = await fetchWithTimeout(`https://api.zippopotam.us/us/${zip}`, {}, 5000);
  if (res.status === 404) throw new ZipNotFoundError(`ZIP code ${zip} not found`);
  if (!res.ok) throw new Error(`Zip lookup failed: HTTP ${res.status}`);
  const data = await res.json();
  const place = data.places?.[0];
  if (!place) throw new ZipNotFoundError(`ZIP code ${zip} not found`);
  return {
    city: place['place name'],
    state: place['state'],
    stateAbbr: place['state abbreviation'],
    lat: parseFloat(place.latitude),
    lng: parseFloat(place.longitude),
  };
}

function distanceKm(lat1, lng1, lat2, lng2) {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) * Math.cos((lat2 * Math.PI) / 180) * Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

async function findNearbyPollingVenues(lat, lng, city, state) {
  const locationTypes = [
    { query: 'library', label: 'Likely Polling Place' },
    { query: 'community center', label: 'Likely Early Voting' },
    { query: 'town hall', label: 'Likely Early Voting' },
  ];

  const allLocations = [];

  for (let i = 0; i < locationTypes.length; i++) {
    const { query, label } = locationTypes[i];
    if (i > 0) await new Promise((r) => setTimeout(r, 1000));

    try {
      const bbox = `${lng - 0.03},${lat - 0.03},${lng + 0.03},${lat + 0.03}`;
      const url = `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(
        query + ' ' + city + ' ' + state
      )}&format=json&limit=3&addressdetails=1&bounded=1&viewbox=${bbox}&dedupe=1&countrycodes=us`;

      const res = await fetchWithTimeout(url, { headers: { 'User-Agent': USER_AGENT, 'Accept-Language': 'en' } }, 5000);
      if (!res.ok) continue;

      const data = await res.json();
      data.forEach((place) => {
        const placeLat = parseFloat(place.lat);
        const placeLng = parseFloat(place.lon);
        const distance = distanceKm(lat, lng, placeLat, placeLng);
        if (distance >= 10) return;

        const addr = place.address || {};
        const parts = [
          [addr.house_number, addr.road || addr.street].filter(Boolean).join(' '),
          addr.city || addr.town || addr.village || addr.municipality,
          state,
          addr.postcode,
        ].filter(Boolean);
        const fullAddress =
          parts.length >= 2 ? parts.join(', ') : place.display_name.split(',').slice(0, 3).join(', ').trim();

        allLocations.push({
          name: place.name || place.display_name.split(',')[0],
          addr: fullAddress,
          type: label,
          lat: placeLat,
          lng: placeLng,
          distance: Math.round(distance * 10) / 10,
          isReal: true,
          isEstimated: true,
        });
      });
    } catch (_) {
      // continue with next type
    }
  }

  const seenNames = new Set();
  const seenAddrs = new Set();
  return allLocations
    .sort((a, b) => a.distance - b.distance)
    .filter((loc) => {
      const n = loc.name.toLowerCase().trim();
      const a = loc.addr.toLowerCase().trim();
      if (seenNames.has(n) || seenAddrs.has(a)) return false;
      seenNames.add(n);
      seenAddrs.add(a);
      return true;
    })
    .slice(0, 5);
}

module.exports = {
  zipToCoords,
  coordsToZip,
  findNearbyPollingVenues,
  distanceKm,
  roundCoord,
  ZipNotFoundError,
  OutsideUsError,
};
