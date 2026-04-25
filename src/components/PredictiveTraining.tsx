import React, { useState } from 'react';
import { Sparkles, Loader2, TrendingUp, AlertCircle, Target } from 'lucide-react';
import { getGeminiClient } from '../lib/gemini';

interface TrainingRecord {
  id: string;
  courseName: string;
  status: 'Active' | 'Expired';
}

interface Props {
  records: TrainingRecord[];
}

interface Forecast {
  period: string;
  recommendations: {
    skill: string;
    reasoning: string;
    impact: 'High' | 'Medium' | 'Low';
  }[];
  riskAssessment: string;
}

export default function PredictiveTraining({ records }: Props) {
  const [outlook, setOutlook] = useState('');
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [forecast, setForecast] = useState<Forecast | null>(null);

  const generateForecast = async () => {
    setIsAnalyzing(true);
    try {
      const ai = getGeminiClient();
      const currentSkills = Array.from(new Set(records.map(r => r.courseName))).join(', ');
      
      const prompt = `As a strategic safety consultant, perform a Predictive Training Needs Analysis.
      Current Workforce Skills: [${currentSkills}].
      Future Business Outlook: "${outlook || 'Standard operations and maintenance'}".
      
      Predict the training needs for the next 12 months. Consider emerging safety trends, potential skill gaps for the described outlook, and proactive risk mitigation.
      
      Return the response as a JSON object:
      {
        "period": "Next 12 Months",
        "recommendations": [
          {"skill": "...", "reasoning": "...", "impact": "High|Medium|Low"}
        ],
        "riskAssessment": "A brief summary of the safety risks if these training needs are not met."
      }`;

      const response = await ai.models.generateContent({
        model: "gemini-3-flash-preview",
        contents: prompt,
        config: { responseMimeType: "application/json" }
      });

      const result = JSON.parse(response.text!);
      setForecast(result);
    } catch (error) {
      console.error("Failed to generate forecast:", error);
    } finally {
      setIsAnalyzing(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="bg-slate-900 rounded-xl p-8 text-white relative overflow-hidden shadow-xl">
        <div className="relative z-10">
          <div className="flex items-center gap-3 mb-4">
            <TrendingUp className="text-blue-400" size={28} />
            <h2 className="text-xl font-bold">Predictive Training Analysis</h2>
          </div>
          <p className="text-slate-400 mb-8 max-w-2xl">
            Leverage AI to forecast future competency requirements based on your business outlook and current workforce capabilities.
          </p>
          
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-slate-400 mb-2">Future Project / Business Outlook</label>
              <textarea 
                value={outlook}
                onChange={(e) => setOutlook(e.target.value)}
                placeholder="e.g., Starting a new offshore wind farm project, expanding into chemical processing, or general maintenance cycle..."
                className="w-full p-4 rounded-xl bg-white/5 border border-white/10 text-white placeholder:text-slate-600 focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all"
                rows={3}
              />
            </div>
            <button 
              onClick={generateForecast}
              disabled={isAnalyzing}
              className="bg-blue-600 text-white px-8 py-3 rounded-xl font-bold hover:bg-blue-500 transition-all disabled:bg-slate-700 flex items-center gap-2 shadow-lg shadow-blue-900/20"
            >
              {isAnalyzing ? <Loader2 className="animate-spin" size={20} /> : <Sparkles size={20} />}
              Run Predictive Analysis
            </button>
          </div>
        </div>
        
        {/* Decorative background element */}
        <div className="absolute top-0 right-0 w-64 h-64 bg-blue-600/10 rounded-full blur-3xl -mr-32 -mt-32"></div>
      </div>

      {forecast && (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2 space-y-4">
            <h3 className="font-bold text-slate-900 flex items-center gap-2">
              <Target size={20} className="text-blue-600" />
              Forecasted Training Priorities
            </h3>
            <div className="grid grid-cols-1 gap-4">
              {forecast.recommendations.map((rec, idx) => (
                <div key={idx} className="bg-white border border-slate-200 rounded-xl p-5 hover:border-blue-300 transition-all shadow-sm">
                  <div className="flex items-center justify-between mb-2">
                    <h4 className="font-bold text-slate-900">{rec.skill}</h4>
                    <span className={`text-[10px] font-bold px-2 py-1 rounded-full uppercase ${
                      rec.impact === 'High' ? 'bg-red-100 text-red-700' : 
                      rec.impact === 'Medium' ? 'bg-amber-100 text-amber-700' : 
                      'bg-blue-100 text-blue-700'
                    }`}>
                      {rec.impact} Impact
                    </span>
                  </div>
                  <p className="text-sm text-slate-600 leading-relaxed">{rec.reasoning}</p>
                </div>
              ))}
            </div>
          </div>

          <div className="lg:col-span-1 space-y-4">
            <h3 className="font-bold text-slate-900 flex items-center gap-2">
              <AlertCircle size={20} className="text-red-600" />
              Strategic Risk Assessment
            </h3>
            <div className="bg-red-50 border border-red-100 rounded-xl p-6 text-red-900">
              <p className="text-sm leading-relaxed italic">
                "{forecast.riskAssessment}"
              </p>
            </div>
            
            <div className="bg-blue-50 border border-blue-100 rounded-xl p-6">
              <h4 className="font-bold text-blue-900 text-sm mb-2">Proactive Planning</h4>
              <p className="text-xs text-blue-700 leading-relaxed">
                Based on this analysis, it is recommended to allocate budget for these certifications in the next quarterly review.
              </p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
