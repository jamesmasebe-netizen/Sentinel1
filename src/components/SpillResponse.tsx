import React, { useState, useEffect } from 'react';
import { collection, onSnapshot, query, addDoc, doc, updateDoc, orderBy } from 'firebase/firestore';
import { db, auth, handleFirestoreError } from '../lib/firebase';
import { 
  Droplets, 
  FileText, 
  ShieldAlert, 
  AlertTriangle, 
  CheckCircle2, 
  Search, 
  Plus, 
  X, 
  Wind,
  Trash2
} from 'lucide-react';

interface Chemical {
  id: string;
  name: string;
  hazardClass: string;
  sdsUrl: string;
  location: string;
  quantity: string;
}

interface SpillIncident {
  id: string;
  chemicalName: string;
  location: string;
  volume: string;
  containmentStatus: 'Contained' | 'Spreading' | 'Cleaned';
  environmentalImpact: 'Low' | 'Medium' | 'High';
  timestamp: string;
  reportedBy: string;
}

export default function SpillResponse() {
  const [chemicals, setChemicals] = useState<Chemical[]>([]);
  const [incidents, setIncidents] = useState<SpillIncident[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');

  // Form State
  const [chemicalName, setChemicalName] = useState('');
  const [location, setLocation] = useState('');
  const [volume, setVolume] = useState('');
  const [impact, setImpact] = useState<SpillIncident['environmentalImpact']>('Low');

  useEffect(() => {
    const qChem = query(collection(db, 'chemicals'));
    const unsubscribeChem = onSnapshot(qChem, (snapshot) => {
      setChemicals(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as Chemical[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'chemicals'));

    const qIncidents = query(collection(db, 'spill_incidents'), orderBy('timestamp', 'desc'));
    const unsubscribeIncidents = onSnapshot(qIncidents, (snapshot) => {
      setIncidents(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as SpillIncident[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'spill_incidents'));

    return () => {
      unsubscribeChem();
      unsubscribeIncidents();
    };
  }, []);

  const handleReportSpill = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;

    try {
      await addDoc(collection(db, 'spill_incidents'), {
        chemicalName,
        location,
        volume,
        containmentStatus: 'Spreading',
        environmentalImpact: impact,
        reportedBy: auth.currentUser.email,
        timestamp: new Date().toISOString()
      });
      setIsAdding(false);
      setChemicalName('');
      setLocation('');
      setVolume('');
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'spill_incidents');
    }
  };

  const updateContainment = async (id: string, status: SpillIncident['containmentStatus']) => {
    try {
      await updateDoc(doc(db, 'spill_incidents', id), { containmentStatus: status });
    } catch (error) {
      handleFirestoreError(error, 'update' as any, 'spill_incidents');
    }
  };

  const filteredChemicals = chemicals.filter(c => 
    c.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    c.location.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row justify-between items-center gap-4">
        <div className="flex items-center gap-3">
          <div className="bg-amber-50 p-2 rounded-lg text-amber-600">
            <Droplets size={24} />
          </div>
          <div>
            <h2 className="text-xl font-bold text-slate-900">HAZMAT & Spill Response</h2>
            <p className="text-sm text-slate-500">ISO 14001 Environmental Compliance Hub</p>
          </div>
        </div>
        <button 
          onClick={() => setIsAdding(true)}
          className="w-full md:w-auto flex items-center justify-center gap-2 bg-amber-600 text-white px-6 py-3 rounded-xl font-bold hover:bg-amber-700 transition-all shadow-lg shadow-amber-200"
        >
          <AlertTriangle size={20} />
          Report Active Spill
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* SDS & Chemical Inventory */}
        <div className="lg:col-span-1 space-y-4">
          <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm">
            <h3 className="font-bold text-slate-900 mb-4 flex items-center gap-2">
              <FileText size={18} className="text-blue-600" />
              SDS & Chemical Inventory
            </h3>
            <div className="relative mb-4">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={16} />
              <input 
                type="text"
                placeholder="Search chemicals..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-amber-500"
              />
            </div>
            <div className="space-y-3 max-h-[400px] overflow-y-auto pr-2 custom-scrollbar">
              {filteredChemicals.map(chem => (
                <div key={chem.id} className="p-3 bg-slate-50 rounded-xl border border-slate-100 hover:border-amber-200 transition-colors">
                  <div className="flex justify-between items-start mb-1">
                    <h4 className="font-bold text-slate-900 text-sm">{chem.name}</h4>
                    <span className="text-[10px] font-bold text-amber-600 uppercase">{chem.hazardClass}</span>
                  </div>
                  <p className="text-[10px] text-slate-500 mb-2">Location: {chem.location}</p>
                  <button className="text-[10px] font-bold text-blue-600 flex items-center gap-1 hover:underline">
                    <Download size={10} /> View SDS
                  </button>
                </div>
              ))}
              {filteredChemicals.length === 0 && (
                <p className="text-center py-4 text-xs text-slate-400 italic">No chemicals found.</p>
              )}
            </div>
          </div>

          <div className="bg-slate-900 rounded-2xl p-6 text-white">
            <h3 className="font-bold mb-4 flex items-center gap-2 text-sm">
              <ShieldAlert size={18} className="text-amber-500" />
              Containment Protocols
            </h3>
            <div className="space-y-3">
              <div className="flex items-start gap-3">
                <div className="bg-white/10 p-1.5 rounded text-amber-500">
                  <Wind size={14} />
                </div>
                <p className="text-[10px] text-slate-300">Assess wind direction before approaching any airborne spill.</p>
              </div>
              <div className="flex items-start gap-3">
                <div className="bg-white/10 p-1.5 rounded text-amber-500">
                  <Trash2 size={14} />
                </div>
                <p className="text-[10px] text-slate-300">Dispose of contaminated absorbents in designated HAZMAT bins.</p>
              </div>
            </div>
          </div>
        </div>

        {/* Active Incidents */}
        <div className="lg:col-span-2 space-y-4">
          {incidents.map(incident => (
            <div key={incident.id} className="bg-white border border-slate-200 rounded-2xl p-5 hover:shadow-md transition-shadow">
              <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mb-4">
                <div className="flex items-center gap-3">
                  <div className={`p-3 rounded-xl ${
                    incident.environmentalImpact === 'High' ? 'bg-red-50 text-red-600' :
                    incident.environmentalImpact === 'Medium' ? 'bg-amber-50 text-amber-600' : 'bg-green-50 text-green-600'
                  }`}>
                    <Droplets size={24} />
                  </div>
                  <div>
                    <h3 className="font-bold text-slate-900">{incident.chemicalName} Spill</h3>
                    <p className="text-[10px] font-bold uppercase tracking-wider text-slate-400">
                      {incident.location} • {new Date(incident.timestamp).toLocaleTimeString()}
                    </p>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <select 
                    value={incident.containmentStatus}
                    onChange={(e) => updateContainment(incident.id, e.target.value as any)}
                    className={`text-xs font-bold uppercase px-3 py-1.5 rounded-lg border-none focus:ring-0 cursor-pointer ${
                      incident.containmentStatus === 'Spreading' ? 'bg-red-100 text-red-700' :
                      incident.containmentStatus === 'Contained' ? 'bg-amber-100 text-amber-700' : 'bg-green-100 text-green-700'
                    }`}
                  >
                    <option value="Spreading">Spreading</option>
                    <option value="Contained">Contained</option>
                    <option value="Cleaned">Cleaned</option>
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-6 pt-4 border-t border-slate-50">
                <div>
                  <label className="block text-[10px] font-bold text-slate-400 uppercase mb-1">Volume</label>
                  <p className="text-sm text-slate-700 font-medium">{incident.volume}</p>
                </div>
                <div>
                  <label className="block text-[10px] font-bold text-slate-400 uppercase mb-1">Impact Level</label>
                  <span className={`text-xs font-bold ${
                    incident.environmentalImpact === 'High' ? 'text-red-600' :
                    incident.environmentalImpact === 'Medium' ? 'text-amber-600' : 'text-green-600'
                  }`}>
                    {incident.environmentalImpact}
                  </span>
                </div>
                <div>
                  <label className="block text-[10px] font-bold text-slate-400 uppercase mb-1">Reported By</label>
                  <p className="text-xs text-slate-600">{incident.reportedBy?.split('@')[0]}</p>
                </div>
              </div>
            </div>
          ))}
          {incidents.length === 0 && (
            <div className="text-center py-12 bg-slate-50 rounded-2xl border-2 border-dashed border-slate-200">
              <CheckCircle2 className="mx-auto text-slate-300 mb-3" size={40} />
              <p className="text-slate-500 font-medium">No active environmental spills reported.</p>
            </div>
          )}
        </div>
      </div>

      {/* Report Spill Modal */}
      {isAdding && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex justify-between items-center">
              <h2 className="text-xl font-bold text-slate-900">Report Chemical Spill</h2>
              <button onClick={() => setIsAdding(false)} className="text-slate-400 hover:text-slate-600">
                <X size={24} />
              </button>
            </div>
            <form onSubmit={handleReportSpill} className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Chemical Name</label>
                <input 
                  type="text" 
                  required
                  value={chemicalName}
                  onChange={(e) => setChemicalName(e.target.value)}
                  placeholder="e.g., Diesel, Sulfuric Acid"
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-amber-500"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Location</label>
                <input 
                  type="text" 
                  required
                  value={location}
                  onChange={(e) => setLocation(e.target.value)}
                  placeholder="e.g., Workshop Bay 4"
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-amber-500"
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Est. Volume</label>
                  <input 
                    type="text" 
                    required
                    value={volume}
                    onChange={(e) => setVolume(e.target.value)}
                    placeholder="e.g., 5 Liters"
                    className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-amber-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Env. Impact</label>
                  <select 
                    value={impact}
                    onChange={(e) => setImpact(e.target.value as any)}
                    className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-amber-500"
                  >
                    <option value="Low">Low</option>
                    <option value="Medium">Medium</option>
                    <option value="High">High</option>
                  </select>
                </div>
              </div>
              <div className="pt-4 flex justify-end gap-3">
                <button 
                  type="button"
                  onClick={() => setIsAdding(false)}
                  className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
                >
                  Cancel
                </button>
                <button 
                  type="submit"
                  className="px-4 py-2 bg-amber-600 text-white rounded-lg hover:bg-amber-700 transition-colors font-bold"
                >
                  Report Incident
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      <style>{`
        .custom-scrollbar::-webkit-scrollbar {
          width: 4px;
        }
        .custom-scrollbar::-webkit-scrollbar-track {
          background: #f1f5f9;
        }
        .custom-scrollbar::-webkit-scrollbar-thumb {
          background: #cbd5e1;
          border-radius: 10px;
        }
      `}</style>
    </div>
  );
}

function Download({ size }: { size: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
      <polyline points="7 10 12 15 17 10" />
      <line x1="12" y1="15" x2="12" y2="3" />
    </svg>
  );
}
