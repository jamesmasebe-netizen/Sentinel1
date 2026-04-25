import React, { useState, useEffect } from 'react';
import { 
  ShieldCheck, 
  Calendar, 
  AlertTriangle, 
  CheckCircle2, 
  Clock,
  Plus,
  History,
  FileCheck,
  QrCode
} from 'lucide-react';
import { collection, query, onSnapshot, orderBy, addDoc, serverTimestamp, where } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { format, isAfter, addYears } from 'date-fns';

interface InductionRecord {
  id: string;
  employeeId: string;
  inductionType: string;
  inductionDate: string;
  expiryDate: string;
  status: 'Valid' | 'Expired';
  conductedBy: string;
  createdAt: any;
}

export default function EmployeeInduction({ employeeId }: { employeeId: string }) {
  const [inductions, setInductions] = useState<InductionRecord[]>([]);
  const [isAdding, setIsAdding] = useState(false);

  useEffect(() => {
    const q = query(
      collection(db, 'employees', employeeId, 'inductions'), 
      orderBy('inductionDate', 'desc')
    );
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setInductions(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as InductionRecord[]);
    });
    return () => unsubscribe();
  }, [employeeId]);

  const handleAddInduction = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const formData = new FormData(e.currentTarget);
    const date = formData.get('inductionDate') as string;
    const expiry = format(addYears(new Date(date), 1), "yyyy-MM-dd'T'HH:mm:ss'Z'");

    try {
      await addDoc(collection(db, 'employees', employeeId, 'inductions'), {
        inductionType: formData.get('inductionType'),
        inductionDate: date + "T00:00:00Z",
        expiryDate: expiry,
        status: 'Valid',
        conductedBy: formData.get('conductedBy'),
        authorId: auth.currentUser?.uid,
        createdAt: serverTimestamp()
      });
      setIsAdding(false);
    } catch (error) {
      console.error("Error adding induction:", error);
    }
  };

  const latestInduction = inductions[0];
  const isValid = latestInduction && isAfter(new Date(latestInduction.expiryDate), new Date());

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h4 className="font-bold text-slate-900 flex items-center gap-2">
          <ShieldCheck size={20} className="text-green-600" />
          Site Induction Status
        </h4>
        <button 
          onClick={() => setIsAdding(true)}
          className="text-sm font-bold text-blue-600 hover:underline flex items-center gap-1"
        >
          <Plus size={16} />
          New Induction
        </button>
      </div>

      {/* Current Status Card */}
      <div className={`p-6 rounded-2xl border ${isValid ? 'bg-green-50 border-green-100' : 'bg-red-50 border-red-100'} flex items-center justify-between`}>
        <div className="flex items-center gap-4">
          <div className={`p-3 rounded-xl bg-white shadow-sm ${isValid ? 'text-green-600' : 'text-red-600'}`}>
            {isValid ? <CheckCircle2 size={24} /> : <AlertTriangle size={24} />}
          </div>
          <div>
            <p className="text-sm font-bold text-slate-900">
              {isValid ? 'Induction Valid' : 'Induction Expired / Missing'}
            </p>
            <p className={`text-xs font-medium ${isValid ? 'text-green-700' : 'text-red-700'}`}>
              {latestInduction 
                ? `Expires on ${format(new Date(latestInduction.expiryDate), 'PPP')}` 
                : 'No induction record found for this site.'}
            </p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <button className="p-2 bg-white rounded-lg border border-slate-200 text-slate-600 hover:bg-slate-50 shadow-sm">
            <QrCode size={18} />
          </button>
          <button className="p-2 bg-white rounded-lg border border-slate-200 text-slate-600 hover:bg-slate-50 shadow-sm">
            <FileCheck size={18} />
          </button>
        </div>
      </div>

      {/* Induction History */}
      <div className="space-y-3">
        <h5 className="text-sm font-bold text-slate-900 flex items-center gap-2">
          <History size={16} className="text-slate-400" />
          Induction History
        </h5>
        <div className="bg-white rounded-xl border border-slate-200 divide-y divide-slate-100 overflow-hidden">
          {inductions.length === 0 ? (
            <div className="p-8 text-center text-slate-500 italic text-sm">
              No historical induction records found.
            </div>
          ) : (
            inductions.map((record) => (
              <div key={record.id} className="p-4 flex items-center justify-between hover:bg-slate-50 transition-colors">
                <div className="flex items-center gap-3">
                  <div className="p-2 bg-slate-100 rounded-lg text-slate-500">
                    <Clock size={16} />
                  </div>
                  <div>
                    <p className="text-sm font-bold text-slate-900">{record.inductionType}</p>
                    <p className="text-xs text-slate-500">Conducted by {record.conductedBy} • {format(new Date(record.inductionDate), 'PP')}</p>
                  </div>
                </div>
                <span className={`px-2 py-0.5 rounded text-[10px] font-bold uppercase ${isAfter(new Date(record.expiryDate), new Date()) ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
                  {isAfter(new Date(record.expiryDate), new Date()) ? 'Valid' : 'Expired'}
                </span>
              </div>
            ))
          )}
        </div>
      </div>

      {/* Add Induction Modal */}
      {isAdding && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-sm">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex items-center justify-between bg-slate-50">
              <h3 className="text-lg font-bold text-slate-900">Log Site Induction</h3>
              <button onClick={() => setIsAdding(false)} className="text-slate-400 hover:text-slate-600">
                <Plus className="rotate-45" size={24} />
              </button>
            </div>
            <form onSubmit={handleAddInduction} className="p-6 space-y-4">
              <div className="space-y-1">
                <label className="text-sm font-medium text-slate-700">Induction Type</label>
                <select name="inductionType" className="w-full px-4 py-2 rounded-lg border border-slate-200 outline-none focus:ring-2 focus:ring-blue-500/20">
                  <option>General Site Induction</option>
                  <option>Visitor Safety Briefing</option>
                  <option>High-Risk Area Induction</option>
                  <option>Contractor Safety Induction</option>
                </select>
              </div>
              <div className="space-y-1">
                <label className="text-sm font-medium text-slate-700">Induction Date</label>
                <input name="inductionDate" type="date" required className="w-full px-4 py-2 rounded-lg border border-slate-200 outline-none focus:ring-2 focus:ring-blue-500/20" />
              </div>
              <div className="space-y-1">
                <label className="text-sm font-medium text-slate-700">Conducted By</label>
                <input name="conductedBy" required placeholder="Safety Officer Name" className="w-full px-4 py-2 rounded-lg border border-slate-200 outline-none focus:ring-2 focus:ring-blue-500/20" />
              </div>
              <div className="pt-4 flex gap-3">
                <button 
                  type="button"
                  onClick={() => setIsAdding(false)}
                  className="flex-1 px-4 py-2 rounded-lg border border-slate-200 hover:bg-slate-50 text-slate-700 font-medium transition-colors"
                >
                  Cancel
                </button>
                <button 
                  type="submit"
                  className="flex-1 px-4 py-2 rounded-lg bg-blue-600 hover:bg-blue-700 text-white font-medium transition-colors shadow-sm"
                >
                  Save Record
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
