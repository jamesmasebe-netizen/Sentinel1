import React, { useEffect, useRef, useState } from 'react';
import { Loader } from '@googlemaps/js-api-loader';
import { AlertTriangle } from 'lucide-react';

interface SiteMapProps {
  locations: { lat: number; lng: number; name: string; status: 'Green' | 'Amber' | 'Red' }[];
  center?: { lat: number; lng: number };
  zoom?: number;
}

export default function SiteMap({ locations, center = { lat: -26.2041, lng: 28.0473 }, zoom = 10 }: SiteMapProps) {
  const mapRef = useRef<HTMLDivElement>(null);
  const [mapError, setMapError] = useState<string | null>(null);

  useEffect(() => {
    const apiKey = (import.meta as any).env.VITE_GOOGLE_MAPS_API_KEY;
    
    if (!apiKey) {
      setMapError('Google Maps API Key missing. Please set VITE_GOOGLE_MAPS_API_KEY in your environment.');
      return;
    }

    const loader = new Loader({
      apiKey: apiKey,
      version: 'weekly',
    });

    loader.load().then(() => {
      if (mapRef.current) {
        const map = new google.maps.Map(mapRef.current, {
          center,
          zoom,
          styles: [
            {
              featureType: 'all',
              elementType: 'labels.text.fill',
              stylers: [{ color: '#ffffff' }, { weight: '0.1' }],
            },
          ],
        });

        locations.forEach((loc) => {
          const color = loc.status === 'Green' ? '#10b981' : loc.status === 'Amber' ? '#f59e0b' : '#ef4444';
          new google.maps.Marker({
            position: { lat: loc.lat, lng: loc.lng },
            map,
            title: loc.name,
            icon: {
              path: google.maps.SymbolPath.CIRCLE,
              fillColor: color,
              fillOpacity: 1,
              strokeWeight: 2,
              strokeColor: '#ffffff',
              scale: 10,
            },
          });
        });
      }
    }).catch((e) => {
      console.error("Google Maps failed to load:", e);
      setMapError('Failed to load Google Maps. Please check your API key and project settings.');
    });
  }, [locations, center, zoom]);

  if (mapError) {
    return (
      <div className="w-full h-full rounded-xl overflow-hidden shadow-inner border border-slate-200 bg-slate-100 flex flex-col items-center justify-center text-slate-500 p-6 text-center">
        <AlertTriangle size={32} className="mb-3 text-amber-500" />
        <p className="font-medium text-slate-700 mb-1">Map Unavailable</p>
        <p className="text-sm">{mapError}</p>
      </div>
    );
  }

  return (
    <div className="w-full h-full rounded-xl overflow-hidden shadow-inner border border-slate-200 relative">
      <div ref={mapRef} className="w-full h-full" />
    </div>
  );
}
