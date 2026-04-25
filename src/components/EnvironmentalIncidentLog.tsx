import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy, where } from 'firebase/firestore';
import { db, auth, handleFirestoreError } from '../lib/firebase';
import { useAuth } from '../contexts/AuthContext';
import { Plus, AlertTriangle, Calendar } from 'lucide-react';

interface Incident {
  id: string;
  type: 'Spill' | 'Emission' | 'Noise' | 'Other';
  description: string;
  severity: 'Minor' | 'Major' | 'Critical';
  date: string;
  authorId: string;
  createdAt: string;
}

export default function EnvironmentalIncidentLog() {
  const { profile } = useAuth();
  const [incidents, setIncidents] = useState<Incident[]>([]);
  const [isAdding, setIsAdding] = useState(false);

  useEffect(() => {
    if (!profile?.siteId) return;
    const q = query(collection(db, 'env_incidents'), where('siteId', '==', profile.siteId), orderBy('createdAt', 'desc'));
    const unsub = onSnapshot(q, (snapshot) => {
      setIncidents(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as Incident)));
    }, (error) => handleFirestoreError(error, 'list' as any, 'env_incidents'));
    return () => unsub();
  }, [profile?.siteId]);

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h2 className="text-lg font-bold text-slate-900">Environmental Incident Log</h2>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-red-600 text-white px-3 py-1.5 rounded-lg text-sm hover:bg-red-700">
          <Plus size={16} /> Log Incident
        </button>
      </div>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {incidents.map(incident => (
          <div key={incident.id} className="border border-slate-200 rounded-lg p-4 bg-white shadow-sm">
            <div className="flex items-center gap-2">
              <AlertTriangle size={20} className="text-red-500" />
              <h3 className="font-semibold">{incident.type}</h3>
              <span className={`text-xs px-2 py-1 rounded-full ${incident.severity === 'Critical' ? 'bg-red-100 text-red-800' : 'bg-amber-100 text-amber-800'}`}>
                {incident.severity}
              </span>
            </div>
            <p className="text-sm text-slate-600 mt-2">{incident.description}</p>
            <div className="text-xs text-slate-500 mt-2 flex items-center gap-2">
              <Calendar size={12} /> {new Date(incident.date).toLocaleDateString()}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
