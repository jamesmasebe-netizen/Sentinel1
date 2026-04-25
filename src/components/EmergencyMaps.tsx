import React, { useState, useEffect, useRef } from 'react';
import { collection, onSnapshot, query, addDoc, doc, updateDoc, deleteDoc } from 'firebase/firestore';
import { db, auth, handleFirestoreError } from '../lib/firebase';
import { 
  Map as MapIcon, 
  Flame, 
  Stethoscope, 
  Droplets, 
  Plus, 
  X, 
  Save,
  Trash2,
  Maximize2,
  Navigation
} from 'lucide-react';

interface MapMarker {
  id: string;
  type: 'Extinguisher' | 'AED' | 'FirstAid' | 'SpillKit' | 'Exit' | 'Assembly';
  x: number; // percentage
  y: number; // percentage
  label: string;
}

interface EmergencyMap {
  id: string;
  name: string;
  imageUrl: string;
  markers: MapMarker[];
}

export default function EmergencyMaps() {
  const [maps, setMaps] = useState<EmergencyMap[]>([]);
  const [selectedMap, setSelectedMap] = useState<EmergencyMap | null>(null);
  const [isAddingMarker, setIsAddingMarker] = useState(false);
  const [newMarkerType, setNewMarkerType] = useState<MapMarker['type']>('Extinguisher');
  const [isAddingMap, setIsAddingMap] = useState(false);
  const [newMapName, setNewMapName] = useState('');
  const [newMapUrl, setNewMapUrl] = useState('');

  const mapRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const q = query(collection(db, 'emergency_maps'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as EmergencyMap[];
      setMaps(data);
      if (data.length > 0 && !selectedMap) {
        setSelectedMap(data[0]);
      }
    }, (error) => {
      handleFirestoreError(error, 'list' as any, 'emergency_maps');
    });

    return () => unsubscribe();
  }, [selectedMap]);

  const handleMapClick = async (e: React.MouseEvent<HTMLDivElement>) => {
    if (!isAddingMarker || !selectedMap || !mapRef.current) return;

    const rect = mapRef.current.getBoundingClientRect();
    const x = ((e.clientX - rect.left) / rect.width) * 100;
    const y = ((e.clientY - rect.top) / rect.height) * 100;

    const newMarker: Omit<MapMarker, 'id'> = {
      type: newMarkerType,
      x,
      y,
      label: `${newMarkerType} at ${Math.round(x)}%, ${Math.round(y)}%`
    };

    try {
      const updatedMarkers = [...(selectedMap.markers || []), { ...newMarker, id: Math.random().toString(36).substr(2, 9) }];
      await updateDoc(doc(db, 'emergency_maps', selectedMap.id), {
        markers: updatedMarkers
      });
      setIsAddingMarker(false);
    } catch (error) {
      handleFirestoreError(error, 'update' as any, 'emergency_maps');
    }
  };

  const deleteMarker = async (markerId: string) => {
    if (!selectedMap) return;
    try {
      const updatedMarkers = selectedMap.markers.filter(m => m.id !== markerId);
      await updateDoc(doc(db, 'emergency_maps', selectedMap.id), {
        markers: updatedMarkers
      });
    } catch (error) {
      handleFirestoreError(error, 'update' as any, 'emergency_maps');
    }
  };

  const handleAddMap = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await addDoc(collection(db, 'emergency_maps'), {
        name: newMapName,
        imageUrl: newMapUrl || 'https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&q=80&w=2000',
        markers: []
      });
      setIsAddingMap(false);
      setNewMapName('');
      setNewMapUrl('');
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'emergency_maps');
    }
  };

  const getMarkerIcon = (type: MapMarker['type']) => {
    switch (type) {
      case 'Extinguisher': return <Flame size={16} className="text-red-500" />;
      case 'AED': return <Stethoscope size={16} className="text-blue-500" />;
      case 'FirstAid': return <Plus size={16} className="text-green-500" />;
      case 'SpillKit': return <Droplets size={16} className="text-amber-500" />;
      case 'Exit': return <Navigation size={16} className="text-slate-900" />;
      case 'Assembly': return <Users size={16} className="text-blue-600" />;
      default: return <MapIcon size={16} />;
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row gap-4 items-center justify-between">
        <div className="flex items-center gap-2 overflow-x-auto pb-2 w-full md:w-auto">
          {maps.map(map => (
            <button
              key={map.id}
              onClick={() => setSelectedMap(map)}
              className={`px-4 py-2 rounded-lg font-medium transition-all whitespace-nowrap ${
                selectedMap?.id === map.id 
                  ? 'bg-red-600 text-white shadow-md' 
                  : 'bg-white border border-slate-200 text-slate-600 hover:border-red-300'
              }`}
            >
              {map.name}
            </button>
          ))}
          <button 
            onClick={() => setIsAddingMap(true)}
            className="p-2 bg-slate-100 text-slate-600 rounded-lg hover:bg-slate-200 transition-colors"
          >
            <Plus size={20} />
          </button>
        </div>

        {selectedMap && (
          <div className="flex items-center gap-2 w-full md:w-auto">
            <select 
              value={newMarkerType}
              onChange={(e) => setNewMarkerType(e.target.value as any)}
              className="p-2 border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-red-500"
            >
              <option value="Extinguisher">Fire Extinguisher</option>
              <option value="AED">AED</option>
              <option value="FirstAid">First Aid Kit</option>
              <option value="SpillKit">Spill Kit</option>
              <option value="Exit">Emergency Exit</option>
              <option value="Assembly">Assembly Point</option>
            </select>
            <button
              onClick={() => setIsAddingMarker(!isAddingMarker)}
              className={`flex items-center gap-2 px-4 py-2 rounded-lg font-bold transition-all ${
                isAddingMarker 
                  ? 'bg-amber-500 text-white animate-pulse' 
                  : 'bg-slate-900 text-white hover:bg-slate-800'
              }`}
            >
              {isAddingMarker ? 'Click on Map to Place' : 'Add Marker'}
            </button>
          </div>
        )}
      </div>

      {selectedMap ? (
        <div className="relative bg-slate-100 rounded-2xl border border-slate-200 overflow-hidden shadow-inner min-h-[500px]">
          <div 
            ref={mapRef}
            onClick={handleMapClick}
            className={`relative w-full h-full min-h-[500px] cursor-crosshair ${isAddingMarker ? 'cursor-crosshair' : 'cursor-default'}`}
          >
            <img 
              src={selectedMap.imageUrl} 
              alt={selectedMap.name}
              className="w-full h-full object-contain pointer-events-none"
              referrerPolicy="no-referrer"
            />
            
            {selectedMap.markers?.map(marker => (
              <div 
                key={marker.id}
                className="absolute -translate-x-1/2 -translate-y-1/2 group"
                style={{ left: `${marker.x}%`, top: `${marker.y}%` }}
              >
                <div className="bg-white p-1.5 rounded-full shadow-lg border-2 border-white group-hover:scale-125 transition-transform cursor-pointer">
                  {getMarkerIcon(marker.type)}
                </div>
                
                <div className="absolute top-full left-1/2 -translate-x-1/2 mt-2 hidden group-hover:block z-20">
                  <div className="bg-slate-900 text-white text-[10px] px-2 py-1 rounded whitespace-nowrap flex items-center gap-2">
                    {marker.label}
                    <button 
                      onClick={(e) => {
                        e.stopPropagation();
                        deleteMarker(marker.id);
                      }}
                      className="text-red-400 hover:text-red-300"
                    >
                      <Trash2 size={12} />
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>

          <div className="absolute bottom-4 right-4 flex gap-2">
            <button className="p-2 bg-white/80 backdrop-blur rounded-lg shadow hover:bg-white transition-colors">
              <Maximize2 size={20} className="text-slate-600" />
            </button>
          </div>
        </div>
      ) : (
        <div className="bg-slate-50 border-2 border-dashed border-slate-200 rounded-2xl p-12 text-center">
          <MapIcon size={48} className="mx-auto text-slate-300 mb-4" />
          <h3 className="text-lg font-bold text-slate-900">No Emergency Maps Found</h3>
          <p className="text-slate-500 mb-6 text-sm">Upload your site floor plans to start mapping emergency equipment.</p>
          <button 
            onClick={() => setIsAddingMap(true)}
            className="bg-red-600 text-white px-6 py-2 rounded-lg font-bold hover:bg-red-700 transition-colors"
          >
            Upload First Map
          </button>
        </div>
      )}

      {/* Add Map Modal */}
      {isAddingMap && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex justify-between items-center">
              <h2 className="text-xl font-bold text-slate-900">Add Site Map</h2>
              <button onClick={() => setIsAddingMap(false)} className="text-slate-400 hover:text-slate-600">
                <X size={24} />
              </button>
            </div>
            <form onSubmit={handleAddMap} className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Map Name</label>
                <input 
                  type="text" 
                  required
                  value={newMapName}
                  onChange={(e) => setNewMapName(e.target.value)}
                  placeholder="e.g., Warehouse Ground Floor"
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Map Image URL</label>
                <input 
                  type="url" 
                  value={newMapUrl}
                  onChange={(e) => setNewMapUrl(e.target.value)}
                  placeholder="https://example.com/floorplan.jpg"
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500"
                />
                <p className="text-[10px] text-slate-400 mt-1">Leave blank to use a placeholder floorplan for testing.</p>
              </div>
              <div className="pt-4 flex justify-end gap-3">
                <button 
                  type="button"
                  onClick={() => setIsAddingMap(false)}
                  className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
                >
                  Cancel
                </button>
                <button 
                  type="submit"
                  className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors font-bold"
                >
                  Create Map
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

// Helper icons for markers
function Users({ size, className }: { size: number, className?: string }) {
  return (
    <svg 
      width={size} 
      height={size} 
      viewBox="0 0 24 24" 
      fill="none" 
      stroke="currentColor" 
      strokeWidth="2" 
      strokeLinecap="round" 
      strokeLinejoin="round"
      className={className}
    >
      <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" />
      <circle cx="9" cy="7" r="4" />
      <path d="M22 21v-2a4 4 0 0 0-3-3.87" />
      <path d="M16 3.13a4 4 0 0 1 0 7.75" />
    </svg>
  );
}
