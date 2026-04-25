import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { Ear, Plus, TrendingDown, TrendingUp, AlertCircle, CheckCircle2 } from 'lucide-react';

interface AudiometryRecord {
  id: string;
  employeeName: string;
  testDate: string;
  baselineDate: string;
  leftEarPLH: number; // Percentage Loss of Hearing
  rightEarPLH: number;
  totalPLH: number;
  shiftDetected: boolean;
  shiftValue: number;
  status: 'Normal' | 'Warning' | 'STS Detected';
  createdAt: string;
}

export default function AudiometricAnalysis() {
  const [records, setRecords] = useState<AudiometryRecord[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [formData, setFormData] = useState({
    employeeName: '',
    testDate: '',
    baselineDate: '',
    leftEarPLH: 0,
    rightEarPLH: 0,
    totalPLH: 0,
    shiftValue: 0
  });

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'audiometry_analysis'), orderBy('testDate', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as AudiometryRecord[];
      setRecords(data);
    }, (error) => handleFirestoreError(error, 'list' as any, 'audiometry_analysis'));
    return () => unsubscribe();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      const shiftDetected = formData.shiftValue >= 10;
      const status = shiftDetected ? 'STS Detected' : (formData.totalPLH > 5 ? 'Warning' : 'Normal');
      
      await addDoc(collection(db, 'audiometry_analysis'), {
        ...formData,
        shiftDetected,
        status,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAdding(false);
      setFormData({ employeeName: '', testDate: '', baselineDate: '', leftEarPLH: 0, rightEarPLH: 0, totalPLH: 0, shiftValue: 0 });
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'audiometry_analysis');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">Audiometric Shift Analysis</h2>
          <p className="text-sm text-slate-500">Monitor hearing trends and detect Standard Threshold Shifts (STS).</p>
        </div>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700">
          <Plus size={18} /> Log Audiogram
        </button>
      </div>

      {isAdding && (
        <div className="bg-slate-50 p-4 rounded-lg border border-slate-200 mb-6">
          <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Employee Name</label>
              <input type="text" required value={formData.employeeName} onChange={e => setFormData({...formData, employeeName: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div className="grid grid-cols-2 gap-2">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Test Date</label>
                <input type="date" required value={formData.testDate} onChange={e => setFormData({...formData, testDate: e.target.value})} className="w-full p-2 border rounded-lg" />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Baseline Date</label>
                <input type="date" required value={formData.baselineDate} onChange={e => setFormData({...formData, baselineDate: e.target.value})} className="w-full p-2 border rounded-lg" />
              </div>
            </div>
            <div className="grid grid-cols-3 gap-2">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Left PLH %</label>
                <input type="number" step="0.1" required value={formData.leftEarPLH} onChange={e => setFormData({...formData, leftEarPLH: parseFloat(e.target.value) || 0})} className="w-full p-2 border rounded-lg" />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Right PLH %</label>
                <input type="number" step="0.1" required value={formData.rightEarPLH} onChange={e => setFormData({...formData, rightEarPLH: parseFloat(e.target.value) || 0})} className="w-full p-2 border rounded-lg" />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Total PLH %</label>
                <input type="number" step="0.1" required value={formData.totalPLH} onChange={e => setFormData({...formData, totalPLH: parseFloat(e.target.value) || 0})} className="w-full p-2 border rounded-lg" />
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Shift from Baseline (dB)</label>
              <input type="number" step="0.1" required value={formData.shiftValue} onChange={e => setFormData({...formData, shiftValue: parseFloat(e.target.value) || 0})} className="w-full p-2 border rounded-lg" />
            </div>
            <div className="md:col-span-2 flex justify-end gap-2 mt-2">
              <button type="button" onClick={() => setIsAdding(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg">Cancel</button>
              <button type="submit" className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">Save Analysis</button>
            </div>
          </form>
        </div>
      )}

      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 text-sm">
              <th className="p-4 font-medium">Test Date</th>
              <th className="p-4 font-medium">Employee</th>
              <th className="p-4 font-medium">PLH (L/R/Total)</th>
              <th className="p-4 font-medium">Shift (dB)</th>
              <th className="p-4 font-medium">Status</th>
            </tr>
          </thead>
          <tbody>
            {records.map(record => (
              <tr key={record.id} className="border-b border-slate-100 hover:bg-slate-50">
                <td className="p-4 text-slate-600">
                  <div className="flex flex-col">
                    <span>{new Date(record.testDate).toLocaleDateString()}</span>
                    <span className="text-[10px] text-slate-400 uppercase font-bold">Baseline: {new Date(record.baselineDate).toLocaleDateString()}</span>
                  </div>
                </td>
                <td className="p-4 font-medium text-slate-900">{record.employeeName}</td>
                <td className="p-4 text-slate-600">
                  <div className="flex items-center gap-2">
                    <span className="text-xs bg-slate-100 px-1.5 py-0.5 rounded">L: {record.leftEarPLH}%</span>
                    <span className="text-xs bg-slate-100 px-1.5 py-0.5 rounded">R: {record.rightEarPLH}%</span>
                    <span className="font-bold text-slate-800">{record.totalPLH}%</span>
                  </div>
                </td>
                <td className="p-4">
                  <div className="flex items-center gap-1">
                    {record.shiftValue > 0 ? <TrendingUp size={14} className="text-red-500" /> : <TrendingDown size={14} className="text-green-500" />}
                    <span className={`font-bold ${record.shiftValue >= 10 ? 'text-red-600' : 'text-slate-700'}`}>{record.shiftValue} dB</span>
                  </div>
                </td>
                <td className="p-4">
                  {record.status === 'Normal' && <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800"><CheckCircle2 size={12}/> Normal</span>}
                  {record.status === 'Warning' && <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-amber-100 text-amber-800"><AlertCircle size={12}/> Warning</span>}
                  {record.status === 'STS Detected' && <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-red-100 text-red-800"><Ear size={12}/> STS Detected</span>}
                </td>
              </tr>
            ))}
            {records.length === 0 && !isAdding && (
              <tr>
                <td colSpan={5} className="p-8 text-center text-slate-500">No audiometric records found.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
