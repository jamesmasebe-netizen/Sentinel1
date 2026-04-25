import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy, doc, updateDoc } from 'firebase/firestore';
import { db, auth, handleFirestoreError } from '../lib/firebase';
import { ShieldCheck, Plus, X } from 'lucide-react';

interface StrategicRisk {
  id: string;
  title: string;
  category: 'Financial' | 'Operational' | 'Reputational' | 'Compliance' | 'Strategic' | 'Environmental';
  description: string;
  impact: number;
  likelihood: number;
  riskScore: number;
  owner: string;
  mitigationStrategy?: string;
  status: 'Active' | 'Mitigated' | 'Closed';
  authorId: string;
  createdAt: string;
}

export default function StrategicRiskRegister() {
  const [strategicRisks, setStrategicRisks] = useState<StrategicRisk[]>([]);
  const [isAddingStrategic, setIsAddingStrategic] = useState(false);

  const [riskTitle, setRiskTitle] = useState('');
  const [riskCategory, setRiskCategory] = useState<StrategicRisk['category']>('Strategic');
  const [riskDesc, setRiskDesc] = useState('');
  const [riskImpact, setRiskImpact] = useState(3);
  const [riskLikelihood, setRiskLikelihood] = useState(3);
  const [riskOwner, setRiskOwner] = useState('');
  const [riskMitigation, setRiskMitigation] = useState('');

  useEffect(() => {
    if (!auth.currentUser) return;
    const qStrategic = query(collection(db, 'strategic_risks'), orderBy('createdAt', 'desc'));
    const unsubStrategic = onSnapshot(qStrategic, (snapshot) => {
      setStrategicRisks(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as StrategicRisk[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'strategic_risks'));

    return () => unsubStrategic();
  }, []);

  const handleAddStrategic = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      await addDoc(collection(db, 'strategic_risks'), {
        title: riskTitle,
        category: riskCategory,
        description: riskDesc,
        impact: riskImpact,
        likelihood: riskLikelihood,
        riskScore: riskImpact * riskLikelihood,
        owner: riskOwner,
        mitigationStrategy: riskMitigation,
        status: 'Active',
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAddingStrategic(false);
      setRiskTitle(''); setRiskDesc(''); setRiskOwner(''); setRiskMitigation('');
      setRiskImpact(3); setRiskLikelihood(3); setRiskCategory('Strategic');
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'strategic_risks');
    }
  };

  const updateStrategicStatus = async (id: string, status: StrategicRisk['status']) => {
    try {
      await updateDoc(doc(db, 'strategic_risks', id), { status });
    } catch (error) {
      handleFirestoreError(error, 'update' as any, 'strategic_risks');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h2 className="text-lg font-bold text-slate-900">Strategic Risk Register</h2>
        <button
          onClick={() => setIsAddingStrategic(true)}
          className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 flex items-center gap-2 transition-colors shadow-sm"
        >
          <Plus size={20} /> Add Strategic Risk
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-red-50 p-4 rounded-lg border border-red-200">
          <p className="text-xs font-bold text-red-600 uppercase tracking-wider">High Risks (15+)</p>
          <p className="text-2xl font-bold text-red-700">{strategicRisks.filter(r => r.riskScore >= 15).length}</p>
        </div>
        <div className="bg-amber-50 p-4 rounded-lg border border-amber-200">
          <p className="text-xs font-bold text-amber-600 uppercase tracking-wider">Medium Risks (8-14)</p>
          <p className="text-2xl font-bold text-amber-700">{strategicRisks.filter(r => r.riskScore >= 8 && r.riskScore < 15).length}</p>
        </div>
        <div className="bg-green-50 p-4 rounded-lg border border-green-200">
          <p className="text-xs font-bold text-green-600 uppercase tracking-wider">Low Risks (1-7)</p>
          <p className="text-2xl font-bold text-green-700">{strategicRisks.filter(r => r.riskScore < 8).length}</p>
        </div>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 text-sm">
              <th className="p-4 font-medium">Risk Title</th>
              <th className="p-4 font-medium">Category</th>
              <th className="p-4 font-medium text-center">Score</th>
              <th className="p-4 font-medium">Owner</th>
              <th className="p-4 font-medium">Status</th>
            </tr>
          </thead>
          <tbody>
            {strategicRisks.length === 0 ? (
              <tr><td colSpan={5} className="p-8 text-center text-slate-500">No strategic risks identified.</td></tr>
            ) : (
              strategicRisks.map((risk) => (
                <tr key={risk.id} className="border-b border-slate-100 hover:bg-slate-50 transition-colors">
                  <td className="p-4">
                    <p className="font-medium text-slate-900">{risk.title}</p>
                    <p className="text-xs text-slate-500 line-clamp-1">{risk.description}</p>
                  </td>
                  <td className="p-4">
                    <span className="px-2 py-1 bg-slate-100 rounded text-xs font-medium text-slate-600">{risk.category}</span>
                  </td>
                  <td className="p-4 text-center">
                    <span className={`inline-block w-8 h-8 leading-8 rounded-full text-xs font-bold text-white ${
                      risk.riskScore >= 15 ? 'bg-red-500' :
                      risk.riskScore >= 8 ? 'bg-amber-500' :
                      'bg-green-500'
                    }`}>
                      {risk.riskScore}
                    </span>
                  </td>
                  <td className="p-4 text-slate-600 text-sm">{risk.owner}</td>
                  <td className="p-4">
                    <select
                      value={risk.status}
                      onChange={(e) => updateStrategicStatus(risk.id, e.target.value as any)}
                      className={`text-sm rounded-lg border-slate-300 focus:ring-blue-500 focus:border-blue-500 ${
                        risk.status === 'Active' ? 'bg-red-50 text-red-700' :
                        risk.status === 'Mitigated' ? 'bg-amber-50 text-amber-700' :
                        'bg-green-50 text-green-700'
                      }`}
                    >
                      <option value="Active">Active</option>
                      <option value="Mitigated">Mitigated</option>
                      <option value="Closed">Closed</option>
                    </select>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {isAddingStrategic && (
        <div className="fixed inset-0 bg-slate-900/50 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-2xl overflow-hidden">
            <div className="p-6 border-b border-slate-200 flex justify-between items-center bg-slate-50">
              <h2 className="text-xl font-bold text-slate-900">Add Strategic Risk</h2>
              <button onClick={() => setIsAddingStrategic(false)} className="text-slate-400 hover:text-slate-600">
                <X size={24} />
              </button>
            </div>
            <form onSubmit={handleAddStrategic} className="p-6 space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="md:col-span-2">
                  <label className="block text-sm font-medium text-slate-700 mb-1">Risk Title</label>
                  <input type="text" required value={riskTitle} onChange={e => setRiskTitle(e.target.value)} className="w-full p-2.5 border border-slate-300 rounded-lg" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Category</label>
                  <select value={riskCategory} onChange={e => setRiskCategory(e.target.value as any)} className="w-full p-2.5 border border-slate-300 rounded-lg">
                    <option value="Strategic">Strategic</option>
                    <option value="Operational">Operational</option>
                    <option value="Financial">Financial</option>
                    <option value="Compliance">Compliance</option>
                    <option value="Reputational">Reputational</option>
                    <option value="Environmental">Environmental</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Risk Owner</label>
                  <input type="text" required value={riskOwner} onChange={e => setRiskOwner(e.target.value)} className="w-full p-2.5 border border-slate-300 rounded-lg" />
                </div>
                <div className="md:col-span-2">
                  <label className="block text-sm font-medium text-slate-700 mb-1">Description</label>
                  <textarea required value={riskDesc} onChange={e => setRiskDesc(e.target.value)} className="w-full p-2.5 border border-slate-300 rounded-lg" rows={3}></textarea>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Impact (1-5)</label>
                  <input type="number" min="1" max="5" required value={riskImpact} onChange={e => setRiskImpact(Number(e.target.value))} className="w-full p-2.5 border border-slate-300 rounded-lg" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Likelihood (1-5)</label>
                  <input type="number" min="1" max="5" required value={riskLikelihood} onChange={e => setRiskLikelihood(Number(e.target.value))} className="w-full p-2.5 border border-slate-300 rounded-lg" />
                </div>
                <div className="md:col-span-2">
                  <label className="block text-sm font-medium text-slate-700 mb-1">Mitigation Strategy</label>
                  <textarea value={riskMitigation} onChange={e => setRiskMitigation(e.target.value)} className="w-full p-2.5 border border-slate-300 rounded-lg" rows={2}></textarea>
                </div>
              </div>
              <div className="flex justify-end gap-3 pt-4 border-t border-slate-200">
                <button type="button" onClick={() => setIsAddingStrategic(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg">Cancel</button>
                <button type="submit" className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">Save Risk</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
