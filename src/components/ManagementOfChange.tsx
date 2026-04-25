import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy, doc, updateDoc } from 'firebase/firestore';
import { db, auth, handleFirestoreError } from '../lib/firebase';
import { Plus, X, Brain, Loader2 } from 'lucide-react';
import { getGeminiClient } from '../lib/gemini';

interface ManagementOfChange {
  id: string;
  title: string;
  description: string;
  changeType: 'Process' | 'Equipment' | 'Personnel' | 'Facility' | 'Document';
  status: 'Draft' | 'Review' | 'Approved' | 'Implemented' | 'Closed';
  targetDate: string;
  aiImpactAssessment?: string;
  authorId: string;
  authorName: string;
  createdAt: string;
}

export default function ManagementOfChange() {
  const [mocs, setMocs] = useState<ManagementOfChange[]>([]);
  const [isAddingMoC, setIsAddingMoC] = useState(false);
  const [viewingMoC, setViewingMoC] = useState<ManagementOfChange | null>(null);

  const [mocTitle, setMocTitle] = useState('');
  const [mocDesc, setMocDesc] = useState('');
  const [mocType, setMocType] = useState<ManagementOfChange['changeType']>('Equipment');
  const [mocTargetDate, setMocTargetDate] = useState('');
  const [aiLoading, setAiLoading] = useState(false);
  const [aiImpact, setAiImpact] = useState('');

  useEffect(() => {
    if (!auth.currentUser) return;
    const qMocs = query(collection(db, 'mocs'), orderBy('createdAt', 'desc'));
    const unsubMocs = onSnapshot(qMocs, (snapshot) => {
      setMocs(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as ManagementOfChange[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'mocs'));

    return () => unsubMocs();
  }, []);

  const handleAddMoC = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      await addDoc(collection(db, 'mocs'), {
        title: mocTitle,
        description: mocDesc,
        changeType: mocType,
        status: 'Draft',
        targetDate: new Date(mocTargetDate).toISOString(),
        aiImpactAssessment: aiImpact,
        authorId: auth.currentUser.uid,
        authorName: auth.currentUser.displayName || 'Unknown',
        createdAt: new Date().toISOString()
      });
      setIsAddingMoC(false);
      setMocTitle(''); setMocDesc(''); setMocType('Equipment'); setMocTargetDate(''); setAiImpact('');
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'mocs');
    }
  };

  const analyzeImpact = async () => {
    if (!mocTitle || !mocDesc) return;
    setAiLoading(true);
    try {
      const ai = getGeminiClient();
      const prompt = `As a SHEQ (Safety, Health, Environment, Quality) expert, analyze the following proposed change and identify 3 potential risks and 3 mitigation strategies:
      Title: ${mocTitle}
      Description: ${mocDesc}
      Type: ${mocType}
      Format the response as a concise summary.`;
      
      const result = await ai.models.generateContent({
        model: 'gemini-3-flash-preview',
        contents: prompt,
      });
      setAiImpact(result.text || "No assessment generated.");
    } catch (error) {
      console.error("AI Impact Analysis failed:", error);
      setAiImpact("Failed to generate AI impact assessment. Please try again.");
    }
    setAiLoading(false);
  };

  const updateMoCStatus = async (id: string, status: ManagementOfChange['status']) => {
    try {
      await updateDoc(doc(db, 'mocs', id), { status });
    } catch (error) {
      handleFirestoreError(error, 'update' as any, 'mocs');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h2 className="text-lg font-bold text-slate-900">Management of Change (MoC)</h2>
        <button
          onClick={() => setIsAddingMoC(true)}
          className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 flex items-center gap-2 transition-colors shadow-sm"
        >
          <Plus size={20} /> Initiate MoC
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {mocs.length === 0 ? (
          <div className="col-span-full p-8 text-center text-slate-500 bg-slate-50 rounded-xl border border-slate-200 border-dashed">
            No active MoC requests.
          </div>
        ) : (
          mocs.map((moc) => (
            <div key={moc.id} className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm hover:shadow-md transition-shadow">
              <div className="flex justify-between items-start mb-3">
                <span className="px-2.5 py-1 bg-slate-100 text-slate-600 text-xs font-bold rounded-md uppercase tracking-wider">
                  {moc.changeType}
                </span>
                <select
                  value={moc.status}
                  onChange={(e) => updateMoCStatus(moc.id, e.target.value as any)}
                  className={`text-xs font-bold rounded-md border-0 py-1 pl-2 pr-6 ${
                    moc.status === 'Draft' ? 'bg-slate-100 text-slate-700' :
                    moc.status === 'Review' ? 'bg-amber-100 text-amber-700' :
                    moc.status === 'Approved' ? 'bg-blue-100 text-blue-700' :
                    moc.status === 'Implemented' ? 'bg-emerald-100 text-emerald-700' :
                    'bg-slate-100 text-slate-500'
                  }`}
                >
                  <option value="Draft">Draft</option>
                  <option value="Review">Review</option>
                  <option value="Approved">Approved</option>
                  <option value="Implemented">Implemented</option>
                  <option value="Closed">Closed</option>
                </select>
              </div>
              <h3 className="font-bold text-slate-900 mb-2 line-clamp-2">{moc.title}</h3>
              <p className="text-sm text-slate-500 mb-4 line-clamp-3">{moc.description}</p>
              
              <div className="flex justify-between items-center pt-4 border-t border-slate-100">
                <div className="text-xs text-slate-500">
                  Target: <span className="font-medium text-slate-700">{new Date(moc.targetDate).toLocaleDateString()}</span>
                </div>
                <button 
                  onClick={() => setViewingMoC(moc)}
                  className="text-blue-600 text-sm font-medium hover:text-blue-800"
                >
                  View Details
                </button>
              </div>
            </div>
          ))
        )}
      </div>

      {/* Add MoC Modal */}
      {isAddingMoC && (
        <div className="fixed inset-0 bg-slate-900/50 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-2xl overflow-hidden max-h-[90vh] flex flex-col">
            <div className="p-6 border-b border-slate-200 flex justify-between items-center bg-slate-50 shrink-0">
              <h2 className="text-xl font-bold text-slate-900">Initiate Management of Change</h2>
              <button onClick={() => setIsAddingMoC(false)} className="text-slate-400 hover:text-slate-600">
                <X size={24} />
              </button>
            </div>
            <div className="p-6 overflow-y-auto">
              <form id="moc-form" onSubmit={handleAddMoC} className="space-y-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div className="md:col-span-2">
                    <label className="block text-sm font-medium text-slate-700 mb-1">Change Title</label>
                    <input type="text" required value={mocTitle} onChange={e => setMocTitle(e.target.value)} className="w-full p-2.5 border border-slate-300 rounded-lg" />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">Change Type</label>
                    <select value={mocType} onChange={e => setMocType(e.target.value as any)} className="w-full p-2.5 border border-slate-300 rounded-lg">
                      <option value="Process">Process</option>
                      <option value="Equipment">Equipment</option>
                      <option value="Personnel">Personnel</option>
                      <option value="Facility">Facility</option>
                      <option value="Document">Document</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">Target Implementation Date</label>
                    <input type="date" required value={mocTargetDate} onChange={e => setMocTargetDate(e.target.value)} className="w-full p-2.5 border border-slate-300 rounded-lg" />
                  </div>
                  <div className="md:col-span-2">
                    <label className="block text-sm font-medium text-slate-700 mb-1">Detailed Description</label>
                    <textarea required value={mocDesc} onChange={e => setMocDesc(e.target.value)} className="w-full p-2.5 border border-slate-300 rounded-lg" rows={4}></textarea>
                  </div>
                </div>

                <div className="bg-blue-50 p-4 rounded-lg border border-blue-100">
                  <div className="flex justify-between items-center mb-3">
                    <h3 className="font-bold text-blue-900 flex items-center gap-2">
                      <Brain size={18} /> AI Impact Assessment
                    </h3>
                    <button
                      type="button"
                      onClick={analyzeImpact}
                      disabled={aiLoading || !mocTitle || !mocDesc}
                      className="bg-blue-600 text-white px-3 py-1.5 rounded-md text-sm font-medium hover:bg-blue-700 disabled:opacity-50 flex items-center gap-2"
                    >
                      {aiLoading ? <Loader2 size={16} className="animate-spin" /> : 'Analyze Risk'}
                    </button>
                  </div>
                  {aiImpact ? (
                    <div className="text-sm text-blue-800 whitespace-pre-wrap bg-white p-3 rounded border border-blue-200">
                      {aiImpact}
                    </div>
                  ) : (
                    <p className="text-sm text-blue-600/70">Fill in the title and description, then click analyze to generate an AI risk assessment.</p>
                  )}
                </div>
              </form>
            </div>
            <div className="p-6 border-t border-slate-200 bg-slate-50 flex justify-end gap-3 shrink-0">
              <button type="button" onClick={() => setIsAddingMoC(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg font-medium">Cancel</button>
              <button type="submit" form="moc-form" className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 font-medium">Submit MoC</button>
            </div>
          </div>
        </div>
      )}

      {/* View MoC Modal */}
      {viewingMoC && (
        <div className="fixed inset-0 bg-slate-900/50 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-2xl overflow-hidden max-h-[90vh] flex flex-col">
            <div className="p-6 border-b border-slate-200 flex justify-between items-center bg-slate-50 shrink-0">
              <h2 className="text-xl font-bold text-slate-900">MoC Details</h2>
              <button onClick={() => setViewingMoC(null)} className="text-slate-400 hover:text-slate-600">
                <X size={24} />
              </button>
            </div>
            <div className="p-6 overflow-y-auto space-y-6">
              <div>
                <div className="flex items-center gap-3 mb-2">
                  <span className="px-2.5 py-1 bg-slate-100 text-slate-600 text-xs font-bold rounded-md uppercase tracking-wider">
                    {viewingMoC.changeType}
                  </span>
                  <span className="px-2.5 py-1 bg-blue-100 text-blue-700 text-xs font-bold rounded-md uppercase tracking-wider">
                    {viewingMoC.status}
                  </span>
                </div>
                <h3 className="text-2xl font-bold text-slate-900">{viewingMoC.title}</h3>
                <p className="text-sm text-slate-500 mt-1">Initiated by {viewingMoC.authorName} on {new Date(viewingMoC.createdAt).toLocaleDateString()}</p>
              </div>
              
              <div>
                <h4 className="font-bold text-slate-900 mb-2">Description</h4>
                <p className="text-slate-700 whitespace-pre-wrap bg-slate-50 p-4 rounded-lg border border-slate-100">{viewingMoC.description}</p>
              </div>

              {viewingMoC.aiImpactAssessment && (
                <div>
                  <h4 className="font-bold text-slate-900 mb-2 flex items-center gap-2">
                    <Brain size={18} className="text-purple-600" /> AI Impact Assessment
                  </h4>
                  <div className="text-slate-700 whitespace-pre-wrap bg-purple-50 p-4 rounded-lg border border-purple-100 text-sm">
                    {viewingMoC.aiImpactAssessment}
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
