import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy, where } from 'firebase/firestore';
import { db, auth, handleFirestoreError } from '../lib/firebase';
import { useAuth } from '../contexts/AuthContext';
import { Plus, Target, Calendar } from 'lucide-react';

interface CalibrationRecord {
  id: string;
  equipmentName: string;
  lastCalibration: string;
  nextCalibration: string;
  status: 'Valid' | 'Expired';
  authorId: string;
  createdAt: string;
}

export default function CalibrationRegister() {
  const { profile } = useAuth();
  const [records, setRecords] = useState<CalibrationRecord[]>([]);
  const [isAdding, setIsAdding] = useState(false);

  useEffect(() => {
    if (!profile?.siteId) return;
    const q = query(collection(db, 'calibration_register'), where('siteId', '==', profile.siteId), orderBy('createdAt', 'desc'));
    const unsub = onSnapshot(q, (snapshot) => {
      setRecords(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as CalibrationRecord)));
    }, (error) => handleFirestoreError(error, 'list' as any, 'calibration_register'));
    return () => unsub();
  }, [profile?.siteId]);

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h2 className="text-lg font-bold text-slate-900">Calibration Register</h2>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-blue-600 text-white px-3 py-1.5 rounded-lg text-sm hover:bg-blue-700">
          <Plus size={16} /> Log Calibration
        </button>
      </div>
      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 text-sm">
              <th className="p-3">Equipment</th>
              <th className="p-3">Last</th>
              <th className="p-3">Next</th>
              <th className="p-3">Status</th>
            </tr>
          </thead>
          <tbody>
            {records.map(record => (
              <tr key={record.id} className="border-b border-slate-100">
                <td className="p-3 font-medium">{record.equipmentName}</td>
                <td className="p-3 text-sm">{new Date(record.lastCalibration).toLocaleDateString()}</td>
                <td className="p-3 text-sm">{new Date(record.nextCalibration).toLocaleDateString()}</td>
                <td className="p-3">
                  <span className={`px-2 py-1 rounded-full text-xs ${record.status === 'Valid' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}`}>
                    {record.status}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
