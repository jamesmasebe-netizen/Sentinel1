import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { ShieldAlert, Plus, FileText, User, Calendar, CheckCircle2, AlertCircle } from 'lucide-react';

interface Section56Claim {
  id: string;
  employeeName: string;
  claimNumber: string;
  negligenceType: 'Employer' | 'Foreman' | 'Machinery' | 'Other';
  investigationStatus: 'In Progress' | 'Completed' | 'Submitted' | 'Finalized';
  increasedCompensationRequested: boolean;
  findings: string;
  createdAt: string;
}

export default function Section56Investigation() {
  const [claims, setClaims] = useState<Section56Claim[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [formData, setFormData] = useState({
    employeeName: '',
    claimNumber: '',
    negligenceType: 'Employer' as Section56Claim['negligenceType'],
    investigationStatus: 'In Progress' as Section56Claim['investigationStatus'],
    increasedCompensationRequested: false,
    findings: ''
  });

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'coida_section56_claims'), orderBy('createdAt', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setClaims(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as Section56Claim[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'coida_section56_claims'));
    return () => unsubscribe();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      await addDoc(collection(db, 'coida_section56_claims'), {
        ...formData,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAdding(false);
      setFormData({ employeeName: '', claimNumber: '', negligenceType: 'Employer', investigationStatus: 'In Progress', increasedCompensationRequested: false, findings: '' });
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'coida_section56_claims');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">Section 56 Investigation (Increased Compensation)</h2>
          <p className="text-sm text-slate-500">Track claims for increased compensation due to employer negligence.</p>
        </div>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-amber-600 text-white px-4 py-2 rounded-lg hover:bg-amber-700">
          <Plus size={18} /> Log Section 56 Claim
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
              <label className="block text-sm font-medium text-slate-700 mb-1">Claim Number</label>
              <input type="text" required value={formData.claimNumber} onChange={e => setFormData({...formData, claimNumber: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Negligence Type</label>
              <select value={formData.negligenceType} onChange={e => setFormData({...formData, negligenceType: e.target.value as any})} className="w-full p-2 border rounded-lg">
                <option value="Employer">Employer Negligence</option>
                <option value="Foreman">Foreman/Supervisor Negligence</option>
                <option value="Machinery">Machinery Defect</option>
                <option value="Other">Other</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Investigation Status</label>
              <select value={formData.investigationStatus} onChange={e => setFormData({...formData, investigationStatus: e.target.value as any})} className="w-full p-2 border rounded-lg">
                <option value="In Progress">In Progress</option>
                <option value="Completed">Completed</option>
                <option value="Submitted">Submitted</option>
                <option value="Finalized">Finalized</option>
              </select>
            </div>
            <div className="flex items-center gap-2 md:col-span-2 py-2">
              <input type="checkbox" checked={formData.increasedCompensationRequested} onChange={e => setFormData({...formData, increasedCompensationRequested: e.target.checked})} className="rounded border-slate-300 text-amber-600 focus:ring-amber-500" />
              <label className="text-sm font-medium text-slate-700">Increased Compensation Requested</label>
            </div>
            <div className="md:col-span-2">
              <label className="block text-sm font-medium text-slate-700 mb-1">Findings / Negligence Details</label>
              <textarea value={formData.findings} onChange={e => setFormData({...formData, findings: e.target.value})} className="w-full p-2 border rounded-lg" rows={3}></textarea>
            </div>
            <div className="md:col-span-2 flex justify-end gap-2 mt-2">
              <button type="button" onClick={() => setIsAdding(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg">Cancel</button>
              <button type="submit" className="px-4 py-2 bg-amber-600 text-white rounded-lg hover:bg-amber-700">Save Claim</button>
            </div>
          </form>
        </div>
      )}

      <div className="space-y-4">
        {claims.map(claim => (
          <div key={claim.id} className="border border-slate-200 rounded-xl p-5 bg-white shadow-sm hover:shadow-md transition-shadow">
            <div className="flex justify-between items-start mb-4">
              <div className="flex items-center gap-3">
                <div className="bg-amber-50 p-2 rounded-lg text-amber-600"><ShieldAlert size={24} /></div>
                <div>
                  <h3 className="font-bold text-slate-900">{claim.employeeName}</h3>
                  <p className="text-xs text-slate-500">Claim: {claim.claimNumber}</p>
                </div>
              </div>
              <span className={`text-[10px] px-2 py-1 rounded-full font-bold uppercase tracking-wider ${
                claim.investigationStatus === 'Finalized' ? 'bg-green-100 text-green-800' :
                'bg-amber-100 text-amber-800'
              }`}>
                {claim.investigationStatus}
              </span>
            </div>
            
            <div className="flex items-center gap-4 mb-4">
              <div className="text-xs font-medium text-slate-600">Negligence: <span className="text-slate-900 font-bold">{claim.negligenceType}</span></div>
              {claim.increasedCompensationRequested && (
                <div className="flex items-center gap-1 text-[10px] font-bold text-red-600 uppercase tracking-wider">
                  <AlertCircle size={12} /> Increased Compensation Claimed
                </div>
              )}
            </div>

            <p className="text-sm text-slate-600 mb-4 bg-slate-50 p-3 rounded-lg border border-slate-100">{claim.findings}</p>

            <div className="flex items-center justify-between text-xs text-slate-400">
              <span>Logged: {new Date(claim.createdAt).toLocaleDateString()}</span>
              <button className="text-blue-600 hover:underline flex items-center gap-1">
                View Investigation Report <FileText size={12} />
              </button>
            </div>
          </div>
        ))}
        {claims.length === 0 && !isAdding && (
          <div className="p-8 text-center text-slate-500 bg-slate-50 rounded-xl border border-dashed border-slate-300">
            No Section 56 claims logged.
          </div>
        )}
      </div>
    </div>
  );
}
