import React, { useState } from 'react';
import { Sparkles, Loader2, BookOpen, ChevronRight, CheckCircle2 } from 'lucide-react';
import { getGeminiClient } from '../lib/gemini';

interface TrainingRecord {
  id: string;
  employeeName: string;
  courseName: string;
  status: 'Active' | 'Expired';
}

interface Props {
  records: TrainingRecord[];
}

interface Recommendation {
  courseName: string;
  reason: string;
  priority: 'High' | 'Medium' | 'Low';
}

export default function LearningPaths({ records }: Props) {
  const [role, setRole] = useState('');
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [recommendations, setRecommendations] = useState<Recommendation[]>([]);

  const generatePath = async () => {
    if (!role) return;
    setIsAnalyzing(true);
    try {
      const ai = getGeminiClient();
      const completedCourses = Array.from(new Set(records.map(r => r.courseName))).join(', ');
      
      const prompt = `As a safety and competency expert, suggest a personalized learning path for a worker with the role: "${role}". 
      They have already completed the following courses: [${completedCourses}].
      Suggest 3-5 additional courses or certifications that would bridge their competency gaps and improve workplace safety.
      Return the response as a JSON array of objects with the following structure:
      [{"courseName": "...", "reason": "...", "priority": "High|Medium|Low"}]`;

      const response = await ai.models.generateContent({
        model: "gemini-3-flash-preview",
        contents: prompt,
        config: { responseMimeType: "application/json" }
      });

      const result = JSON.parse(response.text!);
      setRecommendations(result);
    } catch (error) {
      console.error("Failed to generate learning path:", error);
    } finally {
      setIsAnalyzing(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="bg-gradient-to-r from-blue-600 to-indigo-700 rounded-xl p-6 text-white shadow-lg">
        <div className="flex items-center gap-3 mb-4">
          <Sparkles className="text-blue-200" size={28} />
          <h2 className="text-xl font-bold">AI Learning Path Generator</h2>
        </div>
        <p className="text-blue-100 mb-6 max-w-2xl">
          Enter a job role or target skill set to receive a personalized training roadmap powered by Gemini AI.
        </p>
        <div className="flex flex-col sm:flex-row gap-3">
          <input 
            type="text" 
            placeholder="e.g., Forklift Operator, Site Supervisor, Electrician..." 
            value={role}
            onChange={(e) => setRole(e.target.value)}
            className="flex-1 p-3 rounded-lg bg-white/10 border border-white/20 text-white placeholder:text-blue-200 focus:outline-none focus:ring-2 focus:ring-white/50"
          />
          <button 
            onClick={generatePath}
            disabled={isAnalyzing || !role}
            className="bg-white text-blue-700 px-6 py-3 rounded-lg font-bold hover:bg-blue-50 transition-colors disabled:bg-white/50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
          >
            {isAnalyzing ? <Loader2 className="animate-spin" size={20} /> : <Sparkles size={20} />}
            Generate Roadmap
          </button>
        </div>
      </div>

      {recommendations.length > 0 && (
        <div className="grid grid-cols-1 gap-4">
          <h3 className="text-lg font-bold text-slate-900 flex items-center gap-2">
            <BookOpen size={20} className="text-blue-600" />
            Recommended Training Roadmap
          </h3>
          {recommendations.map((rec, idx) => (
            <div key={idx} className="bg-white border border-slate-200 rounded-xl p-5 hover:border-blue-300 transition-colors shadow-sm flex items-start gap-4">
              <div className={`p-3 rounded-lg shrink-0 ${
                rec.priority === 'High' ? 'bg-red-50 text-red-600' : 
                rec.priority === 'Medium' ? 'bg-amber-50 text-amber-600' : 
                'bg-blue-50 text-blue-600'
              }`}>
                <ChevronRight size={24} />
              </div>
              <div className="flex-1">
                <div className="flex items-center justify-between mb-1">
                  <h4 className="font-bold text-slate-900">{rec.courseName}</h4>
                  <span className={`text-xs font-bold px-2 py-1 rounded-full uppercase ${
                    rec.priority === 'High' ? 'bg-red-100 text-red-700' : 
                    rec.priority === 'Medium' ? 'bg-amber-100 text-amber-700' : 
                    'bg-blue-100 text-blue-700'
                  }`}>
                    {rec.priority} Priority
                  </span>
                </div>
                <p className="text-sm text-slate-600">{rec.reason}</p>
              </div>
            </div>
          ))}
        </div>
      )}

      {records.length > 0 && recommendations.length === 0 && !isAnalyzing && (
        <div className="bg-slate-50 border border-slate-200 rounded-xl p-6">
          <h3 className="text-sm font-bold text-slate-500 uppercase mb-4">Current Competencies</h3>
          <div className="flex flex-wrap gap-2">
            {Array.from(new Set(records.map(r => r.courseName))).map((course, idx) => (
              <span key={idx} className="flex items-center gap-1 bg-white border border-slate-200 px-3 py-1.5 rounded-lg text-sm text-slate-700">
                <CheckCircle2 size={14} className="text-green-500" />
                {course}
              </span>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
