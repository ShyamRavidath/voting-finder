const { fetchWithTimeout } = require('../lib/fetchWithTimeout');

const CIVIC_BASE = 'https://www.googleapis.com/civicinfo/v2';

function parseLocations(voterInfo) {
  const locations = [];

  const addLocs = (arr, type) => {
    (arr || []).forEach((loc) => {
      if (!loc.address?.line1) return;
      const parts = [loc.address.line1, loc.address.line2, loc.address.city, loc.address.state, loc.address.zip].filter(Boolean);
      locations.push({
        name: loc.address.locationName || loc.name || type,
        addr: parts.join(', '),
        type,
        // Only use coordinates the API actually provides — never invent them
        lat: loc.latitude ?? null,
        lng: loc.longitude ?? null,
        isReal: true,
        hours: loc.pollingHours || null,
      });
    });
  };

  addLocs(voterInfo.pollingLocations, 'Polling Place');
  addLocs(voterInfo.earlyVoteSites, 'Early Voting');
  addLocs(voterInfo.dropOffLocations, 'Ballot Drop-off');
  return locations;
}

async function civicGet(path, apiKey) {
  const res = await fetchWithTimeout(`${CIVIC_BASE}${path}${path.includes('?') ? '&' : '?'}key=${apiKey}`, {}, 6000);
  return res.json();
}

// Official locations only exist for elections Google's Voting Information Project has data for,
// typically a few weeks before election day.
async function fetchOfficialLocations(address, stateAbbr, apiKey) {
  const electionsData = await civicGet('/elections', apiKey);
  const today = new Date().toISOString().slice(0, 10);
  const stateDivision = `ocd-division/country:us/state:${stateAbbr.toLowerCase()}`;

  const relevant = (electionsData.elections || [])
    .filter((e) => e.id !== '2000') // Google's "VIP Test Election" returns fake test data
    .filter((e) => e.electionDay >= today)
    .filter((e) => e.ocdDivisionId === 'ocd-division/country:us' || e.ocdDivisionId?.startsWith(stateDivision))
    .sort((a, b) => a.electionDay.localeCompare(b.electionDay))
    .slice(0, 3);

  for (const election of relevant) {
    const data = await civicGet(
      `/voterinfo?address=${encodeURIComponent(address)}&electionId=${election.id}`,
      apiKey
    );
    if (data.error) continue;
    const locs = parseLocations(data);
    if (locs.length > 0) return { locations: locs, election: election.name };
  }

  return { locations: [], election: null };
}

module.exports = { fetchOfficialLocations, parseLocations };
