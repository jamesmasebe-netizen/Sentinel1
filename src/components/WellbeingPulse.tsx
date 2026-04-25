import React, { useState, useEffect } from 'react';
import { collection, onSnapshot, query, orderBy, addDoc } from 'firebase/firestore';
import { db, auth, handleFirestoreError } from '../lib/firebase';
import { Heart, Smile, Frown, Meh, TrendingUp, Sparkles, ShieldCheck, Send } from 'lucide-react';

interface PulseEntry {
  id: string;
  mood: 'Great' | 'Okay' | 'Struggling';
  stressLevel: number;
  timestamp: string;
}

export default function WellbeingPulse() {
  const [entries, setEntries] = useState<PulseEntry[]>([]);
  const [mood, setMood] = useState<'Great' | 'Okay' | 'Struggling' | null>(null);
  const [stress, setStress] = useState<number>(5);
  const [submitted, setSubmitted] = useState(false);

  useEffect(() => {
    const q = query(collection(db, 'wellbeing_pulse'), orderBy('timestamp', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setEntries(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as PulseEntry[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'wellbeing_pulse'));

    return () => unsubscribe();
  }, []);

  const handleSubmit = async () => {
    if (!mood) return;
    try {
      await addDoc(collection(db, 'wellbeing_pulse'), {
        mood,
        stressLevel: stress,
        timestamp: new Date().toISOString()
      });
      setSubmitted(true);
      setTimeout(() => {
        setSubmitted(false);
        setMood(null);
        setStress(5);
      }, 3000);
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'wellbeing_pulse');
    }
  };

  const stats = {
    total: entries.length,
    great: entries.filter(e => e.mood === 'Great').length,
    okay: entries.filter(e => e.mood === 'Okay').length,
    struggling: entries.filter(e => e.mood === 'Struggling').length,
    avgStress: entries.length > 0 ? (entries.reduce((acc, curr) => acc + curr.stressLevel, 0) / entries.length).toFixed(1) : '0'
  };

  return (
    <div className="space-y-8">
      <div className="flex items-center gap-3">
        <div className="bg-pink-50 p-2 rounded-lg text-pink-600">
          <Heart size={24} />
        </div>
        <div>
          <h2 className="text-xl font-bold text-slate-900">Mental Health & Wellbeing Pulse</h2>
          <p className="text-sm text-slate-500">Anonymous tracking of site-wide morale and stress levels</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Check-in Card */}
        <div className="bg-white border border-slate-200 rounded-3xl p-8 shadow-sm relative overflow-hidden">
          <div className="relative z-10">
            <h3 className="text-lg font-bold text-slate-900 mb-2">Daily Check-in</h3>
            <p className="text-sm text-slate-500 mb-8">How are you feeling today? Your response is completely anonymous.</p>

            {submitted ? (
              <div className="flex flex-col items-center justify-center py-12 text-center animate-in fade-in zoom-in duration-300">
                <div className="bg-green-100 p-4 rounded-full text-green-600 mb-4">
                  <ShieldCheck size={40} />
                </div>
                <h4 className="text-xl font-bold text-slate-900 mb-2">Thank you for sharing!</h4>
                <p className="text-slate-500">Your wellbeing matters to us.</p>
              </div>
            ) : (
              <div className="space-y-8">
                <div>
                  <label className="block text-sm font-bold text-slate-700 mb-4 text-center">Select your mood</label>
                  <div className="flex justify-center gap-4">
                    <button 
                      onClick={() => setMood('Great')}
                      className={`flex flex-col items-center gap-2 p-4 rounded-2xl transition-all ${
                        mood === 'Great' ? 'bg-green-50 border-2 border-green-500 text-green-700 scale-110' : 'bg-slate-50 border-2 border-transparent text-slate-500 hover:bg-slate-100'
                      }`}
                    >
                      <Smile size={40} />
                      <span className="text-xs font-bold uppercase">Great</span>
                    </button>
                    <button 
                      onClick={() => setMood('Okay')}
                      className={`flex flex-col items-center gap-2 p-4 rounded-2xl transition-all ${
                        mood === 'Okay' ? 'bg-amber-50 border-2 border-amber-500 text-amber-700 scale-110' : 'bg-slate-50 border-2 border-transparent text-slate-500 hover:bg-slate-100'
                      }`}
                    >
                      <Meh size={40} />
                      <span className="text-xs font-bold uppercase">Okay</span>
                    </button>
                    <button 
                      onClick={() => setMood('Struggling')}
                      className={`flex flex-col items-center gap-2 p-4 rounded-2xl transition-all ${
                        mood === 'Struggling' ? 'bg-red-50 border-2 border-red-500 text-red-700 scale-110' : 'bg-slate-50 border-2 border-transparent text-slate-500 hover:bg-slate-100'
                      }`}
                    >
                      <Frown size={40} />
                      <span className="text-xs font-bold uppercase">Struggling</span>
                    </button>
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-bold text-slate-700 mb-4 text-center">
                    Current Stress Level: <span className="text-pink-600">{stress}/10</span>
                  </label>
                  <input 
                    type="range" 
                    min="1" 
                    max="10" 
                    value={stress}
                    onChange={(e) => setStress(parseInt(e.target.value))}
                    className="w-full h-2 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-pink-600"
                  />
                  <div className="flex justify-between text-xs text-slate-400 mt-2 font-medium">
                    <span>Very Low</span>
                    <span>Extreme</span>
                  </div>
                </div>

                <button 
                  onClick={handleSubmit}
                  disabled={!mood}
                  className="w-full flex items-center justify-center gap-2 bg-slate-900 text-white py-4 rounded-xl font-bold hover:bg-slate-800 transition-colors disabled:bg-slate-300 disabled:cursor-not-allowed"
                >
                  <Send size={18} />
                  Submit Anonymously
                </button>
              </div>
            )}
          </div>
          <div className="absolute top-0 right-0 w-64 h-64 bg-pink-50 rounded-full blur-3xl -mr-32 -mt-32 pointer-events-none"></div>
        </div>

        {/* Dashboard */}
        <div className="space-y-6">
          <div className="bg-slate-900 rounded-3xl p-6 text-white">
            <h3 className="text-lg font-bold mb-6 flex items-center gap-2">
              <TrendingUp size={20} className="text-pink-400" />
              Site-wide Pulse
            </h3>
            
            <div className="grid grid-cols-2 gap-4 mb-6">
              <div className="bg-white/10 rounded-2xl p-4">
                <p className="text-slate-400 text-xs font-bold uppercase mb-1">Avg Stress</p>
                <p className="text-3xl font-black text-white">{stats.avgStress}<span className="text-lg text-slate-500 font-medium">/10</span></p>
              </div>
              <div className="bg-white/10 rounded-2xl p-4">
                <p className="text-slate-400 text-xs font-bold uppercase mb-1">Total Check-ins</p>
                <p className="text-3xl font-black text-white">{stats.total}</p>
              </div>
            </div>

            <div className="space-y-3">
              <div className="flex items-center gap-3">
                <Smile size={18} className="text-green-400" />
                <div className="flex-1 h-2 bg-white/10 rounded-full overflow-hidden">
                  <div className="h-full bg-green-400 rounded-full" style={{ width: `${stats.total ? (stats.great / stats.total) * 100 : 0}%` }}></div>
                </div>
                <span className="text-xs font-bold w-8 text-right">{stats.total ? Math.round((stats.great / stats.total) * 100) : 0}%</span>
              </div>
              <div className="flex items-center gap-3">
                <Meh size={18} className="text-amber-400" />
                <div className="flex-1 h-2 bg-white/10 rounded-full overflow-hidden">
                  <div className="h-full bg-amber-400 rounded-full" style={{ width: `${stats.total ? (stats.okay / stats.total) * 100 : 0}%` }}></div>
                </div>
                <span className="text-xs font-bold w-8 text-right">{stats.total ? Math.round((stats.okay / stats.total) * 100) : 0}%</span>
              </div>
              <div className="flex items-center gap-3">
                <Frown size={18} className="text-red-400" />
                <div className="flex-1 h-2 bg-white/10 rounded-full overflow-hidden">
                  <div className="h-full bg-red-400 rounded-full" style={{ width: `${stats.total ? (stats.struggling / stats.total) * 100 : 0}%` }}></div>
                </div>
                <span className="text-xs font-bold w-8 text-right">{stats.total ? Math.round((stats.struggling / stats.total) * 100) : 0}%</span>
              </div>
            </div>
          </div>

          <div className="bg-blue-50 border border-blue-100 rounded-2xl p-6 flex items-start gap-4">
            <div className="bg-white p-3 rounded-xl text-blue-600 shadow-sm shrink-0">
              <Sparkles size={24} />
            </div>
            <div>
              <h4 className="font-bold text-blue-900 mb-1">AI Insight</h4>
              <p className="text-xs text-blue-700 leading-relaxed">
                {parseFloat(stats.avgStress) > 7 
                  ? "High stress levels detected. Consider reviewing workloads and implementing mandatory rest breaks."
                  : "Overall site morale is stable. Continue promoting open communication and regular check-ins."}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
