import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { Ambulance, Plus, MapPin, Phone, Hospital } from 'lucide-react';

interface MedevacPlan {
  id: string;
  siteName: string;
  primaryHospital: string;
  hospitalContact: string;
  landingZoneCoords: string;
  medevacProvider: string;
  providerContact: string;
  lastDrillDate: string;
  createdAt: string;
}

export default function MedevacPlanning() {
  const [plans, setPlans] = useState<MedevacPlan[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [formData, setFormData] = useState({
    siteName: '',
    primaryHospital: '',
    hospitalContact: '',
    landingZoneCoords: '',
    medevacProvider: '',
    providerContact: '',
    lastDrillDate: ''
  });

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'medevac_plans'), orderBy('createdAt', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as MedevacPlan[];
      setPlans(data);
    }, (error) => handleFirestoreError(error, 'list' as any, 'medevac_plans'));
    return () => unsubscribe();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      await addDoc(collection(db, 'medevac_plans'), {
        ...formData,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAdding(false);
      setFormData({ siteName: '', primaryHospital: '', hospitalContact: '', landingZoneCoords: '', medevacProvider: '', providerContact: '', lastDrillDate: '' });
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'medevac_plans');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">Medical Evacuation (Medevac) Plans</h2>
          <p className="text-sm text-slate-500">Site-specific emergency medical response and extraction plans.</p>
        </div>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700">
          <Plus size={18} /> Add Site Plan
        </button>
      </div>

      {isAdding && (
        <div className="bg-slate-50 p-4 rounded-lg border border-slate-200 mb-6">
          <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Site / Project Name</label>
              <input type="text" required value={formData.siteName} onChange={e => setFormData({...formData, siteName: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Landing Zone Coordinates</label>
              <input type="text" required placeholder={"e.g., 26°12'15.5\"S 28°02'44.4\"E"} value={formData.landingZoneCoords} onChange={e => setFormData({...formData, landingZoneCoords: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Primary Trauma Hospital</label>
              <input type="text" required value={formData.primaryHospital} onChange={e => setFormData({...formData, primaryHospital: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Hospital Contact</label>
              <input type="text" required value={formData.hospitalContact} onChange={e => setFormData({...formData, hospitalContact: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Medevac Provider (Aviation/Ambulance)</label>
              <input type="text" required value={formData.medevacProvider} onChange={e => setFormData({...formData, medevacProvider: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Provider Emergency Contact</label>
              <input type="text" required value={formData.providerContact} onChange={e => setFormData({...formData, providerContact: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Last Drill Date</label>
              <input type="date" required value={formData.lastDrillDate} onChange={e => setFormData({...formData, lastDrillDate: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div className="md:col-span-2 flex justify-end gap-2 mt-2">
              <button type="button" onClick={() => setIsAdding(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg">Cancel</button>
              <button type="submit" className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">Save Plan</button>
            </div>
          </form>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {plans.map(plan => (
          <div key={plan.id} className="border border-slate-200 rounded-xl p-5 bg-white shadow-sm hover:shadow-md transition-shadow">
            <div className="flex items-center gap-3 mb-4 border-b border-slate-100 pb-4">
              <div className="bg-red-50 p-3 rounded-xl text-red-600"><Ambulance size={28} /></div>
              <div>
                <h3 className="font-bold text-slate-900 text-lg">{plan.siteName}</h3>
                <p className="text-sm text-slate-500 flex items-center gap-1"><MapPin size={14}/> LZ: {plan.landingZoneCoords}</p>
              </div>
            </div>
            
            <div className="grid grid-cols-2 gap-4 mb-4">
              <div className="space-y-1">
                <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Hospital</p>
                <p className="text-sm font-medium text-slate-800 flex items-center gap-1"><Hospital size={14} className="text-slate-400"/> {plan.primaryHospital}</p>
                <p className="text-sm text-slate-600 flex items-center gap-1"><Phone size={14} className="text-slate-400"/> {plan.hospitalContact}</p>
              </div>
              <div className="space-y-1">
                <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Medevac Provider</p>
                <p className="text-sm font-medium text-slate-800">{plan.medevacProvider}</p>
                <p className="text-sm text-slate-600 flex items-center gap-1"><Phone size={14} className="text-slate-400"/> {plan.providerContact}</p>
              </div>
            </div>

            <div className="bg-slate-50 p-3 rounded-lg flex justify-between items-center text-sm">
              <span className="text-slate-500">Last Evacuation Drill:</span>
              <span className="font-medium text-slate-700">{new Date(plan.lastDrillDate).toLocaleDateString()}</span>
            </div>
          </div>
        ))}
        {plans.length === 0 && !isAdding && (
          <div className="col-span-full p-8 text-center text-slate-500 bg-slate-50 rounded-xl border border-dashed border-slate-300">
            No Medevac plans configured.
          </div>
        )}
      </div>
    </div>
  );
}
