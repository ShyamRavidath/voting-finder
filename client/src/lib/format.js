export function timeAgo(dateString, now = Date.now()) {
  const time = new Date(dateString).getTime();
  if (!dateString || Number.isNaN(time)) return '';
  const mins = Math.max(0, Math.floor((now - time) / 60000));
  if (mins < 1) return 'Just now';
  if (mins < 60) return `${mins} min ago`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours} hr ago`;
  const days = Math.floor(hours / 24);
  if (days < 7) return `${days} day${days === 1 ? '' : 's'} ago`;
  return new Date(time).toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

export function formatMiles(km) {
  if (km == null) return null;
  const mi = km * 0.621371;
  return `${mi < 10 ? mi.toFixed(1) : Math.round(mi)} mi`;
}

// U.S. federal general elections: the Tuesday after the first Monday in November of even years.
export function nextFederalElection(from = new Date()) {
  const today = new Date(from.getFullYear(), from.getMonth(), from.getDate());
  for (let year = today.getFullYear(); ; year++) {
    if (year % 2 !== 0) continue;
    const nov1 = new Date(year, 10, 1);
    const firstMonday = 1 + ((8 - nov1.getDay()) % 7);
    const date = new Date(year, 10, firstMonday + 1);
    if (date >= today) {
      return {
        date,
        daysAway: Math.round((date - today) / 86400000),
        kind: year % 4 === 0 ? 'Presidential election' : 'Midterm elections',
      };
    }
  }
}

const isApple = () => typeof navigator !== 'undefined' && /iPhone|iPad|iPod|Macintosh/.test(navigator.userAgent);

export function directionsUrl({ lat, lng, addr, name }) {
  const destination = lat != null && lng != null ? `${lat},${lng}` : addr;
  if (isApple()) {
    return `https://maps.apple.com/?daddr=${encodeURIComponent(destination)}&q=${encodeURIComponent(name || addr || '')}`;
  }
  return `https://www.google.com/maps/dir/?api=1&destination=${encodeURIComponent(destination)}`;
}
