import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { Syringe, Plus, AlertTriangle, CheckCircle } from 'lucide-react';

interface VaccinationRecord {
  id: string;
  employeeName: string;
  vaccineType: string;
  dateAdministered: string;
  nextBoosterDue: string;
  status: 'Up to Date' | 'Overdue' | 'Pending';
  createdAt: string;
}

export default function VaccinationManager() {
  const [records, setRecords] = useState<VaccinationRecord[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [formData, setFormData] = useState({
    employeeName: '',
    vaccineType: 'Hepatitis B',
    dateAdministered: '',
    nextBoosterDue: '',
    status: 'Up to Date' as VaccinationRecord['status']
  });

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'vaccination_records'), orderBy('createdAt', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as VaccinationRecord[];
      setRecords(data);
    }, (error) => handleFirestoreError(error, 'list' as any, 'vaccination_records'));
    return () => unsubscribe();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      await addDoc(collection(db, 'vaccination_records'), {
        ...formData,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAdding(false);
      setFormData({ employeeName: '', vaccineType: 'Hepatitis B', dateAdministered: '', nextBoosterDue: '', status: 'Up to Date' });
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'vaccination_records');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">Vaccination & Immunization</h2>
          <p className="text-sm text-slate-500">Track employee immunizations and booster schedules.</p>
        </div>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700">
          <Plus size={18} /> Log Vaccination
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
              <label className="block text-sm font-medium text-slate-700 mb-1">Vaccine Type</label>
              <select value={formData.vaccineType} onChange={e => setFormData({...formData, vaccineType: e.target.value})} className="w-full p-2 border rounded-lg">
                <option value="Hepatitis B">Hepatitis B</option>
                <option value="Tetanus">Tetanus</option>
                <option value="Influenza">Influenza</option>
                <option value="Rabies">Rabies</option>
                <option value="Yellow Fever">Yellow Fever</option>
                <option value="Other">Other</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Date Administered</label>
              <input type="date" required value={formData.dateAdministered} onChange={e => setFormData({...formData, dateAdministered: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Next Booster Due</label>
              <input type="date" required value={formData.nextBoosterDue} onChange={e => setFormData({...formData, nextBoosterDue: e.target.value})} className="w-full p-2 border rounded-lg" />
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
              <th className="p-4 font-medium">Employee</th>
              <th className="p-4 font-medium">Vaccine</th>
              <th className="p-4 font-medium">Administered</th>
              <th className="p-4 font-medium">Next Booster</th>
              <th className="p-4 font-medium">Status</th>
            </tr>
          </thead>
          <tbody>
            {records.map(record => {
              const isOverdue = new Date(record.nextBoosterDue).getTime() < new Date().getTime();
              return (
                <tr key={record.id} className="border-b border-slate-100 hover:bg-slate-50">
                  <td className="p-4 font-medium text-slate-900">{record.employeeName}</td>
                  <td className="p-4 text-slate-600 flex items-center gap-2"><Syringe size={16} className="text-blue-500"/> {record.vaccineType}</td>
                  <td className="p-4 text-slate-600">{new Date(record.dateAdministered).toLocaleDateString()}</td>
                  <td className="p-4 text-slate-600">{new Date(record.nextBoosterDue).toLocaleDateString()}</td>
                  <td className="p-4">
                    {isOverdue ? (
                      <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-red-100 text-red-800"><AlertTriangle size={12}/> Overdue</span>
                    ) : (
                      <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800"><CheckCircle size={12}/> Up to Date</span>
                    )}
                  </td>
                </tr>
              );
            })}
            {records.length === 0 && !isAdding && (
              <tr>
                <td colSpan={5} className="p-8 text-center text-slate-500">No vaccination records found.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
