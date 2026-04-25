import React, { useState, useEffect } from 'react';
import { collection, onSnapshot, query, addDoc, doc, updateDoc, orderBy } from 'firebase/firestore';
import { db, auth, handleFirestoreError } from '../lib/firebase';
import { 
  Settings, 
  ClipboardCheck, 
  History, 
  AlertCircle, 
  CheckCircle2, 
  Wrench, 
  Calendar,
  Camera,
  Plus,
  X
} from 'lucide-react';

interface MaintenanceLog {
  id: string;
  equipmentId: string;
  equipmentName: string;
  date: string;
  performedBy: string;
  type: 'Routine' | 'Repair' | 'Major Service';
  findings: string;
  status: 'Pass' | 'Fail' | 'Fixed';
}

interface Equipment {
  id: string;
  equipmentType: string;
  location: string;
  status: string;
}

export default function EquipmentMaintenance() {
  const [logs, setLogs] = useState<MaintenanceLog[]>([]);
  const [equipment, setEquipment] = useState<Equipment[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  
  // Form State
  const [selectedEquip, setSelectedEquip] = useState('');
  const [serviceType, setServiceType] = useState<MaintenanceLog['type']>('Routine');
  const [findings, setFindings] = useState('');
  const [serviceStatus, setServiceStatus] = useState<MaintenanceLog['status']>('Pass');

  useEffect(() => {
    const qLogs = query(collection(db, 'maintenance_logs'), orderBy('date', 'desc'));
    const unsubscribeLogs = onSnapshot(qLogs, (snapshot) => {
      setLogs(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as MaintenanceLog[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'maintenance_logs'));

    const qEquip = query(collection(db, 'emergency_equipment'));
    const unsubscribeEquip = onSnapshot(qEquip, (snapshot) => {
      setEquipment(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as Equipment[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'emergency_equipment'));

    return () => {
      unsubscribeLogs();
      unsubscribeEquip();
    };
  }, []);

  const handleAddLog = async (e: React.FormEvent) => {
    e.preventDefault();
    const equip = equipment.find(e => e.id === selectedEquip);
    if (!equip || !auth.currentUser) return;

    try {
      await addDoc(collection(db, 'maintenance_logs'), {
        equipmentId: selectedEquip,
        equipmentName: `${equip.equipmentType} - ${equip.location}`,
        date: new Date().toISOString(),
        performedBy: auth.currentUser.email,
        type: serviceType,
        findings,
        status: serviceStatus
      });

      // Update equipment status if it failed
      if (serviceStatus === 'Fail') {
        await updateDoc(doc(db, 'emergency_equipment', selectedEquip), {
          status: 'Out of Service'
        });
      } else if (serviceStatus === 'Pass' || serviceStatus === 'Fixed') {
        await updateDoc(doc(db, 'emergency_equipment', selectedEquip), {
          status: 'Operational'
        });
      }

      setIsAdding(false);
      setFindings('');
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'maintenance_logs');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div className="flex items-center gap-3">
          <div className="bg-slate-100 p-2 rounded-lg text-slate-600">
            <Wrench size={20} />
          </div>
          <h2 className="text-xl font-bold text-slate-900">Advanced Maintenance Logs</h2>
        </div>
        <button 
          onClick={() => setIsAdding(true)}
          className="flex items-center gap-2 bg-slate-900 text-white px-4 py-2 rounded-lg hover:bg-slate-800 transition-colors"
        >
          <Plus size={20} />
          New Inspection
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Recent History */}
        <div className="lg:col-span-2 space-y-4">
          {logs.map(log => (
            <div key={log.id} className="bg-white border border-slate-200 rounded-xl p-4 flex items-start justify-between hover:shadow-sm transition-shadow">
              <div className="flex items-start gap-4">
                <div className={`p-2 rounded-lg ${
                  log.status === 'Pass' ? 'bg-green-50 text-green-600' : 
                  log.status === 'Fail' ? 'bg-red-50 text-red-600' : 'bg-blue-50 text-blue-600'
                }`}>
                  <ClipboardCheck size={24} />
                </div>
                <div>
                  <h3 className="font-bold text-slate-900">{log.equipmentName}</h3>
                  <p className="text-xs text-slate-500 mb-2">{log.type} Inspection • {new Date(log.date).toLocaleDateString()}</p>
                  <p className="text-sm text-slate-600 italic">"{log.findings}"</p>
                </div>
              </div>
              <div className="text-right">
                <span className={`text-[10px] font-bold uppercase px-2 py-1 rounded-full ${
                  log.status === 'Pass' ? 'bg-green-100 text-green-700' : 
                  log.status === 'Fail' ? 'bg-red-100 text-red-700' : 'bg-blue-100 text-blue-700'
                }`}>
                  {log.status}
                </span>
                <p className="text-[10px] text-slate-400 mt-2">By: {log.performedBy?.split('@')[0]}</p>
              </div>
            </div>
          ))}
        </div>

        {/* Maintenance Stats */}
        <div className="space-y-4">
          <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm">
            <h3 className="font-bold text-slate-900 mb-4 flex items-center gap-2">
              <History size={18} className="text-blue-600" />
              Compliance Overview
            </h3>
            <div className="space-y-4">
              <div className="flex justify-between items-center">
                <span className="text-sm text-slate-500">Operational Rate</span>
                <span className="text-sm font-bold text-green-600">94%</span>
              </div>
              <div className="w-full bg-slate-100 rounded-full h-2">
                <div className="bg-green-500 h-2 rounded-full" style={{ width: '94%' }}></div>
              </div>
              <div className="grid grid-cols-2 gap-4 pt-2">
                <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                  <p className="text-xl font-bold text-slate-900">{logs.length}</p>
                  <p className="text-[10px] text-slate-500 uppercase font-bold tracking-wider">Total Inspections</p>
                </div>
                <div className="bg-red-50 p-3 rounded-xl border border-red-100">
                  <p className="text-xl font-bold text-red-600">{logs.filter(l => l.status === 'Fail').length}</p>
                  <p className="text-[10px] text-red-500 uppercase font-bold tracking-wider">Failures Found</p>
                </div>
              </div>
            </div>
          </div>

          <div className="bg-amber-50 border border-amber-100 rounded-2xl p-6">
            <h3 className="font-bold text-amber-900 mb-2 flex items-center gap-2 text-sm">
              <AlertCircle size={18} />
              Upcoming Major Services
            </h3>
            <div className="space-y-3 mt-4">
              <div className="flex items-center justify-between text-xs">
                <span className="text-amber-800">Fire Sprinkler System</span>
                <span className="font-bold text-amber-900">12 Days</span>
              </div>
              <div className="flex items-center justify-between text-xs">
                <span className="text-amber-800">AED Battery Replacement</span>
                <span className="font-bold text-amber-900">Overdue</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Add Log Modal */}
      {isAdding && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex justify-between items-center">
              <h2 className="text-xl font-bold text-slate-900">Log Equipment Inspection</h2>
              <button onClick={() => setIsAdding(false)} className="text-slate-400 hover:text-slate-600">
                <X size={24} />
              </button>
            </div>
            <form onSubmit={handleAddLog} className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Select Equipment</label>
                <select 
                  required
                  value={selectedEquip}
                  onChange={(e) => setSelectedEquip(e.target.value)}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-slate-900"
                >
                  <option value="">-- Select Asset --</option>
                  {equipment.map(e => (
                    <option key={e.id} value={e.id}>{e.equipmentType} - {e.location}</option>
                  ))}
                </select>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Type</label>
                  <select 
                    value={serviceType}
                    onChange={(e) => setServiceType(e.target.value as any)}
                    className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-slate-900"
                  >
                    <option value="Routine">Routine</option>
                    <option value="Repair">Repair</option>
                    <option value="Major Service">Major Service</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Result</label>
                  <select 
                    value={serviceStatus}
                    onChange={(e) => setServiceStatus(e.target.value as any)}
                    className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-slate-900"
                  >
                    <option value="Pass">Pass</option>
                    <option value="Fail">Fail</option>
                    <option value="Fixed">Fixed</option>
                  </select>
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Findings & Observations</label>
                <textarea 
                  required
                  value={findings}
                  onChange={(e) => setFindings(e.target.value)}
                  placeholder="Describe condition, pressure levels, seal integrity, etc."
                  rows={3}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-slate-900"
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
                  className="px-4 py-2 bg-slate-900 text-white rounded-lg hover:bg-slate-800 transition-colors font-bold"
                >
                  Save Inspection
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
