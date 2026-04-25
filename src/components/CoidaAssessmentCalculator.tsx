import React, { useState } from 'react';
import { Calculator, Plus, DollarSign, Percent, Info } from 'lucide-react';

export default function CoidaAssessmentCalculator() {
  const [roe, setRoe] = useState<number>(0);
  const [assessmentRate, setAssessmentRate] = useState<number>(0);
  const [meritRebate, setMeritRebate] = useState<number>(0);

  const calculateAssessment = () => {
    const baseAssessment = (roe * assessmentRate) / 100;
    const rebateAmount = (baseAssessment * meritRebate) / 100;
    const finalAssessment = baseAssessment - rebateAmount;
    return {
      baseAssessment,
      rebateAmount,
      finalAssessment
    };
  };

  const results = calculateAssessment();

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">COIDA Assessment Calculator</h2>
          <p className="text-sm text-slate-500">Estimate your annual assessment based on Return of Earnings (ROE) and industry class rates.</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm space-y-4">
          <h3 className="font-bold text-slate-900 flex items-center gap-2"><Calculator size={18} className="text-rose-600" /> Input Parameters</h3>
          
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">Total Annual Earnings (ROE)</label>
            <div className="relative">
              <span className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400">R</span>
              <input 
                type="number" 
                value={roe} 
                onChange={e => setRoe(parseFloat(e.target.value) || 0)}
                className="w-full pl-8 pr-4 py-2 border rounded-lg focus:ring-2 focus:ring-rose-500"
                placeholder="0.00"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">Assessment Rate (%)</label>
            <div className="relative">
              <input 
                type="number" 
                step="0.01"
                value={assessmentRate} 
                onChange={e => setAssessmentRate(parseFloat(e.target.value) || 0)}
                className="w-full pr-8 pl-4 py-2 border rounded-lg focus:ring-2 focus:ring-rose-500"
                placeholder="e.g., 1.25"
              />
              <span className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400">%</span>
            </div>
            <p className="text-[10px] text-slate-400 mt-1">Based on your industry classification (e.g., Class V, Rate 1.25).</p>
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">Merit Rebate / Discount (%)</label>
            <div className="relative">
              <input 
                type="number" 
                value={meritRebate} 
                onChange={e => setMeritRebate(parseFloat(e.target.value) || 0)}
                className="w-full pr-8 pl-4 py-2 border rounded-lg focus:ring-2 focus:ring-rose-500"
                placeholder="0"
              />
              <span className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400">%</span>
            </div>
          </div>
        </div>

        <div className="space-y-4">
          <div className="bg-rose-600 p-6 rounded-xl text-white shadow-lg shadow-rose-200">
            <h3 className="text-rose-100 text-xs font-bold uppercase tracking-widest mb-2">Estimated Final Assessment</h3>
            <p className="text-4xl font-black">R {results.finalAssessment.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</p>
            <div className="mt-4 pt-4 border-t border-rose-500 flex justify-between text-sm">
              <span>Base Assessment:</span>
              <span className="font-bold">R {results.baseAssessment.toLocaleString()}</span>
            </div>
            <div className="mt-2 flex justify-between text-sm">
              <span>Merit Rebate:</span>
              <span className="font-bold text-rose-200">- R {results.rebateAmount.toLocaleString()}</span>
            </div>
          </div>

          <div className="bg-blue-50 p-4 rounded-xl border border-blue-100 flex gap-3">
            <Info className="text-blue-600 shrink-0" size={20} />
            <div className="text-xs text-blue-800 leading-relaxed">
              <p className="font-bold mb-1">Pro-Tip for SHEQ Managers:</p>
              Reducing your Lost Time Injury Frequency Rate (LTIFR) can lead to merit rebates of up to 50% on your annual assessment. This calculator provides an estimate only.
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
