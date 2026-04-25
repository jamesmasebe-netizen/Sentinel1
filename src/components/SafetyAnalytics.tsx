import React, { useState, useEffect } from 'react';
import { collection, onSnapshot, query, orderBy, where } from 'firebase/firestore';
import { db, handleFirestoreError } from '../lib/firebase';
import { useAuth } from '../contexts/AuthContext';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, LineChart, Line, AreaChart, Area } from 'recharts';
import { AlertTriangle, TrendingUp, Activity, ShieldAlert } from 'lucide-react';

export default function SafetyAnalytics() {
  const { profile } = useAuth();
  const [data, setData] = useState<any[]>([]);
  const [riskScore, setRiskScore] = useState(0);

  useEffect(() => {
    if (!profile?.siteId) return;
    const q = query(collection(db, 'incidents'), where('siteId', '==', profile.siteId), orderBy('createdAt', 'desc'));
    const unsub = onSnapshot(q, (snapshot) => {
      const incidents = snapshot.docs.map(doc => doc.data());
      
      // Aggregate by month for trend
      const aggregated = incidents.reduce((acc, inc) => {
        const month = new Date(inc.createdAt).toLocaleString('default', { month: 'short' });
        acc[month] = (acc[month] || 0) + 1;
        return acc;
      }, {});
      
      const chartData = Object.entries(aggregated).map(([name, value]) => ({ 
        name, 
        incidents: value,
        // Mocking predictive trend based on historical data
        predicted: Math.round((value as number) * 1.1) 
      }));
      
      setData(chartData);

      // Simple mock risk score calculation based on recent incident frequency
      const recentIncidents = incidents.filter(i => {
        const diffDays = (new Date().getTime() - new Date(i.createdAt).getTime()) / (1000 * 3600 * 24);
        return diffDays <= 30;
      }).length;
      
      setRiskScore(Math.min(100, recentIncidents * 15)); // Mock formula

    }, (error) => handleFirestoreError(error, 'list' as any, 'incidents'));
    return () => unsub();
  }, [profile?.siteId]);

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h2 className="text-lg font-bold text-slate-900">Predictive Safety Analytics</h2>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm flex items-center gap-4">
          <div className={`p-3 rounded-full ${riskScore > 50 ? 'bg-red-100 text-red-600' : 'bg-green-100 text-green-600'}`}>
            <ShieldAlert size={24} />
          </div>
          <div>
            <p className="text-sm text-slate-500 font-medium">Current Risk Score</p>
            <h3 className="text-2xl font-bold text-slate-900">{riskScore}/100</h3>
          </div>
        </div>
        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm flex items-center gap-4">
          <div className="p-3 rounded-full bg-blue-100 text-blue-600">
            <TrendingUp size={24} />
          </div>
          <div>
            <p className="text-sm text-slate-500 font-medium">Predicted Trend</p>
            <h3 className="text-2xl font-bold text-slate-900">Increasing</h3>
          </div>
        </div>
        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm flex items-center gap-4">
          <div className="p-3 rounded-full bg-purple-100 text-purple-600">
            <Activity size={24} />
          </div>
          <div>
            <p className="text-sm text-slate-500 font-medium">Total Incidents (YTD)</p>
            <h3 className="text-2xl font-bold text-slate-900">{data.reduce((acc, curr) => acc + curr.incidents, 0)}</h3>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Incident Trend vs Prediction */}
        <div className="bg-white p-6 border border-slate-200 rounded-xl shadow-sm">
          <h3 className="text-md font-bold text-slate-800 mb-4 flex items-center gap-2">
            <TrendingUp size={18} className="text-blue-500" />
            Incident Trend & Forecast
          </h3>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={data}>
                <defs>
                  <linearGradient id="colorIncidents" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#ef4444" stopOpacity={0.3}/>
                    <stop offset="95%" stopColor="#ef4444" stopOpacity={0}/>
                  </linearGradient>
                  <linearGradient id="colorPredicted" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.3}/>
                    <stop offset="95%" stopColor="#3b82f6" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" vertical={false} />
                <XAxis dataKey="name" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Area type="monotone" dataKey="incidents" stroke="#ef4444" fillOpacity={1} fill="url(#colorIncidents)" name="Actual Incidents" />
                <Area type="monotone" dataKey="predicted" stroke="#3b82f6" strokeDasharray="5 5" fillOpacity={1} fill="url(#colorPredicted)" name="Predicted (AI Model)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* High Risk Areas (Mock Data for demonstration) */}
        <div className="bg-white p-6 border border-slate-200 rounded-xl shadow-sm">
          <h3 className="text-md font-bold text-slate-800 mb-4 flex items-center gap-2">
            <AlertTriangle size={18} className="text-amber-500" />
            Predicted High-Risk Zones
          </h3>
          <div className="space-y-4">
            <div className="p-4 bg-red-50 border border-red-100 rounded-lg flex justify-between items-center">
              <div>
                <h4 className="font-bold text-red-900">Zone B - Heavy Machinery</h4>
                <p className="text-sm text-red-700">High probability of equipment-related incidents based on recent near-misses.</p>
              </div>
              <span className="bg-red-200 text-red-800 text-xs font-bold px-2 py-1 rounded-full">85% Risk</span>
            </div>
            <div className="p-4 bg-amber-50 border border-amber-100 rounded-lg flex justify-between items-center">
              <div>
                <h4 className="font-bold text-amber-900">Zone A - Scaffolding</h4>
                <p className="text-sm text-amber-700">Elevated risk due to upcoming weather conditions (high winds).</p>
              </div>
              <span className="bg-amber-200 text-amber-800 text-xs font-bold px-2 py-1 rounded-full">60% Risk</span>
            </div>
            <div className="p-4 bg-blue-50 border border-blue-100 rounded-lg flex justify-between items-center">
              <div>
                <h4 className="font-bold text-blue-900">Zone C - Loading Dock</h4>
                <p className="text-sm text-blue-700">Normal operations. Continue standard monitoring.</p>
              </div>
              <span className="bg-blue-200 text-blue-800 text-xs font-bold px-2 py-1 rounded-full">15% Risk</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
