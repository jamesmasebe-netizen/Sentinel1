import React, { useState } from 'react';
import { Type, ThinkingLevel, Modality } from '@google/genai';
import { Camera, Image as ImageIcon, Video, Mic, MapPin, Brain, Volume2, Loader2 } from 'lucide-react';
import { getGeminiClient } from '../lib/gemini';

export default function GeminiFeatures() {
  const [activeTab, setActiveTab] = useState('image-gen');
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<any>(null);
  const [prompt, setPrompt] = useState('');
  const [file, setFile] = useState<File | null>(null);
  const [aspectRatio, setAspectRatio] = useState('1:1');

  const handleImageGeneration = async () => {
    if (!prompt) return;
    setLoading(true);
    try {
      const ai = getGeminiClient();
      const response = await ai.models.generateContent({
        model: 'gemini-3.1-flash-image-preview',
        contents: { parts: [{ text: prompt }] },
        config: {
          imageConfig: { aspectRatio: aspectRatio as any, imageSize: "1K" }
        }
      });
      
      for (const part of response.candidates?.[0]?.content?.parts || []) {
        if (part.inlineData) {
          setResult(`data:image/png;base64,${part.inlineData.data}`);
          break;
        }
      }
    } catch (error) {
      console.error(error);
      setResult('Error generating image');
    }
    setLoading(false);
  };

  const handleImageAnalysis = async () => {
    if (!file || !prompt) return;
    setLoading(true);
    try {
      const reader = new FileReader();
      reader.onloadend = async () => {
        const base64Data = (reader.result as string).split(',')[1];
        const ai = getGeminiClient();
        const response = await ai.models.generateContent({
          model: 'gemini-3.1-pro-preview',
          contents: {
            parts: [
              { text: prompt },
              { inlineData: { data: base64Data, mimeType: file.type } }
            ]
          }
        });
        setResult(response.text);
        setLoading(false);
      };
      reader.readAsDataURL(file);
    } catch (error) {
      console.error(error);
      setResult('Error analyzing image');
      setLoading(false);
    }
  };

  const handleMapsGrounding = async () => {
    if (!prompt) return;
    setLoading(true);
    try {
      const ai = getGeminiClient();
      const response = await ai.models.generateContent({
        model: 'gemini-3-flash-preview',
        contents: prompt,
        config: {
          tools: [{ googleMaps: {} }]
        }
      });
      setResult(response.text);
    } catch (error) {
      console.error(error);
      setResult('Error fetching map data');
    }
    setLoading(false);
  };

  const handleHighThinking = async () => {
    if (!prompt) return;
    setLoading(true);
    try {
      const ai = getGeminiClient();
      const response = await ai.models.generateContent({
        model: 'gemini-3.1-pro-preview',
        contents: prompt,
        config: {
          thinkingConfig: { thinkingLevel: ThinkingLevel.HIGH }
        }
      });
      setResult(response.text);
    } catch (error) {
      console.error(error);
      setResult('Error processing complex query');
    }
    setLoading(false);
  };

  const handleTTS = async () => {
    if (!prompt) return;
    setLoading(true);
    try {
      const ai = getGeminiClient();
      const response = await ai.models.generateContent({
        model: 'gemini-2.5-flash-preview-tts',
        contents: [{ parts: [{ text: prompt }] }],
        config: {
          responseModalities: [Modality.AUDIO],
          speechConfig: {
            voiceConfig: { prebuiltVoiceConfig: { voiceName: 'Kore' } }
          }
        }
      });
      
      const base64Audio = response.candidates?.[0]?.content?.parts?.[0]?.inlineData?.data;
      if (base64Audio) {
        setResult(`data:audio/wav;base64,${base64Audio}`);
      }
    } catch (error) {
      console.error(error);
      setResult('Error generating speech');
    }
    setLoading(false);
  };

  const tabs = [
    { id: 'image-gen', name: 'Generate Image', icon: ImageIcon },
    { id: 'image-analysis', name: 'Analyze Image', icon: Camera },
    { id: 'maps', name: 'Maps Grounding', icon: MapPin },
    { id: 'thinking', name: 'High Thinking', icon: Brain },
    { id: 'tts', name: 'Text to Speech', icon: Volume2 },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Gemini Intelligence</h1>
        <p className="text-gray-500">Explore advanced AI capabilities for SHEQ management.</p>
      </div>

      <div className="flex space-x-2 overflow-x-auto pb-2">
        {tabs.map(tab => (
          <button
            key={tab.id}
            onClick={() => { setActiveTab(tab.id); setResult(null); setPrompt(''); setFile(null); }}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg whitespace-nowrap transition-colors ${
              activeTab === tab.id ? 'bg-blue-600 text-white' : 'bg-white text-gray-600 hover:bg-gray-50 border border-gray-200'
            }`}
          >
            <tab.icon size={18} />
            {tab.name}
          </button>
        ))}
      </div>

      <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-200">
        <div className="space-y-4">
          {activeTab === 'image-analysis' && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Upload Image</label>
              <input 
                type="file" 
                accept="image/*" 
                onChange={(e) => setFile(e.target.files?.[0] || null)}
                className="block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-sm file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100"
              />
            </div>
          )}

          {activeTab === 'image-gen' && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Aspect Ratio</label>
              <select 
                value={aspectRatio} 
                onChange={(e) => setAspectRatio(e.target.value)}
                className="w-full rounded-lg border border-gray-300 px-4 py-2"
              >
                {['1:1', '3:4', '4:3', '9:16', '16:9'].map(ratio => (
                  <option key={ratio} value={ratio}>{ratio}</option>
                ))}
              </select>
            </div>
          )}

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Prompt</label>
            <textarea
              value={prompt}
              onChange={(e) => setPrompt(e.target.value)}
              placeholder="Enter your prompt here..."
              className="w-full rounded-lg border border-gray-300 px-4 py-2 h-24 focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
          </div>

          <button
            onClick={() => {
              if (activeTab === 'image-gen') handleImageGeneration();
              if (activeTab === 'image-analysis') handleImageAnalysis();
              if (activeTab === 'maps') handleMapsGrounding();
              if (activeTab === 'thinking') handleHighThinking();
              if (activeTab === 'tts') handleTTS();
            }}
            disabled={loading || !prompt || (activeTab === 'image-analysis' && !file)}
            className="w-full bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 disabled:opacity-50 flex items-center justify-center gap-2"
          >
            {loading ? <Loader2 className="animate-spin" size={20} /> : 'Process'}
          </button>
        </div>

        {result && (
          <div className="mt-8 p-4 bg-gray-50 rounded-lg border border-gray-200">
            <h3 className="text-sm font-medium text-gray-900 mb-2">Result:</h3>
            {activeTab === 'image-gen' && typeof result === 'string' && result.startsWith('data:image') ? (
              <img src={result} alt="Generated" className="max-w-full h-auto rounded-lg shadow-sm" />
            ) : activeTab === 'tts' && typeof result === 'string' && result.startsWith('data:audio') ? (
              <audio controls src={result} className="w-full" />
            ) : (
              <div className="whitespace-pre-wrap text-gray-700">{result}</div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
