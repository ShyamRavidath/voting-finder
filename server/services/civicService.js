const CIVIC_BASE = 'https://www.googleapis.com/civicinfo/v2';

function parseLocations(voterInfo, defaultLat, defaultLng) {
  const locations = [];
  const offset = () => Math.random() * 0.03 - 0.015;

  const addLocs = (arr, defaultType) => {
    (arr || []).forEach((loc) => {
      if (!loc.address?.line1) return;
      const parts = [loc.address.line1, loc.address.line2, loc.address.city, loc.address.state, loc.address.zip].filter(Boolean);
      locations.push({
        name: loc.address.locationName || loc.name || defaultType,
        addr: parts.join(', '),
        type: defaultType,
        lat: loc.latitude || defaultLat + offset(),
        lng: loc.longitude || defaultLng + offset(),
        isReal: true,
        hours: loc.pollingHours || loc.hours || loc.startDate || null,
      });
    });
  };

  addLocs(voterInfo.pollingLocations, 'Polling Place');
  addLocs(voterInfo.earlyVoteSites, 'Early Voting');
  return locations;
}

async function fetchOfficialLocations(address, lat, lng, apiKey) {
  const electionsRes = await fetch(`${CIVIC_BASE}/elections?key=${apiKey}`);
  const electionsData = await electionsRes.json();

  const idsToTry = ['2000'];
  if (Array.isArray(electionsData.elections)) {
    const upcoming = electionsData.elections
      .filter((e) => e.electionDay && new Date(e.electionDay) >= new Date())
      .sort((a, b) => new Date(a.electionDay) - new Date(b.electionDay))
      .slice(0, 3)
      .map((e) => e.id);
    idsToTry.unshift(...upcoming);
  }

  for (const id of idsToTry) {
    const res = await fetch(
      `${CIVIC_BASE}/voterinfo?address=${encodeURIComponent(address)}&key=${apiKey}&electionId=${id}`
    );
    const data = await res.json();
    if (data.error) continue;
    const locs = parseLocations(data, lat, lng);
    if (locs.length > 0) return locs;
  }

  const res = await fetch(`${CIVIC_BASE}/voterinfo?address=${encodeURIComponent(address)}&key=${apiKey}`);
  const data = await res.json();
  if (!data.error) {
    const locs = parseLocations(data, lat, lng);
    if (locs.length > 0) return locs;
  }

  throw new Error('No polling locations available yet from official sources.');
}

module.exports = { fetchOfficialLocations };
