import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { AlertTriangle, Plus, FileText, User, Calendar, CheckCircle2 } from 'lucide-react';

interface FatalClaim {
  id: string;
  deceasedEmployee: string;
  incidentDate: string;
  claimNumber: string;
  wcl11Submitted: boolean;
  wcl12Submitted: boolean;
  dependentsNotified: boolean;
  status: 'Investigation' | 'Submitted' | 'Awarded' | 'Closed';
  createdAt: string;
}

export default function FatalClaimManagement() {
  const [claims, setClaims] = useState<FatalClaim[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [formData, setFormData] = useState({
    deceasedEmployee: '',
    incidentDate: '',
    claimNumber: '',
    wcl11Submitted: false,
    wcl12Submitted: false,
    dependentsNotified: false,
    status: 'Investigation' as FatalClaim['status']
  });

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'coida_fatal_claims'), orderBy('createdAt', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setClaims(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as FatalClaim[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'coida_fatal_claims'));
    return () => unsubscribe();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      await addDoc(collection(db, 'coida_fatal_claims'), {
        ...formData,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAdding(false);
      setFormData({ deceasedEmployee: '', incidentDate: '', claimNumber: '', wcl11Submitted: false, wcl12Submitted: false, dependentsNotified: false, status: 'Investigation' });
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'coida_fatal_claims');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">Fatal Claim Management</h2>
          <p className="text-sm text-slate-500">Specialized workflow for fatal accidents (W.Cl.11, W.Cl.12).</p>
        </div>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-red-600 text-white px-4 py-2 rounded-lg hover:bg-red-700">
          <Plus size={18} /> Log Fatal Claim
        </button>
      </div>

      {isAdding && (
        <div className="bg-slate-50 p-4 rounded-lg border border-slate-200 mb-6">
          <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Deceased Employee Name</label>
              <input type="text" required value={formData.deceasedEmployee} onChange={e => setFormData({...formData, deceasedEmployee: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Incident Date</label>
              <input type="date" required value={formData.incidentDate} onChange={e => setFormData({...formData, incidentDate: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Claim Number</label>
              <input type="text" required value={formData.claimNumber} onChange={e => setFormData({...formData, claimNumber: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Status</label>
              <select value={formData.status} onChange={e => setFormData({...formData, status: e.target.value as any})} className="w-full p-2 border rounded-lg">
                <option value="Investigation">Investigation</option>
                <option value="Submitted">Submitted</option>
                <option value="Awarded">Awarded</option>
                <option value="Closed">Closed</option>
              </select>
            </div>
            <div className="flex items-center gap-4 md:col-span-2 py-2">
              <label className="flex items-center gap-2 text-sm font-medium text-slate-700">
                <input type="checkbox" checked={formData.wcl11Submitted} onChange={e => setFormData({...formData, wcl11Submitted: e.target.checked})} className="rounded border-slate-300 text-red-600 focus:ring-red-500" />
                W.Cl.11 Submitted
              </label>
              <label className="flex items-center gap-2 text-sm font-medium text-slate-700">
                <input type="checkbox" checked={formData.wcl12Submitted} onChange={e => setFormData({...formData, wcl12Submitted: e.target.checked})} className="rounded border-slate-300 text-red-600 focus:ring-red-500" />
                W.Cl.12 Submitted
              </label>
              <label className="flex items-center gap-2 text-sm font-medium text-slate-700">
                <input type="checkbox" checked={formData.dependentsNotified} onChange={e => setFormData({...formData, dependentsNotified: e.target.checked})} className="rounded border-slate-300 text-red-600 focus:ring-red-500" />
                Dependents Notified
              </label>
            </div>
            <div className="md:col-span-2 flex justify-end gap-2 mt-2">
              <button type="button" onClick={() => setIsAdding(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg">Cancel</button>
              <button type="submit" className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700">Save Claim</button>
            </div>
          </form>
        </div>
      )}

      <div className="space-y-4">
        {claims.map(claim => (
          <div key={claim.id} className="border border-slate-200 rounded-xl p-5 bg-white shadow-sm hover:shadow-md transition-shadow">
            <div className="flex justify-between items-start mb-4">
              <div className="flex items-center gap-3">
                <div className="bg-red-50 p-2 rounded-lg text-red-600"><AlertTriangle size={24} /></div>
                <div>
                  <h3 className="font-bold text-slate-900">{claim.deceasedEmployee}</h3>
                  <p className="text-xs text-slate-500">Incident: {new Date(claim.incidentDate).toLocaleDateString()}</p>
                </div>
              </div>
              <span className={`text-[10px] px-2 py-1 rounded-full font-bold uppercase tracking-wider ${
                claim.status === 'Awarded' ? 'bg-green-100 text-green-800' :
                claim.status === 'Closed' ? 'bg-slate-100 text-slate-800' :
                'bg-red-100 text-red-800'
              }`}>
                {claim.status}
              </span>
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
              <div className={`p-3 rounded-lg border ${claim.wcl11Submitted ? 'bg-green-50 border-green-100 text-green-700' : 'bg-slate-50 border-slate-100 text-slate-400'}`}>
                <div className="flex items-center justify-between mb-1">
                  <span className="text-[10px] font-bold uppercase">W.Cl.11</span>
                  {claim.wcl11Submitted && <CheckCircle2 size={12} />}
                </div>
                <p className="text-xs font-medium">Notice of Death</p>
              </div>
              <div className={`p-3 rounded-lg border ${claim.wcl12Submitted ? 'bg-green-50 border-green-100 text-green-700' : 'bg-slate-50 border-slate-100 text-slate-400'}`}>
                <div className="flex items-center justify-between mb-1">
                  <span className="text-[10px] font-bold uppercase">W.Cl.12</span>
                  {claim.wcl12Submitted && <CheckCircle2 size={12} />}
                </div>
                <p className="text-xs font-medium">Claim for Compensation</p>
              </div>
              <div className={`p-3 rounded-lg border ${claim.dependentsNotified ? 'bg-green-50 border-green-100 text-green-700' : 'bg-slate-50 border-slate-100 text-slate-400'}`}>
                <div className="flex items-center justify-between mb-1">
                  <span className="text-[10px] font-bold uppercase">Dependents</span>
                  {claim.dependentsNotified && <CheckCircle2 size={12} />}
                </div>
                <p className="text-xs font-medium">Notification Status</p>
              </div>
            </div>

            <div className="flex items-center justify-between text-xs text-slate-400">
              <span>Claim: <span className="text-slate-700 font-medium">{claim.claimNumber}</span></span>
              <span>Logged: {new Date(claim.createdAt).toLocaleDateString()}</span>
            </div>
          </div>
        ))}
        {claims.length === 0 && !isAdding && (
          <div className="p-8 text-center text-slate-500 bg-slate-50 rounded-xl border border-dashed border-slate-300">
            No fatal claims logged.
          </div>
        )}
      </div>
    </div>
  );
}
