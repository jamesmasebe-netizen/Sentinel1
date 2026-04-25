import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { ShieldAlert, Plus, CheckCircle2, AlertTriangle, Clock, Calendar } from 'lucide-react';

interface EmergencyDrill {
  id: string;
  drillType: 'Spill' | 'Fire' | 'Evacuation' | 'Chemical Leak';
  location: string;
  drillDate: string;
  participantsCount: number;
  outcome: 'Satisfactory' | 'Needs Improvement' | 'Failed';
  notes: string;
  createdAt: string;
}

export default function EnvironmentalEmergencyPreparedness() {
  const [drills, setDrills] = useState<EmergencyDrill[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [formData, setFormData] = useState({
    drillType: 'Spill' as EmergencyDrill['drillType'],
    location: '',
    drillDate: '',
    participantsCount: 0,
    outcome: 'Satisfactory' as EmergencyDrill['outcome'],
    notes: ''
  });

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'env_drills'), orderBy('drillDate', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setDrills(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as EmergencyDrill[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'env_drills'));
    return () => unsubscribe();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      await addDoc(collection(db, 'env_drills'), {
        ...formData,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAdding(false);
      setFormData({ drillType: 'Spill', location: '', drillDate: '', participantsCount: 0, outcome: 'Satisfactory', notes: '' });
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'env_drills');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">Emergency Preparedness (Environmental)</h2>
          <p className="text-sm text-slate-500">Log and track environmental emergency drills and equipment checks.</p>
        </div>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-orange-600 text-white px-4 py-2 rounded-lg hover:bg-orange-700">
          <Plus size={18} /> Log Drill
        </button>
      </div>

      {isAdding && (
        <div className="bg-slate-50 p-4 rounded-lg border border-slate-200 mb-6">
          <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Drill Type</label>
              <select value={formData.drillType} onChange={e => setFormData({...formData, drillType: e.target.value as any})} className="w-full p-2 border rounded-lg">
                <option value="Spill">Spill Response</option>
                <option value="Fire">Fire / Explosion</option>
                <option value="Evacuation">Site Evacuation</option>
                <option value="Chemical Leak">Chemical Leak / Release</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Location</label>
              <input type="text" required placeholder="e.g., Warehouse A, Fuel Farm" value={formData.location} onChange={e => setFormData({...formData, location: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Drill Date</label>
              <input type="date" required value={formData.drillDate} onChange={e => setFormData({...formData, drillDate: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Participants Count</label>
              <input type="number" required value={formData.participantsCount} onChange={e => setFormData({...formData, participantsCount: parseInt(e.target.value) || 0})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Outcome</label>
              <select value={formData.outcome} onChange={e => setFormData({...formData, outcome: e.target.value as any})} className="w-full p-2 border rounded-lg">
                <option value="Satisfactory">Satisfactory</option>
                <option value="Needs Improvement">Needs Improvement</option>
                <option value="Failed">Failed</option>
              </select>
            </div>
            <div className="md:col-span-2">
              <label className="block text-sm font-medium text-slate-700 mb-1">Notes / Findings</label>
              <textarea value={formData.notes} onChange={e => setFormData({...formData, notes: e.target.value})} className="w-full p-2 border rounded-lg" rows={2}></textarea>
            </div>
            <div className="md:col-span-2 flex justify-end gap-2 mt-2">
              <button type="button" onClick={() => setIsAdding(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg">Cancel</button>
              <button type="submit" className="px-4 py-2 bg-orange-600 text-white rounded-lg hover:bg-orange-700">Save Drill</button>
            </div>
          </form>
        </div>
      )}

      <div className="space-y-4">
        {drills.map(drill => (
          <div key={drill.id} className="border border-slate-200 rounded-xl p-5 bg-white shadow-sm hover:shadow-md transition-shadow">
            <div className="flex justify-between items-start mb-4">
              <div className="flex items-center gap-3">
                <div className="bg-orange-50 p-2 rounded-lg text-orange-600"><ShieldAlert size={24} /></div>
                <div>
                  <h3 className="font-bold text-slate-900">{drill.drillType} Drill</h3>
                  <p className="text-xs text-slate-500 font-bold uppercase tracking-wider">{drill.location}</p>
                </div>
              </div>
              <span className={`text-[10px] px-2 py-1 rounded-full font-bold uppercase tracking-wider ${
                drill.outcome === 'Satisfactory' ? 'bg-green-100 text-green-800' :
                drill.outcome === 'Failed' ? 'bg-red-100 text-red-800' :
                'bg-amber-100 text-amber-800'
              }`}>
                {drill.outcome}
              </span>
            </div>
            
            <p className="text-sm text-slate-600 mb-4 italic">{drill.notes}</p>
            
            <div className="flex items-center justify-between text-xs text-slate-400 pt-3 border-t border-slate-100">
              <span className="flex items-center gap-1"><Calendar size={12}/> Date: <span className="text-slate-700 font-medium">{new Date(drill.drillDate).toLocaleDateString()}</span></span>
              <span className="flex items-center gap-1"><Clock size={12}/> Participants: <span className="font-bold">{drill.participantsCount}</span></span>
            </div>
          </div>
        ))}
        {drills.length === 0 && !isAdding && (
          <div className="p-8 text-center text-slate-500 bg-slate-50 rounded-xl border border-dashed border-slate-300">
            No emergency drills logged.
          </div>
        )}
      </div>
    </div>
  );
}
