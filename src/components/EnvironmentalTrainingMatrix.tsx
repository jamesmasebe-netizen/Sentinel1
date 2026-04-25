import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { GraduationCap, Plus, CheckCircle2, XCircle, AlertCircle, User } from 'lucide-react';

interface TrainingRecord {
  id: string;
  employeeName: string;
  trainingType: 'ISO 14001 Awareness' | 'Spill Response' | 'Waste Management' | 'Emergency Preparedness';
  completionDate: string;
  expiryDate: string;
  status: 'Valid' | 'Expired' | 'Due Soon';
  createdAt: string;
}

export default function EnvironmentalTrainingMatrix() {
  const [records, setRecords] = useState<TrainingRecord[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [formData, setFormData] = useState({
    employeeName: '',
    trainingType: 'ISO 14001 Awareness' as TrainingRecord['trainingType'],
    completionDate: '',
    expiryDate: ''
  });

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'env_training'), orderBy('completionDate', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setRecords(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as TrainingRecord[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'env_training'));
    return () => unsubscribe();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      const expiry = new Date(formData.expiryDate);
      const today = new Date();
      let status: TrainingRecord['status'] = 'Valid';
      if (expiry < today) status = 'Expired';
      else if (expiry.getTime() - today.getTime() < 30 * 24 * 60 * 60 * 1000) status = 'Due Soon';

      await addDoc(collection(db, 'env_training'), {
        ...formData,
        status,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAdding(false);
      setFormData({ employeeName: '', trainingType: 'ISO 14001 Awareness', completionDate: '', expiryDate: '' });
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'env_training');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">Environmental Training Matrix</h2>
          <p className="text-sm text-slate-500">Track environmental awareness and competency training for all employees.</p>
        </div>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-indigo-600 text-white px-4 py-2 rounded-lg hover:bg-indigo-700">
          <Plus size={18} /> Log Training
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
              <label className="block text-sm font-medium text-slate-700 mb-1">Training Type</label>
              <select value={formData.trainingType} onChange={e => setFormData({...formData, trainingType: e.target.value as any})} className="w-full p-2 border rounded-lg">
                <option value="ISO 14001 Awareness">ISO 14001 Awareness</option>
                <option value="Spill Response">Spill Response & Control</option>
                <option value="Waste Management">Waste Management & Segregation</option>
                <option value="Emergency Preparedness">Environmental Emergency Preparedness</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Completion Date</label>
              <input type="date" required value={formData.completionDate} onChange={e => setFormData({...formData, completionDate: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Expiry Date</label>
              <input type="date" required value={formData.expiryDate} onChange={e => setFormData({...formData, expiryDate: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div className="md:col-span-2 flex justify-end gap-2 mt-2">
              <button type="button" onClick={() => setIsAdding(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg">Cancel</button>
              <button type="submit" className="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700">Save Record</button>
            </div>
          </form>
        </div>
      )}

      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 text-sm">
              <th className="p-4 font-medium">Employee</th>
              <th className="p-4 font-medium">Training Type</th>
              <th className="p-4 font-medium">Completed</th>
              <th className="p-4 font-medium">Expiry</th>
              <th className="p-4 font-medium">Status</th>
            </tr>
          </thead>
          <tbody>
            {records.map(record => (
              <tr key={record.id} className="border-b border-slate-100 hover:bg-slate-50">
                <td className="p-4">
                  <div className="flex items-center gap-2">
                    <User size={16} className="text-slate-400" />
                    <span className="font-bold text-slate-900">{record.employeeName}</span>
                  </div>
                </td>
                <td className="p-4 text-slate-600 font-medium">{record.trainingType}</td>
                <td className="p-4 text-slate-600">{new Date(record.completionDate).toLocaleDateString()}</td>
                <td className="p-4 text-slate-600">{new Date(record.expiryDate).toLocaleDateString()}</td>
                <td className="p-4">
                  <span className={`text-[10px] px-2 py-1 rounded-full font-bold uppercase tracking-wider ${
                    record.status === 'Valid' ? 'bg-green-100 text-green-800' :
                    record.status === 'Expired' ? 'bg-red-100 text-red-800' :
                    'bg-amber-100 text-amber-800'
                  }`}>
                    {record.status}
                  </span>
                </td>
              </tr>
            ))}
            {records.length === 0 && !isAdding && (
              <tr>
                <td colSpan={5} className="p-8 text-center text-slate-500">No training records logged.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
