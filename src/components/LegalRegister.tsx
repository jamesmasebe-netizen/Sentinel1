import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy, doc, updateDoc } from 'firebase/firestore';
import { db, auth, handleFirestoreError } from '../lib/firebase';
import { Plus, X } from 'lucide-react';

interface LegalRegister {
  id: string;
  actOrRegulation: string;
  section: string;
  relevance: string;
  complianceStatus: 'Compliant' | 'Non-Compliant' | 'Under Review';
  lastReviewed: string;
  authorId: string;
  createdAt: string;
}

export default function LegalRegisterComponent() {
  const [legalItems, setLegalItems] = useState<LegalRegister[]>([]);
  const [isAddingLegal, setIsAddingLegal] = useState(false);

  const [actName, setActName] = useState('');
  const [section, setSection] = useState('');
  const [relevance, setRelevance] = useState('');
  const [complianceStatus, setComplianceStatus] = useState<LegalRegister['complianceStatus']>('Under Review');

  useEffect(() => {
    if (!auth.currentUser) return;
    const qLegal = query(collection(db, 'legal_register'), orderBy('createdAt', 'desc'));
    const unsubLegal = onSnapshot(qLegal, (snapshot) => {
      setLegalItems(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as LegalRegister[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'legal_register'));

    return () => unsubLegal();
  }, []);

  const handleAddLegal = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      await addDoc(collection(db, 'legal_register'), {
        actOrRegulation: actName,
        section,
        relevance,
        complianceStatus,
        lastReviewed: new Date().toISOString(),
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAddingLegal(false);
      setActName(''); setSection(''); setRelevance(''); setComplianceStatus('Under Review');
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'legal_register');
    }
  };

  const updateLegalStatus = async (id: string, status: LegalRegister['complianceStatus']) => {
    try {
      await updateDoc(doc(db, 'legal_register', id), { complianceStatus: status, lastReviewed: new Date().toISOString() });
    } catch (error) {
      handleFirestoreError(error, 'update' as any, 'legal_register');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h2 className="text-lg font-bold text-slate-900">Legal Register</h2>
        <button
          onClick={() => setIsAddingLegal(true)}
          className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 flex items-center gap-2 transition-colors shadow-sm"
        >
          <Plus size={20} /> Add Requirement
        </button>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 text-sm">
              <th className="p-4 font-medium">Act / Regulation</th>
              <th className="p-4 font-medium">Section</th>
              <th className="p-4 font-medium">Relevance to Business</th>
              <th className="p-4 font-medium">Compliance Status</th>
            </tr>
          </thead>
          <tbody>
            {legalItems.length === 0 ? (
              <tr><td colSpan={4} className="p-8 text-center text-slate-500">No legal requirements tracked yet.</td></tr>
            ) : (
              legalItems.map((item) => (
                <tr key={item.id} className="border-b border-slate-100 hover:bg-slate-50 transition-colors">
                  <td className="p-4 font-medium text-slate-900">{item.actOrRegulation}</td>
                  <td className="p-4 text-slate-600">{item.section}</td>
                  <td className="p-4 text-sm text-slate-600 max-w-xs truncate" title={item.relevance}>{item.relevance}</td>
                  <td className="p-4">
                    <select
                      value={item.complianceStatus}
                      onChange={(e) => updateLegalStatus(item.id, e.target.value as any)}
                      className={`text-sm rounded-lg border-slate-300 focus:ring-purple-500 focus:border-purple-500 ${
                        item.complianceStatus === 'Compliant' ? 'bg-green-50 text-green-700' :
                        item.complianceStatus === 'Non-Compliant' ? 'bg-red-50 text-red-700' :
                        'bg-amber-50 text-amber-700'
                      }`}
                    >
                      <option value="Compliant">Compliant</option>
                      <option value="Under Review">Under Review</option>
                      <option value="Non-Compliant">Non-Compliant</option>
                    </select>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {isAddingLegal && (
        <div className="fixed inset-0 bg-slate-900/50 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-2xl overflow-hidden">
            <div className="p-6 border-b border-slate-200 flex justify-between items-center bg-slate-50">
              <h2 className="text-xl font-bold text-slate-900">Add Legal Requirement</h2>
              <button onClick={() => setIsAddingLegal(false)} className="text-slate-400 hover:text-slate-600">
                <X size={24} />
              </button>
            </div>
            <form onSubmit={handleAddLegal} className="p-6 space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Act / Regulation</label>
                  <input type="text" required value={actName} onChange={e => setActName(e.target.value)} className="w-full p-2.5 border border-slate-300 rounded-lg" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Section / Clause</label>
                  <input type="text" required value={section} onChange={e => setSection(e.target.value)} className="w-full p-2.5 border border-slate-300 rounded-lg" />
                </div>
                <div className="md:col-span-2">
                  <label className="block text-sm font-medium text-slate-700 mb-1">Relevance to Business</label>
                  <textarea required value={relevance} onChange={e => setRelevance(e.target.value)} className="w-full p-2.5 border border-slate-300 rounded-lg" rows={3}></textarea>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Initial Compliance Status</label>
                  <select value={complianceStatus} onChange={e => setComplianceStatus(e.target.value as any)} className="w-full p-2.5 border border-slate-300 rounded-lg">
                    <option value="Compliant">Compliant</option>
                    <option value="Under Review">Under Review</option>
                    <option value="Non-Compliant">Non-Compliant</option>
                  </select>
                </div>
              </div>
              <div className="flex justify-end gap-3 pt-4 border-t border-slate-200">
                <button type="button" onClick={() => setIsAddingLegal(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg">Cancel</button>
                <button type="submit" className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">Save Requirement</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
