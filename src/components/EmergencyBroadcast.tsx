import React, { useState, useEffect } from 'react';
import { collection, onSnapshot, query, addDoc, orderBy } from 'firebase/firestore';
import { db, auth, handleFirestoreError } from '../lib/firebase';
import { 
  Send, 
  Users, 
  ShieldCheck, 
  Building2, 
  Bell, 
  History, 
  CheckCircle2, 
  Loader2,
  AlertTriangle,
  Siren
} from 'lucide-react';

interface Broadcast {
  id: string;
  message: string;
  audience: 'All Staff' | 'Wardens Only' | 'Contractors Only';
  type: 'Emergency' | 'Alert' | 'Information';
  sentBy: string;
  timestamp: string;
  status: 'Sent' | 'Delivering' | 'Failed';
}

export default function EmergencyBroadcast() {
  const [broadcasts, setBroadcasts] = useState<Broadcast[]>([]);
  const [isSending, setIsSending] = useState(false);
  
  // Form State
  const [message, setMessage] = useState('');
  const [audience, setAudience] = useState<Broadcast['audience']>('All Staff');
  const [type, setType] = useState<Broadcast['type']>('Alert');

  useEffect(() => {
    const q = query(collection(db, 'emergency_broadcasts'), orderBy('timestamp', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setBroadcasts(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as Broadcast[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'emergency_broadcasts'));

    return () => unsubscribe();
  }, []);

  const handleSendBroadcast = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser || !message) return;

    setIsSending(true);
    try {
      await addDoc(collection(db, 'emergency_broadcasts'), {
        message,
        audience,
        type,
        sentBy: auth.currentUser.email,
        timestamp: new Date().toISOString(),
        status: 'Sent'
      });
      
      // Simulate delivery delay
      setTimeout(() => {
        setMessage('');
        setIsSending(false);
      }, 1500);
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'emergency_broadcasts');
      setIsSending(false);
    }
  };

  const templates = [
    { label: 'Fire Evacuation', text: 'EMERGENCY: Fire detected. Please evacuate to the nearest assembly point immediately. Follow warden instructions.' },
    { label: 'Medical Emergency', text: 'ALERT: Medical emergency in [Location]. First Aiders please respond to the area.' },
    { label: 'Drill Notification', text: 'NOTICE: An emergency drill will commence in 15 minutes. Please prepare for evacuation.' },
    { label: 'All Clear', text: 'ALL CLEAR: The emergency situation has been resolved. You may return to your work areas.' }
  ];

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Composer */}
        <div className="lg:col-span-2 space-y-6">
          <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm">
            <h2 className="text-xl font-bold text-slate-900 mb-6 flex items-center gap-2">
              <Send size={24} className="text-blue-600" />
              Broadcast Emergency Alert
            </h2>
            
            <form onSubmit={handleSendBroadcast} className="space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Audience</label>
                  <div className="flex gap-2">
                    <button 
                      type="button"
                      onClick={() => setAudience('All Staff')}
                      className={`flex-1 flex items-center justify-center gap-2 py-2 px-3 rounded-lg border text-xs font-bold transition-all ${
                        audience === 'All Staff' ? 'bg-blue-600 border-blue-600 text-white' : 'bg-white border-slate-200 text-slate-600 hover:bg-slate-50'
                      }`}
                    >
                      <Users size={14} /> All Staff
                    </button>
                    <button 
                      type="button"
                      onClick={() => setAudience('Wardens Only')}
                      className={`flex-1 flex items-center justify-center gap-2 py-2 px-3 rounded-lg border text-xs font-bold transition-all ${
                        audience === 'Wardens Only' ? 'bg-red-600 border-red-600 text-white' : 'bg-white border-slate-200 text-slate-600 hover:bg-slate-50'
                      }`}
                    >
                      <ShieldCheck size={14} /> Wardens
                    </button>
                    <button 
                      type="button"
                      onClick={() => setAudience('Contractors Only')}
                      className={`flex-1 flex items-center justify-center gap-2 py-2 px-3 rounded-lg border text-xs font-bold transition-all ${
                        audience === 'Contractors Only' ? 'bg-amber-600 border-amber-600 text-white' : 'bg-white border-slate-200 text-slate-600 hover:bg-slate-50'
                      }`}
                    >
                      <Building2 size={14} /> Contractors
                    </button>
                  </div>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Alert Type</label>
                  <select 
                    value={type}
                    onChange={(e) => setType(e.target.value as any)}
                    className="w-full p-2 border border-slate-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="Emergency">Emergency (High Priority)</option>
                    <option value="Alert">Alert (Standard)</option>
                    <option value="Information">Information (Low Priority)</option>
                  </select>
                </div>
              </div>

              <div>
                <div className="flex justify-between items-center mb-1">
                  <label className="block text-sm font-medium text-slate-700">Message Content</label>
                  <span className="text-[10px] text-slate-400 font-bold uppercase tracking-wider">{message.length} / 160 characters</span>
                </div>
                <textarea 
                  required
                  maxLength={160}
                  value={message}
                  onChange={(e) => setMessage(e.target.value)}
                  placeholder="Type your emergency message here..."
                  rows={4}
                  className="w-full p-4 border border-slate-300 rounded-xl focus:ring-2 focus:ring-blue-500 text-lg font-medium"
                />
              </div>

              <div className="flex flex-wrap gap-2">
                {templates.map(tmpl => (
                  <button 
                    key={tmpl.label}
                    type="button"
                    onClick={() => setMessage(tmpl.text)}
                    className="text-[10px] font-bold uppercase bg-slate-100 text-slate-600 px-3 py-1.5 rounded-full hover:bg-slate-200 transition-colors"
                  >
                    {tmpl.label}
                  </button>
                ))}
              </div>

              <button 
                type="submit"
                disabled={isSending || !message}
                className={`w-full flex items-center justify-center gap-3 py-4 rounded-xl font-black text-xl shadow-lg transition-all ${
                  type === 'Emergency' ? 'bg-red-600 hover:bg-red-700 shadow-red-200' : 
                  type === 'Alert' ? 'bg-blue-600 hover:bg-blue-700 shadow-blue-200' : 'bg-slate-900 hover:bg-slate-800 shadow-slate-200'
                } text-white disabled:bg-slate-300 disabled:shadow-none`}
              >
                {isSending ? <Loader2 className="animate-spin" size={24} /> : <Bell size={24} />}
                {isSending ? 'SENDING BROADCAST...' : 'SEND BROADCAST NOW'}
              </button>
            </form>
          </div>
        </div>

        {/* History */}
        <div className="space-y-6">
          <div className="bg-slate-50 border border-slate-200 rounded-2xl p-6">
            <h3 className="font-bold text-slate-900 mb-4 flex items-center gap-2">
              <History size={18} className="text-slate-500" />
              Broadcast History
            </h3>
            <div className="space-y-4 max-h-[600px] overflow-y-auto pr-2 custom-scrollbar">
              {broadcasts.map(bc => (
                <div key={bc.id} className="bg-white border border-slate-100 rounded-xl p-4 shadow-sm">
                  <div className="flex justify-between items-start mb-2">
                    <span className={`text-[10px] font-bold uppercase px-2 py-0.5 rounded ${
                      bc.type === 'Emergency' ? 'bg-red-100 text-red-700' :
                      bc.type === 'Alert' ? 'bg-blue-100 text-blue-700' : 'bg-slate-100 text-slate-700'
                    }`}>
                      {bc.type}
                    </span>
                    <span className="text-[10px] text-slate-400 font-medium">{new Date(bc.timestamp).toLocaleTimeString()}</span>
                  </div>
                  <p className="text-sm text-slate-700 font-medium mb-3 leading-snug">"{bc.message}"</p>
                  <div className="flex justify-between items-center pt-2 border-t border-slate-50">
                    <div className="flex items-center gap-1.5 text-[10px] text-slate-500 font-bold uppercase">
                      <Users size={12} />
                      {bc.audience}
                    </div>
                    <div className="flex items-center gap-1 text-[10px] text-green-600 font-bold uppercase">
                      <CheckCircle2 size={12} />
                      {bc.status}
                    </div>
                  </div>
                </div>
              ))}
              {broadcasts.length === 0 && (
                <p className="text-center py-8 text-xs text-slate-400 italic">No broadcasts sent yet.</p>
              )}
            </div>
          </div>

          <div className="bg-red-50 border border-red-100 rounded-2xl p-6">
            <h3 className="font-bold text-red-900 mb-3 flex items-center gap-2 text-sm">
              <Siren size={18} />
              Emergency Channels
            </h3>
            <div className="space-y-2">
              <div className="flex justify-between text-xs">
                <span className="text-red-800">SMS Gateway</span>
                <span className="font-bold text-green-600 uppercase">Online</span>
              </div>
              <div className="flex justify-between text-xs">
                <span className="text-red-800">Push Notifications</span>
                <span className="font-bold text-green-600 uppercase">Online</span>
              </div>
              <div className="flex justify-between text-xs">
                <span className="text-red-800">Email Relay</span>
                <span className="font-bold text-green-600 uppercase">Online</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <style>{`
        .custom-scrollbar::-webkit-scrollbar {
          width: 4px;
        }
        .custom-scrollbar::-webkit-scrollbar-track {
          background: #f1f5f9;
        }
        .custom-scrollbar::-webkit-scrollbar-thumb {
          background: #cbd5e1;
          border-radius: 10px;
        }
      `}</style>
    </div>
  );
}
