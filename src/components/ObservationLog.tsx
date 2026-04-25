import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy, where } from 'firebase/firestore';
import { db, auth, handleFirestoreError } from '../lib/firebase';
import { useAuth } from '../contexts/AuthContext';
import { Plus, Eye, MapPin, Calendar } from 'lucide-react';

interface Observation {
  id: string;
  title: string;
  description: string;
  location: string;
  type: 'Safety' | 'Quality' | 'Environmental';
  authorId: string;
  createdAt: string;
}

export default function ObservationLog() {
  const { profile } = useAuth();
  const [observations, setObservations] = useState<Observation[]>([]);
  const [isAdding, setIsAdding] = useState(false);

  useEffect(() => {
    if (!profile?.siteId) return;
    const q = query(collection(db, 'observations'), where('siteId', '==', profile.siteId), orderBy('createdAt', 'desc'));
    const unsub = onSnapshot(q, (snapshot) => {
      setObservations(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as Observation)));
    }, (error) => handleFirestoreError(error, 'list' as any, 'observations'));
    return () => unsub();
  }, [profile?.siteId]);

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h2 className="text-lg font-bold text-slate-900">Observation Log</h2>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-indigo-600 text-white px-3 py-1.5 rounded-lg text-sm hover:bg-indigo-700">
          <Plus size={16} /> Log Observation
        </button>
      </div>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {observations.map(obs => (
          <div key={obs.id} className="border border-slate-200 rounded-lg p-4 bg-white shadow-sm">
            <h3 className="font-semibold">{obs.title}</h3>
            <p className="text-sm text-slate-600">{obs.description}</p>
            <div className="flex items-center gap-2 text-xs text-slate-500 mt-2">
              <MapPin size={12} /> {obs.location}
              <Calendar size={12} /> {new Date(obs.createdAt).toLocaleDateString()}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
