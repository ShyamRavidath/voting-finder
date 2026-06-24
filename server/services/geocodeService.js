const timeoutPromise = (ms) =>
  new Promise((_, reject) => setTimeout(() => reject(new Error('Request timeout')), ms));

async function zipToCoords(zip) {
  const res = await Promise.race([
    fetch(`https://api.zippopotam.us/us/${zip}`),
    timeoutPromise(5000),
  ]);
  if (!res.ok) throw new Error('Invalid zip code');
  const data = await res.json();
  const place = data.places[0];
  return {
    city: place['place name'],
    state: place['state'],
    stateAbbr: place['state abbreviation'],
    lat: parseFloat(place.latitude),
    lng: parseFloat(place.longitude),
  };
}

async function findNearbyPollingVenues(lat, lng, city, state) {
  const locationTypes = [
    { query: 'library', label: 'Likely Polling Place' },
    { query: 'community center', label: 'Likely Early Voting' },
    { query: 'town hall', label: 'Likely Early Voting' },
    { query: 'school', label: 'Likely Polling Place' },
  ];

  const allLocations = [];

  for (let i = 0; i < Math.min(locationTypes.length, 3); i++) {
    const { query, label } = locationTypes[i];
    if (i > 0) await new Promise((r) => setTimeout(r, 1000));

    try {
      const bbox = `${lng - 0.03},${lat - 0.03},${lng + 0.03},${lat + 0.03}`;
      const url = `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(
        query + ' ' + city + ' ' + state
      )}&format=json&limit=3&addressdetails=1&bounded=1&viewbox=${bbox}&dedupe=1`;

      const res = await Promise.race([
        fetch(url, {
          headers: { 'User-Agent': 'Vote4U-PollingFinder/1.0', 'Accept-Language': 'en' },
        }),
        timeoutPromise(5000),
      ]);
      if (!res.ok) continue;

      const data = await res.json();
      data.forEach((place) => {
        const placeLat = parseFloat(place.lat);
        const placeLng = parseFloat(place.lon);
        const R = 6371;
        const dLat = ((placeLat - lat) * Math.PI) / 180;
        const dLon = ((placeLng - lng) * Math.PI) / 180;
        const a =
          Math.sin(dLat / 2) ** 2 +
          Math.cos((lat * Math.PI) / 180) *
            Math.cos((placeLat * Math.PI) / 180) *
            Math.sin(dLon / 2) ** 2;
        const distance = R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

        if (distance < 10) {
          const addr = place.address || {};
          const parts = [
            addr.house_number,
            addr.road || addr.street,
            addr.city || addr.town || addr.village || addr.municipality,
            state,
            addr.postcode,
          ].filter(Boolean);
          const fullAddress =
            parts.length >= 2
              ? parts.join(', ')
              : place.display_name.split(',').slice(0, 3).join(', ').trim();

          allLocations.push({
            name: place.name || place.display_name.split(',')[0],
            addr: fullAddress,
            type: label,
            lat: placeLat,
            lng: placeLng,
            distance,
            isReal: true,
            isEstimated: true,
          });
        }
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
    .slice(0, 4);
}

function generateSampleLocations(lat, lng, city, state) {
  const rand = () => Math.floor(Math.random() * 900 + 100);
  const offset = () => Math.random() * 0.1 - 0.05;
  return [
    { name: `${city} Public Library`, addr: `${rand()} Main St, ${city}, ${state}`, type: 'Estimated Location', lat: lat + offset(), lng: lng + offset(), isSample: true },
    { name: `${city} Community Center`, addr: `${rand()} Park Ave, ${city}, ${state}`, type: 'Estimated Location', lat: lat + offset(), lng: lng + offset(), isSample: true },
    { name: `${city} High School`, addr: `${rand()} School Dr, ${city}, ${state}`, type: 'Estimated Location', lat: lat + offset(), lng: lng + offset(), isSample: true },
    { name: `${city} Recreation Center`, addr: `${rand()} Recreation Way, ${city}, ${state}`, type: 'Estimated Location', lat: lat + offset(), lng: lng + offset(), isSample: true },
  ];
}

module.exports = { zipToCoords, findNearbyPollingVenues, generateSampleLocations };
