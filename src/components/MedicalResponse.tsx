import React, { useState, useEffect } from 'react';
import { collection, onSnapshot, query, addDoc, doc, updateDoc, orderBy } from 'firebase/firestore';
import { db, auth, handleFirestoreError } from '../lib/firebase';
import { 
  HeartPulse, 
  Stethoscope, 
  Clock, 
  User, 
  AlertTriangle, 
  CheckCircle2, 
  Plus, 
  X, 
  Activity,
  ShieldAlert
} from 'lucide-react';

interface MedicalIncident {
  id: string;
  patientName: string;
  triageLevel: 'Red (Immediate)' | 'Yellow (Delayed)' | 'Green (Minor)' | 'Black (Deceased)';
  condition: string;
  treatment: string;
  firstAider: string;
  status: 'Active' | 'Stabilized' | 'Evacuated';
  timestamp: string;
}

export default function MedicalResponse() {
  const [incidents, setIncidents] = useState<MedicalIncident[]>([]);
  const [isAdding, setIsAdding] = useState(false);

  // Form State
  const [patientName, setPatientName] = useState('');
  const [triageLevel, setTriageLevel] = useState<MedicalIncident['triageLevel']>('Green (Minor)');
  const [condition, setCondition] = useState('');
  const [treatment, setTreatment] = useState('');

  useEffect(() => {
    const q = query(collection(db, 'medical_incidents'), orderBy('timestamp', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setIncidents(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as MedicalIncident[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'medical_incidents'));

    return () => unsubscribe();
  }, []);

  const handleAddIncident = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;

    try {
      await addDoc(collection(db, 'medical_incidents'), {
        patientName,
        triageLevel,
        condition,
        treatment,
        firstAider: auth.currentUser.email,
        status: 'Active',
        timestamp: new Date().toISOString()
      });
      setIsAdding(false);
      setPatientName('');
      setCondition('');
      setTreatment('');
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'medical_incidents');
    }
  };

  const updateStatus = async (id: string, newStatus: MedicalIncident['status']) => {
    try {
      await updateDoc(doc(db, 'medical_incidents', id), { status: newStatus });
    } catch (error) {
      handleFirestoreError(error, 'update' as any, 'medical_incidents');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row justify-between items-center gap-4">
        <div className="flex items-center gap-3">
          <div className="bg-red-50 p-2 rounded-lg text-red-600">
            <HeartPulse size={24} />
          </div>
          <div>
            <h2 className="text-xl font-bold text-slate-900">Medical Response & Triage</h2>
            <p className="text-sm text-slate-500">Real-time patient tracking during emergency events</p>
          </div>
        </div>
        <button 
          onClick={() => setIsAdding(true)}
          className="w-full md:w-auto flex items-center justify-center gap-2 bg-red-600 text-white px-6 py-3 rounded-xl font-bold hover:bg-red-700 transition-all shadow-lg shadow-red-200"
        >
          <Plus size={20} />
          Log Medical Intervention
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
        {/* Triage Summary */}
        <div className="lg:col-span-1 space-y-4">
          <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm">
            <h3 className="font-bold text-slate-900 mb-4 flex items-center gap-2">
              <Activity size={18} className="text-red-500" />
              Current Triage
            </h3>
            <div className="space-y-3">
              {[
                { label: 'Red (Immediate)', color: 'bg-red-500', count: incidents.filter(i => i.triageLevel.includes('Red') && i.status === 'Active').length },
                { label: 'Yellow (Delayed)', color: 'bg-amber-500', count: incidents.filter(i => i.triageLevel.includes('Yellow') && i.status === 'Active').length },
                { label: 'Green (Minor)', color: 'bg-green-500', count: incidents.filter(i => i.triageLevel.includes('Green') && i.status === 'Active').length },
                { label: 'Black (Deceased)', color: 'bg-slate-900', count: incidents.filter(i => i.triageLevel.includes('Black') && i.status === 'Active').length },
              ].map(item => (
                <div key={item.label} className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <div className={`w-3 h-3 rounded-full ${item.color}`}></div>
                    <span className="text-xs text-slate-600 font-medium">{item.label}</span>
                  </div>
                  <span className="text-sm font-bold text-slate-900">{item.count}</span>
                </div>
              ))}
            </div>
          </div>

          <div className="bg-blue-50 border border-blue-100 rounded-2xl p-6">
            <h3 className="font-bold text-blue-900 mb-2 flex items-center gap-2 text-sm">
              <ShieldAlert size={18} />
              First Aid Resources
            </h3>
            <p className="text-[10px] text-blue-700 uppercase font-bold tracking-wider mb-3">On-Duty First Aiders</p>
            <div className="space-y-2">
              <div className="flex items-center gap-2 text-xs text-blue-800">
                <div className="w-2 h-2 bg-green-500 rounded-full"></div>
                <span>John Smith (Lead)</span>
              </div>
              <div className="flex items-center gap-2 text-xs text-blue-800">
                <div className="w-2 h-2 bg-green-500 rounded-full"></div>
                <span>Sarah Connor</span>
              </div>
            </div>
          </div>
        </div>

        {/* Incident List */}
        <div className="lg:col-span-3 space-y-4">
          {incidents.map(incident => (
            <div key={incident.id} className="bg-white border border-slate-200 rounded-2xl p-5 hover:shadow-md transition-shadow">
              <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mb-4">
                <div className="flex items-center gap-3">
                  <div className={`w-10 h-10 rounded-full flex items-center justify-center text-white font-bold ${
                    incident.triageLevel.includes('Red') ? 'bg-red-500' :
                    incident.triageLevel.includes('Yellow') ? 'bg-amber-500' :
                    incident.triageLevel.includes('Green') ? 'bg-green-500' : 'bg-slate-900'
                  }`}>
                    {incident.patientName.charAt(0)}
                  </div>
                  <div>
                    <h3 className="font-bold text-slate-900">{incident.patientName}</h3>
                    <p className="text-[10px] font-bold uppercase tracking-wider text-slate-400">
                      {incident.triageLevel} • {new Date(incident.timestamp).toLocaleTimeString()}
                    </p>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <select 
                    value={incident.status}
                    onChange={(e) => updateStatus(incident.id, e.target.value as any)}
                    className={`text-xs font-bold uppercase px-3 py-1.5 rounded-lg border-none focus:ring-0 cursor-pointer ${
                      incident.status === 'Active' ? 'bg-red-100 text-red-700' :
                      incident.status === 'Stabilized' ? 'bg-green-100 text-green-700' : 'bg-blue-100 text-blue-700'
                    }`}
                  >
                    <option value="Active">Active</option>
                    <option value="Stabilized">Stabilized</option>
                    <option value="Evacuated">Evacuated</option>
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6 pt-4 border-t border-slate-50">
                <div>
                  <label className="block text-[10px] font-bold text-slate-400 uppercase mb-1">Condition</label>
                  <p className="text-sm text-slate-700">{incident.condition}</p>
                </div>
                <div>
                  <label className="block text-[10px] font-bold text-slate-400 uppercase mb-1">Treatment Provided</label>
                  <p className="text-sm text-slate-700">{incident.treatment}</p>
                </div>
              </div>

              <div className="mt-4 flex items-center justify-between text-[10px] text-slate-400">
                <div className="flex items-center gap-1">
                  <Stethoscope size={12} />
                  <span>First Aider: {incident.firstAider?.split('@')[0]}</span>
                </div>
                <div className="flex items-center gap-1">
                  <Clock size={12} />
                  <span>Last Updated: {new Date(incident.timestamp).toLocaleTimeString()}</span>
                </div>
              </div>
            </div>
          ))}
          {incidents.length === 0 && (
            <div className="text-center py-12 bg-slate-50 rounded-2xl border-2 border-dashed border-slate-200">
              <HeartPulse className="mx-auto text-slate-300 mb-3" size={40} />
              <p className="text-slate-500 font-medium">No active medical incidents.</p>
            </div>
          )}
        </div>
      </div>

      {/* Add Incident Modal */}
      {isAdding && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex justify-between items-center">
              <h2 className="text-xl font-bold text-slate-900">Log Medical Intervention</h2>
              <button onClick={() => setIsAdding(false)} className="text-slate-400 hover:text-slate-600">
                <X size={24} />
              </button>
            </div>
            <form onSubmit={handleAddIncident} className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Patient Name / Description</label>
                <input 
                  type="text" 
                  required
                  value={patientName}
                  onChange={(e) => setPatientName(e.target.value)}
                  placeholder="e.g., John Doe or 'Worker in Workshop'"
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Triage Level</label>
                <select 
                  value={triageLevel}
                  onChange={(e) => setTriageLevel(e.target.value as any)}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500"
                >
                  <option value="Red (Immediate)">Red (Immediate)</option>
                  <option value="Yellow (Delayed)">Yellow (Delayed)</option>
                  <option value="Green (Minor)">Green (Minor)</option>
                  <option value="Black (Deceased)">Black (Deceased)</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Condition / Symptoms</label>
                <textarea 
                  required
                  value={condition}
                  onChange={(e) => setCondition(e.target.value)}
                  placeholder="Describe injuries or symptoms..."
                  rows={2}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Treatment Administered</label>
                <textarea 
                  required
                  value={treatment}
                  onChange={(e) => setTreatment(e.target.value)}
                  placeholder="Describe first aid provided..."
                  rows={2}
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
                  Save Record
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
