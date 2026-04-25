import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { UserCheck, Plus, AlertTriangle, CheckCircle, Clock } from 'lucide-react';

interface RTWRecord {
  id: string;
  employeeName: string;
  injuryDate: string;
  rtwDate: string;
  status: 'Full Duty' | 'Restricted Duty' | 'Off Work';
  restrictions: string;
  nextReviewDate: string;
  createdAt: string;
}

export default function ReturnToWork() {
  const [records, setRecords] = useState<RTWRecord[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [formData, setFormData] = useState({
    employeeName: '',
    injuryDate: '',
    rtwDate: '',
    status: 'Restricted Duty' as RTWRecord['status'],
    restrictions: '',
    nextReviewDate: ''
  });

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'rtw_records'), orderBy('createdAt', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as RTWRecord[];
      setRecords(data);
    }, (error) => handleFirestoreError(error, 'list' as any, 'rtw_records'));
    return () => unsubscribe();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      await addDoc(collection(db, 'rtw_records'), {
        ...formData,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAdding(false);
      setFormData({ employeeName: '', injuryDate: '', rtwDate: '', status: 'Restricted Duty', restrictions: '', nextReviewDate: '' });
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'rtw_records');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">Return to Work (RTW) Tracker</h2>
          <p className="text-sm text-slate-500">Manage rehabilitation and restricted duties.</p>
        </div>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700">
          <Plus size={18} /> Log RTW Case
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
              <label className="block text-sm font-medium text-slate-700 mb-1">Status</label>
              <select value={formData.status} onChange={e => setFormData({...formData, status: e.target.value as any})} className="w-full p-2 border rounded-lg">
                <option value="Full Duty">Full Duty</option>
                <option value="Restricted Duty">Restricted Duty</option>
                <option value="Off Work">Off Work</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Injury/Illness Date</label>
              <input type="date" required value={formData.injuryDate} onChange={e => setFormData({...formData, injuryDate: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Expected/Actual RTW Date</label>
              <input type="date" required value={formData.rtwDate} onChange={e => setFormData({...formData, rtwDate: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div className="md:col-span-2">
              <label className="block text-sm font-medium text-slate-700 mb-1">Restrictions / Accommodations</label>
              <input type="text" value={formData.restrictions} onChange={e => setFormData({...formData, restrictions: e.target.value})} className="w-full p-2 border rounded-lg" placeholder="e.g., No lifting over 10kg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Next Review Date</label>
              <input type="date" required value={formData.nextReviewDate} onChange={e => setFormData({...formData, nextReviewDate: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div className="md:col-span-2 flex justify-end gap-2 mt-2">
              <button type="button" onClick={() => setIsAdding(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg">Cancel</button>
              <button type="submit" className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">Save Case</button>
            </div>
          </form>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {records.map(record => (
          <div key={record.id} className="border border-slate-200 rounded-xl p-4 bg-white shadow-sm">
            <div className="flex justify-between items-start mb-3">
              <div className="flex items-center gap-2">
                <div className="p-2 bg-blue-50 text-blue-600 rounded-lg"><UserCheck size={20} /></div>
                <h3 className="font-semibold text-slate-900">{record.employeeName}</h3>
              </div>
              {record.status === 'Full Duty' && <span className="bg-green-100 text-green-800 text-xs px-2 py-1 rounded-full flex items-center gap-1"><CheckCircle size={12}/> Full Duty</span>}
              {record.status === 'Restricted Duty' && <span className="bg-amber-100 text-amber-800 text-xs px-2 py-1 rounded-full flex items-center gap-1"><AlertTriangle size={12}/> Restricted</span>}
              {record.status === 'Off Work' && <span className="bg-red-100 text-red-800 text-xs px-2 py-1 rounded-full flex items-center gap-1"><Clock size={12}/> Off Work</span>}
            </div>
            <div className="space-y-2 text-sm text-slate-600">
              <p><span className="font-medium">Injury Date:</span> {new Date(record.injuryDate).toLocaleDateString()}</p>
              <p><span className="font-medium">RTW Date:</span> {new Date(record.rtwDate).toLocaleDateString()}</p>
              {record.restrictions && <p><span className="font-medium">Restrictions:</span> {record.restrictions}</p>}
              <p className="text-blue-600 font-medium mt-2 pt-2 border-t border-slate-100">Next Review: {new Date(record.nextReviewDate).toLocaleDateString()}</p>
            </div>
          </div>
        ))}
        {records.length === 0 && !isAdding && (
          <div className="col-span-full p-8 text-center text-slate-500 bg-slate-50 rounded-xl border border-dashed border-slate-300">
            No Return to Work cases currently tracked.
          </div>
        )}
      </div>
    </div>
  );
}
