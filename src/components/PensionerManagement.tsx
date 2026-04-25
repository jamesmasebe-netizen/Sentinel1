import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { Wallet, Plus, User, Calendar, CheckCircle2, AlertCircle, TrendingUp } from 'lucide-react';

interface PensionerRecord {
  id: string;
  employeeName: string;
  claimNumber: string;
  pensionNumber: string;
  monthlyAmount: number;
  pdPercentage: number;
  status: 'Active' | 'Suspended' | 'Terminated';
  lastPaymentDate: string;
  createdAt: string;
}

export default function PensionerManagement() {
  const [pensioners, setPensioners] = useState<PensionerRecord[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [formData, setFormData] = useState({
    employeeName: '',
    claimNumber: '',
    pensionNumber: '',
    monthlyAmount: 0,
    pdPercentage: 0,
    status: 'Active' as PensionerRecord['status'],
    lastPaymentDate: ''
  });

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'coida_pensioners'), orderBy('createdAt', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setPensioners(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as PensionerRecord[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'coida_pensioners'));
    return () => unsubscribe();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      await addDoc(collection(db, 'coida_pensioners'), {
        ...formData,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAdding(false);
      setFormData({ employeeName: '', claimNumber: '', pensionNumber: '', monthlyAmount: 0, pdPercentage: 0, status: 'Active', lastPaymentDate: '' });
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'coida_pensioners');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">Pensioner Management</h2>
          <p className="text-sm text-slate-500">Track monthly pension payments for employees with PD awards greater than 30%.</p>
        </div>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-purple-600 text-white px-4 py-2 rounded-lg hover:bg-purple-700">
          <Plus size={18} /> Add Pensioner
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
              <label className="block text-sm font-medium text-slate-700 mb-1">Pension Number</label>
              <input type="text" required value={formData.pensionNumber} onChange={e => setFormData({...formData, pensionNumber: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div className="grid grid-cols-2 gap-2">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Monthly Amount (R)</label>
                <input type="number" required value={formData.monthlyAmount} onChange={e => setFormData({...formData, monthlyAmount: parseFloat(e.target.value) || 0})} className="w-full p-2 border rounded-lg" />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">PD Percentage (%)</label>
                <input type="number" required min="31" max="100" value={formData.pdPercentage} onChange={e => setFormData({...formData, pdPercentage: parseFloat(e.target.value) || 0})} className="w-full p-2 border rounded-lg" />
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Last Payment Date</label>
              <input type="date" required value={formData.lastPaymentDate} onChange={e => setFormData({...formData, lastPaymentDate: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Status</label>
              <select value={formData.status} onChange={e => setFormData({...formData, status: e.target.value as any})} className="w-full p-2 border rounded-lg">
                <option value="Active">Active</option>
                <option value="Suspended">Suspended</option>
                <option value="Terminated">Terminated</option>
              </select>
            </div>
            <div className="md:col-span-2 flex justify-end gap-2 mt-2">
              <button type="button" onClick={() => setIsAdding(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg">Cancel</button>
              <button type="submit" className="px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700">Save Pensioner</button>
            </div>
          </form>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {pensioners.map(pensioner => (
          <div key={pensioner.id} className="border border-slate-200 rounded-xl p-5 bg-white shadow-sm hover:shadow-md transition-shadow">
            <div className="flex justify-between items-start mb-4">
              <div className="bg-purple-50 p-2 rounded-lg text-purple-600"><Wallet size={24} /></div>
              <div className="text-right">
                <p className="text-2xl font-black text-slate-900">R {pensioner.monthlyAmount.toLocaleString()}</p>
                <p className="text-[10px] text-slate-400 font-bold uppercase tracking-tighter">Monthly Pension</p>
              </div>
            </div>
            <h3 className="font-bold text-slate-900">{pensioner.employeeName}</h3>
            <p className="text-xs text-slate-500 mb-4 font-bold uppercase tracking-wider">PD: {pensioner.pdPercentage}%</p>
            
            <div className="flex items-center justify-between py-3 border-t border-slate-100">
              <div className="flex flex-col">
                <span className="text-[10px] text-slate-400 font-bold uppercase">Pension No.</span>
                <span className="text-xs text-slate-700 font-medium">{pensioner.pensionNumber}</span>
              </div>
              <span className={`text-[10px] px-2 py-1 rounded-full font-bold uppercase tracking-wider ${
                pensioner.status === 'Active' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
              }`}>
                {pensioner.status}
              </span>
            </div>
          </div>
        ))}
        {pensioners.length === 0 && !isAdding && (
          <div className="col-span-full p-8 text-center text-slate-500 bg-slate-50 rounded-xl border border-dashed border-slate-300">
            No pensioner records logged.
          </div>
        )}
      </div>
    </div>
  );
}
