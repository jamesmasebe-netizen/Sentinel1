import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { Activity, Plus, DollarSign, User, Calendar, CheckCircle2, AlertCircle } from 'lucide-react';

interface MedicalAccount {
  id: string;
  employeeName: string;
  claimNumber: string;
  accountNumber: string;
  serviceProvider: string;
  amount: number;
  submissionDate: string;
  status: 'Submitted' | 'Adjudicated' | 'Paid' | 'Rejected';
  createdAt: string;
}

export default function MedicalAdjudicationTracker() {
  const [accounts, setAccounts] = useState<MedicalAccount[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [formData, setFormData] = useState({
    employeeName: '',
    claimNumber: '',
    accountNumber: '',
    serviceProvider: '',
    amount: 0,
    submissionDate: '',
    status: 'Submitted' as MedicalAccount['status']
  });

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'coida_medical_accounts'), orderBy('createdAt', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setAccounts(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as MedicalAccount[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'coida_medical_accounts'));
    return () => unsubscribe();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      await addDoc(collection(db, 'coida_medical_accounts'), {
        ...formData,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAdding(false);
      setFormData({ employeeName: '', claimNumber: '', accountNumber: '', serviceProvider: '', amount: 0, submissionDate: '', status: 'Submitted' });
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'coida_medical_accounts');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">Medical Adjudication Tracker</h2>
          <p className="text-sm text-slate-500">Track the status of medical accounts submitted to the Compensation Fund.</p>
        </div>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-emerald-600 text-white px-4 py-2 rounded-lg hover:bg-emerald-700">
          <Plus size={18} /> Log Account
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
              <label className="block text-sm font-medium text-slate-700 mb-1">Account Number / Invoice</label>
              <input type="text" required value={formData.accountNumber} onChange={e => setFormData({...formData, accountNumber: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Service Provider</label>
              <input type="text" required value={formData.serviceProvider} onChange={e => setFormData({...formData, serviceProvider: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div className="grid grid-cols-2 gap-2">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Amount (R)</label>
                <input type="number" required value={formData.amount} onChange={e => setFormData({...formData, amount: parseFloat(e.target.value) || 0})} className="w-full p-2 border rounded-lg" />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Submission Date</label>
                <input type="date" required value={formData.submissionDate} onChange={e => setFormData({...formData, submissionDate: e.target.value})} className="w-full p-2 border rounded-lg" />
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Status</label>
              <select value={formData.status} onChange={e => setFormData({...formData, status: e.target.value as any})} className="w-full p-2 border rounded-lg">
                <option value="Submitted">Submitted</option>
                <option value="Adjudicated">Adjudicated</option>
                <option value="Paid">Paid</option>
                <option value="Rejected">Rejected</option>
              </select>
            </div>
            <div className="md:col-span-2 flex justify-end gap-2 mt-2">
              <button type="button" onClick={() => setIsAdding(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg">Cancel</button>
              <button type="submit" className="px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700">Save Account</button>
            </div>
          </form>
        </div>
      )}

      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 text-sm">
              <th className="p-4 font-medium">Date</th>
              <th className="p-4 font-medium">Employee</th>
              <th className="p-4 font-medium">Provider</th>
              <th className="p-4 font-medium">Amount</th>
              <th className="p-4 font-medium">Status</th>
            </tr>
          </thead>
          <tbody>
            {accounts.map(account => (
              <tr key={account.id} className="border-b border-slate-100 hover:bg-slate-50">
                <td className="p-4 text-slate-600">{new Date(account.submissionDate).toLocaleDateString()}</td>
                <td className="p-4">
                  <div className="flex flex-col">
                    <span className="font-bold text-slate-900">{account.employeeName}</span>
                    <span className="text-[10px] text-slate-400 font-bold uppercase tracking-wider">Claim: {account.claimNumber}</span>
                  </div>
                </td>
                <td className="p-4 text-slate-600 font-medium">{account.serviceProvider}</td>
                <td className="p-4 text-slate-900 font-black">R {account.amount.toLocaleString()}</td>
                <td className="p-4">
                  <span className={`text-[10px] px-2 py-1 rounded-full font-bold uppercase tracking-wider ${
                    account.status === 'Paid' ? 'bg-green-100 text-green-800' :
                    account.status === 'Rejected' ? 'bg-red-100 text-red-800' :
                    'bg-amber-100 text-amber-800'
                  }`}>
                    {account.status}
                  </span>
                </td>
              </tr>
            ))}
            {accounts.length === 0 && !isAdding && (
              <tr>
                <td colSpan={5} className="p-8 text-center text-slate-500">No medical accounts logged.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
