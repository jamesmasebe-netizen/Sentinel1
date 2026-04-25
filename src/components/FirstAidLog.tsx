import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { BriefcaseMedical, Plus, Clock } from 'lucide-react';

interface FirstAidRecord {
  id: string;
  dateTime: string;
  employeeName: string;
  injuryType: string;
  treatment: string;
  treatedBy: string;
  referredToHospital: boolean;
  createdAt: string;
}

export default function FirstAidLog() {
  const [records, setRecords] = useState<FirstAidRecord[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [formData, setFormData] = useState({
    dateTime: '',
    employeeName: '',
    injuryType: '',
    treatment: '',
    treatedBy: '',
    referredToHospital: false
  });

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'first_aid_logs'), orderBy('dateTime', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as FirstAidRecord[];
      setRecords(data);
    }, (error) => handleFirestoreError(error, 'list' as any, 'first_aid_logs'));
    return () => unsubscribe();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      await addDoc(collection(db, 'first_aid_logs'), {
        ...formData,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAdding(false);
      setFormData({ dateTime: '', employeeName: '', injuryType: '', treatment: '', treatedBy: '', referredToHospital: false });
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'first_aid_logs');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">Clinic & First Aid Log</h2>
          <p className="text-sm text-slate-500">Quick-entry log for minor injuries and clinic visits.</p>
        </div>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700">
          <Plus size={18} /> Log Treatment
        </button>
      </div>

      {isAdding && (
        <div className="bg-slate-50 p-4 rounded-lg border border-slate-200 mb-6">
          <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Date & Time</label>
              <input type="datetime-local" required value={formData.dateTime} onChange={e => setFormData({...formData, dateTime: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Employee Name</label>
              <input type="text" required value={formData.employeeName} onChange={e => setFormData({...formData, employeeName: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Injury / Complaint</label>
              <input type="text" required placeholder="e.g., Minor cut on left thumb" value={formData.injuryType} onChange={e => setFormData({...formData, injuryType: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Treated By (First Aider/Nurse)</label>
              <input type="text" required value={formData.treatedBy} onChange={e => setFormData({...formData, treatedBy: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div className="md:col-span-2">
              <label className="block text-sm font-medium text-slate-700 mb-1">Treatment Given</label>
              <textarea required value={formData.treatment} onChange={e => setFormData({...formData, treatment: e.target.value})} className="w-full p-2 border rounded-lg" rows={2} placeholder="e.g., Cleaned wound, applied plaster"></textarea>
            </div>
            <div className="md:col-span-2 flex items-center gap-2">
              <input type="checkbox" id="hospital" checked={formData.referredToHospital} onChange={e => setFormData({...formData, referredToHospital: e.target.checked})} className="w-4 h-4 text-blue-600 rounded border-slate-300" />
              <label htmlFor="hospital" className="text-sm font-medium text-slate-700">Referred to Hospital / Doctor</label>
            </div>
            <div className="md:col-span-2 flex justify-end gap-2 mt-2">
              <button type="button" onClick={() => setIsAdding(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg">Cancel</button>
              <button type="submit" className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">Save Log</button>
            </div>
          </form>
        </div>
      )}

      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 text-sm">
              <th className="p-4 font-medium">Date & Time</th>
              <th className="p-4 font-medium">Employee</th>
              <th className="p-4 font-medium">Complaint</th>
              <th className="p-4 font-medium">Treatment</th>
              <th className="p-4 font-medium">Hospital Ref.</th>
            </tr>
          </thead>
          <tbody>
            {records.map(record => (
              <tr key={record.id} className="border-b border-slate-100 hover:bg-slate-50">
                <td className="p-4 text-slate-600 whitespace-nowrap">
                  <div className="flex items-center gap-2">
                    <Clock size={14} className="text-slate-400"/>
                    {new Date(record.dateTime).toLocaleString([], { dateStyle: 'short', timeStyle: 'short' })}
                  </div>
                </td>
                <td className="p-4 font-medium text-slate-900">{record.employeeName}</td>
                <td className="p-4 text-slate-600">{record.injuryType}</td>
                <td className="p-4 text-slate-600 max-w-xs truncate" title={record.treatment}>{record.treatment}</td>
                <td className="p-4">
                  {record.referredToHospital ? (
                    <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-red-100 text-red-800">Yes</span>
                  ) : (
                    <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-slate-100 text-slate-800">No</span>
                  )}
                </td>
              </tr>
            ))}
            {records.length === 0 && !isAdding && (
              <tr>
                <td colSpan={5} className="p-8 text-center text-slate-500">No clinic visits logged.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
