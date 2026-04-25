import React, { useState, useEffect } from 'react';
import { 
  Truck, 
  Plus, 
  Calendar, 
  BadgeCheck, 
  AlertTriangle, 
  CheckCircle2, 
  Clock,
  History,
  FileCheck,
  Edit2,
  Trash2,
  Construction,
  Zap,
  ShieldCheck
} from 'lucide-react';
import { collection, query, onSnapshot, orderBy, addDoc, serverTimestamp, where } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { format, isAfter } from 'date-fns';

interface Authorization {
  id: string;
  employeeId: string;
  type: string;
  licenseNumber: string;
  issueDate: string;
  expiryDate: string;
  status: 'Valid' | 'Expired' | 'Suspended';
  authorId: string;
  createdAt: any;
}

export default function EmployeeAuthorizations({ employeeId }: { employeeId: string }) {
  const [authorizations, setAuthorizations] = useState<Authorization[]>([]);
  const [isAdding, setIsAdding] = useState(false);

  useEffect(() => {
    const q = query(
      collection(db, 'employees', employeeId, 'authorizations'), 
      orderBy('expiryDate', 'desc')
    );
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setAuthorizations(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as Authorization[]);
    });
    return () => unsubscribe();
  }, [employeeId]);

  const handleAddAuthorization = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const formData = new FormData(e.currentTarget);
    
    try {
      await addDoc(collection(db, 'employees', employeeId, 'authorizations'), {
        type: formData.get('type'),
        licenseNumber: formData.get('licenseNumber'),
        issueDate: formData.get('issueDate') + "T00:00:00Z",
        expiryDate: formData.get('expiryDate') + "T00:00:00Z",
        status: 'Valid',
        authorId: auth.currentUser?.uid,
        createdAt: serverTimestamp()
      });
      setIsAdding(false);
    } catch (error) {
      console.error("Error adding authorization:", error);
    }
  };

  const getIcon = (type: string) => {
    const t = type.toLowerCase();
    if (t.includes('forklift') || t.includes('truck')) return <Truck size={20} className="text-blue-600" />;
    if (t.includes('crane') || t.includes('machinery')) return <Construction size={20} className="text-orange-600" />;
    if (t.includes('electrical') || t.includes('loto')) return <Zap size={20} className="text-yellow-600" />;
    if (t.includes('first aid') || t.includes('fire')) return <ShieldCheck size={20} className="text-red-600" />;
    return <BadgeCheck size={20} className="text-slate-600" />;
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h4 className="font-bold text-slate-900 flex items-center gap-2">
          <BadgeCheck size={20} className="text-blue-600" />
          Vehicle & Machinery Authorizations
        </h4>
        <button 
          onClick={() => setIsAdding(true)}
          className="text-sm font-bold text-blue-600 hover:underline flex items-center gap-1"
        >
          <Plus size={16} />
          Add Authorization
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {authorizations.length === 0 ? (
          <div className="col-span-2 p-8 text-center text-slate-500 italic text-sm bg-slate-50 rounded-2xl border border-slate-100">
            No active machinery or task authorizations found.
          </div>
        ) : (
          authorizations.map((auth) => {
            const isValid = isAfter(new Date(auth.expiryDate), new Date());
            return (
              <div key={auth.id} className={`p-4 rounded-2xl border ${isValid ? 'bg-white border-slate-200' : 'bg-red-50 border-red-100'} shadow-sm space-y-3`}>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="p-2 bg-slate-50 rounded-lg">
                      {getIcon(auth.type)}
                    </div>
                    <div>
                      <p className="text-sm font-bold text-slate-900">{auth.type}</p>
                      <p className="text-xs text-slate-500">Lic: {auth.licenseNumber}</p>
                    </div>
                  </div>
                  <span className={`px-2 py-0.5 rounded text-[10px] font-bold uppercase ${isValid ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
                    {isValid ? 'Valid' : 'Expired'}
                  </span>
                </div>
                <div className="flex items-center justify-between text-xs text-slate-500 pt-2 border-t border-slate-50">
                  <div className="flex items-center gap-1">
                    <Calendar size={12} />
                    Issued: {format(new Date(auth.issueDate), 'PP')}
                  </div>
                  <div className="flex items-center gap-1 font-medium">
                    <Clock size={12} />
                    Expires: {format(new Date(auth.expiryDate), 'PP')}
                  </div>
                </div>
              </div>
            );
          })
        )}
      </div>

      {/* Add Authorization Modal */}
      {isAdding && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-sm">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex items-center justify-between bg-slate-50">
              <h3 className="text-lg font-bold text-slate-900">Add Authorization</h3>
              <button onClick={() => setIsAdding(false)} className="text-slate-400 hover:text-slate-600">
                <Plus className="rotate-45" size={24} />
              </button>
            </div>
            <form onSubmit={handleAddAuthorization} className="p-6 space-y-4">
              <div className="space-y-1">
                <label className="text-sm font-medium text-slate-700">Authorization Type</label>
                <input name="type" required placeholder="e.g. Forklift Operator (Level 1)" className="w-full px-4 py-2 rounded-lg border border-slate-200 outline-none focus:ring-2 focus:ring-blue-500/20" />
              </div>
              <div className="space-y-1">
                <label className="text-sm font-medium text-slate-700">License / Permit Number</label>
                <input name="licenseNumber" required placeholder="e.g. LIC-123456" className="w-full px-4 py-2 rounded-lg border border-slate-200 outline-none focus:ring-2 focus:ring-blue-500/20" />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-1">
                  <label className="text-sm font-medium text-slate-700">Issue Date</label>
                  <input name="issueDate" type="date" required className="w-full px-4 py-2 rounded-lg border border-slate-200 outline-none focus:ring-2 focus:ring-blue-500/20" />
                </div>
                <div className="space-y-1">
                  <label className="text-sm font-medium text-slate-700">Expiry Date</label>
                  <input name="expiryDate" type="date" required className="w-full px-4 py-2 rounded-lg border border-slate-200 outline-none focus:ring-2 focus:ring-blue-500/20" />
                </div>
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
                  Save Authorization
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
