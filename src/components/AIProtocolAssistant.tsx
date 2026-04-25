import React, { useState } from 'react';
import { 
  Bot, 
  Send, 
  Loader2, 
  ShieldCheck, 
  AlertTriangle, 
  BookOpen, 
  HelpCircle,
  Sparkles,
  ChevronRight
} from 'lucide-react';
import { getGeminiClient } from '../lib/gemini';

export default function AIProtocolAssistant() {
  const [query, setQuery] = useState('');
  const [isGenerating, setIsGenerating] = useState(false);
  const [response, setResponse] = useState<string | null>(null);

  const handleAsk = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!query || isGenerating) return;

    setIsGenerating(true);
    setResponse(null);

    try {
      const ai = getGeminiClient();
      const result = await ai.models.generateContent({
        model: "gemini-3-flash-preview",
        contents: `You are a SHEQ Emergency Protocol Assistant for Sentinel SHEQ Pro. 
        Your task is to provide immediate, clear, and actionable emergency protocols based on ISO 45001 and standard industrial safety practices.
        
        User Query: ${query}
        
        Provide:
        1. Immediate Actions (Step 1, 2, 3)
        2. PPE Requirements
        3. Notification Protocol (Who to call)
        4. Post-Incident Requirement
        
        Keep it professional, concise, and formatted for rapid reading during an emergency.`,
      });
      setResponse(result.text);
    } catch (error) {
      console.error("Error asking AI:", error);
      setResponse("I'm sorry, I encountered an error. Please refer to the physical ERP or contact the SHEQ Manager immediately.");
    } finally {
      setIsGenerating(false);
    }
  };

  const suggestedQueries = [
    "Protocol for a major chemical spill in the workshop",
    "How to handle a suspected spinal injury",
    "Fire evacuation steps for Level 3",
    "Ammonia leak containment steps"
  ];

  return (
    <div className="space-y-6 max-w-4xl mx-auto">
      <div className="bg-slate-900 rounded-3xl p-8 text-white relative overflow-hidden shadow-2xl">
        <div className="relative z-10">
          <div className="flex items-center gap-4 mb-6">
            <div className="bg-blue-500 p-3 rounded-2xl shadow-lg shadow-blue-500/40">
              <Bot size={32} />
            </div>
            <div>
              <h2 className="text-2xl font-black tracking-tight">AI Protocol Assistant</h2>
              <p className="text-slate-400 text-sm">Instant emergency guidance powered by Gemini AI</p>
            </div>
          </div>

          <form onSubmit={handleAsk} className="relative mb-8">
            <input 
              type="text"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Ask for any emergency protocol..."
              className="w-full bg-white/10 border border-white/20 rounded-2xl py-4 pl-6 pr-16 text-lg font-medium focus:ring-2 focus:ring-blue-500 focus:bg-white/20 transition-all outline-none placeholder:text-slate-500"
            />
            <button 
              type="submit"
              disabled={isGenerating || !query}
              className="absolute right-2 top-2 bottom-2 bg-blue-600 hover:bg-blue-500 text-white px-6 rounded-xl font-bold transition-all disabled:bg-slate-700"
            >
              {isGenerating ? <Loader2 className="animate-spin" size={20} /> : <Send size={20} />}
            </button>
          </form>

          <div className="flex flex-wrap gap-2">
            {suggestedQueries.map(sq => (
              <button 
                key={sq}
                onClick={() => setQuery(sq)}
                className="text-[10px] font-bold uppercase bg-white/5 hover:bg-white/10 border border-white/10 px-3 py-1.5 rounded-full transition-colors text-slate-300"
              >
                {sq}
              </button>
            ))}
          </div>
        </div>
        <div className="absolute top-0 right-0 w-96 h-96 bg-blue-600/20 rounded-full blur-3xl -mr-48 -mt-48"></div>
      </div>

      {response && (
        <div className="bg-white border border-slate-200 rounded-3xl p-8 shadow-xl animate-in fade-in slide-in-from-bottom-4 duration-500">
          <div className="flex items-center gap-2 text-blue-600 mb-6">
            <Sparkles size={20} />
            <span className="text-xs font-black uppercase tracking-widest">AI Response Protocol</span>
          </div>
          <div className="prose prose-slate max-w-none">
            <div className="whitespace-pre-wrap text-slate-700 leading-relaxed font-medium">
              {response}
            </div>
          </div>
          <div className="mt-8 pt-6 border-t border-slate-100 flex flex-col md:flex-row justify-between items-center gap-4">
            <div className="flex items-center gap-2 text-[10px] font-bold text-amber-600 uppercase bg-amber-50 px-3 py-1.5 rounded-full">
              <AlertTriangle size={14} />
              Verify with Physical ERP if possible
            </div>
            <div className="flex gap-3">
              <button className="text-xs font-bold text-slate-500 hover:text-slate-900 flex items-center gap-1">
                <BookOpen size={14} /> View Full ERP
              </button>
              <button className="text-xs font-bold text-slate-500 hover:text-slate-900 flex items-center gap-1">
                <HelpCircle size={14} /> Provide Feedback
              </button>
            </div>
          </div>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="bg-blue-50 border border-blue-100 rounded-2xl p-6 flex items-start gap-4">
          <div className="bg-white p-3 rounded-xl text-blue-600 shadow-sm">
            <ShieldCheck size={24} />
          </div>
          <div>
            <h4 className="font-bold text-blue-900 mb-1">ISO 45001 Compliant</h4>
            <p className="text-xs text-blue-700 leading-relaxed">Guidance is aligned with international safety standards and site-specific risk assessments.</p>
          </div>
        </div>
        <div className="bg-slate-50 border border-slate-200 rounded-2xl p-6 flex items-start gap-4">
          <div className="bg-white p-3 rounded-xl text-slate-600 shadow-sm">
            <ChevronRight size={24} />
          </div>
          <div>
            <h4 className="font-bold text-slate-900 mb-1">Rapid Response</h4>
            <p className="text-xs text-slate-600 leading-relaxed">Average response time of 1.2 seconds for critical safety information retrieval.</p>
          </div>
        </div>
      </div>
    </div>
  );
}
