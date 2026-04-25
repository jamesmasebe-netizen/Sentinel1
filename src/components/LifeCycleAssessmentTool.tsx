import React, { useState } from 'react';
import { RefreshCw, Plus, CheckCircle2, AlertCircle, Info, ArrowRight } from 'lucide-react';

interface LCAStage {
  id: string;
  stage: string;
  impact: string;
  mitigation: string;
}

const initialStages: LCAStage[] = [
  { id: '1', stage: 'Raw Material Extraction', impact: 'High resource depletion', mitigation: 'Use recycled materials' },
  { id: '2', stage: 'Manufacturing', impact: 'High energy consumption', mitigation: 'Optimize processes' },
  { id: '3', stage: 'Distribution', impact: 'Carbon emissions from transport', mitigation: 'Local sourcing' },
  { id: '4', stage: 'Use Phase', impact: 'Energy/water consumption', mitigation: 'Energy-efficient design' },
  { id: '5', stage: 'End of Life', impact: 'Waste to landfill', mitigation: 'Design for disassembly' },
];

export default function LifeCycleAssessmentTool() {
  const [stages, setStages] = useState<LCAStage[]>(initialStages);
  const [productName, setProductName] = useState('');

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">Life Cycle Assessment (LCA) Tool</h2>
          <p className="text-sm text-slate-500">Assess product/service life cycle impacts and identify mitigation strategies.</p>
        </div>
      </div>

      <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm space-y-6">
        <div>
          <label className="block text-sm font-medium text-slate-700 mb-1">Product / Service Name</label>
          <input 
            type="text" 
            value={productName} 
            onChange={e => setProductName(e.target.value)}
            className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-green-500"
            placeholder="e.g., Industrial Pump, New Packaging Design"
          />
        </div>

        <div className="space-y-4">
          <h3 className="text-xs font-black text-slate-400 uppercase tracking-widest border-b border-slate-100 pb-2">Life Cycle Stages</h3>
          <div className="space-y-3">
            {stages.map((stage, index) => (
              <div key={stage.id} className="flex flex-col md:flex-row md:items-center gap-4 p-4 bg-slate-50 rounded-xl border border-slate-100">
                <div className="flex items-center gap-3 md:w-1/4">
                  <div className="bg-green-600 text-white w-6 h-6 rounded-full flex items-center justify-center text-[10px] font-bold shrink-0">{index + 1}</div>
                  <span className="text-sm font-bold text-slate-900">{stage.stage}</span>
                </div>
                
                <div className="flex-1 space-y-2 md:space-y-0 md:flex md:items-center md:gap-4">
                  <div className="flex-1">
                    <p className="text-[10px] text-slate-400 font-bold uppercase mb-1">Primary Impact</p>
                    <p className="text-xs text-slate-600">{stage.impact}</p>
                  </div>
                  <ArrowRight size={16} className="text-slate-300 hidden md:block" />
                  <div className="flex-1">
                    <p className="text-[10px] text-slate-400 font-bold uppercase mb-1">Mitigation Strategy</p>
                    <p className="text-xs text-green-700 font-medium">{stage.mitigation}</p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="bg-blue-50 p-4 rounded-xl border border-blue-100 flex gap-3">
          <Info className="text-blue-600 shrink-0" size={20} />
          <div className="text-xs text-blue-800 leading-relaxed">
            <p className="font-bold mb-1">LCA Note:</p>
            This tool provides a simplified qualitative assessment. For ISO 14040/44 compliance, a detailed quantitative study is required. Use this to identify "hotspots" in your product's life cycle.
          </div>
        </div>
      </div>
    </div>
  );
}
