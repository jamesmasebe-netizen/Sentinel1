import React, { useState, useEffect } from 'react';
import { collection, onSnapshot, query, addDoc, orderBy, doc, updateDoc } from 'firebase/firestore';
import { db, auth, handleFirestoreError } from '../lib/firebase';
import { 
  ClipboardList, 
  Target, 
  CheckCircle2, 
  AlertCircle, 
  Plus, 
  X, 
  FileText, 
  TrendingUp,
  Calendar,
  User
} from 'lucide-react';

interface CAPA {
  id: string;
  action: string;
  assignedTo: string;
  dueDate: string;
  status: 'Open' | 'Closed';
}

interface PIR {
  id: string;
  incidentTitle: string;
  date: string;
  summary: string;
  rootCause: string;
  lessonsLearned: string;
  capas: CAPA[];
  status: 'Draft' | 'Finalized';
  author: string;
  timestamp: string;
}

export default function PostIncidentReview() {
  const [reviews, setReviews] = useState<PIR[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  
  // Form State
  const [title, setTitle] = useState('');
  const [summary, setSummary] = useState('');
  const [rootCause, setRootCause] = useState('');
  const [lessons, setLessons] = useState('');
  const [newCapas, setNewCapas] = useState<{action: string, assignedTo: string, dueDate: string}[]>([]);

  useEffect(() => {
    const q = query(collection(db, 'incident_reviews'), orderBy('timestamp', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setReviews(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as PIR[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'incident_reviews'));

    return () => unsubscribe();
  }, []);

  const handleAddReview = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;

    try {
      await addDoc(collection(db, 'incident_reviews'), {
        incidentTitle: title,
        date: new Date().toISOString().split('T')[0],
        summary,
        rootCause,
        lessonsLearned: lessons,
        capas: newCapas.map(c => ({ ...c, id: Math.random().toString(36).substr(2, 9), status: 'Open' })),
        status: 'Finalized',
        author: auth.currentUser.email,
        timestamp: new Date().toISOString()
      });
      setIsAdding(false);
      setTitle('');
      setSummary('');
      setRootCause('');
      setLessons('');
      setNewCapas([]);
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'incident_reviews');
    }
  };

  const addCapaField = () => {
    setNewCapas([...newCapas, { action: '', assignedTo: '', dueDate: '' }]);
  };

  const toggleCapaStatus = async (reviewId: string, capaId: string) => {
    const review = reviews.find(r => r.id === reviewId);
    if (!review) return;

    const updatedCapas = review.capas.map(c => 
      c.id === capaId ? { ...c, status: c.status === 'Open' ? 'Closed' : 'Open' } : c
    );

    try {
      await updateDoc(doc(db, 'incident_reviews', reviewId), { capas: updatedCapas });
    } catch (error) {
      handleFirestoreError(error, 'update' as any, 'incident_reviews');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row justify-between items-center gap-4">
        <div className="flex items-center gap-3">
          <div className="bg-blue-50 p-2 rounded-lg text-blue-600">
            <ClipboardList size={24} />
          </div>
          <div>
            <h2 className="text-xl font-bold text-slate-900">Post-Incident Review (PIR) & CAPA</h2>
            <p className="text-sm text-slate-500">ISO 9001/45001 Corrective & Preventive Actions Hub</p>
          </div>
        </div>
        <button 
          onClick={() => setIsAdding(true)}
          className="w-full md:w-auto flex items-center justify-center gap-2 bg-blue-600 text-white px-6 py-3 rounded-xl font-bold hover:bg-blue-700 transition-all shadow-lg shadow-blue-200"
        >
          <Plus size={20} />
          New Incident Review
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Review List */}
        <div className="lg:col-span-2 space-y-6">
          {reviews.map(review => (
            <div key={review.id} className="bg-white border border-slate-200 rounded-2xl overflow-hidden shadow-sm hover:shadow-md transition-shadow">
              <div className="p-6 border-b border-slate-50 bg-slate-50/50">
                <div className="flex justify-between items-start mb-4">
                  <div>
                    <h3 className="text-lg font-bold text-slate-900">{review.incidentTitle}</h3>
                    <p className="text-xs text-slate-500 font-medium uppercase tracking-wider">
                      {new Date(review.date).toLocaleDateString()} • {review.author?.split('@')[0]}
                    </p>
                  </div>
                  <span className="bg-green-100 text-green-700 text-[10px] font-bold uppercase px-2 py-1 rounded">
                    {review.status}
                  </span>
                </div>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <h4 className="text-[10px] font-bold text-slate-400 uppercase mb-1">Root Cause</h4>
                    <p className="text-sm text-slate-700 leading-relaxed">{review.rootCause}</p>
                  </div>
                  <div>
                    <h4 className="text-[10px] font-bold text-slate-400 uppercase mb-1">Lessons Learned</h4>
                    <p className="text-sm text-slate-700 leading-relaxed">{review.lessonsLearned}</p>
                  </div>
                </div>
              </div>

              <div className="p-6">
                <h4 className="text-sm font-bold text-slate-900 mb-4 flex items-center gap-2">
                  <Target size={16} className="text-red-500" />
                  Corrective & Preventive Actions (CAPA)
                </h4>
                <div className="space-y-3">
                  {review.capas.map(capa => (
                    <div key={capa.id} className={`p-4 rounded-xl border flex items-center justify-between transition-all ${
                      capa.status === 'Closed' ? 'bg-slate-50 border-slate-100 opacity-60' : 'bg-white border-slate-200'
                    }`}>
                      <div className="flex items-center gap-4">
                        <button 
                          onClick={() => toggleCapaStatus(review.id, capa.id)}
                          className={`p-1 rounded-full transition-colors ${
                            capa.status === 'Closed' ? 'text-green-500' : 'text-slate-300 hover:text-green-500'
                          }`}
                        >
                          <CheckCircle2 size={24} />
                        </button>
                        <div>
                          <p className={`text-sm font-bold ${capa.status === 'Closed' ? 'text-slate-400 line-through' : 'text-slate-900'}`}>
                            {capa.action}
                          </p>
                          <p className="text-[10px] text-slate-500">
                            Assigned to: {capa.assignedTo} • Due: {new Date(capa.dueDate).toLocaleDateString()}
                          </p>
                        </div>
                      </div>
                      {capa.status === 'Open' && new Date(capa.dueDate) < new Date() && (
                        <span className="text-[10px] font-bold text-red-600 uppercase bg-red-50 px-2 py-1 rounded">Overdue</span>
                      )}
                    </div>
                  ))}
                  {review.capas.length === 0 && (
                    <p className="text-center py-4 text-xs text-slate-400 italic">No CAPAs assigned for this incident.</p>
                  )}
                </div>
              </div>
            </div>
          ))}
          {reviews.length === 0 && (
            <div className="text-center py-12 bg-slate-50 rounded-2xl border-2 border-dashed border-slate-200">
              <ClipboardList className="mx-auto text-slate-300 mb-3" size={40} />
              <p className="text-slate-500 font-medium">No incident reviews logged yet.</p>
            </div>
          )}
        </div>

        {/* Stats & Insights */}
        <div className="space-y-6">
          <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm">
            <h3 className="font-bold text-slate-900 mb-4 flex items-center gap-2">
              <TrendingUp size={18} className="text-blue-600" />
              CAPA Performance
            </h3>
            <div className="space-y-4">
              <div className="flex justify-between items-center">
                <span className="text-sm text-slate-500">Closure Rate</span>
                <span className="text-sm font-bold text-blue-600">
                  {Math.round((reviews.reduce((acc, r) => acc + r.capas.filter(c => c.status === 'Closed').length, 0) / 
                   Math.max(reviews.reduce((acc, r) => acc + r.capas.length, 0), 1)) * 100)}%
                </span>
              </div>
              <div className="w-full bg-slate-100 rounded-full h-2">
                <div 
                  className="bg-blue-600 h-2 rounded-full transition-all" 
                  style={{ width: `${(reviews.reduce((acc, r) => acc + r.capas.filter(c => c.status === 'Closed').length, 0) / 
                   Math.max(reviews.reduce((acc, r) => acc + r.capas.length, 0), 1)) * 100}%` }}
                ></div>
              </div>
              <div className="grid grid-cols-2 gap-4 pt-2">
                <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                  <p className="text-xl font-bold text-slate-900">
                    {reviews.reduce((acc, r) => acc + r.capas.filter(c => c.status === 'Open').length, 0)}
                  </p>
                  <p className="text-[10px] text-slate-500 uppercase font-bold tracking-wider">Open Actions</p>
                </div>
                <div className="bg-green-50 p-3 rounded-xl border border-green-100">
                  <p className="text-xl font-bold text-green-600">
                    {reviews.reduce((acc, r) => acc + r.capas.filter(c => c.status === 'Closed').length, 0)}
                  </p>
                  <p className="text-[10px] text-green-500 uppercase font-bold tracking-wider">Resolved</p>
                </div>
              </div>
            </div>
          </div>

          <div className="bg-slate-900 rounded-2xl p-6 text-white">
            <h3 className="font-bold mb-4 flex items-center gap-2 text-sm">
              <FileText size={18} className="text-blue-400" />
              Compliance Checklist
            </h3>
            <div className="space-y-3">
              <div className="flex items-center gap-3 text-xs text-slate-300">
                <CheckCircle2 size={14} className="text-green-500" />
                <span>Root Cause Analysis Performed</span>
              </div>
              <div className="flex items-center gap-3 text-xs text-slate-300">
                <CheckCircle2 size={14} className="text-green-500" />
                <span>Lessons Learned Communicated</span>
              </div>
              <div className="flex items-center gap-3 text-xs text-slate-300">
                <CheckCircle2 size={14} className="text-green-500" />
                <span>CAPA Timelines Enforced</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Add Review Modal */}
      {isAdding && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-2xl overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex justify-between items-center bg-slate-50">
              <h2 className="text-xl font-bold text-slate-900">New Post-Incident Review</h2>
              <button onClick={() => setIsAdding(false)} className="text-slate-400 hover:text-slate-600">
                <X size={24} />
              </button>
            </div>
            <form onSubmit={handleAddReview} className="p-6 space-y-6 max-h-[80vh] overflow-y-auto custom-scrollbar">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">Incident Title / Drill Name</label>
                    <input 
                      type="text" 
                      required
                      value={title}
                      onChange={(e) => setTitle(e.target.value)}
                      placeholder="e.g., Fire Drill - Workshop A"
                      className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">Incident Summary</label>
                    <textarea 
                      required
                      value={summary}
                      onChange={(e) => setSummary(e.target.value)}
                      rows={3}
                      className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                </div>
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">Root Cause Analysis</label>
                    <textarea 
                      required
                      value={rootCause}
                      onChange={(e) => setRootCause(e.target.value)}
                      rows={3}
                      className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">Lessons Learned</label>
                    <textarea 
                      required
                      value={lessons}
                      onChange={(e) => setLessons(e.target.value)}
                      rows={3}
                      className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                </div>
              </div>

              <div className="space-y-4 pt-4 border-t border-slate-100">
                <div className="flex justify-between items-center">
                  <h3 className="font-bold text-slate-900 flex items-center gap-2">
                    <Target size={18} className="text-red-500" />
                    Corrective Actions (CAPA)
                  </h3>
                  <button 
                    type="button"
                    onClick={addCapaField}
                    className="text-xs font-bold text-blue-600 hover:text-blue-800 flex items-center gap-1"
                  >
                    <Plus size={14} /> Add Action
                  </button>
                </div>
                
                {newCapas.map((capa, index) => (
                  <div key={index} className="grid grid-cols-1 md:grid-cols-3 gap-3 p-4 bg-slate-50 rounded-xl border border-slate-200">
                    <div className="md:col-span-1">
                      <label className="block text-[10px] font-bold text-slate-400 uppercase mb-1">Action</label>
                      <input 
                        type="text"
                        required
                        value={capa.action}
                        onChange={(e) => {
                          const updated = [...newCapas];
                          updated[index].action = e.target.value;
                          setNewCapas(updated);
                        }}
                        className="w-full p-2 border border-slate-300 rounded-lg text-sm"
                      />
                    </div>
                    <div>
                      <label className="block text-[10px] font-bold text-slate-400 uppercase mb-1">Assignee</label>
                      <input 
                        type="text"
                        required
                        value={capa.assignedTo}
                        onChange={(e) => {
                          const updated = [...newCapas];
                          updated[index].assignedTo = e.target.value;
                          setNewCapas(updated);
                        }}
                        className="w-full p-2 border border-slate-300 rounded-lg text-sm"
                      />
                    </div>
                    <div>
                      <label className="block text-[10px] font-bold text-slate-400 uppercase mb-1">Due Date</label>
                      <input 
                        type="date"
                        required
                        value={capa.dueDate}
                        onChange={(e) => {
                          const updated = [...newCapas];
                          updated[index].dueDate = e.target.value;
                          setNewCapas(updated);
                        }}
                        className="w-full p-2 border border-slate-300 rounded-lg text-sm"
                      />
                    </div>
                  </div>
                ))}
              </div>

              <div className="pt-4 flex justify-end gap-3">
                <button 
                  type="button"
                  onClick={() => setIsAdding(false)}
                  className="px-6 py-2.5 text-slate-600 hover:bg-slate-100 rounded-xl transition-colors font-bold"
                >
                  Cancel
                </button>
                <button 
                  type="submit"
                  className="px-6 py-2.5 bg-blue-600 text-white rounded-xl hover:bg-blue-700 transition-colors font-bold shadow-lg shadow-blue-200"
                >
                  Finalize Review
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      <style>{`
        .custom-scrollbar::-webkit-scrollbar {
          width: 4px;
        }
        .custom-scrollbar::-webkit-scrollbar-track {
          background: #f1f5f9;
        }
        .custom-scrollbar::-webkit-scrollbar-thumb {
          background: #cbd5e1;
          border-radius: 10px;
        }
      `}</style>
    </div>
  );
}
