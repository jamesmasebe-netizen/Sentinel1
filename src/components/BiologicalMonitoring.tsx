import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { Beaker, Plus, AlertCircle, CheckCircle2, Info } from 'lucide-react';

interface BioRecord {
  id: string;
  employeeName: string;
  substance: string;
  sampleType: 'Blood' | 'Urine' | 'Other';
  resultValue: number;
  unit: string;
  referenceLimit: number;
  dateSampled: string;
  status: 'Normal' | 'Action Level' | 'Exceeded';
  notes: string;
  createdAt: string;
}

export default function BiologicalMonitoring() {
  const [records, setRecords] = useState<BioRecord[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [formData, setFormData] = useState({
    employeeName: '',
    substance: 'Lead (Pb)',
    sampleType: 'Blood' as BioRecord['sampleType'],
    resultValue: 0,
    unit: 'µg/dL',
    referenceLimit: 30,
    dateSampled: '',
    notes: ''
  });

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'biological_monitoring'), orderBy('dateSampled', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as BioRecord[];
      setRecords(data);
    }, (error) => handleFirestoreError(error, 'list' as any, 'biological_monitoring'));
    return () => unsubscribe();
  }, []);

  const getStatus = (val: number, limit: number): BioRecord['status'] => {
    if (val >= limit) return 'Exceeded';
    if (val >= limit * 0.8) return 'Action Level';
    return 'Normal';
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      const status = getStatus(formData.resultValue, formData.referenceLimit);
      await addDoc(collection(db, 'biological_monitoring'), {
        ...formData,
        status,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAdding(false);
      setFormData({ employeeName: '', substance: 'Lead (Pb)', sampleType: 'Blood', resultValue: 0, unit: 'µg/dL', referenceLimit: 30, dateSampled: '', notes: '' });
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'biological_monitoring');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900 text-balance">Biological Monitoring Log</h2>
          <p className="text-sm text-slate-500">Track blood and urine levels for chemical exposure monitoring.</p>
        </div>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700">
          <Plus size={18} /> Log Sample
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
              <label className="block text-sm font-medium text-slate-700 mb-1">Substance</label>
              <input type="text" required placeholder="e.g., Lead, Benzene, Mercury" value={formData.substance} onChange={e => setFormData({...formData, substance: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Sample Type</label>
              <select value={formData.sampleType} onChange={e => setFormData({...formData, sampleType: e.target.value as any})} className="w-full p-2 border rounded-lg">
                <option value="Blood">Blood</option>
                <option value="Urine">Urine</option>
                <option value="Other">Other</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Date Sampled</label>
              <input type="date" required value={formData.dateSampled} onChange={e => setFormData({...formData, dateSampled: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div className="grid grid-cols-3 gap-2">
              <div className="col-span-1">
                <label className="block text-sm font-medium text-slate-700 mb-1">Result</label>
                <input type="number" step="0.01" required value={formData.resultValue} onChange={e => setFormData({...formData, resultValue: parseFloat(e.target.value) || 0})} className="w-full p-2 border rounded-lg" />
              </div>
              <div className="col-span-1">
                <label className="block text-sm font-medium text-slate-700 mb-1">Unit</label>
                <input type="text" required value={formData.unit} onChange={e => setFormData({...formData, unit: e.target.value})} className="w-full p-2 border rounded-lg" />
              </div>
              <div className="col-span-1">
                <label className="block text-sm font-medium text-slate-700 mb-1">Limit</label>
                <input type="number" step="0.01" required value={formData.referenceLimit} onChange={e => setFormData({...formData, referenceLimit: parseFloat(e.target.value) || 0})} className="w-full p-2 border rounded-lg" />
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Notes</label>
              <input type="text" value={formData.notes} onChange={e => setFormData({...formData, notes: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div className="md:col-span-2 flex justify-end gap-2 mt-2">
              <button type="button" onClick={() => setIsAdding(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg">Cancel</button>
              <button type="submit" className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">Save Record</button>
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
              <th className="p-4 font-medium">Substance & Sample</th>
              <th className="p-4 font-medium">Result / Limit</th>
              <th className="p-4 font-medium">Status</th>
            </tr>
          </thead>
          <tbody>
            {records.map(record => (
              <tr key={record.id} className="border-b border-slate-100 hover:bg-slate-50">
                <td className="p-4 text-slate-600">{new Date(record.dateSampled).toLocaleDateString()}</td>
                <td className="p-4 font-medium text-slate-900">{record.employeeName}</td>
                <td className="p-4 text-slate-600">
                  <div className="flex flex-col">
                    <span className="font-medium">{record.substance}</span>
                    <span className="text-xs text-slate-400 flex items-center gap-1"><Beaker size={12}/> {record.sampleType}</span>
                  </div>
                </td>
                <td className="p-4 text-slate-600">
                  <span className="font-bold">{record.resultValue}</span>
                  <span className="text-xs text-slate-400 ml-1">{record.unit}</span>
                  <span className="text-xs text-slate-400 block">Limit: {record.referenceLimit} {record.unit}</span>
                </td>
                <td className="p-4">
                  {record.status === 'Normal' && <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800"><CheckCircle2 size={12}/> Normal</span>}
                  {record.status === 'Action Level' && <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-amber-100 text-amber-800"><Info size={12}/> Action Level</span>}
                  {record.status === 'Exceeded' && <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-red-100 text-red-800"><AlertCircle size={12}/> Exceeded</span>}
                </td>
              </tr>
            ))}
            {records.length === 0 && !isAdding && (
              <tr>
                <td colSpan={5} className="p-8 text-center text-slate-500">No biological monitoring records found.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
