import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { Scale, Plus, CheckCircle2, AlertCircle, ExternalLink } from 'lucide-react';

interface LegalRecord {
  id: string;
  actName: string;
  section: string;
  requirement: string;
  complianceStatus: 'Compliant' | 'Partial' | 'Non-Compliant';
  responsiblePerson: string;
  lastAuditDate: string;
  createdAt: string;
}

export default function EnvironmentalLegalRegister() {
  const [laws, setLaws] = useState<LegalRecord[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [formData, setFormData] = useState({
    actName: '',
    section: '',
    requirement: '',
    complianceStatus: 'Compliant' as LegalRecord['complianceStatus'],
    responsiblePerson: '',
    lastAuditDate: ''
  });

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'env_legal_register'), orderBy('createdAt', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setLaws(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as LegalRecord[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'env_legal_register'));
    return () => unsubscribe();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      await addDoc(collection(db, 'env_legal_register'), {
        ...formData,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAdding(false);
      setFormData({ actName: '', section: '', requirement: '', complianceStatus: 'Compliant', responsiblePerson: '', lastAuditDate: '' });
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'env_legal_register');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">Environmental Legal Register</h2>
          <p className="text-sm text-slate-500">Track compliance with NEMA, National Water Act, and other environmental laws.</p>
        </div>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700">
          <Plus size={18} /> Add Requirement
        </button>
      </div>

      {isAdding && (
        <div className="bg-slate-50 p-4 rounded-lg border border-slate-200 mb-6">
          <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Act / Regulation Name</label>
              <input type="text" required placeholder="e.g., National Environmental Management Act (NEMA)" value={formData.actName} onChange={e => setFormData({...formData, actName: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Section / Clause</label>
              <input type="text" required placeholder="e.g., Section 28 (Duty of Care)" value={formData.section} onChange={e => setFormData({...formData, section: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div className="md:col-span-2">
              <label className="block text-sm font-medium text-slate-700 mb-1">Compliance Requirement</label>
              <textarea required value={formData.requirement} onChange={e => setFormData({...formData, requirement: e.target.value})} className="w-full p-2 border rounded-lg" rows={2}></textarea>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Status</label>
              <select value={formData.complianceStatus} onChange={e => setFormData({...formData, complianceStatus: e.target.value as any})} className="w-full p-2 border rounded-lg">
                <option value="Compliant">Compliant</option>
                <option value="Partial">Partial Compliance</option>
                <option value="Non-Compliant">Non-Compliant</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Responsible Person</label>
              <input type="text" required value={formData.responsiblePerson} onChange={e => setFormData({...formData, responsiblePerson: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div className="md:col-span-2 flex justify-end gap-2 mt-2">
              <button type="button" onClick={() => setIsAdding(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg">Cancel</button>
              <button type="submit" className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700">Save Requirement</button>
            </div>
          </form>
        </div>
      )}

      <div className="space-y-4">
        {laws.map(law => (
          <div key={law.id} className="border border-slate-200 rounded-xl p-5 bg-white shadow-sm hover:shadow-md transition-shadow">
            <div className="flex justify-between items-start mb-3">
              <div className="flex items-center gap-3">
                <div className="bg-green-50 p-2 rounded-lg text-green-600"><Scale size={20} /></div>
                <div>
                  <h3 className="font-bold text-slate-900">{law.actName}</h3>
                  <p className="text-xs text-slate-500 font-mono">{law.section}</p>
                </div>
              </div>
              <span className={`text-[10px] px-2 py-1 rounded-full font-bold uppercase tracking-wider ${
                law.complianceStatus === 'Compliant' ? 'bg-green-100 text-green-800' :
                law.complianceStatus === 'Partial' ? 'bg-amber-100 text-amber-800' :
                'bg-red-100 text-red-800'
              }`}>
                {law.complianceStatus}
              </span>
            </div>
            <p className="text-sm text-slate-600 mb-4 bg-slate-50 p-3 rounded-lg border border-slate-100">{law.requirement}</p>
            <div className="flex justify-between items-center text-xs">
              <span className="text-slate-400">Responsible: <span className="text-slate-700 font-medium">{law.responsiblePerson}</span></span>
              <button className="text-blue-600 hover:underline flex items-center gap-1">
                View Legislation <ExternalLink size={12} />
              </button>
            </div>
          </div>
        ))}
        {laws.length === 0 && !isAdding && (
          <div className="p-8 text-center text-slate-500 bg-slate-50 rounded-xl border border-dashed border-slate-300">
            No legal requirements logged in the register.
          </div>
        )}
      </div>
    </div>
  );
}
