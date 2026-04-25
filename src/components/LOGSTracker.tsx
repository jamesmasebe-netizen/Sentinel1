import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { FileCheck, Plus, Calendar, AlertCircle, CheckCircle2 } from 'lucide-react';

interface LOGSRecord {
  id: string;
  certificateNumber: string;
  issueDate: string;
  expiryDate: string;
  status: 'Valid' | 'Expired' | 'Renewal Pending';
  renewalDate?: string;
  createdAt: string;
}

export default function LOGSTracker() {
  const [records, setRecords] = useState<LOGSRecord[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [formData, setFormData] = useState({
    certificateNumber: '',
    issueDate: '',
    expiryDate: '',
    status: 'Valid' as LOGSRecord['status']
  });

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'coida_logs'), orderBy('createdAt', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setRecords(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as LOGSRecord[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'coida_logs'));
    return () => unsubscribe();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      await addDoc(collection(db, 'coida_logs'), {
        ...formData,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAdding(false);
      setFormData({ certificateNumber: '', issueDate: '', expiryDate: '', status: 'Valid' });
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'coida_logs');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">Letter of Good Standing (LOGS) Tracker</h2>
          <p className="text-sm text-slate-500">Monitor validity and renewal dates of LOGS for the Compensation Fund.</p>
        </div>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700">
          <Plus size={18} /> Log Certificate
        </button>
      </div>

      {isAdding && (
        <div className="bg-slate-50 p-4 rounded-lg border border-slate-200 mb-6">
          <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Certificate Number</label>
              <input type="text" required value={formData.certificateNumber} onChange={e => setFormData({...formData, certificateNumber: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Issue Date</label>
              <input type="date" required value={formData.issueDate} onChange={e => setFormData({...formData, issueDate: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Expiry Date</label>
              <input type="date" required value={formData.expiryDate} onChange={e => setFormData({...formData, expiryDate: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Status</label>
              <select value={formData.status} onChange={e => setFormData({...formData, status: e.target.value as any})} className="w-full p-2 border rounded-lg">
                <option value="Valid">Valid</option>
                <option value="Expired">Expired</option>
                <option value="Renewal Pending">Renewal Pending</option>
              </select>
            </div>
            <div className="md:col-span-2 flex justify-end gap-2 mt-2">
              <button type="button" onClick={() => setIsAdding(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg">Cancel</button>
              <button type="submit" className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">Save Certificate</button>
            </div>
          </form>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {records.map(record => (
          <div key={record.id} className="border border-slate-200 rounded-xl p-5 bg-white shadow-sm hover:shadow-md transition-shadow">
            <div className="flex justify-between items-start mb-4">
              <div className="bg-blue-50 p-2 rounded-lg text-blue-600"><FileCheck size={24} /></div>
              <span className={`text-[10px] px-2 py-1 rounded-full font-bold uppercase tracking-wider ${
                record.status === 'Valid' ? 'bg-green-100 text-green-800' :
                record.status === 'Expired' ? 'bg-red-100 text-red-800' :
                'bg-amber-100 text-amber-800'
              }`}>
                {record.status}
              </span>
            </div>
            <h3 className="font-bold text-slate-900">{record.certificateNumber}</h3>
            <p className="text-xs text-slate-500 mb-4">Compensation Fund Letter</p>
            
            <div className="space-y-2 mb-4">
              <div className="flex justify-between text-xs">
                <span className="text-slate-400">Issue Date:</span>
                <span className="text-slate-700 font-medium">{new Date(record.issueDate).toLocaleDateString()}</span>
              </div>
              <div className="flex justify-between text-xs">
                <span className="text-slate-400">Expiry Date:</span>
                <span className="text-slate-700 font-medium">{new Date(record.expiryDate).toLocaleDateString()}</span>
              </div>
            </div>

            {new Date(record.expiryDate) < new Date() && record.status === 'Valid' && (
              <div className="mt-4 p-2 bg-red-50 rounded flex items-center gap-2 text-red-700 text-[10px] font-bold uppercase tracking-wider">
                <AlertCircle size={14} /> Certificate Expired
              </div>
            )}
            {new Date(record.expiryDate) > new Date() && record.status === 'Valid' && (
              <div className="mt-4 p-2 bg-green-50 rounded flex items-center gap-2 text-green-700 text-[10px] font-bold uppercase tracking-wider">
                <CheckCircle2 size={14} /> Certificate Valid
              </div>
            )}
          </div>
        ))}
        {records.length === 0 && !isAdding && (
          <div className="col-span-full p-8 text-center text-slate-500 bg-slate-50 rounded-xl border border-dashed border-slate-300">
            No LOGS certificates logged.
          </div>
        )}
      </div>
    </div>
  );
}
