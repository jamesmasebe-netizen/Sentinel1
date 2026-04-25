import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { Lightbulb, Plus, TrendingUp, TrendingDown, DollarSign, Leaf } from 'lucide-react';

interface EfficiencyProject {
  id: string;
  projectTitle: string;
  category: 'Energy' | 'Water' | 'Waste' | 'Carbon';
  implementationCost: number;
  estimatedAnnualSavings: number;
  environmentalBenefit: string;
  status: 'Proposed' | 'In Progress' | 'Completed';
  startDate: string;
  createdAt: string;
}

export default function ResourceEfficiencyProjects() {
  const [projects, setProjects] = useState<EfficiencyProject[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [formData, setFormData] = useState({
    projectTitle: '',
    category: 'Energy' as EfficiencyProject['category'],
    implementationCost: 0,
    estimatedAnnualSavings: 0,
    environmentalBenefit: '',
    status: 'Proposed' as EfficiencyProject['status'],
    startDate: ''
  });

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'env_efficiency_projects'), orderBy('startDate', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setProjects(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as EfficiencyProject[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'env_efficiency_projects'));
    return () => unsubscribe();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      await addDoc(collection(db, 'env_efficiency_projects'), {
        ...formData,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAdding(false);
      setFormData({ projectTitle: '', category: 'Energy', implementationCost: 0, estimatedAnnualSavings: 0, environmentalBenefit: '', status: 'Proposed', startDate: '' });
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'env_efficiency_projects');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">Resource Efficiency Projects Tracker</h2>
          <p className="text-sm text-slate-500">Track ROI and environmental savings of green projects (Energy, Water, Waste).</p>
        </div>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700">
          <Plus size={18} /> Log New Project
        </button>
      </div>

      {isAdding && (
        <div className="bg-slate-50 p-4 rounded-lg border border-slate-200 mb-6">
          <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Project Title</label>
              <input type="text" required placeholder="e.g., LED Retrofit, Rainwater Harvesting" value={formData.projectTitle} onChange={e => setFormData({...formData, projectTitle: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Category</label>
              <select value={formData.category} onChange={e => setFormData({...formData, category: e.target.value as any})} className="w-full p-2 border rounded-lg">
                <option value="Energy">Energy Efficiency</option>
                <option value="Water">Water Conservation</option>
                <option value="Waste">Waste Reduction / Circularity</option>
                <option value="Carbon">Carbon Sequestration / Offset</option>
              </select>
            </div>
            <div className="grid grid-cols-2 gap-2">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Cost (R)</label>
                <input type="number" required value={formData.implementationCost} onChange={e => setFormData({...formData, implementationCost: parseFloat(e.target.value) || 0})} className="w-full p-2 border rounded-lg" />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Annual Savings (R)</label>
                <input type="number" required value={formData.estimatedAnnualSavings} onChange={e => setFormData({...formData, estimatedAnnualSavings: parseFloat(e.target.value) || 0})} className="w-full p-2 border rounded-lg" />
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Start Date</label>
              <input type="date" required value={formData.startDate} onChange={e => setFormData({...formData, startDate: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div className="md:col-span-2">
              <label className="block text-sm font-medium text-slate-700 mb-1">Environmental Benefit</label>
              <textarea required value={formData.environmentalBenefit} onChange={e => setFormData({...formData, environmentalBenefit: e.target.value})} className="w-full p-2 border rounded-lg" rows={2}></textarea>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Status</label>
              <select value={formData.status} onChange={e => setFormData({...formData, status: e.target.value as any})} className="w-full p-2 border rounded-lg">
                <option value="Proposed">Proposed</option>
                <option value="In Progress">In Progress</option>
                <option value="Completed">Completed</option>
              </select>
            </div>
            <div className="md:col-span-2 flex justify-end gap-2 mt-2">
              <button type="button" onClick={() => setIsAdding(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg">Cancel</button>
              <button type="submit" className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700">Save Project</button>
            </div>
          </form>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {projects.map(project => (
          <div key={project.id} className="border border-slate-200 rounded-xl p-5 bg-white shadow-sm hover:shadow-md transition-shadow">
            <div className="flex justify-between items-start mb-4">
              <div className="bg-green-50 p-2 rounded-lg text-green-600"><Lightbulb size={24} /></div>
              <span className={`text-[10px] px-2 py-1 rounded-full font-bold uppercase tracking-wider ${
                project.status === 'Completed' ? 'bg-green-100 text-green-800' : 'bg-amber-100 text-amber-800'
              }`}>
                {project.status}
              </span>
            </div>
            <h3 className="font-bold text-slate-900">{project.projectTitle}</h3>
            <p className="text-xs text-slate-500 mb-4 font-bold uppercase tracking-wider">{project.category}</p>
            
            <div className="grid grid-cols-2 gap-4 mb-4">
              <div className="bg-slate-50 p-3 rounded-lg">
                <p className="text-[10px] text-slate-400 font-bold uppercase mb-1">ROI (Annual)</p>
                <div className="flex items-center gap-1 text-slate-900 font-black">
                  <TrendingUp size={14} className="text-green-600" /> R {project.estimatedAnnualSavings.toLocaleString()}
                </div>
              </div>
              <div className="bg-slate-50 p-3 rounded-lg">
                <p className="text-[10px] text-slate-400 font-bold uppercase mb-1">Investment</p>
                <div className="flex items-center gap-1 text-slate-900 font-black">
                  <DollarSign size={14} className="text-slate-400" /> R {project.implementationCost.toLocaleString()}
                </div>
              </div>
            </div>

            <div className="flex items-center gap-2 text-xs text-slate-600 bg-green-50 p-2 rounded border border-green-100">
              <Leaf size={14} className="text-green-600" />
              <span>{project.environmentalBenefit}</span>
            </div>
          </div>
        ))}
        {projects.length === 0 && !isAdding && (
          <div className="col-span-full p-8 text-center text-slate-500 bg-slate-50 rounded-xl border border-dashed border-slate-300">
            No efficiency projects logged.
          </div>
        )}
      </div>
    </div>
  );
}
