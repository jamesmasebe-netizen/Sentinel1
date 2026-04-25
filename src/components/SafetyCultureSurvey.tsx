import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy, where } from 'firebase/firestore';
import { db, auth, handleFirestoreError } from '../lib/firebase';
import { useAuth } from '../contexts/AuthContext';
import { Plus, Target, MessageSquare } from 'lucide-react';

interface Survey {
  id: string;
  topic: string;
  score: number;
  comments: string;
  authorId: string;
  createdAt: string;
}

export default function SafetyCultureSurvey() {
  const { profile } = useAuth();
  const [surveys, setSurveys] = useState<Survey[]>([]);
  const [isAdding, setIsAdding] = useState(false);

  useEffect(() => {
    if (!profile?.siteId) return;
    const q = query(collection(db, 'safety_culture'), where('siteId', '==', profile.siteId), orderBy('createdAt', 'desc'));
    const unsub = onSnapshot(q, (snapshot) => {
      setSurveys(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as Survey)));
    }, (error) => handleFirestoreError(error, 'list' as any, 'safety_culture'));
    return () => unsub();
  }, [profile?.siteId]);

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h2 className="text-lg font-bold text-slate-900">Safety Culture Survey</h2>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-emerald-600 text-white px-3 py-1.5 rounded-lg text-sm hover:bg-emerald-700">
          <Plus size={16} /> Submit Survey
        </button>
      </div>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {surveys.map(survey => (
          <div key={survey.id} className="border border-slate-200 rounded-lg p-4 bg-white shadow-sm">
            <div className="flex items-center justify-between">
              <h3 className="font-semibold">{survey.topic}</h3>
              <span className="text-sm font-bold text-emerald-600">{survey.score}/10</span>
            </div>
            <p className="text-sm text-slate-600 mt-2 italic">"{survey.comments}"</p>
          </div>
        ))}
      </div>
    </div>
  );
}
