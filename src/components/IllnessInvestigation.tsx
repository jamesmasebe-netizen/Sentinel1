import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { Stethoscope, Plus, AlertCircle, FileText } from 'lucide-react';

interface IllnessRecord {
  id: string;
  employeeName: string;
  suspectedIllness: string;
  dateReported: string;
  status: 'Under Investigation' | 'Confirmed' | 'Rejected';
  workRelated: 'Yes' | 'No' | 'Pending';
  actionTaken: string;
  createdAt: string;
}

export default function IllnessInvestigation() {
  const [records, setRecords] = useState<IllnessRecord[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [formData, setFormData] = useState({
    employeeName: '',
    suspectedIllness: '',
    dateReported: '',
    status: 'Under Investigation' as IllnessRecord['status'],
    workRelated: 'Pending' as IllnessRecord['workRelated'],
    actionTaken: ''
  });

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'illness_investigations'), orderBy('createdAt', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as IllnessRecord[];
      setRecords(data);
    }, (error) => handleFirestoreError(error, 'list' as any, 'illness_investigations'));
    return () => unsubscribe();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      await addDoc(collection(db, 'illness_investigations'), {
        ...formData,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAdding(false);
      setFormData({ employeeName: '', suspectedIllness: '', dateReported: '', status: 'Under Investigation', workRelated: 'Pending', actionTaken: '' });
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'illness_investigations');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">Occupational Illness Investigation</h2>
          <p className="text-sm text-slate-500">Track and investigate suspected occupational diseases (e.g., NIHL, Dermatitis).</p>
        </div>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700">
          <Plus size={18} /> New Investigation
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
              <label className="block text-sm font-medium text-slate-700 mb-1">Suspected Illness</label>
              <input type="text" required placeholder="e.g., Noise-Induced Hearing Loss" value={formData.suspectedIllness} onChange={e => setFormData({...formData, suspectedIllness: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Date Reported</label>
              <input type="date" required value={formData.dateReported} onChange={e => setFormData({...formData, dateReported: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Status</label>
              <select value={formData.status} onChange={e => setFormData({...formData, status: e.target.value as any})} className="w-full p-2 border rounded-lg">
                <option value="Under Investigation">Under Investigation</option>
                <option value="Confirmed">Confirmed</option>
                <option value="Rejected">Rejected</option>
              </select>
            </div>
            <div className="md:col-span-2">
              <label className="block text-sm font-medium text-slate-700 mb-1">Initial Action Taken</label>
              <textarea required value={formData.actionTaken} onChange={e => setFormData({...formData, actionTaken: e.target.value})} className="w-full p-2 border rounded-lg" rows={2} placeholder="e.g., Referred to Occupational Medical Practitioner"></textarea>
            </div>
            <div className="md:col-span-2 flex justify-end gap-2 mt-2">
              <button type="button" onClick={() => setIsAdding(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg">Cancel</button>
              <button type="submit" className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">Start Investigation</button>
            </div>
          </form>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {records.map(record => (
          <div key={record.id} className="border border-slate-200 rounded-xl p-5 bg-white shadow-sm hover:shadow-md transition-shadow">
            <div className="flex justify-between items-start mb-4">
              <div className="flex items-center gap-3">
                <div className="bg-purple-50 p-2 rounded-lg text-purple-600"><Stethoscope size={24} /></div>
                <div>
                  <h3 className="font-semibold text-slate-900">{record.suspectedIllness}</h3>
                  <p className="text-sm text-slate-500">{record.employeeName}</p>
                </div>
              </div>
              <span className={`text-xs px-2.5 py-1 rounded-full font-medium ${
                record.status === 'Confirmed' ? 'bg-red-100 text-red-800' :
                record.status === 'Rejected' ? 'bg-green-100 text-green-800' :
                'bg-amber-100 text-amber-800'
              }`}>
                {record.status}
              </span>
            </div>
            <div className="space-y-2 text-sm text-slate-600 mb-4">
              <p className="flex justify-between"><span className="text-slate-400">Reported:</span> <span>{new Date(record.dateReported).toLocaleDateString()}</span></p>
              <p className="flex justify-between"><span className="text-slate-400">Work Related:</span> <span className="font-medium">{record.workRelated}</span></p>
            </div>
            <div className="bg-slate-50 p-3 rounded-lg border border-slate-100 text-sm">
              <p className="text-slate-500 text-xs mb-1 uppercase tracking-wider font-semibold">Action Taken</p>
              <p className="text-slate-700">{record.actionTaken}</p>
            </div>
          </div>
        ))}
        {records.length === 0 && !isAdding && (
          <div className="col-span-full p-8 text-center text-slate-500 bg-slate-50 rounded-xl border border-dashed border-slate-300">
            No illness investigations logged.
          </div>
        )}
      </div>
    </div>
  );
}
