import React, { useState } from 'react';
import { CheckSquare, Plus, CheckCircle2, XCircle, AlertCircle, Info } from 'lucide-react';

interface ChecklistItem {
  id: string;
  category: string;
  requirement: string;
  status: 'Compliant' | 'Non-Compliant' | 'N/A';
  notes?: string;
}

const initialItems: ChecklistItem[] = [
  { id: '1', category: 'Registration', requirement: 'Employer registered with Compensation Fund', status: 'N/A' },
  { id: '2', category: 'Registration', requirement: 'Active Letter of Good Standing (LOGS)', status: 'N/A' },
  { id: '3', category: 'Reporting', requirement: 'W.Cl.2 submitted within 7 days of accident', status: 'N/A' },
  { id: '4', category: 'Reporting', requirement: 'W.Cl.1 submitted within 14 days of disease diagnosis', status: 'N/A' },
  { id: '5', category: 'Medical', requirement: 'First Medical Report (W.Cl.4) obtained', status: 'N/A' },
  { id: '6', category: 'Medical', requirement: 'Progress Medical Reports (W.Cl.5) obtained monthly', status: 'N/A' },
  { id: '7', category: 'Financial', requirement: 'ROE submitted annually by 31 March', status: 'N/A' },
  { id: '8', category: 'Financial', requirement: 'Assessment paid within 30 days of invoice', status: 'N/A' },
];

export default function CoidaComplianceChecklist() {
  const [items, setItems] = useState<ChecklistItem[]>(initialItems);

  const updateStatus = (id: string, status: ChecklistItem['status']) => {
    setItems(items.map(item => item.id === id ? { ...item, status } : item));
  };

  const categories = Array.from(new Set(items.map(item => item.category)));

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">COIDA Compliance Checklist</h2>
          <p className="text-sm text-slate-500">Self-audit tool for COIDA administrative and legal compliance.</p>
        </div>
      </div>

      <div className="space-y-8">
        {categories.map(category => (
          <div key={category} className="space-y-3">
            <h3 className="text-xs font-black text-slate-400 uppercase tracking-widest border-b border-slate-100 pb-2">{category}</h3>
            <div className="grid grid-cols-1 gap-2">
              {items.filter(item => item.category === category).map(item => (
                <div key={item.id} className="flex items-center justify-between p-4 bg-white border border-slate-200 rounded-xl hover:border-rose-200 transition-colors">
                  <div className="flex items-center gap-3">
                    <div className={`p-2 rounded-lg ${
                      item.status === 'Compliant' ? 'bg-green-50 text-green-600' :
                      item.status === 'Non-Compliant' ? 'bg-red-50 text-red-600' :
                      'bg-slate-50 text-slate-400'
                    }`}>
                      <CheckSquare size={20} />
                    </div>
                    <span className="text-sm font-medium text-slate-700">{item.requirement}</span>
                  </div>
                  
                  <div className="flex items-center gap-2">
                    <button 
                      onClick={() => updateStatus(item.id, 'Compliant')}
                      className={`p-2 rounded-lg transition-colors ${item.status === 'Compliant' ? 'bg-green-600 text-white' : 'bg-slate-50 text-slate-400 hover:bg-green-50 hover:text-green-600'}`}
                    >
                      <CheckCircle2 size={18} />
                    </button>
                    <button 
                      onClick={() => updateStatus(item.id, 'Non-Compliant')}
                      className={`p-2 rounded-lg transition-colors ${item.status === 'Non-Compliant' ? 'bg-red-600 text-white' : 'bg-slate-50 text-slate-400 hover:bg-red-50 hover:text-red-600'}`}
                    >
                      <XCircle size={18} />
                    </button>
                    <button 
                      onClick={() => updateStatus(item.id, 'N/A')}
                      className={`p-2 rounded-lg transition-colors ${item.status === 'N/A' ? 'bg-slate-600 text-white' : 'bg-slate-50 text-slate-400 hover:bg-slate-200 hover:text-slate-600'}`}
                    >
                      <AlertCircle size={18} />
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>

      <div className="bg-amber-50 p-4 rounded-xl border border-amber-100 flex gap-3">
        <Info className="text-amber-600 shrink-0" size={20} />
        <div className="text-xs text-amber-800 leading-relaxed">
          <p className="font-bold mb-1">Compliance Note:</p>
          Failure to comply with COIDA reporting timelines (e.g., 7 days for accidents) can result in penalties of up to 10% of the claim value. Use this checklist to ensure all administrative steps are followed.
        </div>
      </div>
    </div>
  );
}
