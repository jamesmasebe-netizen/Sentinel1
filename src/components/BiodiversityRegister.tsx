import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { Leaf, Plus, Camera, MapPin, Search, ShieldCheck } from 'lucide-react';

interface BiodiversityRecord {
  id: string;
  speciesName: string;
  type: 'Flora' | 'Fauna';
  conservationStatus: 'Common' | 'Protected' | 'Endangered' | 'Invasive';
  location: string;
  observationDate: string;
  notes: string;
  createdAt: string;
}

export default function BiodiversityRegister() {
  const [records, setRecords] = useState<BiodiversityRecord[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [formData, setFormData] = useState({
    speciesName: '',
    type: 'Flora' as BiodiversityRecord['type'],
    conservationStatus: 'Common' as BiodiversityRecord['conservationStatus'],
    location: '',
    observationDate: '',
    notes: ''
  });

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'env_biodiversity'), orderBy('observationDate', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setRecords(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as BiodiversityRecord[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'env_biodiversity'));
    return () => unsubscribe();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      await addDoc(collection(db, 'env_biodiversity'), {
        ...formData,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAdding(false);
      setFormData({ speciesName: '', type: 'Flora', conservationStatus: 'Common', location: '', observationDate: '', notes: '' });
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'env_biodiversity');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">Biodiversity Register</h2>
          <p className="text-sm text-slate-500">Track flora and fauna on site and monitor conservation efforts.</p>
        </div>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-emerald-600 text-white px-4 py-2 rounded-lg hover:bg-emerald-700">
          <Plus size={18} /> Log Observation
        </button>
      </div>

      {isAdding && (
        <div className="bg-slate-50 p-4 rounded-lg border border-slate-200 mb-6">
          <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Species Name</label>
              <input type="text" required placeholder="e.g., Cape Weaver, Acacia Karroo" value={formData.speciesName} onChange={e => setFormData({...formData, speciesName: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Type</label>
              <select value={formData.type} onChange={e => setFormData({...formData, type: e.target.value as any})} className="w-full p-2 border rounded-lg">
                <option value="Flora">Flora (Plants)</option>
                <option value="Fauna">Fauna (Animals)</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Conservation Status</label>
              <select value={formData.conservationStatus} onChange={e => setFormData({...formData, conservationStatus: e.target.value as any})} className="w-full p-2 border rounded-lg">
                <option value="Common">Common</option>
                <option value="Protected">Protected</option>
                <option value="Endangered">Endangered</option>
                <option value="Invasive">Invasive / Alien</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Location / Zone</label>
              <input type="text" required placeholder="e.g., North Boundary, Wetland Area" value={formData.location} onChange={e => setFormData({...formData, location: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Observation Date</label>
              <input type="date" required value={formData.observationDate} onChange={e => setFormData({...formData, observationDate: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div className="md:col-span-2">
              <label className="block text-sm font-medium text-slate-700 mb-1">Notes / Description</label>
              <textarea value={formData.notes} onChange={e => setFormData({...formData, notes: e.target.value})} className="w-full p-2 border rounded-lg" rows={2}></textarea>
            </div>
            <div className="md:col-span-2 flex justify-end gap-2 mt-2">
              <button type="button" onClick={() => setIsAdding(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg">Cancel</button>
              <button type="submit" className="px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700">Save Record</button>
            </div>
          </form>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {records.map(record => (
          <div key={record.id} className="border border-slate-200 rounded-xl p-5 bg-white shadow-sm hover:shadow-md transition-shadow">
            <div className="flex justify-between items-start mb-4">
              <div className="bg-emerald-50 p-2 rounded-lg text-emerald-600"><Leaf size={24} /></div>
              <span className={`text-[10px] px-2 py-1 rounded-full font-bold uppercase tracking-wider ${
                record.conservationStatus === 'Endangered' ? 'bg-red-100 text-red-800' :
                record.conservationStatus === 'Protected' ? 'bg-blue-100 text-blue-800' :
                record.conservationStatus === 'Invasive' ? 'bg-orange-100 text-orange-800' :
                'bg-slate-100 text-slate-800'
              }`}>
                {record.conservationStatus}
              </span>
            </div>
            <h3 className="font-bold text-slate-900">{record.speciesName}</h3>
            <p className="text-xs text-slate-500 mb-4 font-bold uppercase tracking-wider">{record.type}</p>
            
            <div className="flex items-center gap-2 text-xs text-slate-600 mb-4">
              <MapPin size={14} className="text-slate-400" />
              <span>{record.location}</span>
            </div>

            <div className="flex items-center justify-between pt-3 border-t border-slate-100 text-[10px] font-bold text-slate-400 uppercase">
              <span>Observed: {new Date(record.observationDate).toLocaleDateString()}</span>
              <div className="flex items-center gap-1"><ShieldCheck size={12} className="text-emerald-500" /> Verified</div>
            </div>
          </div>
        ))}
        {records.length === 0 && !isAdding && (
          <div className="col-span-full p-8 text-center text-slate-500 bg-slate-50 rounded-xl border border-dashed border-slate-300">
            No biodiversity records logged.
          </div>
        )}
      </div>
    </div>
  );
}
