import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { ClipboardCheck, Plus, CheckCircle2, XCircle, AlertCircle } from 'lucide-react';

interface AuditRecord {
  id: string;
  auditTitle: string;
  auditor: string;
  auditDate: string;
  score: number;
  findingsCount: number;
  status: 'Draft' | 'Completed' | 'Follow-up Required';
  createdAt: string;
}

export default function EnvironmentalInternalAudit() {
  const [audits, setAudits] = useState<AuditRecord[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [formData, setFormData] = useState({
    auditTitle: '',
    auditor: '',
    auditDate: '',
    score: 0,
    findingsCount: 0,
    status: 'Completed' as AuditRecord['status']
  });

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'env_audits'), orderBy('auditDate', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setAudits(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as AuditRecord[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'env_audits'));
    return () => unsubscribe();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      await addDoc(collection(db, 'env_audits'), {
        ...formData,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAdding(false);
      setFormData({ auditTitle: '', auditor: '', auditDate: '', score: 0, findingsCount: 0, status: 'Completed' });
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'env_audits');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">Internal Audit Tool (ISO 14001)</h2>
          <p className="text-sm text-slate-500">Log and track internal environmental audits and compliance scores.</p>
        </div>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700">
          <Plus size={18} /> Log Audit Result
        </button>
      </div>

      {isAdding && (
        <div className="bg-slate-50 p-4 rounded-lg border border-slate-200 mb-6">
          <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Audit Title / Scope</label>
              <input type="text" required placeholder="e.g., Waste Management Audit, Annual ISO 14001" value={formData.auditTitle} onChange={e => setFormData({...formData, auditTitle: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Auditor</label>
              <input type="text" required value={formData.auditor} onChange={e => setFormData({...formData, auditor: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Audit Date</label>
              <input type="date" required value={formData.auditDate} onChange={e => setFormData({...formData, auditDate: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div className="grid grid-cols-2 gap-2">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Score (%)</label>
                <input type="number" required min="0" max="100" value={formData.score} onChange={e => setFormData({...formData, score: parseInt(e.target.value) || 0})} className="w-full p-2 border rounded-lg" />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Findings Count</label>
                <input type="number" required min="0" value={formData.findingsCount} onChange={e => setFormData({...formData, findingsCount: parseInt(e.target.value) || 0})} className="w-full p-2 border rounded-lg" />
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Status</label>
              <select value={formData.status} onChange={e => setFormData({...formData, status: e.target.value as any})} className="w-full p-2 border rounded-lg">
                <option value="Completed">Completed</option>
                <option value="Follow-up Required">Follow-up Required</option>
                <option value="Draft">Draft</option>
              </select>
            </div>
            <div className="md:col-span-2 flex justify-end gap-2 mt-2">
              <button type="button" onClick={() => setIsAdding(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg">Cancel</button>
              <button type="submit" className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">Save Audit</button>
            </div>
          </form>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {audits.map(audit => (
          <div key={audit.id} className="border border-slate-200 rounded-xl p-5 bg-white shadow-sm hover:shadow-md transition-shadow">
            <div className="flex justify-between items-start mb-4">
              <div className="bg-blue-50 p-2 rounded-lg text-blue-600"><ClipboardCheck size={24} /></div>
              <div className="text-right">
                <p className="text-2xl font-black text-slate-900">{audit.score}%</p>
                <p className="text-[10px] text-slate-400 font-bold uppercase tracking-tighter">Compliance Score</p>
              </div>
            </div>
            <h3 className="font-bold text-slate-900">{audit.auditTitle}</h3>
            <p className="text-xs text-slate-500 mb-4">Auditor: {audit.auditor}</p>
            
            <div className="flex items-center justify-between py-3 border-t border-slate-100">
              <div className="flex items-center gap-2 text-xs text-slate-600">
                <AlertCircle size={14} className="text-amber-500" />
                <span>{audit.findingsCount} Findings</span>
              </div>
              <span className={`text-[10px] px-2 py-1 rounded-full font-bold uppercase tracking-wider ${
                audit.status === 'Completed' ? 'bg-green-100 text-green-800' : 'bg-amber-100 text-amber-800'
              }`}>
                {audit.status}
              </span>
            </div>
          </div>
        ))}
        {audits.length === 0 && !isAdding && (
          <div className="col-span-full p-8 text-center text-slate-500 bg-slate-50 rounded-xl border border-dashed border-slate-300">
            No audit records logged.
          </div>
        )}
      </div>
    </div>
  );
}
