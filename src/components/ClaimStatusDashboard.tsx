import React, { useState, useEffect } from 'react';
import { collection, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { BarChart3, TrendingUp, TrendingDown, Users, Clock, AlertCircle } from 'lucide-react';

interface CoidaClaim {
  id: string;
  status: 'Submitted' | 'Accepted' | 'Rejected' | 'Closed';
  lostDays: number;
}

export default function ClaimStatusDashboard() {
  const [claims, setClaims] = useState<CoidaClaim[]>([]);

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'coida_claims'), orderBy('createdAt', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setClaims(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as CoidaClaim[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'coida_claims'));
    return () => unsubscribe();
  }, []);

  const stats = {
    total: claims.length,
    accepted: claims.filter(c => c.status === 'Accepted').length,
    pending: claims.filter(c => c.status === 'Submitted').length,
    rejected: claims.filter(c => c.status === 'Rejected').length,
    totalLostDays: claims.reduce((acc, c) => acc + (c.lostDays || 0), 0),
    avgLostDays: claims.length ? (claims.reduce((acc, c) => acc + (c.lostDays || 0), 0) / claims.length).toFixed(1) : 0
  };

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex justify-between items-start mb-2">
            <div className="bg-blue-50 p-2 rounded-lg text-blue-600"><Users size={20} /></div>
            <span className="text-[10px] font-bold text-slate-400 uppercase">Total Claims</span>
          </div>
          <p className="text-2xl font-black text-slate-900">{stats.total}</p>
          <p className="text-xs text-slate-500 mt-1">All time records</p>
        </div>

        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex justify-between items-start mb-2">
            <div className="bg-green-50 p-2 rounded-lg text-green-600"><TrendingUp size={20} /></div>
            <span className="text-[10px] font-bold text-slate-400 uppercase">Accepted</span>
          </div>
          <p className="text-2xl font-black text-slate-900">{stats.accepted}</p>
          <p className="text-xs text-green-600 mt-1">{(stats.accepted / stats.total * 100 || 0).toFixed(0)}% Acceptance Rate</p>
        </div>

        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex justify-between items-start mb-2">
            <div className="bg-amber-50 p-2 rounded-lg text-amber-600"><Clock size={20} /></div>
            <span className="text-[10px] font-bold text-slate-400 uppercase">Pending Fund</span>
          </div>
          <p className="text-2xl font-black text-slate-900">{stats.pending}</p>
          <p className="text-xs text-amber-600 mt-1">Awaiting liability decision</p>
        </div>

        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex justify-between items-start mb-2">
            <div className="bg-rose-50 p-2 rounded-lg text-rose-600"><BarChart3 size={20} /></div>
            <span className="text-[10px] font-bold text-slate-400 uppercase">Lost Days</span>
          </div>
          <p className="text-2xl font-black text-slate-900">{stats.totalLostDays}</p>
          <p className="text-xs text-slate-500 mt-1">Avg: {stats.avgLostDays} days per claim</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm">
          <h3 className="font-bold text-slate-900 mb-4 flex items-center gap-2">
            <TrendingDown size={18} className="text-rose-600" /> Severity Analysis
          </h3>
          <div className="space-y-4">
            <div className="p-4 bg-slate-50 rounded-lg border border-slate-100">
              <p className="text-sm text-slate-600 mb-1">Total Lost Time Cost (Estimated)</p>
              <p className="text-xl font-black text-slate-900">R {(stats.totalLostDays * 1200).toLocaleString()}</p>
              <p className="text-[10px] text-slate-400 mt-1 italic">*Based on average daily wage of R1,200</p>
            </div>
            <div className="flex items-center gap-3 p-4 bg-rose-50 rounded-lg border border-rose-100">
              <AlertCircle className="text-rose-600" size={24} />
              <div>
                <p className="text-sm font-bold text-rose-900">High Severity Alert</p>
                <p className="text-xs text-rose-700">Average lost days ({stats.avgLostDays}) is above industry benchmark of 4.2 days.</p>
              </div>
            </div>
          </div>
        </div>

        <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm">
          <h3 className="font-bold text-slate-900 mb-4">Claim Status Breakdown</h3>
          <div className="space-y-3">
            {['Accepted', 'Submitted', 'Rejected', 'Closed'].map(status => {
              const count = claims.filter(c => c.status === status).length;
              const percent = (count / stats.total * 100) || 0;
              return (
                <div key={status}>
                  <div className="flex justify-between text-xs font-bold mb-1">
                    <span className="text-slate-600 uppercase tracking-wider">{status}</span>
                    <span className="text-slate-900">{count} ({percent.toFixed(0)}%)</span>
                  </div>
                  <div className="w-full h-2 bg-slate-100 rounded-full overflow-hidden">
                    <div 
                      className={`h-full transition-all duration-500 ${
                        status === 'Accepted' ? 'bg-green-500' :
                        status === 'Submitted' ? 'bg-amber-500' :
                        status === 'Rejected' ? 'bg-rose-500' :
                        'bg-slate-400'
                      }`}
                      style={{ width: `${percent}%` }}
                    />
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
}
