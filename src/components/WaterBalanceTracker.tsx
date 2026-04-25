import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { Droplets, Plus, TrendingUp, TrendingDown, AlertCircle, CheckCircle2 } from 'lucide-react';

interface WaterReading {
  id: string;
  meterName: string;
  location: string;
  readingValue: number;
  unit: 'm3' | 'liters' | 'kl';
  readingDate: string;
  previousReading?: number;
  consumption: number;
  status: 'Normal' | 'High' | 'Leak Suspected';
  createdAt: string;
}

export default function WaterBalanceTracker() {
  const [readings, setReadings] = useState<WaterReading[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [formData, setFormData] = useState({
    meterName: '',
    location: '',
    readingValue: 0,
    unit: 'm3' as WaterReading['unit'],
    readingDate: ''
  });

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'env_water_readings'), orderBy('readingDate', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setReadings(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as WaterReading[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'env_water_readings'));
    return () => unsubscribe();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      const prev = readings.find(r => r.meterName === formData.meterName);
      const consumption = prev ? formData.readingValue - prev.readingValue : 0;
      const status = consumption > 100 ? 'High' : 'Normal';
      
      await addDoc(collection(db, 'env_water_readings'), {
        ...formData,
        previousReading: prev?.readingValue || 0,
        consumption,
        status,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAdding(false);
      setFormData({ meterName: '', location: '', readingValue: 0, unit: 'm3', readingDate: '' });
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'env_water_readings');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">Water Balance & Consumption Tracker</h2>
          <p className="text-sm text-slate-500">Monitor water usage across site and detect potential leaks.</p>
        </div>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700">
          <Plus size={18} /> Log Reading
        </button>
      </div>

      {isAdding && (
        <div className="bg-slate-50 p-4 rounded-lg border border-slate-200 mb-6">
          <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Meter Name / ID</label>
              <input type="text" required placeholder="e.g., Main Supply, Cooling Tower" value={formData.meterName} onChange={e => setFormData({...formData, meterName: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Location</label>
              <input type="text" required value={formData.location} onChange={e => setFormData({...formData, location: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div className="grid grid-cols-2 gap-2">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Reading Value</label>
                <input type="number" step="0.01" required value={formData.readingValue} onChange={e => setFormData({...formData, readingValue: parseFloat(e.target.value) || 0})} className="w-full p-2 border rounded-lg" />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Unit</label>
                <select value={formData.unit} onChange={e => setFormData({...formData, unit: e.target.value as any})} className="w-full p-2 border rounded-lg">
                  <option value="m3">m³</option>
                  <option value="kl">kl</option>
                  <option value="liters">liters</option>
                </select>
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Reading Date</label>
              <input type="date" required value={formData.readingDate} onChange={e => setFormData({...formData, readingDate: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div className="md:col-span-2 flex justify-end gap-2 mt-2">
              <button type="button" onClick={() => setIsAdding(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg">Cancel</button>
              <button type="submit" className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">Save Reading</button>
            </div>
          </form>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {readings.map(reading => (
          <div key={reading.id} className="border border-slate-200 rounded-xl p-5 bg-white shadow-sm hover:shadow-md transition-shadow">
            <div className="flex justify-between items-start mb-4">
              <div className="bg-blue-50 p-2 rounded-lg text-blue-600"><Droplets size={24} /></div>
              <div className="text-right">
                <span className={`text-xs px-2.5 py-1 rounded-full font-medium ${
                  reading.status === 'Normal' ? 'bg-green-100 text-green-800' : 'bg-amber-100 text-amber-800'
                }`}>
                  {reading.status}
                </span>
                <p className="text-[10px] text-slate-400 mt-1 font-bold uppercase">{new Date(reading.readingDate).toLocaleDateString()}</p>
              </div>
            </div>
            <h3 className="font-bold text-slate-900">{reading.meterName}</h3>
            <p className="text-xs text-slate-500 mb-4">{reading.location}</p>
            
            <div className="flex items-center gap-6 my-4">
              <div className="text-center">
                <p className="text-2xl font-black text-slate-900">{reading.consumption} {reading.unit}</p>
                <p className="text-[10px] text-slate-400 font-bold uppercase tracking-tighter">Consumption</p>
              </div>
              <div className="flex flex-col text-xs text-slate-500">
                <span className="flex items-center gap-1"><TrendingUp size={12}/> {reading.readingValue}</span>
                <span className="flex items-center gap-1"><TrendingDown size={12}/> {reading.previousReading}</span>
              </div>
            </div>

            {reading.status !== 'Normal' && (
              <div className="mt-4 p-2 bg-amber-50 rounded flex items-center gap-2 text-amber-700 text-[10px] font-bold uppercase tracking-wider">
                <AlertCircle size={14} /> High Consumption Detected
              </div>
            )}
          </div>
        ))}
        {readings.length === 0 && !isAdding && (
          <div className="col-span-full p-8 text-center text-slate-500 bg-slate-50 rounded-xl border border-dashed border-slate-300">
            No water readings logged.
          </div>
        )}
      </div>
    </div>
  );
}
