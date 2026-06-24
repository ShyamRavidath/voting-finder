import { useEffect, useRef } from 'react';
import 'leaflet/dist/leaflet.css';
import { STATE_DATA } from '../data/stateData';

export default function ElectoralMap({ pollingLocations = [], onReady }) {
  const containerRef = useRef(null);
  const mapRef = useRef(null);
  const pollingMarkersRef = useRef([]);

  useEffect(() => {
    if (mapRef.current || !containerRef.current) return;

    import('leaflet').then((L) => {
      const map = L.map(containerRef.current).setView([37.8, -96], 4);
      L.tileLayer('https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png', {
        attribution: '© OpenStreetMap contributors',
      }).addTo(map);

      STATE_DATA.forEach((s) => {
        const color = s.party === 'blue' ? '#2563eb' : s.party === 'red' ? '#dc2626' : '#64748b';
        L.circleMarker([s.lat, s.lng], {
          radius: 8,
          fillColor: color,
          color: '#fff',
          weight: 2,
          fillOpacity: 0.85,
        })
          .addTo(map)
          .bindPopup(`<div class="font-semibold">${s.name}</div><div class="text-sm text-gray-600">${s.ev} Electoral Votes</div>`);
      });

      mapRef.current = map;
      onReady?.(map);
    });

    return () => {
      if (mapRef.current) {
        mapRef.current.remove();
        mapRef.current = null;
      }
    };
  }, []);

  useEffect(() => {
    if (!mapRef.current || !pollingLocations.length) return;

    import('leaflet').then((L) => {
      pollingMarkersRef.current.forEach((m) => mapRef.current?.removeLayer(m));
      pollingMarkersRef.current = [];

      const first = pollingLocations[0];
      if (first?.lat) mapRef.current.setView([first.lat, first.lng], 12);

      pollingLocations.forEach((loc) => {
        if (!loc.lat || !loc.lng) return;
        const color =
          loc.isReal && !loc.isEstimated ? '#10b981' : loc.isReal ? '#3b82f6' : '#f59e0b';

        const marker = L.marker([loc.lat, loc.lng], {
          icon: L.divIcon({
            className: '',
            html: `<div style="background:${color};width:20px;height:20px;border-radius:50%;border:3px solid white;box-shadow:0 2px 8px rgba(0,0,0,0.3)"></div>`,
            iconSize: [20, 20],
            iconAnchor: [10, 10],
          }),
        })
          .bindPopup(`<div class="font-semibold">${loc.name}</div><div class="text-sm text-gray-600">${loc.addr}</div>`)
          .addTo(mapRef.current);

        pollingMarkersRef.current.push(marker);
      });
    });
  }, [pollingLocations]);

  return (
    <div
      ref={containerRef}
      style={{ height: 600, width: '100%', borderRadius: '1rem', zIndex: 1 }}
    />
  );
}
