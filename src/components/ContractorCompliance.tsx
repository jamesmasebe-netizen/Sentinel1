import React from 'react';
import { ShieldCheck, ShieldAlert, Building2, Users } from 'lucide-react';

interface TrainingRecord {
  id: string;
  employeeName: string;
  courseName: string;
  status: 'Active' | 'Expired';
  contractorId?: string;
  contractorName?: string;
}

interface Props {
  records: TrainingRecord[];
  contractors: { id: string, companyName: string }[];
}

export default function ContractorCompliance({ records, contractors }: Props) {
  const contractorStats = contractors.map(contractor => {
    const contractorRecords = records.filter(r => r.contractorId === contractor.id);
    const total = contractorRecords.length;
    const active = contractorRecords.filter(r => r.status === 'Active').length;
    const complianceRate = total > 0 ? Math.round((active / total) * 100) : 0;
    
    return {
      ...contractor,
      total,
      active,
      expired: total - active,
      complianceRate
    };
  });

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {contractorStats.map(stat => (
          <div key={stat.id} className="bg-white border border-slate-200 rounded-xl p-5 shadow-sm">
            <div className="flex items-center gap-3 mb-4">
              <div className="bg-slate-100 p-2 rounded-lg text-slate-600">
                <Building2 size={20} />
              </div>
              <h3 className="font-bold text-slate-900 truncate" title={stat.companyName}>{stat.companyName}</h3>
            </div>
            
            <div className="flex items-end justify-between mb-2">
              <div>
                <p className="text-2xl font-bold text-slate-900">{stat.complianceRate}%</p>
                <p className="text-xs text-slate-500 uppercase font-bold">Compliance</p>
              </div>
              <div className={`p-1.5 rounded-lg ${stat.complianceRate >= 90 ? 'bg-green-50 text-green-600' : 'bg-amber-50 text-amber-600'}`}>
                {stat.complianceRate >= 90 ? <ShieldCheck size={20} /> : <ShieldAlert size={20} />}
              </div>
            </div>

            <div className="w-full bg-slate-100 rounded-full h-1.5 mb-4">
              <div 
                className={`h-1.5 rounded-full transition-all duration-500 ${
                  stat.complianceRate >= 90 ? 'bg-green-500' : 
                  stat.complianceRate >= 70 ? 'bg-amber-500' : 
                  'bg-red-500'
                }`} 
                style={{ width: `${stat.complianceRate}%` }}
              />
            </div>

            <div className="grid grid-cols-2 gap-2 text-center border-t border-slate-50 pt-3">
              <div>
                <p className="text-sm font-bold text-slate-900">{stat.active}</p>
                <p className="text-[10px] text-slate-500 uppercase">Active</p>
              </div>
              <div className="border-l border-slate-100">
                <p className="text-sm font-bold text-red-600">{stat.expired}</p>
                <p className="text-[10px] text-slate-500 uppercase">Expired</p>
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="bg-white border border-slate-200 rounded-xl shadow-sm overflow-hidden">
        <div className="p-6 border-b border-slate-200 bg-slate-50">
          <h3 className="font-bold text-slate-900">Contractor Training Overview</h3>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 text-xs uppercase tracking-wider">
                <th className="p-4 font-bold">Contractor</th>
                <th className="p-4 font-bold text-center">Total Records</th>
                <th className="p-4 font-bold text-center">Active</th>
                <th className="p-4 font-bold text-center">Expired</th>
                <th className="p-4 font-bold text-center">Compliance</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {contractorStats.map(stat => (
                <tr key={stat.id} className="hover:bg-slate-50 transition-colors">
                  <td className="p-4 font-medium text-slate-900">{stat.companyName}</td>
                  <td className="p-4 text-center text-slate-600">{stat.total}</td>
                  <td className="p-4 text-center text-green-600 font-medium">{stat.active}</td>
                  <td className="p-4 text-center text-red-600 font-medium">{stat.expired}</td>
                  <td className="p-4 text-center">
                    <span className={`inline-block px-3 py-1 rounded-full text-xs font-bold ${
                      stat.complianceRate >= 90 ? 'bg-green-100 text-green-700' : 
                      stat.complianceRate >= 70 ? 'bg-amber-100 text-amber-700' : 
                      'bg-red-100 text-red-700'
                    }`}>
                      {stat.complianceRate}%
                    </span>
                  </td>
                </tr>
              ))}
              {contractorStats.length === 0 && (
                <tr>
                  <td colSpan={5} className="p-8 text-center text-slate-500">
                    No contractor data available.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
