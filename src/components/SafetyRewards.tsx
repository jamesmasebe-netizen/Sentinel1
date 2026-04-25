import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy, where } from 'firebase/firestore';
import { db, auth, handleFirestoreError } from '../lib/firebase';
import { useAuth } from '../contexts/AuthContext';
import { Plus, Award, Trophy, Medal, Star } from 'lucide-react';

interface Reward {
  id: string;
  employeeName: string;
  reason: string;
  points: number;
  authorId: string;
  createdAt: string;
}

export default function SafetyRewards() {
  const { profile } = useAuth();
  const [rewards, setRewards] = useState<Reward[]>([]);
  const [isAdding, setIsAdding] = useState(false);

  useEffect(() => {
    if (!profile?.siteId) return;
    const q = query(collection(db, 'safety_rewards'), where('siteId', '==', profile.siteId), orderBy('createdAt', 'desc'));
    const unsub = onSnapshot(q, (snapshot) => {
      setRewards(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as Reward)));
    }, (error) => handleFirestoreError(error, 'list' as any, 'safety_rewards'));
    return () => unsub();
  }, [profile?.siteId]);

  // Calculate Leaderboard
  const leaderboard = rewards.reduce((acc, reward) => {
    if (!acc[reward.employeeName]) {
      acc[reward.employeeName] = 0;
    }
    acc[reward.employeeName] += reward.points;
    return acc;
  }, {} as Record<string, number>);

  const sortedLeaderboard = Object.entries(leaderboard)
    .sort(([, a], [, b]) => b - a)
    .slice(0, 5); // Top 5

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h2 className="text-lg font-bold text-slate-900">Safety Rewards & Leaderboard</h2>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-amber-600 text-white px-3 py-1.5 rounded-lg text-sm hover:bg-amber-700">
          <Plus size={16} /> Award Points
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Leaderboard Section */}
        <div className="lg:col-span-1 bg-gradient-to-br from-amber-50 to-orange-50 border border-amber-200 rounded-xl p-6 shadow-sm">
          <div className="flex items-center gap-2 mb-4">
            <Trophy className="text-amber-500" size={24} />
            <h3 className="text-lg font-bold text-amber-900">Top Performers</h3>
          </div>
          <div className="space-y-3">
            {sortedLeaderboard.map(([name, points], index) => (
              <div key={name} className="flex items-center justify-between bg-white p-3 rounded-lg shadow-sm border border-amber-100">
                <div className="flex items-center gap-3">
                  <div className={`w-8 h-8 rounded-full flex items-center justify-center font-bold ${
                    index === 0 ? 'bg-yellow-100 text-yellow-700' :
                    index === 1 ? 'bg-slate-100 text-slate-700' :
                    index === 2 ? 'bg-orange-100 text-orange-700' :
                    'bg-amber-50 text-amber-600'
                  }`}>
                    {index + 1}
                  </div>
                  <span className="font-semibold text-slate-800">{name}</span>
                </div>
                <div className="flex items-center gap-1 text-amber-600 font-bold">
                  {points} <Star size={14} className="fill-amber-500" />
                </div>
              </div>
            ))}
            {sortedLeaderboard.length === 0 && (
              <p className="text-sm text-amber-700 text-center py-4">No points awarded yet.</p>
            )}
          </div>
        </div>

        {/* Recent Awards Section */}
        <div className="lg:col-span-2 space-y-4">
          <h3 className="text-md font-bold text-slate-800">Recent Awards</h3>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {rewards.map(reward => (
              <div key={reward.id} className="border border-slate-200 rounded-lg p-4 bg-white shadow-sm flex items-start gap-4 hover:border-amber-300 transition-colors">
                <div className="bg-amber-100 p-2 rounded-full">
                  <Medal size={24} className="text-amber-600" />
                </div>
                <div>
                  <h4 className="font-semibold text-slate-900">{reward.employeeName}</h4>
                  <p className="text-sm text-slate-600 mt-1">{reward.reason}</p>
                  <div className="flex items-center gap-2 mt-2">
                    <span className="text-xs font-bold bg-amber-100 text-amber-800 px-2 py-1 rounded-full flex items-center gap-1">
                      +{reward.points} Points
                    </span>
                    <span className="text-xs text-slate-400">
                      {new Date(reward.createdAt).toLocaleDateString()}
                    </span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
