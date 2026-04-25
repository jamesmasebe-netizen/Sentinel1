import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { Scale, Plus, FileText, User, Calendar, CheckCircle2, AlertCircle } from 'lucide-react';

interface ObjectionRecord {
  id: string;
  employeeName: string;
  claimNumber: string;
  objectionType: 'Liability' | 'PD Award' | 'Medical' | 'Other';
  submissionDate: string;
  hearingDate?: string;
  status: 'Draft' | 'Submitted' | 'Hearing Scheduled' | 'Resolved';
  outcome?: string;
  createdAt: string;
}

export default function ObjectionAppealManager() {
  const [objections, setObjections] = useState<ObjectionRecord[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [formData, setFormData] = useState({
    employeeName: '',
    claimNumber: '',
    objectionType: 'Liability' as ObjectionRecord['objectionType'],
    submissionDate: '',
    hearingDate: '',
    status: 'Draft' as ObjectionRecord['status'],
    outcome: ''
  });

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'coida_objections'), orderBy('createdAt', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setObjections(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as ObjectionRecord[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'coida_objections'));
    return () => unsubscribe();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      await addDoc(collection(db, 'coida_objections'), {
        ...formData,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAdding(false);
      setFormData({ employeeName: '', claimNumber: '', objectionType: 'Liability', submissionDate: '', hearingDate: '', status: 'Draft', outcome: '' });
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'coida_objections');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">Objection & Appeal Manager (Section 91)</h2>
          <p className="text-sm text-slate-500">Manage formal objections and appeals against Compensation Fund decisions.</p>
        </div>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-indigo-600 text-white px-4 py-2 rounded-lg hover:bg-indigo-700">
          <Plus size={18} /> New Objection
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
              <label className="block text-sm font-medium text-slate-700 mb-1">Objection Type</label>
              <select value={formData.objectionType} onChange={e => setFormData({...formData, objectionType: e.target.value as any})} className="w-full p-2 border rounded-lg">
                <option value="Liability">Liability (Rejection of Claim)</option>
                <option value="PD Award">Permanent Disablement Award</option>
                <option value="Medical">Medical Expenses / Treatment</option>
                <option value="Other">Other Administrative Decision</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Submission Date</label>
              <input type="date" required value={formData.submissionDate} onChange={e => setFormData({...formData, submissionDate: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Hearing Date (Optional)</label>
              <input type="date" value={formData.hearingDate} onChange={e => setFormData({...formData, hearingDate: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Status</label>
              <select value={formData.status} onChange={e => setFormData({...formData, status: e.target.value as any})} className="w-full p-2 border rounded-lg">
                <option value="Draft">Draft</option>
                <option value="Submitted">Submitted</option>
                <option value="Hearing Scheduled">Hearing Scheduled</option>
                <option value="Resolved">Resolved</option>
              </select>
            </div>
            <div className="md:col-span-2">
              <label className="block text-sm font-medium text-slate-700 mb-1">Outcome / Notes</label>
              <textarea value={formData.outcome} onChange={e => setFormData({...formData, outcome: e.target.value})} className="w-full p-2 border rounded-lg" rows={2}></textarea>
            </div>
            <div className="md:col-span-2 flex justify-end gap-2 mt-2">
              <button type="button" onClick={() => setIsAdding(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg">Cancel</button>
              <button type="submit" className="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700">Save Objection</button>
            </div>
          </form>
        </div>
      )}

      <div className="space-y-4">
        {objections.map(objection => (
          <div key={objection.id} className="border border-slate-200 rounded-xl p-5 bg-white shadow-sm hover:shadow-md transition-shadow">
            <div className="flex justify-between items-start mb-4">
              <div className="flex items-center gap-3">
                <div className="bg-indigo-50 p-2 rounded-lg text-indigo-600"><Scale size={24} /></div>
                <div>
                  <h3 className="font-bold text-slate-900">{objection.employeeName}</h3>
                  <p className="text-xs text-slate-500 font-bold uppercase tracking-wider">Claim: {objection.claimNumber}</p>
                </div>
              </div>
              <span className={`text-[10px] px-2 py-1 rounded-full font-bold uppercase tracking-wider ${
                objection.status === 'Resolved' ? 'bg-green-100 text-green-800' :
                objection.status === 'Hearing Scheduled' ? 'bg-blue-100 text-blue-800' :
                'bg-amber-100 text-amber-800'
              }`}>
                {objection.status}
              </span>
            </div>
            
            <div className="grid grid-cols-2 gap-4 mb-4 text-xs">
              <div className="bg-slate-50 p-2 rounded">
                <span className="text-slate-400 block mb-1 uppercase font-bold tracking-tighter">Type</span>
                <span className="text-slate-700 font-medium">{objection.objectionType}</span>
              </div>
              <div className="bg-slate-50 p-2 rounded">
                <span className="text-slate-400 block mb-1 uppercase font-bold tracking-tighter">Submitted</span>
                <span className="text-slate-700 font-medium">{new Date(objection.submissionDate).toLocaleDateString()}</span>
              </div>
            </div>

            {objection.hearingDate && (
              <div className="flex items-center gap-2 text-xs text-blue-600 bg-blue-50 p-2 rounded border border-blue-100 mb-4">
                <Calendar size={14} />
                <span>Hearing Scheduled: <span className="font-bold">{new Date(objection.hearingDate).toLocaleDateString()}</span></span>
              </div>
            )}

            {objection.outcome && (
              <p className="text-xs text-slate-600 italic border-l-2 border-slate-200 pl-3">{objection.outcome}</p>
            )}
          </div>
        ))}
        {objections.length === 0 && !isAdding && (
          <div className="p-8 text-center text-slate-500 bg-slate-50 rounded-xl border border-dashed border-slate-300">
            No objections or appeals logged.
          </div>
        )}
      </div>
    </div>
  );
}
