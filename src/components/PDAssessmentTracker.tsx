import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { Award, Plus, Calendar, User, Percent, DollarSign } from 'lucide-react';

interface PDAssessment {
  id: string;
  employeeName: string;
  claimNumber: string;
  assessmentDate: string;
  disablementPercentage: number;
  awardAmount: number;
  status: 'Pending' | 'Finalized' | 'Appealed';
  notes: string;
  createdAt: string;
}

export default function PDAssessmentTracker() {
  const [assessments, setAssessments] = useState<PDAssessment[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [formData, setFormData] = useState({
    employeeName: '',
    claimNumber: '',
    assessmentDate: '',
    disablementPercentage: 0,
    awardAmount: 0,
    status: 'Pending' as PDAssessment['status'],
    notes: ''
  });

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'coida_pd_assessments'), orderBy('createdAt', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setAssessments(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as PDAssessment[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'coida_pd_assessments'));
    return () => unsubscribe();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      await addDoc(collection(db, 'coida_pd_assessments'), {
        ...formData,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAdding(false);
      setFormData({ employeeName: '', claimNumber: '', assessmentDate: '', disablementPercentage: 0, awardAmount: 0, status: 'Pending', notes: '' });
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'coida_pd_assessments');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">Permanent Disablement (PD) Assessment Tracker</h2>
          <p className="text-sm text-slate-500">Log and track PD assessments and final awards from the Compensation Fund.</p>
        </div>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-indigo-600 text-white px-4 py-2 rounded-lg hover:bg-indigo-700">
          <Plus size={18} /> Log Assessment
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
              <label className="block text-sm font-medium text-slate-700 mb-1">Assessment Date</label>
              <input type="date" required value={formData.assessmentDate} onChange={e => setFormData({...formData, assessmentDate: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div className="grid grid-cols-2 gap-2">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Disablement %</label>
                <input type="number" required value={formData.disablementPercentage} onChange={e => setFormData({...formData, disablementPercentage: parseFloat(e.target.value) || 0})} className="w-full p-2 border rounded-lg" />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Award Amount (R)</label>
                <input type="number" required value={formData.awardAmount} onChange={e => setFormData({...formData, awardAmount: parseFloat(e.target.value) || 0})} className="w-full p-2 border rounded-lg" />
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Status</label>
              <select value={formData.status} onChange={e => setFormData({...formData, status: e.target.value as any})} className="w-full p-2 border rounded-lg">
                <option value="Pending">Pending</option>
                <option value="Finalized">Finalized</option>
                <option value="Appealed">Appealed</option>
              </select>
            </div>
            <div className="md:col-span-2">
              <label className="block text-sm font-medium text-slate-700 mb-1">Notes</label>
              <textarea value={formData.notes} onChange={e => setFormData({...formData, notes: e.target.value})} className="w-full p-2 border rounded-lg" rows={2}></textarea>
            </div>
            <div className="md:col-span-2 flex justify-end gap-2 mt-2">
              <button type="button" onClick={() => setIsAdding(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg">Cancel</button>
              <button type="submit" className="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700">Save Assessment</button>
            </div>
          </form>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {assessments.map(assessment => (
          <div key={assessment.id} className="border border-slate-200 rounded-xl p-5 bg-white shadow-sm hover:shadow-md transition-shadow">
            <div className="flex justify-between items-start mb-4">
              <div className="bg-indigo-50 p-2 rounded-lg text-indigo-600"><Award size={24} /></div>
              <span className={`text-xs px-2 py-1 rounded-full font-bold uppercase tracking-wider ${
                assessment.status === 'Finalized' ? 'bg-green-100 text-green-800' :
                assessment.status === 'Appealed' ? 'bg-red-100 text-red-800' :
                'bg-amber-100 text-amber-800'
              }`}>
                {assessment.status}
              </span>
            </div>
            <h3 className="font-bold text-slate-900">{assessment.employeeName}</h3>
            <p className="text-xs text-slate-500 mb-4">Claim: {assessment.claimNumber}</p>
            
            <div className="grid grid-cols-2 gap-4 mb-4">
              <div className="bg-slate-50 p-3 rounded-lg">
                <p className="text-[10px] text-slate-400 font-bold uppercase mb-1">Disablement</p>
                <div className="flex items-center gap-1 text-slate-900 font-black">
                  <Percent size={14} /> {assessment.disablementPercentage}%
                </div>
              </div>
              <div className="bg-slate-50 p-3 rounded-lg">
                <p className="text-[10px] text-slate-400 font-bold uppercase mb-1">Award Value</p>
                <div className="flex items-center gap-1 text-slate-900 font-black">
                  <DollarSign size={14} /> R {assessment.awardAmount.toLocaleString()}
                </div>
              </div>
            </div>

            <div className="flex items-center gap-2 text-xs text-slate-400">
              <Calendar size={12} /> Assessed: {new Date(assessment.assessmentDate).toLocaleDateString()}
            </div>
          </div>
        ))}
        {assessments.length === 0 && !isAdding && (
          <div className="col-span-full p-8 text-center text-slate-500 bg-slate-50 rounded-xl border border-dashed border-slate-300">
            No PD assessments logged.
          </div>
        )}
      </div>
    </div>
  );
}
