import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy, where } from 'firebase/firestore';
import { db, auth, handleFirestoreError } from '../lib/firebase';
import { useAuth } from '../contexts/AuthContext';
import { Plus, AlertTriangle, MapPin, Calendar } from 'lucide-react';

interface Hazard {
  id: string;
  title: string;
  description: string;
  location: string;
  severity: 'Low' | 'Medium' | 'High' | 'Critical';
  authorId: string;
  createdAt: string;
}

export default function HazardRegister() {
  const { profile } = useAuth();
  const [hazards, setHazards] = useState<Hazard[]>([]);
  const [isAdding, setIsAdding] = useState(false);

  useEffect(() => {
    if (!profile?.siteId) return;
    const q = query(collection(db, 'hazards'), where('siteId', '==', profile.siteId), orderBy('createdAt', 'desc'));
    const unsub = onSnapshot(q, (snapshot) => {
      setHazards(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as Hazard)));
    }, (error) => handleFirestoreError(error, 'list' as any, 'hazards'));
    return () => unsub();
  }, [profile?.siteId]);

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h2 className="text-lg font-bold text-slate-900">Hazard Register</h2>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-red-600 text-white px-3 py-1.5 rounded-lg text-sm hover:bg-red-700">
          <Plus size={16} /> Log Hazard
        </button>
      </div>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {hazards.map(hazard => (
          <div key={hazard.id} className="border border-slate-200 rounded-lg p-4 bg-white shadow-sm">
            <div className="flex items-center gap-2">
              <AlertTriangle size={20} className={hazard.severity === 'Critical' ? 'text-red-600' : 'text-amber-500'} />
              <h3 className="font-semibold">{hazard.title}</h3>
              <span className={`text-xs px-2 py-1 rounded-full ${hazard.severity === 'Critical' ? 'bg-red-100 text-red-800' : 'bg-amber-100 text-amber-800'}`}>
                {hazard.severity}
              </span>
            </div>
            <p className="text-sm text-slate-600 mt-2">{hazard.description}</p>
            <div className="flex items-center gap-2 text-xs text-slate-500 mt-2">
              <MapPin size={12} /> {hazard.location}
              <Calendar size={12} /> {new Date(hazard.createdAt).toLocaleDateString()}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
