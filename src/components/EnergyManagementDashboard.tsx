import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy, where } from 'firebase/firestore';
import { db, auth, handleFirestoreError } from '../lib/firebase';
import { useAuth } from '../contexts/AuthContext';
import { Plus, Zap, Calendar } from 'lucide-react';

interface EnergyRecord {
  id: string;
  source: 'Electricity' | 'Gas' | 'Diesel' | 'Solar';
  consumption: number;
  unit: 'kWh' | 'm3' | 'Liters';
  date: string;
  authorId: string;
  createdAt: string;
}

export default function EnergyManagementDashboard() {
  const { profile } = useAuth();
  const [records, setRecords] = useState<EnergyRecord[]>([]);
  const [isAdding, setIsAdding] = useState(false);

  useEffect(() => {
    if (!profile?.siteId) return;
    const q = query(collection(db, 'energy_consumption'), where('siteId', '==', profile.siteId), orderBy('createdAt', 'desc'));
    const unsub = onSnapshot(q, (snapshot) => {
      setRecords(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as EnergyRecord)));
    }, (error) => handleFirestoreError(error, 'list' as any, 'energy_consumption'));
    return () => unsub();
  }, [profile?.siteId]);

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h2 className="text-lg font-bold text-slate-900">Energy Management</h2>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-green-600 text-white px-3 py-1.5 rounded-lg text-sm hover:bg-green-700">
          <Plus size={16} /> Log Consumption
        </button>
      </div>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {records.map(record => (
          <div key={record.id} className="border border-slate-200 rounded-lg p-4 bg-white shadow-sm flex items-center gap-4">
            <Zap size={32} className="text-green-500" />
            <div>
              <h3 className="font-semibold">{record.source}</h3>
              <p className="text-sm text-slate-600">{record.consumption} {record.unit}</p>
              <p className="text-xs text-slate-500">{new Date(record.date).toLocaleDateString()}</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
