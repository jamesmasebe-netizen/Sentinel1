import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy, doc, updateDoc } from 'firebase/firestore';
import { db, auth, handleFirestoreError } from '../lib/firebase';
import { Plus, X, Target } from 'lucide-react';

interface BowTieAnalysis {
  id: string;
  hazard: string;
  topEvent: string;
  threats: string[];
  preventative: string[];
  mitigative: string[];
  consequences: string[];
  status: 'Draft' | 'Active' | 'Archived';
  authorId: string;
  createdAt: string;
}

export default function BowTieAnalysisComponent() {
  const [bowties, setBowties] = useState<BowTieAnalysis[]>([]);
  const [isAddingBowTie, setIsAddingBowTie] = useState(false);

  const [hazard, setHazard] = useState('');
  const [topEvent, setTopEvent] = useState('');
  const [threats, setThreats] = useState('');
  const [preventative, setPreventative] = useState('');
  const [mitigative, setMitigative] = useState('');
  const [consequences, setConsequences] = useState('');

  useEffect(() => {
    if (!auth.currentUser) return;
    const qBowtie = query(collection(db, 'bowtie_analyses'), orderBy('createdAt', 'desc'));
    const unsubBowtie = onSnapshot(qBowtie, (snapshot) => {
      setBowties(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as BowTieAnalysis[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'bowtie_analyses'));

    return () => unsubBowtie();
  }, []);

  const handleAddBowTie = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      await addDoc(collection(db, 'bowtie_analyses'), {
        hazard,
        topEvent,
        threats: threats.split(',').map(s => s.trim()).filter(s => s),
        preventative: preventative.split(',').map(s => s.trim()).filter(s => s),
        mitigative: mitigative.split(',').map(s => s.trim()).filter(s => s),
        consequences: consequences.split(',').map(s => s.trim()).filter(s => s),
        status: 'Active',
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAddingBowTie(false);
      setHazard(''); setTopEvent(''); setThreats(''); setPreventative(''); setMitigative(''); setConsequences('');
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'bowtie_analyses');
    }
  };

  const updateBowTieStatus = async (id: string, status: BowTieAnalysis['status']) => {
    try {
      await updateDoc(doc(db, 'bowtie_analyses', id), { status });
    } catch (error) {
      handleFirestoreError(error, 'update' as any, 'bowtie_analyses');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h2 className="text-lg font-bold text-slate-900">BowTie Analysis</h2>
        <button
          onClick={() => setIsAddingBowTie(true)}
          className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 flex items-center gap-2 transition-colors shadow-sm"
        >
          <Plus size={20} /> New Analysis
        </button>
      </div>

      <div className="grid grid-cols-1 gap-6">
        {bowties.length === 0 ? (
          <div className="p-8 text-center text-slate-500 bg-slate-50 rounded-xl border border-slate-200 border-dashed">
            No BowTie analyses found.
          </div>
        ) : (
          bowties.map((bt) => (
            <div key={bt.id} className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm">
              <div className="flex justify-between items-start mb-6">
                <div>
                  <h3 className="text-xl font-bold text-slate-900">{bt.hazard}</h3>
                  <p className="text-sm font-medium text-red-600 flex items-center gap-2 mt-1">
                    <Target size={16} /> Top Event: {bt.topEvent}
                  </p>
                </div>
                <select
                  value={bt.status}
                  onChange={(e) => updateBowTieStatus(bt.id, e.target.value as any)}
                  className={`text-xs font-bold rounded-md border-0 py-1 pl-2 pr-6 ${
                    bt.status === 'Active' ? 'bg-blue-100 text-blue-700' :
                    bt.status === 'Draft' ? 'bg-slate-100 text-slate-700' :
                    'bg-slate-100 text-slate-500'
                  }`}
                >
                  <option value="Draft">Draft</option>
                  <option value="Active">Active</option>
                  <option value="Archived">Archived</option>
                </select>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-4 gap-4 text-sm">
                <div className="bg-amber-50 p-4 rounded-lg border border-amber-100">
                  <h4 className="font-bold text-amber-900 mb-2">Threats</h4>
                  <ul className="list-disc pl-4 space-y-1 text-amber-800">
                    {bt.threats.map((t, i) => <li key={i}>{t}</li>)}
                  </ul>
                </div>
                <div className="bg-blue-50 p-4 rounded-lg border border-blue-100">
                  <h4 className="font-bold text-blue-900 mb-2">Preventative Controls</h4>
                  <ul className="list-disc pl-4 space-y-1 text-blue-800">
                    {bt.preventative.map((p, i) => <li key={i}>{p}</li>)}
                  </ul>
                </div>
                <div className="bg-emerald-50 p-4 rounded-lg border border-emerald-100">
                  <h4 className="font-bold text-emerald-900 mb-2">Mitigative Controls</h4>
                  <ul className="list-disc pl-4 space-y-1 text-emerald-800">
                    {bt.mitigative.map((m, i) => <li key={i}>{m}</li>)}
                  </ul>
                </div>
                <div className="bg-red-50 p-4 rounded-lg border border-red-100">
                  <h4 className="font-bold text-red-900 mb-2">Consequences</h4>
                  <ul className="list-disc pl-4 space-y-1 text-red-800">
                    {bt.consequences.map((c, i) => <li key={i}>{c}</li>)}
                  </ul>
                </div>
              </div>
            </div>
          ))
        )}
      </div>

      {isAddingBowTie && (
        <div className="fixed inset-0 bg-slate-900/50 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-3xl overflow-hidden max-h-[90vh] flex flex-col">
            <div className="p-6 border-b border-slate-200 flex justify-between items-center bg-slate-50 shrink-0">
              <h2 className="text-xl font-bold text-slate-900">New BowTie Analysis</h2>
              <button onClick={() => setIsAddingBowTie(false)} className="text-slate-400 hover:text-slate-600">
                <X size={24} />
              </button>
            </div>
            <div className="p-6 overflow-y-auto">
              <form id="bowtie-form" onSubmit={handleAddBowTie} className="space-y-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div className="md:col-span-2">
                    <label className="block text-sm font-medium text-slate-700 mb-1">Hazard</label>
                    <input type="text" required value={hazard} onChange={e => setHazard(e.target.value)} className="w-full p-2.5 border border-slate-300 rounded-lg" placeholder="e.g., Working at Heights" />
                  </div>
                  <div className="md:col-span-2">
                    <label className="block text-sm font-medium text-slate-700 mb-1">Top Event</label>
                    <input type="text" required value={topEvent} onChange={e => setTopEvent(e.target.value)} className="w-full p-2.5 border border-slate-300 rounded-lg" placeholder="e.g., Fall from height" />
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">Threats (comma separated)</label>
                    <textarea required value={threats} onChange={e => setThreats(e.target.value)} className="w-full p-2.5 border border-slate-300 rounded-lg" rows={3} placeholder="e.g., Unstable scaffolding, Slippery surface"></textarea>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">Preventative Controls (comma separated)</label>
                    <textarea required value={preventative} onChange={e => setPreventative(e.target.value)} className="w-full p-2.5 border border-slate-300 rounded-lg" rows={3} placeholder="e.g., Scaffold inspection, Non-slip footwear"></textarea>
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">Mitigative Controls (comma separated)</label>
                    <textarea required value={mitigative} onChange={e => setMitigative(e.target.value)} className="w-full p-2.5 border border-slate-300 rounded-lg" rows={3} placeholder="e.g., Safety harness, Safety net"></textarea>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">Consequences (comma separated)</label>
                    <textarea required value={consequences} onChange={e => setConsequences(e.target.value)} className="w-full p-2.5 border border-slate-300 rounded-lg" rows={3} placeholder="e.g., Severe injury, Fatality"></textarea>
                  </div>
                </div>
              </form>
            </div>
            <div className="p-6 border-t border-slate-200 bg-slate-50 flex justify-end gap-3 shrink-0">
              <button type="button" onClick={() => setIsAddingBowTie(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg font-medium">Cancel</button>
              <button type="submit" form="bowtie-form" className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 font-medium">Save Analysis</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
