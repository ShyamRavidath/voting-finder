// The polling cache is keyed by whatever the distances were measured from, because that is what
// makes two responses interchangeable.
//
// A ZIP lookup measures from the ZIP centroid, so the ZIP alone identifies it. A device lookup
// measures from the phone, so two people in the same ZIP standing a mile apart must not share a
// row — their distance fields differ. Device lookups used to skip the cache entirely for exactly
// that reason; encoding the origin in the key is what makes them cacheable without poisoning the
// ZIP rows.
//
// A device key deliberately carries **no ZIP**, even though one is known by the time the row is
// written. Including it would mean reverse-geocoding before the cache could be consulted, which
// costs a Nominatim request on every hit — the exact call the cache exists to avoid. The ZIP
// travels inside the cached payload (`place.zip`) instead, so nothing is lost.
//
// Coordinates are already rounded to 3dp (~110 m) by roundCoord before they leave the server, so
// the key inherits that precision and no further rounding decision is made here. A cache hit is
// therefore never more than ~110 m from where the caller actually is, which is finer than the
// one-decimal-kilometre distances the response reports. `toFixed` is what makes 39.1 and 39.100
// the same row rather than two.
function pollingCacheKey(zipCode, device) {
  if (!device) return zipCode;
  return `@${device.lat.toFixed(3)},${device.lng.toFixed(3)}`;
}

module.exports = { pollingCacheKey };
