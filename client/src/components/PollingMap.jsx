import { useEffect, useRef } from 'react';
import L from 'leaflet';
import { isConfirmedLocation } from '../lib/format';
import 'leaflet/dist/leaflet.css';

function pinIcon(number, official) {
  return L.divIcon({
    className: '',
    html: `<div style="display:flex;align-items:center;justify-content:center;width:28px;height:28px;border-radius:9999px;background:${
      official ? '#059669' : '#2563eb'
    };color:#fff;font:700 13px/1 system-ui,sans-serif;border:2px solid #fff;box-shadow:0 1px 4px rgba(0,0,0,.35)">${Number(number)}</div>`,
    iconSize: [28, 28],
    iconAnchor: [14, 14],
    popupAnchor: [0, -14],
  });
}

// Built from DOM nodes (textContent) so names/addresses from upstream APIs can't inject markup.
function popupContent(location) {
  const { name, addr } = location;
  const el = document.createElement('div');
  const title = document.createElement('strong');
  title.textContent = name;
  const address = document.createElement('div');
  address.textContent = addr;
  address.style.color = '#475569';
  const confirmation = document.createElement('div');
  confirmation.textContent = isConfirmedLocation(location) ? 'Official · Confirm your assigned polling place' : 'Not confirmed · Check an official source before you go';
  confirmation.style.color = '#334155';
  confirmation.style.marginTop = '6px';
  el.append(title, address, confirmation);
  return el;
}

// Keeps popups inside narrow maps: 40px gutter per side, 120–280px wide.
function popupMaxWidth(container) {
  return Math.min(280, Math.max(120, container.clientWidth - 80));
}

export default function PollingMap({ locations, center, selected, onSelect }) {
  const containerRef = useRef(null);
  const mapRef = useRef(null);
  const layerRef = useRef(null);
  const markersRef = useRef([]);
  const onSelectRef = useRef(onSelect);
  onSelectRef.current = onSelect;

  useEffect(() => {
    const map = L.map(containerRef.current, { scrollWheelZoom: false, zoomControl: false });
    L.control.zoom({ position: 'bottomright' }).addTo(map);
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
    }).addTo(map);
    layerRef.current = L.layerGroup().addTo(map);
    mapRef.current = map;

    const observer = new ResizeObserver(() => {
      map.invalidateSize();
      const maxWidth = popupMaxWidth(containerRef.current);
      for (const marker of markersRef.current) {
        const popup = marker?.getPopup();
        if (!popup) continue;
        popup.options.maxWidth = maxWidth;
        if (popup.isOpen()) popup.update();
      }
    });
    observer.observe(containerRef.current);
    return () => {
      observer.disconnect();
      map.remove();
      mapRef.current = null;
    };
  }, []);

  useEffect(() => {
    const map = mapRef.current;
    if (!map) return;
    layerRef.current.clearLayers();
    markersRef.current = [];

    const points = [];
    locations.forEach((loc, i) => {
      if (loc.lat == null || loc.lng == null) {
        markersRef.current.push(null);
        return;
      }
      const marker = L.marker([loc.lat, loc.lng], {
        icon: pinIcon(i + 1, isConfirmedLocation(loc)),
        title: loc.name,
        alt: loc.name,
        keyboard: true,
      })
        .bindPopup(popupContent(loc), {
          maxWidth: popupMaxWidth(containerRef.current),
          autoPanPadding: [16, 16],
        })
        .on('click', () => onSelectRef.current?.(i))
        .addTo(layerRef.current);
      markersRef.current.push(marker);
      points.push([loc.lat, loc.lng]);
    });

    if (points.length > 1) map.fitBounds(points, { padding: [32, 32], maxZoom: 15 });
    else if (points.length === 1) map.setView(points[0], 15);
    else if (center) map.setView([center.lat, center.lng], 12);
  }, [locations, center]);

  useEffect(() => {
    const marker = selected != null ? markersRef.current[selected] : null;
    if (!marker || !mapRef.current) return;
    // Finish recentering before popup auto-pan measures its bounds.
    mapRef.current.stop();
    mapRef.current.setView(marker.getLatLng(), Math.max(mapRef.current.getZoom(), 15), { animate: false });
    marker.openPopup();
  }, [selected]);

  return (
    <div
      ref={containerRef}
      role="region"
      aria-label="Map of nearby locations"
      className="relative z-0 h-72 w-full overflow-hidden rounded-2xl border border-slate-200 sm:h-96 lg:h-[28rem]"
    />
  );
}
