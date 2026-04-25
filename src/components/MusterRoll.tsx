import React, { useState, useEffect } from 'react';
import { collection, onSnapshot, query, where, addDoc, doc, updateDoc, getDocs } from 'firebase/firestore';
import { db, auth, handleFirestoreError } from '../lib/firebase';
import { 
  Users, 
  CheckCircle2, 
  XCircle, 
  AlertTriangle, 
  Search, 
  Clock, 
  Filter,
  Download,
  Printer,
  ShieldAlert,
  Siren
} from 'lucide-react';

interface SiteAccess {
  id: string;
  workerId: string;
  workerName: string;
  companyName: string;
  checkInTime: string;
  checkOutTime?: string;
  status: 'In' | 'Out';
}

export default function MusterRoll() {
  const [accessLogs, setAccessLogs] = useState<SiteAccess[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [isEmergencyActive, setIsEmergencyActive] = useState(false);
  const [checkedOff, setCheckedOff] = useState<Set<string>>(new Set());

  useEffect(() => {
    const q = query(collection(db, 'site_access'), where('status', '==', 'In'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as SiteAccess[];
      setAccessLogs(data);
    }, (error) => {
      handleFirestoreError(error, 'list' as any, 'site_access');
    });

    return () => unsubscribe();
  }, []);

  const initiateMuster = () => {
    setIsEmergencyActive(true);
    setCheckedOff(new Set());
  };

  const toggleCheckOff = (id: string) => {
    const updated = new Set(checkedOff);
    if (updated.has(id)) {
      updated.delete(id);
    } else {
      updated.add(id);
    }
    setCheckedOff(updated);
  };

  const filteredLogs = accessLogs.filter(log => 
    log.workerName.toLowerCase().includes(searchTerm.toLowerCase()) ||
    log.companyName.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const safeCount = checkedOff.size;
  const missingCount = accessLogs.length - safeCount;
  const totalCount = accessLogs.length;

  return (
    <div className="space-y-6">
      {isEmergencyActive ? (
        <div className="bg-red-600 rounded-2xl p-6 text-white shadow-xl animate-pulse-slow">
          <div className="flex flex-col md:flex-row justify-between items-center gap-6">
            <div className="flex items-center gap-4">
              <div className="bg-white/20 p-4 rounded-full">
                <Siren size={40} className="animate-pulse" />
              </div>
              <div>
                <h2 className="text-3xl font-black uppercase tracking-tighter">Live Evacuation Muster</h2>
                <p className="text-red-100 font-medium">Emergency Protocol Active • ISO 45001 Standard</p>
              </div>
            </div>
            
            <div className="flex gap-8">
              <div className="text-center">
                <p className="text-4xl font-black">{totalCount}</p>
                <p className="text-[10px] uppercase font-bold text-red-200">On Site</p>
              </div>
              <div className="text-center">
                <p className="text-4xl font-black text-green-300">{safeCount}</p>
                <p className="text-[10px] uppercase font-bold text-red-200">Safe</p>
              </div>
              <div className="text-center">
                <p className="text-4xl font-black text-amber-300">{missingCount}</p>
                <p className="text-[10px] uppercase font-bold text-red-200">Missing</p>
              </div>
            </div>

            <button 
              onClick={() => setIsEmergencyActive(false)}
              className="bg-white text-red-600 px-6 py-3 rounded-xl font-bold hover:bg-red-50 transition-colors shadow-lg"
            >
              End Emergency
            </button>
          </div>
        </div>
      ) : (
        <div className="bg-slate-900 rounded-2xl p-8 text-white relative overflow-hidden shadow-xl">
          <div className="relative z-10 flex flex-col md:flex-row justify-between items-center gap-6">
            <div>
              <h2 className="text-2xl font-bold mb-2 flex items-center gap-2">
                Site Attendance & Muster Readiness <ShieldAlert className="text-amber-500" size={24} />
              </h2>
              <p className="text-slate-400 max-w-xl">
                Real-time tracking of all personnel currently on-site. In an emergency, initiate the muster roll to ensure 100% accountability.
              </p>
            </div>
            <button 
              onClick={initiateMuster}
              className="bg-red-600 text-white px-8 py-4 rounded-xl font-bold text-lg hover:bg-red-700 transition-all shadow-lg hover:shadow-red-900/40 flex items-center gap-3"
            >
              <Siren size={24} />
              INITIATE EMERGENCY MUSTER
            </button>
          </div>
          <div className="absolute top-0 right-0 w-64 h-64 bg-red-600/10 rounded-full blur-3xl -mr-32 -mt-32"></div>
        </div>
      )}

      <div className="bg-white border border-slate-200 rounded-2xl overflow-hidden shadow-sm">
        <div className="p-6 border-b border-slate-100 flex flex-col md:flex-row justify-between items-center gap-4 bg-slate-50">
          <div className="relative w-full md:w-96">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
            <input 
              type="text"
              placeholder="Search personnel or company..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-slate-200 rounded-lg focus:ring-2 focus:ring-red-500"
            />
          </div>
          <div className="flex gap-2 w-full md:w-auto">
            <button className="flex-1 md:flex-none flex items-center justify-center gap-2 px-4 py-2 border border-slate-200 rounded-lg hover:bg-white transition-colors text-sm font-medium text-slate-600">
              <Filter size={16} /> Filter
            </button>
            <button className="flex-1 md:flex-none flex items-center justify-center gap-2 px-4 py-2 border border-slate-200 rounded-lg hover:bg-white transition-colors text-sm font-medium text-slate-600">
              <Printer size={16} /> Print
            </button>
            <button className="flex-1 md:flex-none flex items-center justify-center gap-2 px-4 py-2 bg-slate-900 text-white rounded-lg hover:bg-slate-800 transition-colors text-sm font-medium">
              <Download size={16} /> Export
            </button>
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 text-xs uppercase tracking-wider">
                <th className="p-4 font-bold">Personnel Name</th>
                <th className="p-4 font-bold">Company</th>
                <th className="p-4 font-bold">Check-In Time</th>
                <th className="p-4 font-bold">Duration</th>
                <th className="p-4 font-bold text-center">Status</th>
                {isEmergencyActive && <th className="p-4 font-bold text-center">Accounted For</th>}
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {filteredLogs.map(log => {
                const checkInDate = new Date(log.checkInTime);
                const durationHrs = Math.floor((new Date().getTime() - checkInDate.getTime()) / (1000 * 60 * 60));
                const durationMins = Math.floor(((new Date().getTime() - checkInDate.getTime()) / (1000 * 60)) % 60);
                
                return (
                  <tr 
                    key={log.id} 
                    className={`hover:bg-slate-50 transition-colors ${
                      isEmergencyActive && !checkedOff.has(log.id) ? 'bg-red-50/50' : ''
                    }`}
                  >
                    <td className="p-4">
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center text-xs font-bold text-slate-600">
                          {log.workerName.charAt(0)}
                        </div>
                        <span className="font-medium text-slate-900">{log.workerName}</span>
                      </div>
                    </td>
                    <td className="p-4 text-slate-600 text-sm">{log.companyName}</td>
                    <td className="p-4 text-slate-600 text-sm">{checkInDate.toLocaleTimeString()}</td>
                    <td className="p-4">
                      <div className="flex items-center gap-1.5 text-xs text-slate-500">
                        <Clock size={12} />
                        {durationHrs}h {durationMins}m
                      </div>
                    </td>
                    <td className="p-4 text-center">
                      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase bg-green-100 text-green-700 border border-green-200">
                        On Site
                      </span>
                    </td>
                    {isEmergencyActive && (
                      <td className="p-4 text-center">
                        <button 
                          onClick={() => toggleCheckOff(log.id)}
                          className={`p-2 rounded-lg transition-all ${
                            checkedOff.has(log.id) 
                              ? 'bg-green-500 text-white shadow-lg shadow-green-200' 
                              : 'bg-white border-2 border-slate-200 text-slate-300 hover:border-red-300 hover:text-red-500'
                          }`}
                        >
                          {checkedOff.has(log.id) ? <CheckCircle2 size={24} /> : <XCircle size={24} />}
                        </button>
                      </td>
                    )}
                  </tr>
                );
              })}
              {filteredLogs.length === 0 && (
                <tr>
                  <td colSpan={isEmergencyActive ? 6 : 5} className="p-12 text-center text-slate-400">
                    <Users size={40} className="mx-auto mb-4 opacity-20" />
                    <p className="font-medium">No personnel currently on-site.</p>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      <style>{`
        @keyframes pulse-slow {
          0%, 100% { opacity: 1; }
          50% { opacity: 0.95; }
        }
        .animate-pulse-slow {
          animation: pulse-slow 3s ease-in-out infinite;
        }
      `}</style>
    </div>
  );
}
