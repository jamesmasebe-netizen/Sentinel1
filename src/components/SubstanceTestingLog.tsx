import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { FlaskConical, Plus, AlertTriangle, CheckCircle } from 'lucide-react';

interface TestingRecord {
  id: string;
  employeeName: string;
  testReason: 'Random' | 'Post-Incident' | 'Reasonable Suspicion' | 'Pre-Employment';
  testType: 'Alcohol' | 'Drugs (Multi-panel)' | 'Both';
  result: 'Negative' | 'Non-Negative' | 'Pending';
  dateConducted: string;
  actionTaken: string;
  createdAt: string;
}

export default function SubstanceTestingLog() {
  const [records, setRecords] = useState<TestingRecord[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [formData, setFormData] = useState({
    employeeName: '',
    testReason: 'Random' as TestingRecord['testReason'],
    testType: 'Alcohol' as TestingRecord['testType'],
    result: 'Negative' as TestingRecord['result'],
    dateConducted: '',
    actionTaken: ''
  });

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'substance_testing'), orderBy('createdAt', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as TestingRecord[];
      setRecords(data);
    }, (error) => handleFirestoreError(error, 'list' as any, 'substance_testing'));
    return () => unsubscribe();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      await addDoc(collection(db, 'substance_testing'), {
        ...formData,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAdding(false);
      setFormData({ employeeName: '', testReason: 'Random', testType: 'Alcohol', result: 'Negative', dateConducted: '', actionTaken: '' });
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'substance_testing');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">Substance & Alcohol Testing</h2>
          <p className="text-sm text-slate-500">Log random, post-incident, and suspicion-based testing.</p>
        </div>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700">
          <Plus size={18} /> Log Test
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
              <label className="block text-sm font-medium text-slate-700 mb-1">Date Conducted</label>
              <input type="date" required value={formData.dateConducted} onChange={e => setFormData({...formData, dateConducted: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Reason for Test</label>
              <select value={formData.testReason} onChange={e => setFormData({...formData, testReason: e.target.value as any})} className="w-full p-2 border rounded-lg">
                <option value="Random">Random</option>
                <option value="Post-Incident">Post-Incident</option>
                <option value="Reasonable Suspicion">Reasonable Suspicion</option>
                <option value="Pre-Employment">Pre-Employment</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Test Type</label>
              <select value={formData.testType} onChange={e => setFormData({...formData, testType: e.target.value as any})} className="w-full p-2 border rounded-lg">
                <option value="Alcohol">Alcohol</option>
                <option value="Drugs (Multi-panel)">Drugs (Multi-panel)</option>
                <option value="Both">Both</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Result</label>
              <select value={formData.result} onChange={e => setFormData({...formData, result: e.target.value as any})} className="w-full p-2 border rounded-lg">
                <option value="Negative">Negative</option>
                <option value="Non-Negative">Non-Negative (Positive)</option>
                <option value="Pending">Pending Lab Results</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Action Taken (if Non-Negative)</label>
              <input type="text" value={formData.actionTaken} onChange={e => setFormData({...formData, actionTaken: e.target.value})} placeholder="e.g., Suspended pending lab confirmation" className="w-full p-2 border rounded-lg" />
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
              <th className="p-4 font-medium">Reason & Type</th>
              <th className="p-4 font-medium">Result</th>
              <th className="p-4 font-medium">Action Taken</th>
            </tr>
          </thead>
          <tbody>
            {records.map(record => (
              <tr key={record.id} className="border-b border-slate-100 hover:bg-slate-50">
                <td className="p-4 text-slate-600">{new Date(record.dateConducted).toLocaleDateString()}</td>
                <td className="p-4 font-medium text-slate-900">{record.employeeName}</td>
                <td className="p-4 text-slate-600">
                  <div className="flex flex-col">
                    <span>{record.testReason}</span>
                    <span className="text-xs text-slate-400 flex items-center gap-1"><FlaskConical size={12}/> {record.testType}</span>
                  </div>
                </td>
                <td className="p-4">
                  {record.result === 'Negative' && <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800"><CheckCircle size={12}/> Negative</span>}
                  {record.result === 'Non-Negative' && <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-red-100 text-red-800"><AlertTriangle size={12}/> Non-Negative</span>}
                  {record.result === 'Pending' && <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-amber-100 text-amber-800">Pending</span>}
                </td>
                <td className="p-4 text-slate-600 text-sm">{record.actionTaken || '-'}</td>
              </tr>
            ))}
            {records.length === 0 && !isAdding && (
              <tr>
                <td colSpan={5} className="p-8 text-center text-slate-500">No substance testing records found.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
