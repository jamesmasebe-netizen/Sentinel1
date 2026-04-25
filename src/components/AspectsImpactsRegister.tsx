import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { ListFilter, Plus, AlertTriangle, ShieldCheck, TrendingUp } from 'lucide-react';

interface AspectRecord {
  id: string;
  activity: string;
  aspect: string;
  impact: string;
  severity: number; // 1-5
  probability: number; // 1-5
  significance: number;
  controlMeasures: string;
  status: 'Significant' | 'Non-Significant';
  createdAt: string;
}

export default function AspectsImpactsRegister() {
  const [aspects, setAspects] = useState<AspectRecord[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [formData, setFormData] = useState({
    activity: '',
    aspect: '',
    impact: '',
    severity: 3,
    probability: 3,
    controlMeasures: ''
  });

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'env_aspects'), orderBy('createdAt', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setAspects(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as AspectRecord[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'env_aspects'));
    return () => unsubscribe();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      const significance = formData.severity * formData.probability;
      const status = significance >= 15 ? 'Significant' : 'Non-Significant';
      
      await addDoc(collection(db, 'env_aspects'), {
        ...formData,
        significance,
        status,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAdding(false);
      setFormData({ activity: '', aspect: '', impact: '', severity: 3, probability: 3, controlMeasures: '' });
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'env_aspects');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">Aspects & Impacts Register (ISO 14001)</h2>
          <p className="text-sm text-slate-500">Identify environmental aspects and assess their significance.</p>
        </div>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700">
          <Plus size={18} /> New Aspect
        </button>
      </div>

      {isAdding && (
        <div className="bg-slate-50 p-4 rounded-lg border border-slate-200 mb-6">
          <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Activity / Process</label>
              <input type="text" required placeholder="e.g., Vehicle Maintenance" value={formData.activity} onChange={e => setFormData({...formData, activity: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Environmental Aspect</label>
              <input type="text" required placeholder="e.g., Oil Spillage" value={formData.aspect} onChange={e => setFormData({...formData, aspect: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Environmental Impact</label>
              <input type="text" required placeholder="e.g., Soil Contamination" value={formData.impact} onChange={e => setFormData({...formData, impact: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div className="grid grid-cols-2 gap-2">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Severity (1-5)</label>
                <input type="number" min="1" max="5" required value={formData.severity} onChange={e => setFormData({...formData, severity: parseInt(e.target.value) || 1})} className="w-full p-2 border rounded-lg" />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Probability (1-5)</label>
                <input type="number" min="1" max="5" required value={formData.probability} onChange={e => setFormData({...formData, probability: parseInt(e.target.value) || 1})} className="w-full p-2 border rounded-lg" />
              </div>
            </div>
            <div className="md:col-span-2">
              <label className="block text-sm font-medium text-slate-700 mb-1">Control Measures</label>
              <textarea required value={formData.controlMeasures} onChange={e => setFormData({...formData, controlMeasures: e.target.value})} placeholder="e.g., Drip trays, Spill kits, Training" className="w-full p-2 border rounded-lg" rows={2}></textarea>
            </div>
            <div className="md:col-span-2 flex justify-end gap-2 mt-2">
              <button type="button" onClick={() => setIsAdding(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg">Cancel</button>
              <button type="submit" className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700">Save Aspect</button>
            </div>
          </form>
        </div>
      )}

      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 text-sm">
              <th className="p-4 font-medium">Activity & Aspect</th>
              <th className="p-4 font-medium">Impact</th>
              <th className="p-4 font-medium text-center">Significance</th>
              <th className="p-4 font-medium">Controls</th>
              <th className="p-4 font-medium">Status</th>
            </tr>
          </thead>
          <tbody>
            {aspects.map(aspect => (
              <tr key={aspect.id} className="border-b border-slate-100 hover:bg-slate-50">
                <td className="p-4">
                  <div className="flex flex-col">
                    <span className="font-medium text-slate-900">{aspect.activity}</span>
                    <span className="text-xs text-slate-500 flex items-center gap-1"><ListFilter size={12}/> {aspect.aspect}</span>
                  </div>
                </td>
                <td className="p-4 text-slate-600 text-sm">{aspect.impact}</td>
                <td className="p-4 text-center">
                  <div className="inline-flex flex-col items-center">
                    <span className="text-lg font-black text-slate-900">{aspect.significance}</span>
                    <span className="text-[10px] text-slate-400 font-bold uppercase">Score</span>
                  </div>
                </td>
                <td className="p-4">
                  <div className="flex items-start gap-2 max-w-[200px]">
                    <ShieldCheck size={16} className="text-green-600 mt-0.5 shrink-0" />
                    <p className="text-xs text-slate-600 truncate" title={aspect.controlMeasures}>{aspect.controlMeasures}</p>
                  </div>
                </td>
                <td className="p-4">
                  {aspect.status === 'Significant' ? (
                    <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-red-100 text-red-800 border border-red-200">
                      <AlertTriangle size={12}/> Significant
                    </span>
                  ) : (
                    <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800 border border-green-200">
                      <TrendingUp size={12}/> Low Risk
                    </span>
                  )}
                </td>
              </tr>
            ))}
            {aspects.length === 0 && !isAdding && (
              <tr>
                <td colSpan={5} className="p-8 text-center text-slate-500">No environmental aspects logged.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
