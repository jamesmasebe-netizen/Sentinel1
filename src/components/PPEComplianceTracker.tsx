import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy, where } from 'firebase/firestore';
import { db, auth, handleFirestoreError } from '../lib/firebase';
import { useAuth } from '../contexts/AuthContext';
import { Plus, CheckSquare, Calendar, Bell, AlertCircle, HardHat } from 'lucide-react';

interface PPECompliance {
  id: string;
  employeeName: string;
  ppeType: string;
  status: 'Compliant' | 'Non-Compliant' | 'Expired';
  expiryDate: string;
  authorId: string;
  createdAt: string;
}

export default function PPEComplianceTracker() {
  const { profile } = useAuth();
  const [records, setRecords] = useState<PPECompliance[]>([]);
  const [isAdding, setIsAdding] = useState(false);

  useEffect(() => {
    if (!profile?.siteId) return;
    const q = query(collection(db, 'ppe_compliance'), where('siteId', '==', profile.siteId), orderBy('createdAt', 'desc'));
    const unsub = onSnapshot(q, (snapshot) => {
      setRecords(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as PPECompliance)));
    }, (error) => handleFirestoreError(error, 'list' as any, 'ppe_compliance'));
    return () => unsub();
  }, [profile?.siteId]);

  // Calculate stats
  const total = records.length;
  const compliant = records.filter(r => r.status === 'Compliant').length;
  const nonCompliant = records.filter(r => r.status === 'Non-Compliant').length;
  const expired = records.filter(r => r.status === 'Expired').length;
  
  // Find upcoming expirations (within 30 days)
  const upcomingExpirations = records.filter(r => {
    if (r.status !== 'Compliant') return false;
    const expiry = new Date(r.expiryDate).getTime();
    const now = new Date().getTime();
    const diffDays = (expiry - now) / (1000 * 3600 * 24);
    return diffDays > 0 && diffDays <= 30;
  });

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h2 className="text-lg font-bold text-slate-900">PPE Compliance Tracker</h2>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-red-600 text-white px-3 py-1.5 rounded-lg text-sm hover:bg-red-700">
          <Plus size={16} /> Log Compliance
        </button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm flex items-center gap-4">
          <div className="p-3 rounded-full bg-slate-100 text-slate-600">
            <HardHat size={24} />
          </div>
          <div>
            <p className="text-sm text-slate-500 font-medium">Total Tracked</p>
            <h3 className="text-2xl font-bold text-slate-900">{total}</h3>
          </div>
        </div>
        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm flex items-center gap-4">
          <div className="p-3 rounded-full bg-green-100 text-green-600">
            <CheckSquare size={24} />
          </div>
          <div>
            <p className="text-sm text-slate-500 font-medium">Compliant</p>
            <h3 className="text-2xl font-bold text-slate-900">{compliant}</h3>
          </div>
        </div>
        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm flex items-center gap-4">
          <div className="p-3 rounded-full bg-red-100 text-red-600">
            <AlertCircle size={24} />
          </div>
          <div>
            <p className="text-sm text-slate-500 font-medium">Non-Compliant</p>
            <h3 className="text-2xl font-bold text-slate-900">{nonCompliant}</h3>
          </div>
        </div>
        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm flex items-center gap-4">
          <div className="p-3 rounded-full bg-amber-100 text-amber-600">
            <Calendar size={24} />
          </div>
          <div>
            <p className="text-sm text-slate-500 font-medium">Expired</p>
            <h3 className="text-2xl font-bold text-slate-900">{expired}</h3>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Table */}
        <div className="lg:col-span-2 bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
          <div className="p-4 border-b border-slate-200 bg-slate-50">
            <h3 className="font-bold text-slate-800">Compliance Log</h3>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 text-sm">
                  <th className="p-3">Employee</th>
                  <th className="p-3">PPE Type</th>
                  <th className="p-3">Status</th>
                  <th className="p-3">Expiry</th>
                </tr>
              </thead>
              <tbody>
                {records.map(record => (
                  <tr key={record.id} className="border-b border-slate-100 hover:bg-slate-50">
                    <td className="p-3 font-medium text-slate-900">{record.employeeName}</td>
                    <td className="p-3 text-slate-600">{record.ppeType}</td>
                    <td className="p-3">
                      <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                        record.status === 'Compliant' ? 'bg-green-100 text-green-800 border border-green-200' : 
                        record.status === 'Expired' ? 'bg-amber-100 text-amber-800 border border-amber-200' :
                        'bg-red-100 text-red-800 border border-red-200'
                      }`}>
                        {record.status}
                      </span>
                    </td>
                    <td className="p-3 text-sm text-slate-500">{new Date(record.expiryDate).toLocaleDateString()}</td>
                  </tr>
                ))}
                {records.length === 0 && (
                  <tr>
                    <td colSpan={4} className="p-8 text-center text-slate-500">No PPE records found.</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>

        {/* Smart Reminders Sidebar */}
        <div className="lg:col-span-1 space-y-4">
          <div className="bg-blue-50 border border-blue-200 rounded-xl p-4 shadow-sm">
            <div className="flex items-center gap-2 mb-4">
              <Bell className="text-blue-600" size={20} />
              <h3 className="font-bold text-blue-900">Smart Reminders</h3>
            </div>
            
            <div className="space-y-3">
              {upcomingExpirations.length > 0 ? (
                upcomingExpirations.map(record => {
                  const daysLeft = Math.ceil((new Date(record.expiryDate).getTime() - new Date().getTime()) / (1000 * 3600 * 24));
                  return (
                    <div key={`reminder-${record.id}`} className="bg-white p-3 rounded-lg border border-blue-100 shadow-sm">
                      <div className="flex justify-between items-start">
                        <div>
                          <p className="font-semibold text-slate-800 text-sm">{record.employeeName}</p>
                          <p className="text-xs text-slate-500">{record.ppeType}</p>
                        </div>
                        <span className="text-xs font-bold bg-amber-100 text-amber-800 px-2 py-1 rounded-full">
                          {daysLeft} days left
                        </span>
                      </div>
                      <button className="mt-2 text-xs text-blue-600 font-medium hover:text-blue-800 flex items-center gap-1">
                        Send Reminder <Bell size={12} />
                      </button>
                    </div>
                  );
                })
              ) : (
                <p className="text-sm text-blue-700">No upcoming expirations in the next 30 days.</p>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
