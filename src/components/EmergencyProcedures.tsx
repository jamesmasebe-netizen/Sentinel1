import React, { useState, useEffect } from 'react';
import { collection, onSnapshot, query, orderBy, addDoc } from 'firebase/firestore';
import { db, auth, handleFirestoreError } from '../lib/firebase';
import { 
  Book, 
  Search, 
  Flame, 
  Stethoscope, 
  Droplets, 
  ShieldAlert, 
  Info, 
  ChevronRight,
  Plus,
  XCircle,
  FileText
} from 'lucide-react';

interface Procedure {
  id: string;
  title: string;
  category: 'Fire' | 'Medical' | 'Spill' | 'Security' | 'Natural' | 'Other';
  steps: string[];
  contacts: { name: string; phone: string }[];
  lastUpdated: string;
}

export default function EmergencyProcedures() {
  const [procedures, setProcedures] = useState<Procedure[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedProcedure, setSelectedProcedure] = useState<Procedure | null>(null);
  const [isAdding, setIsAdding] = useState(false);

  // New Procedure Form
  const [newTitle, setNewTitle] = useState('');
  const [newCategory, setNewCategory] = useState<Procedure['category']>('Fire');
  const [newSteps, setNewSteps] = useState<string[]>(['']);
  const [newContacts, setNewContacts] = useState<{ name: string; phone: string }[]>([{ name: '', phone: '' }]);

  useEffect(() => {
    const q = query(collection(db, 'emergency_procedures'), orderBy('category'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as Procedure[];
      setProcedures(data);
    }, (error) => {
      handleFirestoreError(error, 'list' as any, 'emergency_procedures');
    });

    return () => unsubscribe();
  }, []);

  const handleAddProcedure = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;

    try {
      await addDoc(collection(db, 'emergency_procedures'), {
        title: newTitle,
        category: newCategory,
        steps: newSteps.filter(s => s.trim() !== ''),
        contacts: newContacts.filter(c => c.name.trim() !== ''),
        lastUpdated: new Date().toISOString(),
        authorId: auth.currentUser.uid
      });
      setIsAdding(false);
      setNewTitle('');
      setNewSteps(['']);
      setNewContacts([{ name: '', phone: '' }]);
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'emergency_procedures');
    }
  };

  const filteredProcedures = procedures.filter(p => 
    p.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
    p.category.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const getCategoryIcon = (category: Procedure['category']) => {
    switch (category) {
      case 'Fire': return <Flame size={20} className="text-red-500" />;
      case 'Medical': return <Stethoscope size={20} className="text-blue-500" />;
      case 'Spill': return <Droplets size={20} className="text-amber-500" />;
      case 'Security': return <ShieldAlert size={20} className="text-slate-700" />;
      case 'Natural': return <Info size={20} className="text-green-500" />;
      default: return <Book size={20} className="text-slate-500" />;
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row gap-4 items-center justify-between">
        <div className="relative w-full md:w-96">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
          <input 
            type="text"
            placeholder="Search procedures..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-10 pr-4 py-2 border border-slate-200 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-transparent"
          />
        </div>
        <button 
          onClick={() => setIsAdding(true)}
          className="flex items-center gap-2 bg-slate-900 text-white px-4 py-2 rounded-lg hover:bg-slate-800 transition-colors w-full md:w-auto justify-center"
        >
          <Plus size={20} />
          Add Procedure
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {filteredProcedures.map(proc => (
          <button
            key={proc.id}
            onClick={() => setSelectedProcedure(proc)}
            className="flex items-center justify-between p-4 bg-white border border-slate-200 rounded-xl hover:border-red-300 hover:shadow-sm transition-all text-left group"
          >
            <div className="flex items-center gap-3">
              <div className="bg-slate-50 p-2 rounded-lg group-hover:bg-red-50 transition-colors">
                {getCategoryIcon(proc.category)}
              </div>
              <div>
                <h3 className="font-semibold text-slate-900">{proc.title}</h3>
                <p className="text-xs text-slate-500">{proc.category} Response Plan</p>
              </div>
            </div>
            <ChevronRight size={18} className="text-slate-300 group-hover:text-red-500 transition-colors" />
          </button>
        ))}
      </div>

      {/* Procedure Detail Modal */}
      {selectedProcedure && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-2xl max-h-[90vh] overflow-hidden flex flex-col">
            <div className="p-6 border-b border-slate-100 flex justify-between items-center bg-slate-50">
              <div className="flex items-center gap-3">
                {getCategoryIcon(selectedProcedure.category)}
                <div>
                  <h2 className="text-xl font-bold text-slate-900">{selectedProcedure.title}</h2>
                  <p className="text-xs text-slate-500 uppercase font-bold tracking-wider">Emergency Response Procedure</p>
                </div>
              </div>
              <button onClick={() => setSelectedProcedure(null)} className="text-slate-400 hover:text-slate-600">
                <XCircle size={24} />
              </button>
            </div>
            
            <div className="p-6 overflow-y-auto space-y-8">
              <section>
                <h3 className="text-sm font-bold text-slate-900 uppercase tracking-wider mb-4 flex items-center gap-2">
                  <FileText size={16} className="text-red-500" />
                  Response Steps
                </h3>
                <div className="space-y-3">
                  {selectedProcedure.steps.map((step, idx) => (
                    <div key={idx} className="flex gap-4 p-3 bg-slate-50 rounded-lg border border-slate-100">
                      <span className="flex-shrink-0 w-6 h-6 bg-white border border-slate-200 rounded-full flex items-center justify-center text-xs font-bold text-slate-600">
                        {idx + 1}
                      </span>
                      <p className="text-slate-700 text-sm leading-relaxed">{step}</p>
                    </div>
                  ))}
                </div>
              </section>

              {selectedProcedure.contacts.length > 0 && (
                <section>
                  <h3 className="text-sm font-bold text-slate-900 uppercase tracking-wider mb-4 flex items-center gap-2">
                    <ShieldAlert size={16} className="text-red-500" />
                    Emergency Contacts
                  </h3>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    {selectedProcedure.contacts.map((contact, idx) => (
                      <div key={idx} className="p-3 border border-slate-200 rounded-lg flex items-center justify-between">
                        <div>
                          <p className="text-sm font-bold text-slate-900">{contact.name}</p>
                          <p className="text-xs text-slate-500">{contact.phone}</p>
                        </div>
                        <a 
                          href={`tel:${contact.phone}`}
                          className="p-2 bg-red-50 text-red-600 rounded-lg hover:bg-red-100 transition-colors"
                        >
                          Call
                        </a>
                      </div>
                    ))}
                  </div>
                </section>
              )}
            </div>
            
            <div className="p-4 bg-slate-50 border-t border-slate-100 text-center">
              <p className="text-[10px] text-slate-400 uppercase font-bold">
                Last Updated: {new Date(selectedProcedure.lastUpdated).toLocaleDateString()} • ISO 45001 Compliant
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Add Procedure Modal */}
      {isAdding && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-2xl max-h-[90vh] overflow-hidden flex flex-col">
            <div className="p-6 border-b border-slate-100 flex justify-between items-center">
              <h2 className="text-xl font-bold text-slate-900">New Response Procedure</h2>
              <button onClick={() => setIsAdding(false)} className="text-slate-400 hover:text-slate-600">
                <XCircle size={24} />
              </button>
            </div>
            
            <form onSubmit={handleAddProcedure} className="p-6 overflow-y-auto space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Procedure Title</label>
                  <input 
                    type="text" 
                    required
                    value={newTitle}
                    onChange={(e) => setNewTitle(e.target.value)}
                    placeholder="e.g., Major Chemical Spill"
                    className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Category</label>
                  <select 
                    value={newCategory}
                    onChange={(e) => setNewCategory(e.target.value as any)}
                    className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500"
                  >
                    <option value="Fire">Fire</option>
                    <option value="Medical">Medical</option>
                    <option value="Spill">Spill</option>
                    <option value="Security">Security</option>
                    <option value="Natural">Natural</option>
                    <option value="Other">Other</option>
                  </select>
                </div>
              </div>

              <div className="space-y-3">
                <label className="block text-sm font-medium text-slate-700">Response Steps</label>
                {newSteps.map((step, idx) => (
                  <div key={idx} className="flex gap-2">
                    <input 
                      type="text"
                      value={step}
                      onChange={(e) => {
                        const updated = [...newSteps];
                        updated[idx] = e.target.value;
                        setNewSteps(updated);
                      }}
                      placeholder={`Step ${idx + 1}`}
                      className="flex-1 p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500"
                    />
                    {newSteps.length > 1 && (
                      <button 
                        type="button"
                        onClick={() => setNewSteps(newSteps.filter((_, i) => i !== idx))}
                        className="p-2 text-red-500 hover:bg-red-50 rounded-lg"
                      >
                        <XCircle size={20} />
                      </button>
                    )}
                  </div>
                ))}
                <button 
                  type="button"
                  onClick={() => setNewSteps([...newSteps, ''])}
                  className="text-sm font-bold text-blue-600 hover:underline flex items-center gap-1"
                >
                  <Plus size={16} /> Add Step
                </button>
              </div>

              <div className="space-y-3">
                <label className="block text-sm font-medium text-slate-700">Emergency Contacts</label>
                {newContacts.map((contact, idx) => (
                  <div key={idx} className="flex gap-2">
                    <input 
                      type="text"
                      value={contact.name}
                      onChange={(e) => {
                        const updated = [...newContacts];
                        updated[idx].name = e.target.value;
                        setNewContacts(updated);
                      }}
                      placeholder="Name/Role"
                      className="flex-1 p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500"
                    />
                    <input 
                      type="text"
                      value={contact.phone}
                      onChange={(e) => {
                        const updated = [...newContacts];
                        updated[idx].phone = e.target.value;
                        setNewContacts(updated);
                      }}
                      placeholder="Phone"
                      className="flex-1 p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500"
                    />
                    {newContacts.length > 1 && (
                      <button 
                        type="button"
                        onClick={() => setNewContacts(newContacts.filter((_, i) => i !== idx))}
                        className="p-2 text-red-500 hover:bg-red-50 rounded-lg"
                      >
                        <XCircle size={20} />
                      </button>
                    )}
                  </div>
                ))}
                <button 
                  type="button"
                  onClick={() => setNewContacts([...newContacts, { name: '', phone: '' }])}
                  className="text-sm font-bold text-blue-600 hover:underline flex items-center gap-1"
                >
                  <Plus size={16} /> Add Contact
                </button>
              </div>

              <div className="pt-4 flex justify-end gap-3">
                <button 
                  type="button"
                  onClick={() => setIsAdding(false)}
                  className="px-6 py-2 text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
                >
                  Cancel
                </button>
                <button 
                  type="submit"
                  className="px-6 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors font-bold"
                >
                  Save Procedure
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
