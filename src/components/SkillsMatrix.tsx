import React from 'react';
import { Check, X, AlertCircle, TrendingDown } from 'lucide-react';

interface TrainingRecord {
  id: string;
  employeeName: string;
  courseName: string;
  status: 'Active' | 'Expired';
}

interface Props {
  records: TrainingRecord[];
}

const REQUIRED_SKILLS = [
  'First Aid Level 1',
  'Fire Safety',
  'Manual Handling',
  'Working at Heights',
  'Hazardous Materials'
];

export default function SkillsMatrix({ records }: Props) {
  const employees = Array.from(new Set(records.map(r => r.employeeName)));
  
  const getSkillStatus = (employee: string, skill: string) => {
    const record = records.find(r => r.employeeName === employee && r.courseName.includes(skill));
    if (!record) return 'missing';
    return record.status === 'Active' ? 'active' : 'expired';
  };

  const calculateCoverage = (skill: string) => {
    const activeCount = employees.filter(e => getSkillStatus(e, skill) === 'active').length;
    return employees.length > 0 ? Math.round((activeCount / employees.length) * 100) : 0;
  };

  return (
    <div className="space-y-8">
      {/* Coverage Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-5 gap-4">
        {REQUIRED_SKILLS.map(skill => {
          const coverage = calculateCoverage(skill);
          return (
            <div key={skill} className="bg-white border border-slate-200 rounded-xl p-4 shadow-sm">
              <p className="text-xs font-bold text-slate-500 uppercase mb-1 truncate" title={skill}>{skill}</p>
              <div className="flex items-end justify-between">
                <span className="text-2xl font-bold text-slate-900">{coverage}%</span>
                <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${
                  coverage > 80 ? 'bg-green-100 text-green-700' : 
                  coverage > 50 ? 'bg-amber-100 text-amber-700' : 
                  'bg-red-100 text-red-700'
                }`}>
                  Coverage
                </span>
              </div>
              <div className="mt-3 w-full bg-slate-100 rounded-full h-1.5">
                <div 
                  className={`h-1.5 rounded-full transition-all duration-500 ${
                    coverage > 80 ? 'bg-green-500' : 
                    coverage > 50 ? 'bg-amber-500' : 
                    'bg-red-500'
                  }`} 
                  style={{ width: `${coverage}%` }}
                />
              </div>
            </div>
          );
        })}
      </div>

      {/* Skills Grid */}
      <div className="bg-white border border-slate-200 rounded-xl shadow-sm overflow-hidden">
        <div className="p-6 border-b border-slate-200 bg-slate-50">
          <h3 className="font-bold text-slate-900">Workforce Skills Matrix</h3>
          <p className="text-sm text-slate-500">Visual overview of competency compliance across all employees.</p>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 text-xs uppercase tracking-wider">
                <th className="p-4 font-bold sticky left-0 bg-slate-50 z-10">Employee</th>
                {REQUIRED_SKILLS.map(skill => (
                  <th key={skill} className="p-4 font-bold text-center min-w-[120px]">{skill}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {employees.map(employee => (
                <tr key={employee} className="hover:bg-slate-50 transition-colors">
                  <td className="p-4 font-medium text-slate-900 sticky left-0 bg-white z-10 border-r border-slate-100">
                    {employee}
                  </td>
                  {REQUIRED_SKILLS.map(skill => {
                    const status = getSkillStatus(employee, skill);
                    return (
                      <td key={skill} className="p-4 text-center">
                        <div className="flex justify-center">
                          {status === 'active' ? (
                            <div className="bg-green-100 text-green-600 p-1.5 rounded-full" title="Active">
                              <Check size={16} />
                            </div>
                          ) : status === 'expired' ? (
                            <div className="bg-amber-100 text-amber-600 p-1.5 rounded-full" title="Expired">
                              <AlertCircle size={16} />
                            </div>
                          ) : (
                            <div className="bg-red-100 text-red-600 p-1.5 rounded-full" title="Missing">
                              <X size={16} />
                            </div>
                          )}
                        </div>
                      </td>
                    );
                  })}
                </tr>
              ))}
              {employees.length === 0 && (
                <tr>
                  <td colSpan={REQUIRED_SKILLS.length + 1} className="p-8 text-center text-slate-500 italic">
                    No employee data available to generate matrix.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
        <div className="p-4 bg-slate-50 border-t border-slate-200 flex gap-6 text-xs font-medium text-slate-500">
          <div className="flex items-center gap-1.5">
            <div className="bg-green-100 text-green-600 p-0.5 rounded-full"><Check size={10} /></div>
            Active Certification
          </div>
          <div className="flex items-center gap-1.5">
            <div className="bg-amber-100 text-amber-600 p-0.5 rounded-full"><AlertCircle size={10} /></div>
            Expired Certification
          </div>
          <div className="flex items-center gap-1.5">
            <div className="bg-red-100 text-red-600 p-0.5 rounded-full"><X size={10} /></div>
            Missing / Not Trained
          </div>
        </div>
      </div>
    </div>
  );
}
