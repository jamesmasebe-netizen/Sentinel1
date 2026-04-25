import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { Stethoscope, Plus, Calendar, Clock, CheckCircle2, AlertCircle } from 'lucide-react';

interface MedicalReport {
  id: string;
  claimId: string;
  employeeName: string;
  reportType: 'W.Cl.4 (First)' | 'W.Cl.5 (Progress)' | 'W.Cl.5 (Final)';
  doctorName: string;
  dateReceived: string;
  expiryDate: string;
  notes: string;
  createdAt: string;
}

export default function MedicalProgressTracker() {
  const [reports, setReports] = useState<MedicalReport[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [formData, setFormData] = useState({
    employeeName: '',
    reportType: 'W.Cl.5 (Progress)' as MedicalReport['reportType'],
    doctorName: '',
    dateReceived: '',
    expiryDate: '',
    notes: ''
  });

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'coida_medical_reports'), orderBy('dateReceived', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setReports(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as MedicalReport[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'coida_medical_reports'));
    return () => unsubscribe();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      await addDoc(collection(db, 'coida_medical_reports'), {
        ...formData,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAdding(false);
      setFormData({ employeeName: '', reportType: 'W.Cl.5 (Progress)', doctorName: '', dateReceived: '', expiryDate: '', notes: '' });
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'coida_medical_reports');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">Medical Progress Tracker</h2>
          <p className="text-sm text-slate-500">Track W.Cl.4 and W.Cl.5 reports to ensure continuous claim liability.</p>
        </div>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-rose-600 text-white px-4 py-2 rounded-lg hover:bg-rose-700">
          <Plus size={18} /> Log Report
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
              <label className="block text-sm font-medium text-slate-700 mb-1">Report Type</label>
              <select value={formData.reportType} onChange={e => setFormData({...formData, reportType: e.target.value as any})} className="w-full p-2 border rounded-lg">
                <option value="W.Cl.4 (First)">W.Cl.4 (First Medical Report)</option>
                <option value="W.Cl.5 (Progress)">W.Cl.5 (Progress Report)</option>
                <option value="W.Cl.5 (Final)">W.Cl.5 (Final Report)</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Treating Doctor</label>
              <input type="text" required value={formData.doctorName} onChange={e => setFormData({...formData, doctorName: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div className="grid grid-cols-2 gap-2">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Date Received</label>
                <input type="date" required value={formData.dateReceived} onChange={e => setFormData({...formData, dateReceived: e.target.value})} className="w-full p-2 border rounded-lg" />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Expiry Date</label>
                <input type="date" required value={formData.expiryDate} onChange={e => setFormData({...formData, expiryDate: e.target.value})} className="w-full p-2 border rounded-lg" />
              </div>
            </div>
            <div className="md:col-span-2 flex justify-end gap-2 mt-2">
              <button type="button" onClick={() => setIsAdding(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg">Cancel</button>
              <button type="submit" className="px-4 py-2 bg-rose-600 text-white rounded-lg hover:bg-rose-700">Save Report</button>
            </div>
          </form>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {reports.map(report => {
          const isExpired = new Date(report.expiryDate) < new Date();
          return (
            <div key={report.id} className="border border-slate-200 rounded-xl p-5 bg-white shadow-sm hover:shadow-md transition-shadow">
              <div className="flex justify-between items-start mb-4">
                <div className="bg-rose-50 p-2 rounded-lg text-rose-600"><Stethoscope size={24} /></div>
                <span className={`text-xs px-2.5 py-1 rounded-full font-medium ${
                  report.reportType.includes('Final') ? 'bg-green-100 text-green-800' : 'bg-blue-100 text-blue-800'
                }`}>
                  {report.reportType}
                </span>
              </div>
              <h3 className="font-bold text-slate-900">{report.employeeName}</h3>
              <p className="text-xs text-slate-500 mb-4">Dr. {report.doctorName}</p>
              
              <div className="space-y-2 text-xs border-t border-slate-100 pt-4">
                <div className="flex justify-between">
                  <span className="text-slate-400 flex items-center gap-1"><Calendar size={14}/> Received:</span>
                  <span className="text-slate-700 font-medium">{new Date(report.dateReceived).toLocaleDateString()}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-400 flex items-center gap-1"><Clock size={14}/> Expiry:</span>
                  <span className={`font-bold ${isExpired ? 'text-red-600' : 'text-slate-700'}`}>
                    {new Date(report.expiryDate).toLocaleDateString()}
                  </span>
                </div>
              </div>
              
              {isExpired && !report.reportType.includes('Final') && (
                <div className="mt-4 p-2 bg-red-50 rounded flex items-center gap-2 text-red-700 text-[10px] font-bold uppercase tracking-wider">
                  <AlertCircle size={14} /> New W.Cl.5 Required
                </div>
              )}
            </div>
          );
        })}
        {reports.length === 0 && !isAdding && (
          <div className="col-span-full p-8 text-center text-slate-500 bg-slate-50 rounded-xl border border-dashed border-slate-300">
            No medical reports logged.
          </div>
        )}
      </div>
    </div>
  );
}
