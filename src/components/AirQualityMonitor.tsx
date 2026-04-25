import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { Wind, Plus, TrendingUp, TrendingDown, AlertCircle, CheckCircle2 } from 'lucide-react';

interface AirReading {
  id: string;
  location: string;
  parameter: 'PM10' | 'PM2.5' | 'SO2' | 'NO2' | 'CO' | 'O3';
  value: number;
  unit: string;
  limit: number;
  readingDate: string;
  status: 'Normal' | 'Warning' | 'Exceeded';
  createdAt: string;
}

export default function AirQualityMonitor() {
  const [readings, setReadings] = useState<AirReading[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [formData, setFormData] = useState({
    location: '',
    parameter: 'PM10' as AirReading['parameter'],
    value: 0,
    unit: 'µg/m3',
    limit: 75,
    readingDate: ''
  });

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'env_air_readings'), orderBy('readingDate', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setReadings(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as AirReading[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'env_air_readings'));
    return () => unsubscribe();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      const status = formData.value >= formData.limit ? 'Exceeded' : (formData.value >= formData.limit * 0.8 ? 'Warning' : 'Normal');
      
      await addDoc(collection(db, 'env_air_readings'), {
        ...formData,
        status,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAdding(false);
      setFormData({ location: '', parameter: 'PM10', value: 0, unit: 'µg/m3', limit: 75, readingDate: '' });
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'env_air_readings');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">Air Quality & Emissions Monitor</h2>
          <p className="text-sm text-slate-500">Monitor ambient air quality and stack emissions against permit limits.</p>
        </div>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700">
          <Plus size={18} /> Log Reading
        </button>
      </div>

      {isAdding && (
        <div className="bg-slate-50 p-4 rounded-lg border border-slate-200 mb-6">
          <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Location / Stack ID</label>
              <input type="text" required placeholder="e.g., Boiler Stack 1, Site Boundary" value={formData.location} onChange={e => setFormData({...formData, location: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Parameter</label>
              <select value={formData.parameter} onChange={e => setFormData({...formData, parameter: e.target.value as any})} className="w-full p-2 border rounded-lg">
                <option value="PM10">PM10 (Particulate Matter)</option>
                <option value="PM2.5">PM2.5 (Fine Particulate)</option>
                <option value="SO2">SO2 (Sulfur Dioxide)</option>
                <option value="NO2">NO2 (Nitrogen Dioxide)</option>
                <option value="CO">CO (Carbon Monoxide)</option>
                <option value="O3">O3 (Ozone)</option>
              </select>
            </div>
            <div className="grid grid-cols-3 gap-2">
              <div className="col-span-1">
                <label className="block text-sm font-medium text-slate-700 mb-1">Value</label>
                <input type="number" step="0.01" required value={formData.value} onChange={e => setFormData({...formData, value: parseFloat(e.target.value) || 0})} className="w-full p-2 border rounded-lg" />
              </div>
              <div className="col-span-1">
                <label className="block text-sm font-medium text-slate-700 mb-1">Unit</label>
                <input type="text" required value={formData.unit} onChange={e => setFormData({...formData, unit: e.target.value})} className="w-full p-2 border rounded-lg" />
              </div>
              <div className="col-span-1">
                <label className="block text-sm font-medium text-slate-700 mb-1">Limit</label>
                <input type="number" step="0.01" required value={formData.limit} onChange={e => setFormData({...formData, limit: parseFloat(e.target.value) || 0})} className="w-full p-2 border rounded-lg" />
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Reading Date</label>
              <input type="date" required value={formData.readingDate} onChange={e => setFormData({...formData, readingDate: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div className="md:col-span-2 flex justify-end gap-2 mt-2">
              <button type="button" onClick={() => setIsAdding(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg">Cancel</button>
              <button type="submit" className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700">Save Reading</button>
            </div>
          </form>
        </div>
      )}

      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 text-sm">
              <th className="p-4 font-medium">Date</th>
              <th className="p-4 font-medium">Location</th>
              <th className="p-4 font-medium">Parameter</th>
              <th className="p-4 font-medium">Value / Limit</th>
              <th className="p-4 font-medium">Status</th>
            </tr>
          </thead>
          <tbody>
            {readings.map(reading => (
              <tr key={reading.id} className="border-b border-slate-100 hover:bg-slate-50">
                <td className="p-4 text-slate-600">{new Date(reading.readingDate).toLocaleDateString()}</td>
                <td className="p-4 font-medium text-slate-900">{reading.location}</td>
                <td className="p-4 text-slate-600 font-bold">{reading.parameter}</td>
                <td className="p-4 text-slate-600">
                  <div className="flex flex-col">
                    <span className="font-bold">{reading.value} {reading.unit}</span>
                    <span className="text-[10px] text-slate-400 font-bold uppercase tracking-wider">Limit: {reading.limit} {reading.unit}</span>
                  </div>
                </td>
                <td className="p-4">
                  {reading.status === 'Normal' && <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800"><CheckCircle2 size={12}/> Normal</span>}
                  {reading.status === 'Warning' && <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-amber-100 text-amber-800"><AlertCircle size={12}/> Warning</span>}
                  {reading.status === 'Exceeded' && <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-red-100 text-red-800"><AlertCircle size={12}/> Exceeded</span>}
                </td>
              </tr>
            ))}
            {readings.length === 0 && !isAdding && (
              <tr>
                <td colSpan={5} className="p-8 text-center text-slate-500">No air quality readings logged.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
