import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { Banknote, Plus, FileCheck, ShieldAlert, Info } from 'lucide-react';

interface EarningsRecord {
  id: string;
  employeeName: string;
  claimNumber: string;
  monthlyWage: number;
  allowances: number;
  totalEarnings: number;
  periodStart: string;
  periodEnd: string;
  createdAt: string;
}

export default function EarningsIntegration() {
  const [records, setRecords] = useState<EarningsRecord[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [formData, setFormData] = useState({
    employeeName: '',
    claimNumber: '',
    monthlyWage: 0,
    allowances: 0,
    periodStart: '',
    periodEnd: ''
  });

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'coida_earnings'), orderBy('createdAt', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setRecords(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as EarningsRecord[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'coida_earnings'));
    return () => unsubscribe();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      await addDoc(collection(db, 'coida_earnings'), {
        ...formData,
        totalEarnings: Number(formData.monthlyWage) + Number(formData.allowances),
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAdding(false);
      setFormData({ employeeName: '', claimNumber: '', monthlyWage: 0, allowances: 0, periodStart: '', periodEnd: '' });
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'coida_earnings');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">Earnings Statement (W.Cl.3) Integration</h2>
          <p className="text-sm text-slate-500">Securely log employee earnings for accurate TTD and PD calculations.</p>
        </div>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-rose-600 text-white px-4 py-2 rounded-lg hover:bg-rose-700">
          <Plus size={18} /> Log Earnings
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
            <div className="grid grid-cols-2 gap-2">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Monthly Wage (R)</label>
                <input type="number" required value={formData.monthlyWage} onChange={e => setFormData({...formData, monthlyWage: parseFloat(e.target.value) || 0})} className="w-full p-2 border rounded-lg" />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Allowances (R)</label>
                <input type="number" required value={formData.allowances} onChange={e => setFormData({...formData, allowances: parseFloat(e.target.value) || 0})} className="w-full p-2 border rounded-lg" />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-2">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Period Start</label>
                <input type="date" required value={formData.periodStart} onChange={e => setFormData({...formData, periodStart: e.target.value})} className="w-full p-2 border rounded-lg" />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Period End</label>
                <input type="date" required value={formData.periodEnd} onChange={e => setFormData({...formData, periodEnd: e.target.value})} className="w-full p-2 border rounded-lg" />
              </div>
            </div>
            <div className="md:col-span-2 flex justify-end gap-2 mt-2">
              <button type="button" onClick={() => setIsAdding(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg">Cancel</button>
              <button type="submit" className="px-4 py-2 bg-rose-600 text-white rounded-lg hover:bg-rose-700">Save Earnings</button>
            </div>
          </form>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {records.map(record => (
          <div key={record.id} className="border border-slate-200 rounded-xl p-5 bg-white shadow-sm hover:shadow-md transition-shadow">
            <div className="flex justify-between items-start mb-4">
              <div className="bg-emerald-50 p-2 rounded-lg text-emerald-600"><Banknote size={24} /></div>
              <div className="text-right">
                <p className="text-xl font-black text-slate-900">R {record.totalEarnings.toLocaleString()}</p>
                <p className="text-[10px] text-slate-400 font-bold uppercase">Total Monthly</p>
              </div>
            </div>
            <h3 className="font-bold text-slate-900">{record.employeeName}</h3>
            <p className="text-xs text-slate-500 mb-4">Claim: {record.claimNumber}</p>
            
            <div className="space-y-2 text-xs border-t border-slate-100 pt-4">
              <div className="flex justify-between">
                <span className="text-slate-400 flex items-center gap-1"><FileCheck size={14}/> Basic Wage:</span>
                <span className="text-slate-700 font-medium">R {record.monthlyWage.toLocaleString()}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400 flex items-center gap-1"><Info size={14}/> Allowances:</span>
                <span className="text-slate-700 font-medium">R {record.allowances.toLocaleString()}</span>
              </div>
            </div>
            
            <div className="mt-4 p-2 bg-blue-50 rounded flex items-center gap-2 text-blue-700 text-[10px] font-bold uppercase tracking-wider">
              <ShieldAlert size={14} /> POPIA Protected Data
            </div>
          </div>
        ))}
        {records.length === 0 && !isAdding && (
          <div className="col-span-full p-8 text-center text-slate-500 bg-slate-50 rounded-xl border border-dashed border-slate-300">
            No earnings statements logged.
          </div>
        )}
      </div>
    </div>
  );
}
