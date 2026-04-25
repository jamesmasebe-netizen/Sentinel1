import React from 'react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, LineChart, Line } from 'recharts';
import { Activity, TrendingUp, Users, HeartPulse } from 'lucide-react';

const mockTrendData = [
  { month: 'Jan', compliance: 85, illnesses: 4, incidents: 2 },
  { month: 'Feb', compliance: 88, illnesses: 3, incidents: 1 },
  { month: 'Mar', compliance: 92, illnesses: 2, incidents: 3 },
  { month: 'Apr', compliance: 90, illnesses: 5, incidents: 0 },
  { month: 'May', compliance: 95, illnesses: 1, incidents: 1 },
  { month: 'Jun', compliance: 98, illnesses: 0, incidents: 0 },
];

const mockIllnessData = [
  { name: 'NIHL', cases: 12 },
  { name: 'Dermatitis', cases: 8 },
  { name: 'Resp. Issues', cases: 5 },
  { name: 'Ergonomic', cases: 15 },
];

export default function HealthAnalytics() {
  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">Occupational Health Analytics</h2>
          <p className="text-sm text-slate-500">Trends, compliance, and predictive health metrics.</p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm flex items-center gap-4">
          <div className="bg-blue-50 p-3 rounded-lg text-blue-600"><Activity size={24} /></div>
          <div>
            <p className="text-sm text-slate-500 font-medium">Health Index Score</p>
            <p className="text-2xl font-bold text-slate-900">92/100</p>
          </div>
        </div>
        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm flex items-center gap-4">
          <div className="bg-green-50 p-3 rounded-lg text-green-600"><HeartPulse size={24} /></div>
          <div>
            <p className="text-sm text-slate-500 font-medium">Medicals Compliance</p>
            <p className="text-2xl font-bold text-slate-900">98.5%</p>
          </div>
        </div>
        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm flex items-center gap-4">
          <div className="bg-amber-50 p-3 rounded-lg text-amber-600"><TrendingUp size={24} /></div>
          <div>
            <p className="text-sm text-slate-500 font-medium">Occ. Illness Rate</p>
            <p className="text-2xl font-bold text-slate-900">1.2</p>
          </div>
        </div>
        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm flex items-center gap-4">
          <div className="bg-purple-50 p-3 rounded-lg text-purple-600"><Users size={24} /></div>
          <div>
            <p className="text-sm text-slate-500 font-medium">Active RTW Cases</p>
            <p className="text-2xl font-bold text-slate-900">7</p>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
          <h3 className="font-semibold text-slate-900 mb-4">Health Compliance & Incident Trends (6 Months)</h3>
          <div className="h-72">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={mockTrendData}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#E2E8F0" />
                <XAxis dataKey="month" axisLine={false} tickLine={false} />
                <YAxis yAxisId="left" axisLine={false} tickLine={false} />
                <YAxis yAxisId="right" orientation="right" axisLine={false} tickLine={false} />
                <Tooltip />
                <Legend />
                <Line yAxisId="left" type="monotone" dataKey="compliance" name="Compliance %" stroke="#10B981" strokeWidth={3} dot={{ r: 4 }} />
                <Line yAxisId="right" type="monotone" dataKey="illnesses" name="Occ. Illnesses" stroke="#EF4444" strokeWidth={3} dot={{ r: 4 }} />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
          <h3 className="font-semibold text-slate-900 mb-4">Occupational Illness Breakdown (YTD)</h3>
          <div className="h-72">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={mockIllnessData} layout="vertical" margin={{ left: 20 }}>
                <CartesianGrid strokeDasharray="3 3" horizontal={false} stroke="#E2E8F0" />
                <XAxis type="number" axisLine={false} tickLine={false} />
                <YAxis dataKey="name" type="category" axisLine={false} tickLine={false} width={80} />
                <Tooltip cursor={{ fill: '#F1F5F9' }} />
                <Bar dataKey="cases" name="Reported Cases" fill="#3B82F6" radius={[0, 4, 4, 0]} barSize={24} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>
    </div>
  );
}
