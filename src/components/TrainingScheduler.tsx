import React, { useState, useEffect } from 'react';
import { Calendar, Clock, User, Plus, CheckCircle2, AlertCircle, XCircle } from 'lucide-react';
import { collection, addDoc, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth, handleFirestoreError } from '../lib/firebase';

interface TrainingRecord {
  id: string;
  employeeName: string;
  courseName: string;
  expiryDate: string;
  status: 'Active' | 'Expired';
}

interface ScheduledSession {
  id: string;
  courseName: string;
  date: string;
  time: string;
  instructor: string;
  location: string;
  attendeesCount: number;
}

interface Props {
  records: TrainingRecord[];
}

export default function TrainingScheduler({ records }: Props) {
  const [scheduledSessions, setScheduledSessions] = useState<ScheduledSession[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  
  // Form State
  const [courseName, setCourseName] = useState('');
  const [date, setDate] = useState('');
  const [time, setTime] = useState('');
  const [instructor, setInstructor] = useState('');
  const [location, setLocation] = useState('');

  useEffect(() => {
    const q = query(collection(db, 'scheduled_training'), orderBy('date', 'asc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const sessions = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as ScheduledSession[];
      setScheduledSessions(sessions);
    }, (error) => {
      handleFirestoreError(error, 'list' as any, 'scheduled_training');
    });

    return () => unsubscribe();
  }, []);

  const handleSchedule = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;

    try {
      await addDoc(collection(db, 'scheduled_training'), {
        courseName,
        date,
        time,
        instructor,
        location,
        attendeesCount: 0,
        createdAt: new Date().toISOString()
      });
      setIsAdding(false);
      setCourseName('');
      setDate('');
      setTime('');
      setInstructor('');
      setLocation('');
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'scheduled_training');
    }
  };

  const expiringSoon = records.filter(r => 
    r.status === 'Active' && 
    (new Date(r.expiryDate).getTime() - new Date().getTime() < 60 * 24 * 60 * 60 * 1000) // 60 days
  );

  return (
    <div className="space-y-8">
      <div className="flex justify-between items-center">
        <h2 className="text-xl font-bold text-slate-900">Training Scheduler</h2>
        <button 
          onClick={() => setIsAdding(true)}
          className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors flex items-center gap-2"
        >
          <Plus size={20} />
          Schedule Session
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Upcoming Expiries - The "Why" */}
        <div className="lg:col-span-1 space-y-4">
          <h3 className="font-bold text-slate-700 flex items-center gap-2">
            <AlertCircle size={18} className="text-amber-500" />
            Renewal Needs
          </h3>
          <div className="bg-slate-50 border border-slate-200 rounded-xl p-4 space-y-3">
            {expiringSoon.length === 0 ? (
              <p className="text-sm text-slate-500 italic">No immediate renewals needed.</p>
            ) : (
              expiringSoon.map(record => (
                <div key={record.id} className="bg-white p-3 rounded-lg border border-slate-100 shadow-sm">
                  <p className="text-sm font-bold text-slate-900">{record.employeeName}</p>
                  <p className="text-xs text-slate-500">{record.courseName}</p>
                  <p className="text-xs text-amber-600 font-medium mt-1">Expires: {new Date(record.expiryDate).toLocaleDateString()}</p>
                </div>
              ))
            )}
          </div>
        </div>

        {/* Scheduled Sessions - The "What" */}
        <div className="lg:col-span-2 space-y-4">
          <h3 className="font-bold text-slate-700 flex items-center gap-2">
            <Calendar size={18} className="text-blue-500" />
            Upcoming Sessions
          </h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {scheduledSessions.map(session => (
              <div key={session.id} className="bg-white border border-slate-200 rounded-xl p-5 hover:shadow-md transition-shadow">
                <div className="flex justify-between items-start mb-4">
                  <div className="bg-blue-50 p-2 rounded-lg text-blue-600">
                    <Calendar size={20} />
                  </div>
                  <span className="text-xs font-bold bg-green-100 text-green-700 px-2 py-1 rounded-full">
                    Confirmed
                  </span>
                </div>
                <h4 className="font-bold text-slate-900 mb-2">{session.courseName}</h4>
                <div className="space-y-2 text-sm text-slate-600">
                  <div className="flex items-center gap-2">
                    <Clock size={14} className="text-slate-400" />
                    {new Date(session.date).toLocaleDateString()} at {session.time}
                  </div>
                  <div className="flex items-center gap-2">
                    <User size={14} className="text-slate-400" />
                    Instructor: {session.instructor}
                  </div>
                  <div className="flex items-center gap-2">
                    <CheckCircle2 size={14} className="text-slate-400" />
                    Location: {session.location}
                  </div>
                </div>
              </div>
            ))}
            {scheduledSessions.length === 0 && (
              <div className="col-span-full p-8 text-center text-slate-500 border-2 border-dashed border-slate-200 rounded-xl">
                No training sessions scheduled.
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Add Session Modal */}
      {isAdding && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex justify-between items-center">
              <h2 className="text-xl font-bold text-slate-900">Schedule Training</h2>
              <button onClick={() => setIsAdding(false)} className="text-slate-400 hover:text-slate-600">
                <XCircle size={24} />
              </button>
            </div>
            <form onSubmit={handleSchedule} className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Course Name</label>
                <input 
                  type="text" 
                  required
                  value={courseName}
                  onChange={(e) => setCourseName(e.target.value)}
                  className="w-full p-2.5 border border-slate-300 rounded-lg"
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Date</label>
                  <input 
                    type="date" 
                    required
                    value={date}
                    onChange={(e) => setDate(e.target.value)}
                    className="w-full p-2.5 border border-slate-300 rounded-lg"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Time</label>
                  <input 
                    type="time" 
                    required
                    value={time}
                    onChange={(e) => setTime(e.target.value)}
                    className="w-full p-2.5 border border-slate-300 rounded-lg"
                  />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Instructor</label>
                <input 
                  type="text" 
                  required
                  value={instructor}
                  onChange={(e) => setInstructor(e.target.value)}
                  className="w-full p-2.5 border border-slate-300 rounded-lg"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Location</label>
                <input 
                  type="text" 
                  required
                  value={location}
                  onChange={(e) => setLocation(e.target.value)}
                  className="w-full p-2.5 border border-slate-300 rounded-lg"
                />
              </div>
              <div className="pt-4 flex justify-end gap-3">
                <button 
                  type="button"
                  onClick={() => setIsAdding(false)}
                  className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg"
                >
                  Cancel
                </button>
                <button 
                  type="submit"
                  className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                >
                  Schedule Session
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
