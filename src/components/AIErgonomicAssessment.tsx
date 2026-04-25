import React, { useState, useRef } from 'react';
import { Camera, Upload, Sparkles, Activity, AlertTriangle, CheckCircle, Image as ImageIcon, Loader2 } from 'lucide-react';
import { getGeminiClient } from '../lib/gemini';

// ai client is now initialized lazily inside the component when needed

export default function AIErgonomicAssessment() {
  const [image, setImage] = useState<string | null>(null);
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [result, setResult] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        setImage(reader.result as string);
        setResult(null);
      };
      reader.readAsDataURL(file);
    }
  };

  const analyzeErgonomics = async () => {
    if (!image) return;
    setIsAnalyzing(true);
    
    try {
      const ai = getGeminiClient();
      const base64Data = image.split(',')[1];
      const mimeType = image.split(';')[0].split(':')[1];

      const response = await ai.models.generateContent({
        model: 'gemini-3.1-flash-preview',
        contents: [
          {
            inlineData: {
              data: base64Data,
              mimeType: mimeType
            }
          },
          "You are an expert Occupational Health and Ergonomics Assessor. Analyze this image for ergonomic risks. Provide: 1. A brief observation of the posture. 2. Estimated Risk Level (Low, Medium, High). 3. Key risk factors (e.g., back flexion, neck extension). 4. Actionable recommendations to improve the posture or workstation. Format clearly with markdown."
        ]
      });

      setResult(response.text);
    } catch (error) {
      console.error("Error analyzing image:", error);
      setResult("Error analyzing image. Please try again.");
    } finally {
      setIsAnalyzing(false);
    }
  };

  return (
    <div className="space-y-6 max-w-5xl mx-auto">
      <div className="flex items-center gap-3 mb-8">
        <div className="bg-purple-50 p-2 rounded-lg text-purple-600">
          <Activity size={24} />
        </div>
        <div>
          <h2 className="text-xl font-bold text-slate-900">AI Ergonomic Risk Assessment</h2>
          <p className="text-sm text-slate-500">Upload a photo of a worker's posture for instant REBA/RULA-style analysis</p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
        <div className="space-y-4">
          <div 
            className="border-2 border-dashed border-slate-300 rounded-3xl p-8 text-center hover:bg-slate-50 transition-colors cursor-pointer flex flex-col items-center justify-center min-h-[300px]"
            onClick={() => fileInputRef.current?.click()}
          >
            {image ? (
              <img src={image} alt="Uploaded for analysis" className="max-h-[250px] rounded-xl object-contain" />
            ) : (
              <>
                <div className="bg-purple-100 p-4 rounded-full text-purple-600 mb-4">
                  <Camera size={32} />
                </div>
                <h3 className="font-bold text-slate-900 mb-2">Upload Posture Photo</h3>
                <p className="text-sm text-slate-500 max-w-xs mx-auto">
                  Take a clear photo of the worker performing the task from a side profile.
                </p>
              </>
            )}
            <input 
              type="file" 
              ref={fileInputRef} 
              onChange={handleImageUpload} 
              accept="image/*" 
              className="hidden" 
            />
          </div>

          <div className="flex gap-3">
            <button 
              onClick={() => fileInputRef.current?.click()}
              className="flex-1 flex items-center justify-center gap-2 bg-white border border-slate-200 text-slate-700 px-4 py-3 rounded-xl font-bold hover:bg-slate-50 transition-colors"
            >
              <ImageIcon size={18} />
              {image ? 'Change Photo' : 'Select Photo'}
            </button>
            <button 
              onClick={analyzeErgonomics}
              disabled={!image || isAnalyzing}
              className="flex-1 flex items-center justify-center gap-2 bg-purple-600 text-white px-4 py-3 rounded-xl font-bold hover:bg-purple-700 transition-colors disabled:bg-slate-300 disabled:cursor-not-allowed"
            >
              {isAnalyzing ? <Loader2 className="animate-spin" size={18} /> : <Sparkles size={18} />}
              {isAnalyzing ? 'Analyzing...' : 'Analyze Posture'}
            </button>
          </div>
        </div>

        <div className="bg-slate-900 rounded-3xl p-6 text-white relative overflow-hidden min-h-[400px]">
          <div className="absolute top-0 right-0 w-64 h-64 bg-purple-600/20 rounded-full blur-3xl -mr-32 -mt-32"></div>
          
          <div className="relative z-10 h-full flex flex-col">
            <h3 className="text-lg font-bold flex items-center gap-2 mb-6 text-purple-300">
              <Sparkles size={20} />
              AI Assessment Results
            </h3>
            
            {isAnalyzing ? (
              <div className="flex-1 flex flex-col items-center justify-center text-slate-400 space-y-4">
                <Loader2 className="animate-spin text-purple-500" size={40} />
                <p className="font-medium animate-pulse">Running computer vision models...</p>
              </div>
            ) : result ? (
              <div className="flex-1 overflow-y-auto pr-2 custom-scrollbar">
                <div className="prose prose-invert max-w-none prose-p:text-slate-300 prose-headings:text-white prose-strong:text-purple-300">
                  <div className="whitespace-pre-wrap text-sm leading-relaxed">
                    {result}
                  </div>
                </div>
              </div>
            ) : (
              <div className="flex-1 flex flex-col items-center justify-center text-slate-500 space-y-3">
                <Activity size={48} className="opacity-20" />
                <p className="text-sm font-medium text-center max-w-xs">
                  Upload an image and click analyze to generate an ergonomic risk profile.
                </p>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
