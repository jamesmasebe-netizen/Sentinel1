import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { UserCheck, Plus, Calendar, AlertTriangle, CheckCircle2 } from 'lucide-react';

interface ResumptionReport {
  id: string;
  employeeName: string;
  claimNumber: string;
  resumptionDate: string;
  dutyStatus: 'Full Duty' | 'Light Duty' | 'Alternative Duty';
  submittedToFund: boolean;
  submissionDate?: string;
  createdAt: string;
}

export default function ResumptionReportManager() {
  const [reports, setReports] = useState<ResumptionReport[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [formData, setFormData] = useState({
    employeeName: '',
    claimNumber: '',
    resumptionDate: '',
    dutyStatus: 'Full Duty' as ResumptionReport['dutyStatus'],
    submittedToFund: false
  });

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'coida_resumption_reports'), orderBy('resumptionDate', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setReports(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as ResumptionReport[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'coida_resumption_reports'));
    return () => unsubscribe();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      await addDoc(collection(db, 'coida_resumption_reports'), {
        ...formData,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAdding(false);
      setFormData({ employeeName: '', claimNumber: '', resumptionDate: '', dutyStatus: 'Full Duty', submittedToFund: false });
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'coida_resumption_reports');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">Resumption Report (W.Cl.6) Manager</h2>
          <p className="text-sm text-slate-500">Manage employee return-to-work notifications for the Compensation Fund.</p>
        </div>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-rose-600 text-white px-4 py-2 rounded-lg hover:bg-rose-700">
          <Plus size={18} /> Log Resumption
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
              <label className="block text-sm font-medium text-slate-700 mb-1">Claim Number</label>
              <input type="text" required value={formData.claimNumber} onChange={e => setFormData({...formData, claimNumber: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Resumption Date</label>
              <input type="date" required value={formData.resumptionDate} onChange={e => setFormData({...formData, resumptionDate: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Duty Status</label>
              <select value={formData.dutyStatus} onChange={e => setFormData({...formData, dutyStatus: e.target.value as any})} className="w-full p-2 border rounded-lg">
                <option value="Full Duty">Full Duty</option>
                <option value="Light Duty">Light Duty</option>
                <option value="Alternative Duty">Alternative Duty</option>
              </select>
            </div>
            <div className="flex items-center gap-2 pt-2">
              <input type="checkbox" id="submitted" checked={formData.submittedToFund} onChange={e => setFormData({...formData, submittedToFund: e.target.checked})} className="w-4 h-4 text-rose-600 rounded" />
              <label htmlFor="submitted" className="text-sm font-medium text-slate-700">W.Cl.6 Submitted to Fund</label>
            </div>
            <div className="md:col-span-2 flex justify-end gap-2 mt-2">
              <button type="button" onClick={() => setIsAdding(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg">Cancel</button>
              <button type="submit" className="px-4 py-2 bg-rose-600 text-white rounded-lg hover:bg-rose-700">Save Resumption</button>
            </div>
          </form>
        </div>
      )}

      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 text-sm">
              <th className="p-4 font-medium">Resumption Date</th>
              <th className="p-4 font-medium">Employee</th>
              <th className="p-4 font-medium">Claim No.</th>
              <th className="p-4 font-medium">Duty Status</th>
              <th className="p-4 font-medium">W.Cl.6 Status</th>
            </tr>
          </thead>
          <tbody>
            {reports.map(report => (
              <tr key={report.id} className="border-b border-slate-100 hover:bg-slate-50">
                <td className="p-4 text-slate-600">{new Date(report.resumptionDate).toLocaleDateString()}</td>
                <td className="p-4 font-medium text-slate-900">{report.employeeName}</td>
                <td className="p-4 text-slate-600 font-mono text-sm">{report.claimNumber}</td>
                <td className="p-4">
                  <span className={`text-xs px-2 py-1 rounded-full font-medium ${
                    report.dutyStatus === 'Full Duty' ? 'bg-green-100 text-green-800' : 'bg-amber-100 text-amber-800'
                  }`}>
                    {report.dutyStatus}
                  </span>
                </td>
                <td className="p-4">
                  {report.submittedToFund ? (
                    <span className="flex items-center gap-1 text-green-600 text-xs font-bold"><CheckCircle2 size={14}/> SUBMITTED</span>
                  ) : (
                    <span className="flex items-center gap-1 text-red-600 text-xs font-bold"><AlertTriangle size={14}/> PENDING</span>
                  )}
                </td>
              </tr>
            ))}
            {reports.length === 0 && !isAdding && (
              <tr>
                <td colSpan={5} className="p-8 text-center text-slate-500">No resumption reports logged.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
