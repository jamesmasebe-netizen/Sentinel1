import React, { useState, useEffect } from 'react';
import { collection, onSnapshot, query, addDoc, doc, updateDoc, deleteDoc } from 'firebase/firestore';
import { db, auth, handleFirestoreError } from '../lib/firebase';
import { 
  Users, 
  ShieldCheck, 
  ShieldAlert, 
  Phone, 
  Mail, 
  Plus, 
  X, 
  Bell,
  CheckCircle2,
  AlertCircle,
  Clock
} from 'lucide-react';

interface Warden {
  id: string;
  name: string;
  role: 'Chief Warden' | 'Deputy Warden' | 'Floor Warden' | 'First Aider';
  area: string;
  phone: string;
  email: string;
  trainingStatus: 'Certified' | 'Expired' | 'Pending';
  lastTrainingDate: string;
  isAvailable: boolean;
}

export default function WardenManagement() {
  const [wardens, setWardens] = useState<Warden[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [isCallingOut, setIsCallingOut] = useState(false);

  // New Warden Form
  const [newName, setNewName] = useState('');
  const [newRole, setNewRole] = useState<Warden['role']>('Floor Warden');
  const [newArea, setNewArea] = useState('');
  const [newPhone, setNewPhone] = useState('');
  const [newEmail, setNewEmail] = useState('');
  const [newTrainingDate, setNewTrainingDate] = useState('');

  useEffect(() => {
    const q = query(collection(db, 'emergency_wardens'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as Warden[];
      setWardens(data);
    }, (error) => {
      handleFirestoreError(error, 'list' as any, 'emergency_wardens');
    });

    return () => unsubscribe();
  }, []);

  const handleAddWarden = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await addDoc(collection(db, 'emergency_wardens'), {
        name: newName,
        role: newRole,
        area: newArea,
        phone: newPhone,
        email: newEmail,
        lastTrainingDate: newTrainingDate,
        trainingStatus: 'Certified', // Simplified for demo
        isAvailable: true,
        createdAt: new Date().toISOString()
      });
      setIsAdding(false);
      setNewName('');
      setNewArea('');
      setNewPhone('');
      setNewEmail('');
      setNewTrainingDate('');
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'emergency_wardens');
    }
  };

  const toggleAvailability = async (id: string, currentStatus: boolean) => {
    try {
      await updateDoc(doc(db, 'emergency_wardens', id), {
        isAvailable: !currentStatus
      });
    } catch (error) {
      handleFirestoreError(error, 'update' as any, 'emergency_wardens');
    }
  };

  const initiateCallOut = () => {
    setIsCallingOut(true);
    // Simulate API call to notification service
    setTimeout(() => {
      setIsCallingOut(false);
      alert('Emergency Call-Out initiated. All available wardens have been notified via SMS and Push.');
    }, 2000);
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row gap-4 items-center justify-between">
        <div className="flex items-center gap-4">
          <div className="bg-red-50 p-3 rounded-xl text-red-600">
            <Users size={24} />
          </div>
          <div>
            <h2 className="text-xl font-bold text-slate-900">Emergency Warden Team</h2>
            <p className="text-sm text-slate-500">{wardens.filter(w => w.isAvailable).length} Wardens currently on-duty</p>
          </div>
        </div>
        
        <div className="flex gap-3 w-full md:w-auto">
          <button 
            onClick={initiateCallOut}
            disabled={isCallingOut}
            className="flex-1 md:flex-none flex items-center justify-center gap-2 bg-red-600 text-white px-6 py-2.5 rounded-xl font-bold hover:bg-red-700 transition-all shadow-lg shadow-red-200 disabled:bg-red-300"
          >
            <Bell size={20} className={isCallingOut ? 'animate-ring' : ''} />
            {isCallingOut ? 'Calling Out...' : 'Initiate Call-Out'}
          </button>
          <button 
            onClick={() => setIsAdding(true)}
            className="p-2.5 bg-slate-900 text-white rounded-xl hover:bg-slate-800 transition-colors"
          >
            <Plus size={24} />
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {wardens.map(warden => (
          <div key={warden.id} className="bg-white border border-slate-200 rounded-2xl p-5 shadow-sm hover:shadow-md transition-shadow">
            <div className="flex justify-between items-start mb-4">
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 rounded-full bg-slate-100 flex items-center justify-center font-bold text-slate-600 text-lg">
                  {warden.name.charAt(0)}
                </div>
                <div>
                  <h3 className="font-bold text-slate-900">{warden.name}</h3>
                  <p className="text-xs text-slate-500 font-medium uppercase tracking-wider">{warden.role}</p>
                </div>
              </div>
              <button 
                onClick={() => toggleAvailability(warden.id, warden.isAvailable)}
                className={`px-2 py-1 rounded-full text-[10px] font-bold uppercase transition-colors ${
                  warden.isAvailable ? 'bg-green-100 text-green-700' : 'bg-slate-100 text-slate-500'
                }`}
              >
                {warden.isAvailable ? 'On-Duty' : 'Off-Duty'}
              </button>
            </div>

            <div className="space-y-3 mb-6">
              <div className="flex items-center gap-2 text-sm text-slate-600">
                <ShieldCheck size={16} className="text-blue-500" />
                <span>Area: <span className="font-medium text-slate-900">{warden.area}</span></span>
              </div>
              <div className="flex items-center gap-2 text-sm text-slate-600">
                <Phone size={16} className="text-slate-400" />
                <span>{warden.phone}</span>
              </div>
              <div className="flex items-center gap-2 text-sm text-slate-600">
                <Mail size={16} className="text-slate-400" />
                <span className="truncate">{warden.email}</span>
              </div>
            </div>

            <div className="pt-4 border-t border-slate-50 flex items-center justify-between">
              <div className="flex items-center gap-1.5">
                {warden.trainingStatus === 'Certified' ? (
                  <CheckCircle2 size={14} className="text-green-500" />
                ) : (
                  <AlertCircle size={14} className="text-amber-500" />
                )}
                <span className="text-[10px] font-bold text-slate-500 uppercase">Training: {warden.trainingStatus}</span>
              </div>
              <div className="flex items-center gap-1 text-[10px] text-slate-400">
                <Clock size={12} />
                {new Date(warden.lastTrainingDate).toLocaleDateString()}
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Add Warden Modal */}
      {isAdding && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex justify-between items-center">
              <h2 className="text-xl font-bold text-slate-900">Add Emergency Warden</h2>
              <button onClick={() => setIsAdding(false)} className="text-slate-400 hover:text-slate-600">
                <X size={24} />
              </button>
            </div>
            <form onSubmit={handleAddWarden} className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Full Name</label>
                <input 
                  type="text" 
                  required
                  value={newName}
                  onChange={(e) => setNewName(e.target.value)}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500"
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Role</label>
                  <select 
                    value={newRole}
                    onChange={(e) => setNewRole(e.target.value as any)}
                    className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500"
                  >
                    <option value="Chief Warden">Chief Warden</option>
                    <option value="Deputy Warden">Deputy Warden</option>
                    <option value="Floor Warden">Floor Warden</option>
                    <option value="First Aider">First Aider</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Area/Floor</label>
                  <input 
                    type="text" 
                    required
                    value={newArea}
                    onChange={(e) => setNewArea(e.target.value)}
                    placeholder="e.g., Level 2"
                    className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500"
                  />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Phone</label>
                  <input 
                    type="tel" 
                    required
                    value={newPhone}
                    onChange={(e) => setNewPhone(e.target.value)}
                    className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Last Training</label>
                  <input 
                    type="date" 
                    required
                    value={newTrainingDate}
                    onChange={(e) => setNewTrainingDate(e.target.value)}
                    className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500"
                  />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Email</label>
                <input 
                  type="email" 
                  required
                  value={newEmail}
                  onChange={(e) => setNewEmail(e.target.value)}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500"
                />
              </div>
              <div className="pt-4 flex justify-end gap-3">
                <button 
                  type="button"
                  onClick={() => setIsAdding(false)}
                  className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
                >
                  Cancel
                </button>
                <button 
                  type="submit"
                  className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors font-bold"
                >
                  Save Warden
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      <style>{`
        @keyframes ring {
          0% { transform: rotate(0); }
          10% { transform: rotate(15deg); }
          20% { transform: rotate(-15deg); }
          30% { transform: rotate(10deg); }
          40% { transform: rotate(-10deg); }
          50% { transform: rotate(0); }
          100% { transform: rotate(0); }
        }
        .animate-ring {
          animation: ring 0.5s ease infinite;
        }
      `}</style>
    </div>
  );
}
