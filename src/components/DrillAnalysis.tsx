import React, { useState } from 'react';
import { Sparkles, Loader2, TrendingUp, AlertCircle, Target, BookOpen, CheckCircle2 } from 'lucide-react';
import { getGeminiClient } from '../lib/gemini';

interface DrillPerformance {
  type: string;
  evacuationTime: number; // in minutes
  personnelAccounted: number; // percentage
  observations: string;
}

export default function DrillAnalysis() {
  const [isGenerating, setIsGenerating] = useState(false);
  const [scenario, setScenario] = useState<string | null>(null);
  const [analysis, setAnalysis] = useState<string | null>(null);
  
  const [drillData, setDrillData] = useState<DrillPerformance>({
    type: 'Fire',
    evacuationTime: 8,
    personnelAccounted: 95,
    observations: 'Some workers in the workshop didn\'t hear the alarm immediately. One fire exit was partially blocked by pallets.'
  });

  const generateScenario = async () => {
    setIsGenerating(true);
    try {
      const ai = getGeminiClient();
      const response = await ai.models.generateContent({
        model: "gemini-3-flash-preview",
        contents: `Generate a realistic and challenging emergency response drill scenario for a construction site/industrial facility. 
        Include:
        1. Scenario Title
        2. Initial Trigger (e.g., smoke detected, chemical spill)
        3. Complicating Factors (e.g., blocked exit, power failure, missing person)
        4. Specific Objectives for the response team.
        Make it futuristic and aligned with ISO 45001 standards.`,
      });
      setScenario(response.text);
    } catch (error) {
      console.error("Error generating scenario:", error);
    } finally {
      setIsGenerating(false);
    }
  };

  const analyzePerformance = async () => {
    setIsGenerating(true);
    try {
      const ai = getGeminiClient();
      const response = await ai.models.generateContent({
        model: "gemini-3-flash-preview",
        contents: `Analyze the following emergency drill performance and provide professional SHEQ recommendations for improvement.
        Drill Type: ${drillData.type}
        Evacuation Time: ${drillData.evacuationTime} minutes
        Personnel Accounted For: ${drillData.personnelAccounted}%
        Observations: ${drillData.observations}
        
        Provide:
        1. Performance Rating (e.g., Needs Improvement, Satisfactory, Excellent)
        2. Key Risks Identified
        3. Action Plan for next 30 days.`,
      });
      setAnalysis(response.text);
    } catch (error) {
      console.error("Error analyzing performance:", error);
    } finally {
      setIsGenerating(false);
    }
  };

  return (
    <div className="space-y-8">
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Scenario Generator */}
        <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm">
          <div className="flex items-center justify-between mb-6">
            <div className="flex items-center gap-3">
              <div className="bg-purple-50 p-2 rounded-lg text-purple-600">
                <Sparkles size={20} />
              </div>
              <h3 className="font-bold text-slate-900">AI Scenario Generator</h3>
            </div>
            <button 
              onClick={generateScenario}
              disabled={isGenerating}
              className="flex items-center gap-2 bg-purple-600 text-white px-4 py-2 rounded-xl text-sm font-bold hover:bg-purple-700 transition-colors disabled:bg-purple-300"
            >
              {isGenerating ? <Loader2 className="animate-spin" size={16} /> : <Sparkles size={16} />}
              Generate New Scenario
            </button>
          </div>

          {scenario ? (
            <div className="bg-slate-50 rounded-xl p-5 border border-slate-100 prose prose-slate prose-sm max-w-none">
              <div className="whitespace-pre-wrap text-slate-700 leading-relaxed">
                {scenario}
              </div>
            </div>
          ) : (
            <div className="text-center py-12 border-2 border-dashed border-slate-200 rounded-xl">
              <BookOpen className="mx-auto text-slate-300 mb-3" size={32} />
              <p className="text-slate-500 text-sm">Click the button above to generate a custom emergency scenario.</p>
            </div>
          )}
        </div>

        {/* Performance Analysis */}
        <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm">
          <div className="flex items-center justify-between mb-6">
            <div className="flex items-center gap-3">
              <div className="bg-blue-50 p-2 rounded-lg text-blue-600">
                <TrendingUp size={20} />
              </div>
              <h3 className="font-bold text-slate-900">AI Drill Performance Analysis</h3>
            </div>
          </div>

          <div className="space-y-4 mb-6">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-[10px] font-bold text-slate-400 uppercase mb-1">Drill Type</label>
                <select 
                  value={drillData.type}
                  onChange={(e) => setDrillData({...drillData, type: e.target.value})}
                  className="w-full p-2 border border-slate-200 rounded-lg text-sm"
                >
                  <option value="Fire">Fire</option>
                  <option value="Medical">Medical</option>
                  <option value="Spill">Spill</option>
                  <option value="Security">Security</option>
                </select>
              </div>
              <div>
                <label className="block text-[10px] font-bold text-slate-400 uppercase mb-1">Evac Time (Mins)</label>
                <input 
                  type="number"
                  value={drillData.evacuationTime}
                  onChange={(e) => setDrillData({...drillData, evacuationTime: parseInt(e.target.value)})}
                  className="w-full p-2 border border-slate-200 rounded-lg text-sm"
                />
              </div>
            </div>
            <div>
              <label className="block text-[10px] font-bold text-slate-400 uppercase mb-1">Accounted For (%)</label>
              <input 
                type="range"
                min="0"
                max="100"
                value={drillData.personnelAccounted}
                onChange={(e) => setDrillData({...drillData, personnelAccounted: parseInt(e.target.value)})}
                className="w-full h-2 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-blue-600"
              />
              <div className="flex justify-between text-[10px] font-bold text-slate-500 mt-1">
                <span>0%</span>
                <span className="text-blue-600">{drillData.personnelAccounted}%</span>
                <span>100%</span>
              </div>
            </div>
            <div>
              <label className="block text-[10px] font-bold text-slate-400 uppercase mb-1">Observations</label>
              <textarea 
                value={drillData.observations}
                onChange={(e) => setDrillData({...drillData, observations: e.target.value})}
                className="w-full p-2 border border-slate-200 rounded-lg text-sm h-20"
                placeholder="Describe what happened during the drill..."
              />
            </div>
            <button 
              onClick={analyzePerformance}
              disabled={isGenerating}
              className="w-full flex items-center justify-center gap-2 bg-blue-600 text-white py-2.5 rounded-xl text-sm font-bold hover:bg-blue-700 transition-colors disabled:bg-blue-300"
            >
              {isGenerating ? <Loader2 className="animate-spin" size={16} /> : <Target size={16} />}
              Analyze Drill Performance
            </button>
          </div>

          {analysis && (
            <div className="bg-blue-50 rounded-xl p-5 border border-blue-100 prose prose-blue prose-sm max-w-none">
              <div className="whitespace-pre-wrap text-blue-900 leading-relaxed">
                {analysis}
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Quick Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-green-50 border border-green-100 rounded-2xl p-5 flex items-center gap-4">
          <div className="bg-white p-3 rounded-xl text-green-600 shadow-sm">
            <CheckCircle2 size={24} />
          </div>
          <div>
            <p className="text-[10px] font-bold text-green-700 uppercase">Average Evacuation</p>
            <p className="text-2xl font-black text-green-900">6.4m</p>
          </div>
        </div>
        <div className="bg-amber-50 border border-amber-100 rounded-2xl p-5 flex items-center gap-4">
          <div className="bg-white p-3 rounded-xl text-amber-600 shadow-sm">
            <AlertCircle size={24} />
          </div>
          <div>
            <p className="text-[10px] font-bold text-amber-700 uppercase">Critical Risks Found</p>
            <p className="text-2xl font-black text-amber-900">3</p>
          </div>
        </div>
        <div className="bg-blue-50 border border-blue-100 rounded-2xl p-5 flex items-center gap-4">
          <div className="bg-white p-3 rounded-xl text-blue-600 shadow-sm">
            <Target size={24} />
          </div>
          <div>
            <p className="text-[10px] font-bold text-blue-700 uppercase">Compliance Score</p>
            <p className="text-2xl font-black text-blue-900">92%</p>
          </div>
        </div>
      </div>
    </div>
  );
}
