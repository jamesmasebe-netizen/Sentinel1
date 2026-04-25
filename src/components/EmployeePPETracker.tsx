import React, { useState, useEffect } from 'react';
import { 
  HardHat, 
  Plus, 
  Calendar, 
  ShieldCheck, 
  AlertTriangle, 
  CheckCircle2, 
  Clock,
  History,
  FileCheck,
  Edit2,
  Trash2,
  Package,
  ArrowRight
} from 'lucide-react';
import { collection, query, onSnapshot, orderBy, addDoc, serverTimestamp, where } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { format, isAfter } from 'date-fns';

interface PPEIssue {
  id: string;
  employeeId: string;
  itemType: string;
  size: string;
  issueDate: string;
  expiryDate?: string;
  condition: 'New' | 'Good' | 'Worn' | 'Damaged';
  authorId: string;
  createdAt: any;
}

export default function EmployeePPETracker({ employeeId }: { employeeId: string }) {
  const [ppeHistory, setPpeHistory] = useState<PPEIssue[]>([]);
  const [isAdding, setIsAdding] = useState(false);

  useEffect(() => {
    const q = query(
      collection(db, 'employees', employeeId, 'ppe'), 
      orderBy('issueDate', 'desc')
    );
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setPpeHistory(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as PPEIssue[]);
    });
    return () => unsubscribe();
  }, [employeeId]);

  const handleAddPPE = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const formData = new FormData(e.currentTarget);
    
    try {
      await addDoc(collection(db, 'employees', employeeId, 'ppe'), {
        itemType: formData.get('itemType'),
        size: formData.get('size'),
        issueDate: formData.get('issueDate') + "T00:00:00Z",
        expiryDate: formData.get('expiryDate') ? formData.get('expiryDate') + "T00:00:00Z" : null,
        condition: 'New',
        authorId: auth.currentUser?.uid,
        createdAt: serverTimestamp()
      });
      setIsAdding(false);
    } catch (error) {
      console.error("Error adding PPE:", error);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h4 className="font-bold text-slate-900 flex items-center gap-2">
          <HardHat size={20} className="text-slate-700" />
          PPE Issue & Size Register
        </h4>
        <button 
          onClick={() => setIsAdding(true)}
          className="text-sm font-bold text-blue-600 hover:underline flex items-center gap-1"
        >
          <Plus size={16} />
          Issue PPE
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {ppeHistory.length === 0 ? (
          <div className="col-span-3 p-8 text-center text-slate-500 italic text-sm bg-slate-50 rounded-2xl border border-slate-100">
            No PPE issue records found for this employee.
          </div>
        ) : (
          ppeHistory.map((item) => (
            <div key={item.id} className="p-4 bg-white rounded-2xl border border-slate-200 shadow-sm space-y-3 hover:border-blue-200 transition-colors group">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="p-2 bg-slate-50 rounded-lg group-hover:bg-blue-50 transition-colors">
                    <ShieldCheck size={18} className="text-slate-600 group-hover:text-blue-600" />
                  </div>
                  <div>
                    <p className="text-sm font-bold text-slate-900">{item.itemType}</p>
                    <p className="text-xs text-slate-500">Size: {item.size}</p>
                  </div>
                </div>
                <span className={`px-2 py-0.5 rounded text-[10px] font-bold uppercase ${item.condition === 'New' ? 'bg-green-100 text-green-700' : 'bg-slate-100 text-slate-700'}`}>
                  {item.condition}
                </span>
              </div>
              <div className="flex items-center justify-between text-xs text-slate-500 pt-2 border-t border-slate-50">
                <div className="flex items-center gap-1">
                  <Calendar size={12} />
                  Issued: {format(new Date(item.issueDate), 'PP')}
                </div>
                {item.expiryDate && (
                  <div className="flex items-center gap-1 font-medium text-orange-600">
                    <Clock size={12} />
                    Due: {format(new Date(item.expiryDate), 'MMM yy')}
                  </div>
                )}
              </div>
            </div>
          ))
        )}
      </div>

      {/* Add PPE Modal */}
      {isAdding && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-sm">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex items-center justify-between bg-slate-50">
              <h3 className="text-lg font-bold text-slate-900">Issue PPE Item</h3>
              <button onClick={() => setIsAdding(false)} className="text-slate-400 hover:text-slate-600">
                <Plus className="rotate-45" size={24} />
              </button>
            </div>
            <form onSubmit={handleAddPPE} className="p-6 space-y-4">
              <div className="space-y-1">
                <label className="text-sm font-medium text-slate-700">Item Type</label>
                <select name="itemType" className="w-full px-4 py-2 rounded-lg border border-slate-200 outline-none focus:ring-2 focus:ring-blue-500/20">
                  <option>Safety Boots (Steel Toe)</option>
                  <option>Reflective Vest (Class 2)</option>
                  <option>Hard Hat (Type 1)</option>
                  <option>Safety Glasses (Clear)</option>
                  <option>Ear Plugs (Disposable)</option>
                  <option>Gloves (Cut Resistant)</option>
                  <option>Respiratory Mask (N95)</option>
                </select>
              </div>
              <div className="space-y-1">
                <label className="text-sm font-medium text-slate-700">Size / Specification</label>
                <input name="size" required placeholder="e.g. UK 9, Large, N/A" className="w-full px-4 py-2 rounded-lg border border-slate-200 outline-none focus:ring-2 focus:ring-blue-500/20" />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-1">
                  <label className="text-sm font-medium text-slate-700">Issue Date</label>
                  <input name="issueDate" type="date" required className="w-full px-4 py-2 rounded-lg border border-slate-200 outline-none focus:ring-2 focus:ring-blue-500/20" />
                </div>
                <div className="space-y-1">
                  <label className="text-sm font-medium text-slate-700">Expiry / Replacement Date</label>
                  <input name="expiryDate" type="date" className="w-full px-4 py-2 rounded-lg border border-slate-200 outline-none focus:ring-2 focus:ring-blue-500/20" />
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
                  Confirm Issue
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
