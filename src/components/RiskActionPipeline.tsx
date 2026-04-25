import React, { useState, useEffect } from 'react';
import { collection, query, orderBy, onSnapshot, addDoc, doc, updateDoc, getDocs, where } from 'firebase/firestore';
import { db, handleFirestoreError, OperationType } from '../lib/firebase';
import { useAuth } from '../contexts/AuthContext';
import { 
  ShieldAlert, 
  ArrowRight, 
  CheckCircle2, 
  Clock, 
  AlertTriangle, 
  Brain, 
  Link as LinkIcon, 
  Plus, 
  Search,
  Activity,
  ChevronRight,
  Filter
} from 'lucide-react';
import { getGeminiClient } from '../lib/gemini';

interface Risk {
  id: string;
  title: string;
  category: string;
  inherentImpact: number;
  inherentLikelihood: number;
  residualImpact: number;
  residualLikelihood: number;
  status: string;
}

interface Action {
  id: string;
  title: string;
  type: 'Incident' | 'CAPA' | 'Observation' | 'Permit';
  status: string;
  date: string;
  riskId?: string;
}

export default function RiskActionPipeline() {
  const { user } = useAuth();
  const [risks, setRisks] = useState<Risk[]>([]);
  const [actions, setActions] = useState<Action[]>([]);
  const [selectedRisk, setSelectedRisk] = useState<Risk | null>(null);
  const [isLinking, setIsLinking] = useState(false);
  const [availableActions, setAvailableActions] = useState<Action[]>([]);
  const [loading, setLoading] = useState(true);
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [aiAnalysis, setAiAnalysis] = useState<string | null>(null);

  useEffect(() => {
    if (!user) return;

    // Fetch Risks
    const qRisks = query(collection(db, 'enterprise_risks'), orderBy('createdAt', 'desc'));
    const unsubRisks = onSnapshot(qRisks, (snapshot) => {
      setRisks(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as Risk[]);
      setLoading(false);
    }, (error) => handleFirestoreError(error, OperationType.LIST, 'enterprise_risks'));

    // Fetch Actions (Consolidated from different collections)
    const fetchActions = async () => {
      const collections = [
        { name: 'incidents', type: 'Incident' },
        { name: 'capa', type: 'CAPA' },
        { name: 'observations', type: 'Observation' },
        { name: 'permits', type: 'Permit' }
      ];

      const allActions: Action[] = [];
      for (const coll of collections) {
        const q = query(collection(db, coll.name));
        const snap = await getDocs(q);
        snap.forEach(doc => {
          const data = doc.data();
          allActions.push({
            id: doc.id,
            title: data.title || data.description || data.type || 'Untitled',
            type: coll.type as any,
            status: data.status || 'Open',
            date: data.date || data.createdAt || new Date().toISOString(),
            riskId: data.riskId
          });
        });
      }
      setActions(allActions);
    };

    fetchActions();
    return () => unsubRisks();
  }, [user]);

  const handleLinkAction = async (actionId: string, actionType: string) => {
    if (!selectedRisk) return;

    try {
      const collectionName = actionType.toLowerCase() === 'capa' ? 'capa' : actionType.toLowerCase() + 's';
      const actionDocRef = doc(db, collectionName, actionId);
      await updateDoc(actionDocRef, { riskId: selectedRisk.id });
      
      // Update local state
      setActions(prev => prev.map(a => a.id === actionId ? { ...a, riskId: selectedRisk.id } : a));
      setIsLinking(false);
    } catch (error) {
      handleFirestoreError(error, OperationType.UPDATE, 'actions');
    }
  };

  const handleAiAnalysis = async () => {
    if (!selectedRisk) return;
    setIsAnalyzing(true);
    setAiAnalysis(null);

    try {
      const linkedActions = actions.filter(a => a.riskId === selectedRisk.id);
      const actionsText = linkedActions.map(a => `- [${a.type}] ${a.title} (${a.status})`).join('\n');

      const prompt = `You are a Senior Risk & Safety Auditor. Analyze the alignment between a strategic risk and its linked operational actions.

Risk: ${selectedRisk.title}
Category: ${selectedRisk.category}
Residual Risk Score: ${selectedRisk.residualImpact * selectedRisk.residualLikelihood}

Linked Actions:
${actionsText || 'No actions linked yet.'}

Provide a brief, high-level analysis (max 150 words) covering:
1. Effectiveness: Are these actions sufficient to mitigate the risk?
2. Gaps: What types of actions are missing?
3. Recommendation: One specific next step to strengthen the pipeline.`;

      const ai = getGeminiClient();
      const result = await ai.models.generateContent({
        model: 'gemini-3-flash-preview',
        contents: prompt,
      });
      setAiAnalysis(result.text || "No assessment generated.");
    } catch (error) {
      console.error("AI Analysis Error:", error);
      setAiAnalysis("Failed to generate analysis. Please try again.");
    } finally {
      setIsAnalyzing(false);
    }
  };

  const getRiskLevel = (impact: number, likelihood: number) => {
    const score = impact * likelihood;
    if (score >= 15) return { label: 'Critical', color: 'text-red-600 bg-red-50 border-red-100' };
    if (score >= 10) return { label: 'High', color: 'text-orange-600 bg-orange-50 border-orange-100' };
    if (score >= 5) return { label: 'Medium', color: 'text-amber-600 bg-amber-50 border-amber-100' };
    return { label: 'Low', color: 'text-emerald-600 bg-emerald-50 border-emerald-100' };
  };

  return (
    <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 p-6">
      {/* Risk List */}
      <div className="lg:col-span-4 space-y-4">
        <div className="flex items-center justify-between mb-2">
          <h3 className="font-bold text-slate-900 flex items-center gap-2">
            <ShieldAlert size={20} className="text-blue-600" /> Strategic Risks
          </h3>
          <span className="text-xs text-slate-500 font-medium">{risks.length} Total</span>
        </div>
        
        <div className="space-y-3 max-h-[600px] overflow-y-auto pr-2 custom-scrollbar">
          {risks.map(risk => {
            const riskLevel = getRiskLevel(risk.residualImpact, risk.residualLikelihood);
            const linkedCount = actions.filter(a => a.riskId === risk.id).length;
            
            return (
              <button
                key={risk.id}
                onClick={() => { setSelectedRisk(risk); setAiAnalysis(null); }}
                className={`w-full text-left p-4 rounded-xl border transition-all ${
                  selectedRisk?.id === risk.id 
                    ? 'border-blue-600 bg-blue-50/50 shadow-sm ring-1 ring-blue-600' 
                    : 'border-slate-200 bg-white hover:border-slate-300 hover:shadow-sm'
                }`}
              >
                <div className="flex justify-between items-start mb-2">
                  <span className={`text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 rounded border ${riskLevel.color}`}>
                    {riskLevel.label}
                  </span>
                  <span className="text-[10px] font-medium text-slate-400">{risk.category}</span>
                </div>
                <h4 className="font-bold text-slate-900 text-sm mb-3 line-clamp-2">{risk.title}</h4>
                <div className="flex items-center justify-between text-xs">
                  <div className="flex items-center gap-1 text-slate-500">
                    <LinkIcon size={12} />
                    <span>{linkedCount} Actions</span>
                  </div>
                  <ChevronRight size={16} className={selectedRisk?.id === risk.id ? 'text-blue-600' : 'text-slate-300'} />
                </div>
              </button>
            );
          })}
        </div>
      </div>

      {/* Pipeline View */}
      <div className="lg:col-span-8 space-y-6">
        {selectedRisk ? (
          <div className="space-y-6 animate-in fade-in slide-in-from-right-4 duration-300">
            {/* Selected Risk Header */}
            <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
              <div className="flex justify-between items-start mb-4">
                <div>
                  <h2 className="text-xl font-bold text-slate-900 mb-1">{selectedRisk.title}</h2>
                  <p className="text-sm text-slate-500">Risk-to-Action Pipeline Analysis</p>
                </div>
                <div className="text-right">
                  <div className="text-2xl font-black text-slate-900">
                    {selectedRisk.residualImpact * selectedRisk.residualLikelihood}
                  </div>
                  <div className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Residual Score</div>
                </div>
              </div>

              {/* AI Analysis Section */}
              <div className="bg-slate-900 rounded-xl p-5 text-slate-100 relative overflow-hidden">
                <div className="absolute top-0 right-0 p-4 opacity-10">
                  <Brain size={80} />
                </div>
                <div className="relative z-10">
                  <div className="flex items-center justify-between mb-4">
                    <h3 className="text-sm font-bold flex items-center gap-2 text-blue-400">
                      <Brain size={18} /> AI Pipeline Intelligence
                    </h3>
                    {!aiAnalysis && (
                      <button
                        onClick={handleAiAnalysis}
                        disabled={isAnalyzing}
                        className="text-xs bg-blue-600 hover:bg-blue-700 text-white px-3 py-1.5 rounded-lg font-bold transition-colors flex items-center gap-2"
                      >
                        {isAnalyzing ? <Activity size={14} className="animate-spin" /> : <Activity size={14} />}
                        Analyze Pipeline
                      </button>
                    )}
                  </div>
                  
                  {aiAnalysis ? (
                    <div className="text-sm text-slate-300 leading-relaxed italic">
                      {aiAnalysis}
                      <button 
                        onClick={() => setAiAnalysis(null)}
                        className="block mt-3 text-xs text-blue-400 hover:text-blue-300 font-bold"
                      >
                        Refresh Analysis
                      </button>
                    </div>
                  ) : (
                    <p className="text-sm text-slate-400">
                      Click 'Analyze Pipeline' to get AI-powered insights on how well your operational actions are mitigating this strategic risk.
                    </p>
                  )}
                </div>
              </div>
            </div>

            {/* Linked Actions */}
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <h3 className="font-bold text-slate-900 flex items-center gap-2">
                  <ArrowRight size={20} className="text-emerald-600" /> Mitigation Pipeline
                </h3>
                <button
                  onClick={() => setIsLinking(true)}
                  className="text-xs bg-emerald-50 text-emerald-700 px-3 py-1.5 rounded-lg font-bold hover:bg-emerald-100 transition-colors flex items-center gap-1"
                >
                  <Plus size={14} /> Link Action
                </button>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {actions.filter(a => a.riskId === selectedRisk.id).length > 0 ? (
                  actions.filter(a => a.riskId === selectedRisk.id).map(action => (
                    <div key={action.id} className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm flex gap-4">
                      <div className={`w-10 h-10 rounded-lg flex items-center justify-center shrink-0 ${
                        action.type === 'Incident' ? 'bg-red-100 text-red-600' :
                        action.type === 'CAPA' ? 'bg-blue-100 text-blue-600' :
                        action.type === 'Observation' ? 'bg-amber-100 text-amber-600' :
                        'bg-emerald-100 text-emerald-600'
                      }`}>
                        {action.type === 'Incident' ? <AlertTriangle size={20} /> :
                         action.type === 'CAPA' ? <CheckCircle2 size={20} /> :
                         action.type === 'Observation' ? <Search size={20} /> :
                         <ShieldAlert size={20} />}
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex justify-between items-start mb-1">
                          <span className="text-[10px] font-bold text-slate-400 uppercase">{action.type}</span>
                          <span className={`text-[10px] font-bold px-1.5 py-0.5 rounded ${
                            action.status === 'Closed' ? 'bg-emerald-100 text-emerald-700' : 'bg-blue-100 text-blue-700'
                          }`}>
                            {action.status}
                          </span>
                        </div>
                        <h4 className="font-bold text-slate-900 text-sm truncate">{action.title}</h4>
                        <p className="text-[10px] text-slate-400 mt-1">{new Date(action.date).toLocaleDateString()}</p>
                      </div>
                    </div>
                  ))
                ) : (
                  <div className="col-span-full py-12 text-center bg-slate-50 rounded-2xl border-2 border-dashed border-slate-200">
                    <LinkIcon size={32} className="mx-auto text-slate-300 mb-3" />
                    <p className="text-sm text-slate-500">No operational actions linked to this risk yet.</p>
                    <button 
                      onClick={() => setIsLinking(true)}
                      className="mt-4 text-sm text-blue-600 font-bold hover:text-blue-700"
                    >
                      Link your first action
                    </button>
                  </div>
                )}
              </div>
            </div>
          </div>
        ) : (
          <div className="h-full flex flex-col items-center justify-center text-center py-20 bg-slate-50 rounded-3xl border-2 border-dashed border-slate-200">
            <div className="w-20 h-20 bg-white rounded-full flex items-center justify-center shadow-sm mb-6 text-slate-300">
              <ShieldAlert size={40} />
            </div>
            <h3 className="text-xl font-bold text-slate-900 mb-2">Select a Risk to View Pipeline</h3>
            <p className="text-slate-500 max-w-xs mx-auto">
              Connect your high-level strategic risks with ground-level operational actions to ensure full mitigation coverage.
            </p>
          </div>
        )}
      </div>

      {/* Link Action Modal */}
      {isLinking && (
        <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-2xl max-w-2xl w-full max-h-[80vh] overflow-hidden flex flex-col">
            <div className="p-6 border-b border-slate-100 flex justify-between items-center">
              <div>
                <h3 className="text-lg font-bold text-slate-900">Link Action to Risk</h3>
                <p className="text-xs text-slate-500">Select an unlinked operational record to associate with this risk.</p>
              </div>
              <button 
                onClick={() => setIsLinking(false)}
                className="text-slate-400 hover:text-slate-600 transition-colors"
              >
                <Plus size={24} className="rotate-45" />
              </button>
            </div>
            
            <div className="p-6 overflow-y-auto flex-1 space-y-3">
              {actions.filter(a => !a.riskId).length > 0 ? (
                actions.filter(a => !a.riskId).map(action => (
                  <button
                    key={action.id}
                    onClick={() => handleLinkAction(action.id, action.type)}
                    className="w-full text-left p-4 rounded-xl border border-slate-200 hover:border-blue-600 hover:bg-blue-50 transition-all flex items-center justify-between group"
                  >
                    <div className="flex items-center gap-4">
                      <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${
                        action.type === 'Incident' ? 'bg-red-100 text-red-600' :
                        action.type === 'CAPA' ? 'bg-blue-100 text-blue-600' :
                        action.type === 'Observation' ? 'bg-amber-100 text-amber-600' :
                        'bg-emerald-100 text-emerald-600'
                      }`}>
                        {action.type === 'Incident' ? <AlertTriangle size={18} /> :
                         action.type === 'CAPA' ? <CheckCircle2 size={18} /> :
                         action.type === 'Observation' ? <Search size={18} /> :
                         <ShieldAlert size={18} />}
                      </div>
                      <div>
                        <span className="text-[10px] font-bold text-slate-400 uppercase">{action.type}</span>
                        <h4 className="font-bold text-slate-900 text-sm">{action.title}</h4>
                      </div>
                    </div>
                    <LinkIcon size={18} className="text-slate-300 group-hover:text-blue-600 transition-colors" />
                  </button>
                ))
              ) : (
                <div className="text-center py-12">
                  <p className="text-slate-500 italic">No unlinked actions found.</p>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
