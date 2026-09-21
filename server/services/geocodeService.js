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

// Venue search runs in tiers, widening only when the tier above it comes back empty.
//
// Tier 1 names the city and state in the query text, which is precise when Nominatim's index
// cooperates. It often doesn't: the exact query this server sends for 90210 returned venues one
// afternoon, `[]` the next morning, and venues again the day after. So tier 2 drops the place
// name entirely and lets the bounding box do the geography, which is far more stable, over a
// wider box and a broader set of venue types — the buildings American precincts actually use.
//
// Tier 2 results are *not* a better guess, they are a weaker one, and the labelling gets more
// cautious to match: "Civic Building", never "Likely Polling Place".
const VENUE_TIERS = [
  {
    dataSource: 'estimated',
    box: 0.03, // ~3 km
    maxDistanceKm: 10,
    scoped: true,
    venues: [
      { query: 'library', label: 'Likely Polling Place' },
      { query: 'community center', label: 'Likely Early Voting' },
      { query: 'town hall', label: 'Likely Early Voting' },
    ],
  },
  {
    dataSource: 'nearby',
    box: 0.1, // ~11 km
    maxDistanceKm: 25,
    scoped: false,
    venues: [
      { query: 'library', label: 'Civic Building' },
      { query: 'community center', label: 'Civic Building' },
      { query: 'school', label: 'Civic Building' },
      { query: 'fire station', label: 'Civic Building' },
    ],
  },
];

// Nominatim matches on free text, so a query for "town hall" happily returns the bus stop named
// "Paterson Plank Rd At Town Hall", "library" returns a Little Free Library book box, and
// "community center" returns a compost drop-off. Every one of those was being shown to voters
// under the heading "Likely Polling Place".
//
// `class` and `type` come back with `addressdetails=1` and are enough to reject them. This is a
// denylist, not an allowlist: a real community center is sometimes only tagged `building=yes`,
// and dropping those would cost more than the noise does.
const REJECTED_CLASSES = new Set([
  'highway', 'railway', 'waterway', 'natural', 'boundary', 'place', 'shop', 'tourism',
]);
const REJECTED_TYPES = new Set([
  'bus_stop', 'bus_station', 'platform', 'public_bookcase', 'recycling', 'waste_disposal',
  'waste_transfer_station', 'bench', 'parking', 'bicycle_parking', 'garden', 'park', 'playground',
  'pitch', 'dog_park', 'bar', 'pub', 'restaurant', 'cafe', 'fast_food', 'atm', 'vending_machine',
  'toilets', 'drinking_water', 'fuel', 'car_wash', 'post_box',
]);

function isPlausibleVenue(place) {
  return !REJECTED_CLASSES.has(place.class) && !REJECTED_TYPES.has(place.type);
}

function buildVenue(place, label, originLat, originLng, state, maxDistanceKm) {
  if (!isPlausibleVenue(place)) return null;

  const placeLat = parseFloat(place.lat);
  const placeLng = parseFloat(place.lon);
  if (!Number.isFinite(placeLat) || !Number.isFinite(placeLng)) return null;

  const distance = distanceKm(originLat, originLng, placeLat, placeLng);
  if (distance >= maxDistanceKm) return null;

  const displayName = typeof place.display_name === 'string' ? place.display_name : '';
  if (!place.name && !displayName) return null;

  const addr = place.address || {};
  const parts = [
    [addr.house_number, addr.road || addr.street].filter(Boolean).join(' '),
    addr.city || addr.town || addr.village || addr.municipality,
    // The venue's own state, not the ZIP's: the widened tier's box is ~11 km and can cross a
    // state line, and printing the wrong state under a venue's name is exactly the kind of
    // quiet inaccuracy rule #1 exists to prevent.
    addr.state || state,
    addr.postcode,
  ].filter(Boolean);
  const fullAddress =
    parts.length >= 2 ? parts.join(', ') : displayName.split(',').slice(0, 3).join(', ').trim();

  return {
    name: place.name || displayName.split(',')[0],
    addr: fullAddress,
    type: label,
    lat: placeLat,
    lng: placeLng,
    distance: Math.round(distance * 10) / 10,
    isReal: true,
    isEstimated: true,
  };
}

function dedupe(locations) {
  const seenNames = new Set();
  const seenAddrs = new Set();
  return locations
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

// Returns { locations, dataSource, searchRadiusKm }. `dataSource` is 'estimated' for a tight,
// place-scoped match, 'nearby' for the widened civic-building fallback, and 'none' when both
// tiers come up empty — we say so rather than inventing anything (rule #1).
async function findNearbyPollingVenues(lat, lng, city, state) {
  // Nominatim's usage policy caps us at one request per second across every query we send, so
  // the tiers share a single sequential budget rather than each pacing themselves.
  let isFirstRequest = true;

  for (const tier of VENUE_TIERS) {
    const found = [];

    for (const { query, label } of tier.venues) {
      if (!isFirstRequest) await new Promise((r) => setTimeout(r, 1000));
      isFirstRequest = false;

      try {
        const bbox = `${lng - tier.box},${lat - tier.box},${lng + tier.box},${lat + tier.box}`;
        const q = tier.scoped ? `${query} ${city} ${state}` : query;
        const url =
          `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(q)}` +
          `&format=json&limit=3&addressdetails=1&bounded=1&viewbox=${bbox}&dedupe=1&countrycodes=us`;

        const res = await fetchWithTimeout(url, { headers: { 'User-Agent': USER_AGENT, 'Accept-Language': 'en' } }, 5000);
        if (!res.ok) continue;

        const data = await res.json();
        if (!Array.isArray(data)) continue;
        data.forEach((place) => {
          const venue = buildVenue(place, label, lat, lng, state, tier.maxDistanceKm);
          if (venue) found.push(venue);
        });
      } catch (_) {
        // A single venue type failing shouldn't sink the tier — try the next one.
      }
    }

    if (found.length > 0) {
      return { locations: dedupe(found), dataSource: tier.dataSource, searchRadiusKm: tier.maxDistanceKm };
    }
  }

  return { locations: [], dataSource: 'none', searchRadiusKm: null };
}

module.exports = {
  isPlausibleVenue,
  zipToCoords,
  coordsToZip,
  findNearbyPollingVenues,
  distanceKm,
  roundCoord,
  ZipNotFoundError,
  OutsideUsError,
};
