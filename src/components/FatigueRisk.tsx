import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { BatteryWarning, Plus, AlertTriangle, CheckCircle, TrendingUp } from 'lucide-react';

interface FatigueRecord {
  id: string;
  employeeName: string;
  consecutiveShifts: number;
  overtimeHours: number;
  commuteTimeMins: number;
  fatigueScore: number;
  status: 'Low Risk' | 'Moderate Risk' | 'High Risk';
  createdAt: string;
}

export default function FatigueRisk() {
  const [records, setRecords] = useState<FatigueRecord[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [formData, setFormData] = useState({
    employeeName: '',
    consecutiveShifts: 0,
    overtimeHours: 0,
    commuteTimeMins: 0
  });

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'fatigue_records'), orderBy('createdAt', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as FatigueRecord[];
      setRecords(data);
    }, (error) => handleFirestoreError(error, 'list' as any, 'fatigue_records'));
    return () => unsubscribe();
  }, []);

  const calculateFatigue = (shifts: number, overtime: number, commute: number) => {
    // Simple algorithm for demo purposes
    let score = (shifts * 10) + (overtime * 5) + (commute / 10);
    score = Math.min(Math.max(score, 0), 100);
    
    let status: FatigueRecord['status'] = 'Low Risk';
    if (score >= 75) status = 'High Risk';
    else if (score >= 40) status = 'Moderate Risk';
    
    return { score: Math.round(score), status };
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      const { score, status } = calculateFatigue(formData.consecutiveShifts, formData.overtimeHours, formData.commuteTimeMins);
      await addDoc(collection(db, 'fatigue_records'), {
        ...formData,
        fatigueScore: score,
        status,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAdding(false);
      setFormData({ employeeName: '', consecutiveShifts: 0, overtimeHours: 0, commuteTimeMins: 0 });
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'fatigue_records');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">Fatigue Risk Management System (FRMS)</h2>
          <p className="text-sm text-slate-500">Monitor shift patterns and calculate fatigue risk scores.</p>
        </div>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700">
          <Plus size={18} /> Log Shift Data
        </button>
      </div>

      {isAdding && (
        <div className="bg-slate-50 p-4 rounded-lg border border-slate-200 mb-6">
          <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Employee Name</label>
              <input type="text" required value={formData.employeeName} onChange={e => setFormData({...formData, employeeName: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Consecutive Shifts Worked</label>
              <input type="number" min="0" required value={formData.consecutiveShifts} onChange={e => setFormData({...formData, consecutiveShifts: parseInt(e.target.value) || 0})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Overtime Hours (Past 7 Days)</label>
              <input type="number" min="0" required value={formData.overtimeHours} onChange={e => setFormData({...formData, overtimeHours: parseInt(e.target.value) || 0})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Average Daily Commute (Mins)</label>
              <input type="number" min="0" required value={formData.commuteTimeMins} onChange={e => setFormData({...formData, commuteTimeMins: parseInt(e.target.value) || 0})} className="w-full p-2 border rounded-lg" />
            </div>
            <div className="md:col-span-2 flex justify-end gap-2 mt-2">
              <button type="button" onClick={() => setIsAdding(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg">Cancel</button>
              <button type="submit" className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">Calculate & Save</button>
            </div>
          </form>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {records.map(record => (
          <div key={record.id} className="border border-slate-200 rounded-xl p-5 bg-white shadow-sm">
            <div className="flex justify-between items-start mb-4">
              <h3 className="font-semibold text-slate-900">{record.employeeName}</h3>
              <span className={`text-xs px-2.5 py-1 rounded-full font-medium flex items-center gap-1 ${
                record.status === 'High Risk' ? 'bg-red-100 text-red-800' :
                record.status === 'Moderate Risk' ? 'bg-amber-100 text-amber-800' :
                'bg-green-100 text-green-800'
              }`}>
                {record.status === 'High Risk' && <AlertTriangle size={12} />}
                {record.status === 'Moderate Risk' && <TrendingUp size={12} />}
                {record.status === 'Low Risk' && <CheckCircle size={12} />}
                {record.status}
              </span>
            </div>
            
            <div className="flex items-center gap-4 mb-4">
              <div className="relative w-16 h-16 flex items-center justify-center">
                <svg className="w-full h-full transform -rotate-90" viewBox="0 0 36 36">
                  <path d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831" fill="none" stroke="#E2E8F0" strokeWidth="3" />
                  <path d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831" fill="none" stroke={record.status === 'High Risk' ? '#EF4444' : record.status === 'Moderate Risk' ? '#F59E0B' : '#10B981'} strokeWidth="3" strokeDasharray={`${record.fatigueScore}, 100`} />
                </svg>
                <div className="absolute flex flex-col items-center justify-center">
                  <span className="text-lg font-bold text-slate-700">{record.fatigueScore}</span>
                </div>
              </div>
              <div className="flex-1 space-y-1 text-sm text-slate-600">
                <p className="flex justify-between"><span>Consecutive Shifts:</span> <span className="font-medium">{record.consecutiveShifts}</span></p>
                <p className="flex justify-between"><span>Overtime (7d):</span> <span className="font-medium">{record.overtimeHours}h</span></p>
                <p className="flex justify-between"><span>Commute:</span> <span className="font-medium">{record.commuteTimeMins}m</span></p>
              </div>
            </div>
            
            {record.status === 'High Risk' && (
              <div className="bg-red-50 text-red-700 text-xs p-2 rounded border border-red-100 flex items-start gap-2">
                <BatteryWarning size={14} className="shrink-0 mt-0.5" />
                <p>Action required: Consider schedule adjustment or mandatory rest period.</p>
              </div>
            )}
          </div>
        ))}
        {records.length === 0 && !isAdding && (
          <div className="col-span-full p-8 text-center text-slate-500 bg-slate-50 rounded-xl border border-dashed border-slate-300">
            No fatigue records logged.
          </div>
        )}
      </div>
    </div>
  );
}
