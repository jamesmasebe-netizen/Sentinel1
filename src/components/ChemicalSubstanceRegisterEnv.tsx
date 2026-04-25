import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { Beaker, Plus, ShieldCheck, AlertCircle, Droplets } from 'lucide-react';

interface ChemicalRecord {
  id: string;
  chemicalName: string;
  storageLocation: string;
  volumeStored: number;
  unit: 'liters' | 'kg' | 'tons';
  bundingCompliant: boolean;
  msdsAvailable: boolean;
  hazardClass: string;
  lastInspectionDate: string;
  createdAt: string;
}

export default function ChemicalSubstanceRegisterEnv() {
  const [chemicals, setChemicals] = useState<ChemicalRecord[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [formData, setFormData] = useState({
    chemicalName: '',
    storageLocation: '',
    volumeStored: 0,
    unit: 'liters' as ChemicalRecord['unit'],
    bundingCompliant: false,
    msdsAvailable: false,
    hazardClass: '',
    lastInspectionDate: ''
  });

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'env_chemical_register'), orderBy('createdAt', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setChemicals(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as ChemicalRecord[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'env_chemical_register'));
    return () => unsubscribe();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      await addDoc(collection(db, 'env_chemical_register'), {
        ...formData,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAdding(false);
      setFormData({ chemicalName: '', storageLocation: '', volumeStored: 0, unit: 'liters', bundingCompliant: false, msdsAvailable: false, hazardClass: '', lastInspectionDate: '' });
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'env_chemical_register');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">Chemical Substance Register (Environmental)</h2>
          <p className="text-sm text-slate-500">Track storage volumes, bunding compliance, and MSDS for hazardous chemicals.</p>
        </div>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-indigo-600 text-white px-4 py-2 rounded-lg hover:bg-indigo-700">
          <Plus size={18} /> Add Substance
        </button>
      </div>

      {isAdding && (
        <div className="bg-slate-50 p-4 rounded-lg border border-slate-200 mb-6">
          <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Chemical Name</label>
              <input type="text" required placeholder="e.g., Diesel, Sulfuric Acid" value={formData.chemicalName} onChange={e => setFormData({...formData, chemicalName: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Storage Location</label>
              <input type="text" required placeholder="e.g., Bulk Tank Farm, Chemical Store" value={formData.storageLocation} onChange={e => setFormData({...formData, storageLocation: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div className="grid grid-cols-2 gap-2">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Volume Stored</label>
                <input type="number" required value={formData.volumeStored} onChange={e => setFormData({...formData, volumeStored: parseFloat(e.target.value) || 0})} className="w-full p-2 border rounded-lg" />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Unit</label>
                <select value={formData.unit} onChange={e => setFormData({...formData, unit: e.target.value as any})} className="w-full p-2 border rounded-lg">
                  <option value="liters">liters</option>
                  <option value="kg">kg</option>
                  <option value="tons">tons</option>
                </select>
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Hazard Class</label>
              <input type="text" required placeholder="e.g., Class 3 (Flammable)" value={formData.hazardClass} onChange={e => setFormData({...formData, hazardClass: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div className="flex items-center gap-4 py-2">
              <label className="flex items-center gap-2 text-sm font-medium text-slate-700">
                <input type="checkbox" checked={formData.bundingCompliant} onChange={e => setFormData({...formData, bundingCompliant: e.target.checked})} className="rounded border-slate-300 text-indigo-600 focus:ring-indigo-500" />
                Bunding Compliant
              </label>
              <label className="flex items-center gap-2 text-sm font-medium text-slate-700">
                <input type="checkbox" checked={formData.msdsAvailable} onChange={e => setFormData({...formData, msdsAvailable: e.target.checked})} className="rounded border-slate-300 text-indigo-600 focus:ring-indigo-500" />
                MSDS Available
              </label>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Last Inspection Date</label>
              <input type="date" required value={formData.lastInspectionDate} onChange={e => setFormData({...formData, lastInspectionDate: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div className="md:col-span-2 flex justify-end gap-2 mt-2">
              <button type="button" onClick={() => setIsAdding(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg">Cancel</button>
              <button type="submit" className="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700">Save Substance</button>
            </div>
          </form>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {chemicals.map(chemical => (
          <div key={chemical.id} className="border border-slate-200 rounded-xl p-5 bg-white shadow-sm hover:shadow-md transition-shadow">
            <div className="flex justify-between items-start mb-4">
              <div className="bg-indigo-50 p-2 rounded-lg text-indigo-600"><Beaker size={24} /></div>
              <div className="text-right">
                <p className="text-2xl font-black text-slate-900">{chemical.volumeStored} <span className="text-xs font-normal text-slate-500">{chemical.unit}</span></p>
                <p className="text-[10px] text-slate-400 font-bold uppercase tracking-tighter">Current Inventory</p>
              </div>
            </div>
            <h3 className="font-bold text-slate-900">{chemical.chemicalName}</h3>
            <p className="text-xs text-slate-500 mb-4">{chemical.storageLocation}</p>
            
            <div className="space-y-2 mb-4">
              <div className="flex items-center justify-between text-xs">
                <span className="text-slate-400">Hazard Class:</span>
                <span className="text-slate-700 font-medium">{chemical.hazardClass}</span>
              </div>
              <div className="flex items-center justify-between text-xs">
                <span className="text-slate-400">Bunding:</span>
                <span className={`font-bold ${chemical.bundingCompliant ? 'text-green-600' : 'text-red-600'}`}>
                  {chemical.bundingCompliant ? 'Compliant' : 'Non-Compliant'}
                </span>
              </div>
            </div>

            <div className="flex items-center justify-between pt-3 border-t border-slate-100">
              <div className="flex items-center gap-1 text-[10px] font-bold text-slate-400 uppercase">
                <Droplets size={12} /> Last Inspected: {new Date(chemical.lastInspectionDate).toLocaleDateString()}
              </div>
              {chemical.msdsAvailable && (
                <span className="text-green-600"><ShieldCheck size={16} /></span>
              )}
            </div>
          </div>
        ))}
        {chemicals.length === 0 && !isAdding && (
          <div className="col-span-full p-8 text-center text-slate-500 bg-slate-50 rounded-xl border border-dashed border-slate-300">
            No chemicals logged in the register.
          </div>
        )}
      </div>
    </div>
  );
}
