import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { Stethoscope, Plus, FileText, User, Calendar, CheckCircle2, AlertCircle } from 'lucide-react';

interface DiseaseClaim {
  id: string;
  employeeName: string;
  diseaseType: string;
  claimNumber: string;
  wcl1Submitted: boolean;
  wcl14Submitted: boolean;
  exposureHistoryLogged: boolean;
  status: 'Investigation' | 'Submitted' | 'Accepted' | 'Rejected';
  createdAt: string;
}

export default function OccupationalDiseaseWorkflow() {
  const [claims, setClaims] = useState<DiseaseClaim[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [formData, setFormData] = useState({
    employeeName: '',
    diseaseType: '',
    claimNumber: '',
    wcl1Submitted: false,
    wcl14Submitted: false,
    exposureHistoryLogged: false,
    status: 'Investigation' as DiseaseClaim['status']
  });

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'coida_disease_claims'), orderBy('createdAt', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setClaims(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as DiseaseClaim[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'coida_disease_claims'));
    return () => unsubscribe();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      await addDoc(collection(db, 'coida_disease_claims'), {
        ...formData,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAdding(false);
      setFormData({ employeeName: '', diseaseType: '', claimNumber: '', wcl1Submitted: false, wcl14Submitted: false, exposureHistoryLogged: false, status: 'Investigation' });
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'coida_disease_claims');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">Occupational Disease Workflow</h2>
          <p className="text-sm text-slate-500">Specialized tracking for occupational diseases (W.Cl.1, W.Cl.14).</p>
        </div>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-purple-600 text-white px-4 py-2 rounded-lg hover:bg-purple-700">
          <Plus size={18} /> Log Disease Claim
        </button>
      </div>

      {isAdding && (
        <div className="bg-slate-50 p-4 rounded-lg border border-slate-200 mb-6">
          <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Employee Name</label>
              <input type="text" required value={formData.employeeName} onChange={e => setFormData({...formData, employeeName: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Disease Type</label>
              <input type="text" required placeholder="e.g., Noise Induced Hearing Loss, Silicosis" value={formData.diseaseType} onChange={e => setFormData({...formData, diseaseType: e.target.value})} className="w-full p-2 border rounded-lg" />
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
                <option value="Accepted">Accepted</option>
                <option value="Rejected">Rejected</option>
              </select>
            </div>
            <div className="flex items-center gap-4 md:col-span-2 py-2">
              <label className="flex items-center gap-2 text-sm font-medium text-slate-700">
                <input type="checkbox" checked={formData.wcl1Submitted} onChange={e => setFormData({...formData, wcl1Submitted: e.target.checked})} className="rounded border-slate-300 text-purple-600 focus:ring-purple-500" />
                W.Cl.1 Submitted
              </label>
              <label className="flex items-center gap-2 text-sm font-medium text-slate-700">
                <input type="checkbox" checked={formData.wcl14Submitted} onChange={e => setFormData({...formData, wcl14Submitted: e.target.checked})} className="rounded border-slate-300 text-purple-600 focus:ring-purple-500" />
                W.Cl.14 Submitted
              </label>
              <label className="flex items-center gap-2 text-sm font-medium text-slate-700">
                <input type="checkbox" checked={formData.exposureHistoryLogged} onChange={e => setFormData({...formData, exposureHistoryLogged: e.target.checked})} className="rounded border-slate-300 text-purple-600 focus:ring-purple-500" />
                Exposure History Logged
              </label>
            </div>
            <div className="md:col-span-2 flex justify-end gap-2 mt-2">
              <button type="button" onClick={() => setIsAdding(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg">Cancel</button>
              <button type="submit" className="px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700">Save Claim</button>
            </div>
          </form>
        </div>
      )}

      <div className="space-y-4">
        {claims.map(claim => (
          <div key={claim.id} className="border border-slate-200 rounded-xl p-5 bg-white shadow-sm hover:shadow-md transition-shadow">
            <div className="flex justify-between items-start mb-4">
              <div className="flex items-center gap-3">
                <div className="bg-purple-50 p-2 rounded-lg text-purple-600"><Stethoscope size={24} /></div>
                <div>
                  <h3 className="font-bold text-slate-900">{claim.employeeName}</h3>
                  <p className="text-xs text-slate-500 font-bold uppercase tracking-wider">{claim.diseaseType}</p>
                </div>
              </div>
              <span className={`text-[10px] px-2 py-1 rounded-full font-bold uppercase tracking-wider ${
                claim.status === 'Accepted' ? 'bg-green-100 text-green-800' :
                claim.status === 'Rejected' ? 'bg-red-100 text-red-800' :
                'bg-purple-100 text-purple-800'
              }`}>
                {claim.status}
              </span>
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
              <div className={`p-3 rounded-lg border ${claim.wcl1Submitted ? 'bg-green-50 border-green-100 text-green-700' : 'bg-slate-50 border-slate-100 text-slate-400'}`}>
                <div className="flex items-center justify-between mb-1">
                  <span className="text-[10px] font-bold uppercase">W.Cl.1</span>
                  {claim.wcl1Submitted && <CheckCircle2 size={12} />}
                </div>
                <p className="text-xs font-medium">Notice of Disease</p>
              </div>
              <div className={`p-3 rounded-lg border ${claim.wcl14Submitted ? 'bg-green-50 border-green-100 text-green-700' : 'bg-slate-50 border-slate-100 text-slate-400'}`}>
                <div className="flex items-center justify-between mb-1">
                  <span className="text-[10px] font-bold uppercase">W.Cl.14</span>
                  {claim.wcl14Submitted && <CheckCircle2 size={12} />}
                </div>
                <p className="text-xs font-medium">First Medical Report</p>
              </div>
              <div className={`p-3 rounded-lg border ${claim.exposureHistoryLogged ? 'bg-green-50 border-green-100 text-green-700' : 'bg-slate-50 border-slate-100 text-slate-400'}`}>
                <div className="flex items-center justify-between mb-1">
                  <span className="text-[10px] font-bold uppercase">Exposure</span>
                  {claim.exposureHistoryLogged && <CheckCircle2 size={12} />}
                </div>
                <p className="text-xs font-medium">History Logged</p>
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
            No occupational disease claims logged.
          </div>
        )}
      </div>
    </div>
  );
}
