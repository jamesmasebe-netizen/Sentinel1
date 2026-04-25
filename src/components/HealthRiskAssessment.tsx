import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { ClipboardList, Plus, ShieldCheck, AlertTriangle, Calendar } from 'lucide-react';

interface HRARecord {
  id: string;
  roleName: string;
  department: string;
  hazards: string[];
  riskLevel: 'Low' | 'Medium' | 'High' | 'Extreme';
  controlMeasures: string;
  reviewDate: string;
  status: 'Current' | 'Needs Review' | 'Expired';
  createdAt: string;
}

export default function HealthRiskAssessment() {
  const [assessments, setAssessments] = useState<HRARecord[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [formData, setFormData] = useState({
    roleName: '',
    department: '',
    hazards: [] as string[],
    riskLevel: 'Medium' as HRARecord['riskLevel'],
    controlMeasures: '',
    reviewDate: ''
  });

  const hazardOptions = ['Noise', 'Dust', 'Vibration', 'Chemicals', 'Ergonomic', 'Stress', 'Biological', 'Thermal'];

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'health_risk_assessments'), orderBy('createdAt', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as HRARecord[];
      setAssessments(data);
    }, (error) => handleFirestoreError(error, 'list' as any, 'health_risk_assessments'));
    return () => unsubscribe();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      await addDoc(collection(db, 'health_risk_assessments'), {
        ...formData,
        status: 'Current',
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAdding(false);
      setFormData({ roleName: '', department: '', hazards: [], riskLevel: 'Medium', controlMeasures: '', reviewDate: '' });
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'health_risk_assessments');
    }
  };

  const toggleHazard = (hazard: string) => {
    const current = [...formData.hazards];
    if (current.includes(hazard)) {
      setFormData({ ...formData, hazards: current.filter(h => h !== hazard) });
    } else {
      setFormData({ ...formData, hazards: [...current, hazard] });
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">Health Risk Assessment (HRA)</h2>
          <p className="text-sm text-slate-500">Define and manage occupational health risks by job role.</p>
        </div>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700">
          <Plus size={18} /> New Assessment
        </button>
      </div>

      {isAdding && (
        <div className="bg-slate-50 p-4 rounded-lg border border-slate-200 mb-6">
          <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Job Role / Occupation</label>
              <input type="text" required placeholder="e.g., Welder, Lab Technician" value={formData.roleName} onChange={e => setFormData({...formData, roleName: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Department</label>
              <input type="text" required value={formData.department} onChange={e => setFormData({...formData, department: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div className="md:col-span-2">
              <label className="block text-sm font-medium text-slate-700 mb-2">Identified Health Hazards</label>
              <div className="flex flex-wrap gap-2">
                {hazardOptions.map(h => (
                  <button
                    key={h}
                    type="button"
                    onClick={() => toggleHazard(h)}
                    className={`px-3 py-1 rounded-full text-xs font-medium transition-colors ${
                      formData.hazards.includes(h) ? 'bg-blue-600 text-white' : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-100'
                    }`}
                  >
                    {h}
                  </button>
                ))}
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Overall Risk Level</label>
              <select value={formData.riskLevel} onChange={e => setFormData({...formData, riskLevel: e.target.value as any})} className="w-full p-2 border rounded-lg">
                <option value="Low">Low</option>
                <option value="Medium">Medium</option>
                <option value="High">High</option>
                <option value="Extreme">Extreme</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Next Review Date</label>
              <input type="date" required value={formData.reviewDate} onChange={e => setFormData({...formData, reviewDate: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div className="md:col-span-2">
              <label className="block text-sm font-medium text-slate-700 mb-1">Control Measures</label>
              <textarea required value={formData.controlMeasures} onChange={e => setFormData({...formData, controlMeasures: e.target.value})} placeholder="e.g., Local Exhaust Ventilation, Mandatory Hearing Protection, Annual Medicals" className="w-full p-2 border rounded-lg" rows={3}></textarea>
            </div>
            <div className="md:col-span-2 flex justify-end gap-2 mt-2">
              <button type="button" onClick={() => setIsAdding(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg">Cancel</button>
              <button type="submit" className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">Save HRA</button>
            </div>
          </form>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {assessments.map(hra => (
          <div key={hra.id} className="border border-slate-200 rounded-xl p-5 bg-white shadow-sm hover:shadow-md transition-shadow">
            <div className="flex justify-between items-start mb-4">
              <div className="bg-blue-50 p-2 rounded-lg text-blue-600"><ClipboardList size={24} /></div>
              <span className={`text-xs px-2.5 py-1 rounded-full font-medium ${
                hra.riskLevel === 'Extreme' ? 'bg-red-100 text-red-800' :
                hra.riskLevel === 'High' ? 'bg-orange-100 text-orange-800' :
                hra.riskLevel === 'Medium' ? 'bg-amber-100 text-amber-800' :
                'bg-green-100 text-green-800'
              }`}>
                {hra.riskLevel} Risk
              </span>
            </div>
            <h3 className="font-bold text-slate-900 text-lg">{hra.roleName}</h3>
            <p className="text-sm text-slate-500 mb-4">{hra.department}</p>
            
            <div className="flex flex-wrap gap-1 mb-4">
              {hra.hazards.map(h => (
                <span key={h} className="px-2 py-0.5 bg-slate-100 text-slate-600 rounded text-[10px] font-bold uppercase tracking-wider">{h}</span>
              ))}
            </div>

            <div className="space-y-3 pt-4 border-t border-slate-100">
              <div className="flex items-start gap-2">
                <ShieldCheck size={16} className="text-green-600 mt-0.5 shrink-0" />
                <p className="text-xs text-slate-600 leading-relaxed">{hra.controlMeasures}</p>
              </div>
              <div className="flex justify-between items-center text-xs">
                <span className="text-slate-400 flex items-center gap-1"><Calendar size={14}/> Review: {new Date(hra.reviewDate).toLocaleDateString()}</span>
                {new Date(hra.reviewDate) < new Date() && <span className="text-red-600 font-bold flex items-center gap-1"><AlertTriangle size={14}/> OVERDUE</span>}
              </div>
            </div>
          </div>
        ))}
        {assessments.length === 0 && !isAdding && (
          <div className="col-span-full p-8 text-center text-slate-500 bg-slate-50 rounded-xl border border-dashed border-slate-300">
            No Health Risk Assessments logged.
          </div>
        )}
      </div>
    </div>
  );
}
