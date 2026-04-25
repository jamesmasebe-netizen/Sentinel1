import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { Video, Plus, Calendar, Clock, User } from 'lucide-react';

interface Consult {
  id: string;
  employeeName: string;
  doctorName: string;
  scheduledDate: string;
  scheduledTime: string;
  reason: string;
  status: 'Scheduled' | 'Completed' | 'Cancelled';
  meetingLink: string;
  createdAt: string;
}

export default function TelemedicineConsults() {
  const [consults, setConsults] = useState<Consult[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [formData, setFormData] = useState({
    employeeName: '',
    doctorName: 'Dr. Sarah Jenkins (OMP)',
    scheduledDate: '',
    scheduledTime: '',
    reason: '',
    status: 'Scheduled' as Consult['status'],
    meetingLink: 'https://meet.google.com/mock-link-123'
  });

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'telemedicine_consults'), orderBy('scheduledDate', 'asc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as Consult[];
      setConsults(data);
    }, (error) => handleFirestoreError(error, 'list' as any, 'telemedicine_consults'));
    return () => unsubscribe();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      await addDoc(collection(db, 'telemedicine_consults'), {
        ...formData,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAdding(false);
      setFormData({ employeeName: '', doctorName: 'Dr. Sarah Jenkins (OMP)', scheduledDate: '', scheduledTime: '', reason: '', status: 'Scheduled', meetingLink: 'https://meet.google.com/mock-link-123' });
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'telemedicine_consults');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">Telemedicine & Remote Consultations</h2>
          <p className="text-sm text-slate-500">Schedule virtual appointments with Occupational Medical Practitioners.</p>
        </div>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700">
          <Plus size={18} /> Schedule Consult
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
              <label className="block text-sm font-medium text-slate-700 mb-1">Doctor / Specialist</label>
              <input type="text" required value={formData.doctorName} onChange={e => setFormData({...formData, doctorName: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Date</label>
              <input type="date" required value={formData.scheduledDate} onChange={e => setFormData({...formData, scheduledDate: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Time</label>
              <input type="time" required value={formData.scheduledTime} onChange={e => setFormData({...formData, scheduledTime: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div className="md:col-span-2">
              <label className="block text-sm font-medium text-slate-700 mb-1">Reason for Consultation</label>
              <input type="text" required value={formData.reason} onChange={e => setFormData({...formData, reason: e.target.value})} placeholder="e.g., Follow-up on RTW restrictions" className="w-full p-2 border rounded-lg" />
            </div>
            <div className="md:col-span-2 flex justify-end gap-2 mt-2">
              <button type="button" onClick={() => setIsAdding(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg">Cancel</button>
              <button type="submit" className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">Schedule</button>
            </div>
          </form>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {consults.map(consult => (
          <div key={consult.id} className="border border-slate-200 rounded-xl p-5 bg-white shadow-sm hover:shadow-md transition-shadow">
            <div className="flex justify-between items-start mb-4">
              <div className="bg-indigo-50 p-2 rounded-lg text-indigo-600"><Video size={24} /></div>
              <span className={`text-xs px-2.5 py-1 rounded-full font-medium ${
                consult.status === 'Scheduled' ? 'bg-blue-100 text-blue-800' :
                consult.status === 'Completed' ? 'bg-green-100 text-green-800' :
                'bg-slate-100 text-slate-800'
              }`}>
                {consult.status}
              </span>
            </div>
            <h3 className="font-semibold text-slate-900 mb-1">{consult.employeeName}</h3>
            <p className="text-sm text-slate-500 mb-4 flex items-center gap-1"><User size={14}/> {consult.doctorName}</p>
            
            <div className="space-y-2 text-sm text-slate-600 mb-4">
              <p className="flex items-center gap-2"><Calendar size={14} className="text-slate-400"/> {new Date(consult.scheduledDate).toLocaleDateString()}</p>
              <p className="flex items-center gap-2"><Clock size={14} className="text-slate-400"/> {consult.scheduledTime}</p>
              <p className="text-slate-500 italic text-xs mt-2 truncate">"{consult.reason}"</p>
            </div>

            {consult.status === 'Scheduled' && (
              <a href={consult.meetingLink} target="_blank" rel="noopener noreferrer" className="block w-full text-center bg-indigo-50 text-indigo-700 py-2 rounded-lg text-sm font-medium hover:bg-indigo-100 transition-colors">
                Join Video Call
              </a>
            )}
          </div>
        ))}
        {consults.length === 0 && !isAdding && (
          <div className="col-span-full p-8 text-center text-slate-500 bg-slate-50 rounded-xl border border-dashed border-slate-300">
            No upcoming consultations.
          </div>
        )}
      </div>
    </div>
  );
}
