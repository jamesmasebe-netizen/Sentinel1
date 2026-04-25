import React, { useState, useEffect } from 'react';
import { collection, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { PieChart, BarChart, TrendingUp, Recycle, Trash2, Leaf } from 'lucide-react';

interface WasteRecord {
  id: string;
  wasteType: string;
  quantity: number;
  unit: string;
  disposalMethod: 'Recycle' | 'Reuse' | 'Recover' | 'Landfill' | 'Incinerate';
  date: string;
}

export default function WasteHierarchyAnalytics() {
  const [records, setRecords] = useState<WasteRecord[]>([]);
  const [stats, setStats] = useState({
    total: 0,
    recycled: 0,
    landfill: 0,
    diversionRate: 0
  });

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'env_waste_manifests'), orderBy('date', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as WasteRecord[];
      setRecords(data);
      
      const total = data.reduce((acc, r) => acc + r.quantity, 0);
      const recycled = data.filter(r => r.disposalMethod === 'Recycle' || r.disposalMethod === 'Reuse').reduce((acc, r) => acc + r.quantity, 0);
      const landfill = data.filter(r => r.disposalMethod === 'Landfill').reduce((acc, r) => acc + r.quantity, 0);
      
      setStats({
        total,
        recycled,
        landfill,
        diversionRate: total > 0 ? (recycled / total) * 100 : 0
      });
    }, (error) => handleFirestoreError(error, 'list' as any, 'env_waste_manifests'));
    return () => unsubscribe();
  }, []);

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">Waste Hierarchy Analytics</h2>
          <p className="text-sm text-slate-500">Visualize waste diversion efforts and progress towards zero-waste-to-landfill.</p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex justify-between items-start mb-2">
            <div className="bg-slate-50 p-2 rounded-lg text-slate-600"><Trash2 size={20} /></div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Total Waste</span>
          </div>
          <p className="text-2xl font-black text-slate-900">{stats.total.toFixed(2)} <span className="text-xs font-normal text-slate-500">tons</span></p>
        </div>
        
        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex justify-between items-start mb-2">
            <div className="bg-green-50 p-2 rounded-lg text-green-600"><Recycle size={20} /></div>
            <span className="text-[10px] font-bold text-green-600 uppercase tracking-wider">Recycled/Reused</span>
          </div>
          <p className="text-2xl font-black text-green-700">{stats.recycled.toFixed(2)} <span className="text-xs font-normal text-slate-500">tons</span></p>
        </div>

        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex justify-between items-start mb-2">
            <div className="bg-amber-50 p-2 rounded-lg text-amber-600"><TrendingUp size={20} /></div>
            <span className="text-[10px] font-bold text-amber-600 uppercase tracking-wider">Diversion Rate</span>
          </div>
          <p className="text-2xl font-black text-amber-700">{stats.diversionRate.toFixed(1)}%</p>
        </div>

        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex justify-between items-start mb-2">
            <div className="bg-blue-50 p-2 rounded-lg text-blue-600"><Leaf size={20} /></div>
            <span className="text-[10px] font-bold text-blue-600 uppercase tracking-wider">Environmental Impact</span>
          </div>
          <p className="text-2xl font-black text-blue-700">Positive</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm">
          <h3 className="font-bold text-slate-900 mb-4 flex items-center gap-2"><PieChart size={18} className="text-slate-400" /> Waste by Disposal Method</h3>
          <div className="space-y-4">
            {['Recycle', 'Reuse', 'Recover', 'Landfill', 'Incinerate'].map(method => {
              const methodTotal = records.filter(r => r.disposalMethod === method).reduce((acc, r) => acc + r.quantity, 0);
              const percentage = stats.total > 0 ? (methodTotal / stats.total) * 100 : 0;
              return (
                <div key={method} className="space-y-1">
                  <div className="flex justify-between text-xs font-medium">
                    <span className="text-slate-600">{method}</span>
                    <span className="text-slate-900 font-bold">{methodTotal.toFixed(2)} tons ({percentage.toFixed(1)}%)</span>
                  </div>
                  <div className="h-2 bg-slate-100 rounded-full overflow-hidden">
                    <div 
                      className={`h-full rounded-full ${
                        method === 'Recycle' || method === 'Reuse' ? 'bg-green-500' :
                        method === 'Landfill' ? 'bg-red-500' : 'bg-blue-500'
                      }`}
                      style={{ width: `${percentage}%` }}
                    ></div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm">
          <h3 className="font-bold text-slate-900 mb-4 flex items-center gap-2"><BarChart size={18} className="text-slate-400" /> Recent Waste Streams</h3>
          <div className="space-y-3">
            {records.slice(0, 5).map(record => (
              <div key={record.id} className="flex items-center justify-between p-3 bg-slate-50 rounded-lg border border-slate-100">
                <div className="flex items-center gap-3">
                  <div className={`p-2 rounded-lg ${
                    record.disposalMethod === 'Recycle' ? 'bg-green-100 text-green-600' : 'bg-slate-200 text-slate-600'
                  }`}>
                    <Trash2 size={16} />
                  </div>
                  <div>
                    <p className="text-sm font-bold text-slate-900">{record.wasteType}</p>
                    <p className="text-[10px] text-slate-400 uppercase font-bold">{new Date(record.date).toLocaleDateString()}</p>
                  </div>
                </div>
                <div className="text-right">
                  <p className="text-sm font-black text-slate-900">{record.quantity} {record.unit}</p>
                  <p className="text-[10px] text-slate-400 uppercase font-bold">{record.disposalMethod}</p>
                </div>
              </div>
            ))}
            {records.length === 0 && (
              <div className="p-8 text-center text-slate-500">No waste records found for analysis.</div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
