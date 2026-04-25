import React, { useState, useEffect } from 'react';
import { Activity, Heart, Thermometer, AlertTriangle, Watch, User, Battery } from 'lucide-react';

interface WorkerVitals {
  id: string;
  name: string;
  role: string;
  heartRate: number;
  bodyTemp: number;
  stressLevel: 'Low' | 'Moderate' | 'High' | 'Critical';
  battery: number;
  status: 'Active' | 'Resting' | 'Alert';
}

export default function WearableBiometrics() {
  const [workers, setWorkers] = useState<WorkerVitals[]>([
    { id: '1', name: 'John Doe', role: 'Confined Space Entry', heartRate: 85, bodyTemp: 37.2, stressLevel: 'Low', battery: 88, status: 'Active' },
    { id: '2', name: 'Jane Smith', role: 'Welder', heartRate: 115, bodyTemp: 38.1, stressLevel: 'Moderate', battery: 45, status: 'Active' },
    { id: '3', name: 'Mike Johnson', role: 'Scaffolder', heartRate: 145, bodyTemp: 38.9, stressLevel: 'Critical', battery: 92, status: 'Alert' },
    { id: '4', name: 'Sarah Williams', role: 'Crane Operator', heartRate: 72, bodyTemp: 36.8, stressLevel: 'Low', battery: 15, status: 'Resting' },
  ]);

  // Simulate real-time updates
  useEffect(() => {
    const interval = setInterval(() => {
      setWorkers(prev => prev.map(w => {
        if (w.status === 'Resting') return w;
        const hrChange = Math.floor(Math.random() * 5) - 2;
        const tempChange = (Math.random() * 0.2) - 0.1;
        const newHr = Math.max(60, Math.min(180, w.heartRate + hrChange));
        const newTemp = Math.max(36.0, Math.min(40.0, w.bodyTemp + tempChange));
        
        let newStress: WorkerVitals['stressLevel'] = 'Low';
        let newStatus: WorkerVitals['status'] = 'Active';
        
        if (newHr > 130 || newTemp > 38.5) {
          newStress = 'Critical';
          newStatus = 'Alert';
        } else if (newHr > 100 || newTemp > 37.8) {
          newStress = 'Moderate';
        }

        return {
          ...w,
          heartRate: newHr,
          bodyTemp: parseFloat(newTemp.toFixed(1)),
          stressLevel: newStress,
          status: newStatus
        };
      }));
    }, 3000);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="bg-indigo-50 p-2 rounded-lg text-indigo-600">
            <Watch size={24} />
          </div>
          <div>
            <h2 className="text-xl font-bold text-slate-900">Live Biometric Telemetry</h2>
            <p className="text-sm text-slate-500">Real-time monitoring for high-risk tasks</p>
          </div>
        </div>
        <div className="flex items-center gap-2 bg-green-50 text-green-700 px-3 py-1.5 rounded-full text-sm font-bold border border-green-200">
          <span className="relative flex h-3 w-3">
            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
            <span className="relative inline-flex rounded-full h-3 w-3 bg-green-500"></span>
          </span>
          System Active
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {workers.map(worker => (
          <div key={worker.id} className={`bg-white border-2 rounded-2xl p-5 transition-all ${
            worker.status === 'Alert' ? 'border-red-500 shadow-lg shadow-red-100' : 'border-slate-200 shadow-sm'
          }`}>
            <div className="flex justify-between items-start mb-4">
              <div className="flex items-center gap-3">
                <div className={`p-2 rounded-full ${
                  worker.status === 'Alert' ? 'bg-red-100 text-red-600' : 'bg-slate-100 text-slate-600'
                }`}>
                  <User size={20} />
                </div>
                <div>
                  <h3 className="font-bold text-slate-900">{worker.name}</h3>
                  <p className="text-[10px] font-bold text-slate-400 uppercase">{worker.role}</p>
                </div>
              </div>
              {worker.status === 'Alert' && (
                <AlertTriangle className="text-red-500 animate-pulse" size={20} />
              )}
            </div>

            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2 text-slate-500">
                  <Heart size={16} className={worker.heartRate > 100 ? 'text-red-500' : ''} />
                  <span className="text-xs font-medium">Heart Rate</span>
                </div>
                <span className={`font-mono font-bold ${worker.heartRate > 120 ? 'text-red-600' : 'text-slate-900'}`}>
                  {Math.round(worker.heartRate)} bpm
                </span>
              </div>
              
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2 text-slate-500">
                  <Thermometer size={16} className={worker.bodyTemp > 38 ? 'text-amber-500' : ''} />
                  <span className="text-xs font-medium">Body Temp</span>
                </div>
                <span className={`font-mono font-bold ${worker.bodyTemp > 38 ? 'text-amber-600' : 'text-slate-900'}`}>
                  {worker.bodyTemp.toFixed(1)}°C
                </span>
              </div>

              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2 text-slate-500">
                  <Activity size={16} />
                  <span className="text-xs font-medium">Stress Level</span>
                </div>
                <span className={`text-[10px] font-bold uppercase px-2 py-0.5 rounded ${
                  worker.stressLevel === 'Critical' ? 'bg-red-100 text-red-700' :
                  worker.stressLevel === 'Moderate' ? 'bg-amber-100 text-amber-700' :
                  'bg-green-100 text-green-700'
                }`}>
                  {worker.stressLevel}
                </span>
              </div>
            </div>

            <div className="mt-4 pt-4 border-t border-slate-100 flex items-center justify-between">
              <div className="flex items-center gap-1 text-slate-400 text-xs font-medium">
                <Battery size={14} className={worker.battery < 20 ? 'text-red-500' : ''} />
                {worker.battery}%
              </div>
              {worker.status === 'Alert' && (
                <button className="text-xs font-bold bg-red-600 text-white px-3 py-1.5 rounded-lg hover:bg-red-700 transition-colors">
                  Initiate Check-in
                </button>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
