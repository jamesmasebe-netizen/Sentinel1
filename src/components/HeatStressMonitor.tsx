import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { Thermometer, Plus, Sun, Wind, AlertTriangle, CheckCircle2 } from 'lucide-react';

interface HeatRecord {
  id: string;
  location: string;
  dryBulbTemp: number;
  wetBulbTemp: number;
  globeTemp: number;
  wbgt: number;
  humidity: number;
  workIntensity: 'Light' | 'Moderate' | 'Heavy' | 'Very Heavy';
  recommendation: string;
  riskLevel: 'Low' | 'Moderate' | 'High' | 'Extreme';
  recordedAt: string;
}

export default function HeatStressMonitor() {
  const [records, setRecords] = useState<HeatRecord[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [formData, setFormData] = useState({
    location: '',
    dryBulbTemp: 30,
    wetBulbTemp: 25,
    globeTemp: 32,
    humidity: 60,
    workIntensity: 'Moderate' as HeatRecord['workIntensity']
  });

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'heat_stress_records'), orderBy('recordedAt', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as HeatRecord[];
      setRecords(data);
    }, (error) => handleFirestoreError(error, 'list' as any, 'heat_stress_records'));
    return () => unsubscribe();
  }, []);

  const calculateWBGT = (tw: number, tg: number, td: number) => {
    // Outdoor formula: 0.7Tw + 0.2Tg + 0.1Td
    return parseFloat((0.7 * tw + 0.2 * tg + 0.1 * td).toFixed(1));
  };

  const getRiskAndRec = (wbgt: number, intensity: HeatRecord['workIntensity']) => {
    let risk: HeatRecord['riskLevel'] = 'Low';
    let rec = 'Normal work-rest cycles.';

    if (wbgt > 32) {
      risk = 'Extreme';
      rec = 'Stop work or 15 min work / 45 min rest per hour.';
    } else if (wbgt > 30) {
      risk = 'High';
      rec = '30 min work / 30 min rest per hour. Hydrate heavily.';
    } else if (wbgt > 28) {
      risk = 'Moderate';
      rec = '45 min work / 15 min rest per hour.';
    }

    return { risk, rec };
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      const wbgt = calculateWBGT(formData.wetBulbTemp, formData.globeTemp, formData.dryBulbTemp);
      const { risk, rec } = getRiskAndRec(wbgt, formData.workIntensity);
      
      await addDoc(collection(db, 'heat_stress_records'), {
        ...formData,
        wbgt,
        riskLevel: risk,
        recommendation: rec,
        authorId: auth.currentUser.uid,
        recordedAt: new Date().toISOString()
      });
      setIsAdding(false);
      setFormData({ location: '', dryBulbTemp: 30, wetBulbTemp: 25, globeTemp: 32, humidity: 60, workIntensity: 'Moderate' });
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'heat_stress_records');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">Heat Stress & WBGT Monitor</h2>
          <p className="text-sm text-slate-500">Calculate Wet Bulb Globe Temperature and manage work-rest cycles.</p>
        </div>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700">
          <Plus size={18} /> Log Reading
        </button>
      </div>

      {isAdding && (
        <div className="bg-slate-50 p-4 rounded-lg border border-slate-200 mb-6">
          <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Location / Zone</label>
              <input type="text" required placeholder="e.g., Open Pit, Boiler Room" value={formData.location} onChange={e => setFormData({...formData, location: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Work Intensity</label>
              <select value={formData.workIntensity} onChange={e => setFormData({...formData, workIntensity: e.target.value as any})} className="w-full p-2 border rounded-lg">
                <option value="Light">Light (Sitting/Standing)</option>
                <option value="Moderate">Moderate (Walking/Lifting)</option>
                <option value="Heavy">Heavy (Intense manual labor)</option>
                <option value="Very Heavy">Very Heavy (Extreme effort)</option>
              </select>
            </div>
            <div className="grid grid-cols-2 gap-2">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Dry Bulb (°C)</label>
                <input type="number" step="0.1" required value={formData.dryBulbTemp} onChange={e => setFormData({...formData, dryBulbTemp: parseFloat(e.target.value) || 0})} className="w-full p-2 border rounded-lg" />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Wet Bulb (°C)</label>
                <input type="number" step="0.1" required value={formData.wetBulbTemp} onChange={e => setFormData({...formData, wetBulbTemp: parseFloat(e.target.value) || 0})} className="w-full p-2 border rounded-lg" />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-2">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Globe Temp (°C)</label>
                <input type="number" step="0.1" required value={formData.globeTemp} onChange={e => setFormData({...formData, globeTemp: parseFloat(e.target.value) || 0})} className="w-full p-2 border rounded-lg" />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Humidity (%)</label>
                <input type="number" required value={formData.humidity} onChange={e => setFormData({...formData, humidity: parseInt(e.target.value) || 0})} className="w-full p-2 border rounded-lg" />
              </div>
            </div>
            <div className="md:col-span-2 flex justify-end gap-2 mt-2">
              <button type="button" onClick={() => setIsAdding(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg">Cancel</button>
              <button type="submit" className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">Calculate & Save</button>
            </div>
          </form>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {records.map(record => (
          <div key={record.id} className="border border-slate-200 rounded-xl p-5 bg-white shadow-sm hover:shadow-md transition-shadow">
            <div className="flex justify-between items-start mb-4">
              <div className="bg-orange-50 p-2 rounded-lg text-orange-600"><Thermometer size={24} /></div>
              <div className="text-right">
                <span className={`text-xs px-2.5 py-1 rounded-full font-medium ${
                  record.riskLevel === 'Extreme' ? 'bg-red-100 text-red-800' :
                  record.riskLevel === 'High' ? 'bg-orange-100 text-orange-800' :
                  record.riskLevel === 'Moderate' ? 'bg-amber-100 text-amber-800' :
                  'bg-green-100 text-green-800'
                }`}>
                  {record.riskLevel} Risk
                </span>
                <p className="text-[10px] text-slate-400 mt-1 font-bold uppercase">{new Date(record.recordedAt).toLocaleTimeString()}</p>
              </div>
            </div>
            <h3 className="font-bold text-slate-900 text-lg">{record.location}</h3>
            
            <div className="flex items-center gap-6 my-4">
              <div className="text-center">
                <p className="text-3xl font-black text-slate-900">{record.wbgt}°C</p>
                <p className="text-[10px] text-slate-400 font-bold uppercase tracking-tighter">WBGT Index</p>
              </div>
              <div className="flex flex-wrap gap-2">
                <span className="text-xs bg-slate-100 px-2 py-1 rounded flex items-center gap-1"><Sun size={12}/> {record.dryBulbTemp}°</span>
                <span className="text-xs bg-slate-100 px-2 py-1 rounded flex items-center gap-1"><Wind size={12}/> {record.humidity}%</span>
              </div>
            </div>

            <div className="bg-slate-50 p-3 rounded-lg border border-slate-100">
              <div className="flex items-start gap-2">
                <AlertTriangle size={16} className={record.riskLevel === 'Low' ? 'text-green-600' : 'text-amber-600'} />
                <p className="text-xs text-slate-700 font-medium leading-relaxed">{record.recommendation}</p>
              </div>
            </div>
          </div>
        ))}
        {records.length === 0 && !isAdding && (
          <div className="col-span-full p-8 text-center text-slate-500 bg-slate-50 rounded-xl border border-dashed border-slate-300">
            No heat stress readings logged.
          </div>
        )}
      </div>
    </div>
  );
}
