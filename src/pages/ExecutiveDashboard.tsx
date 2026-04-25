import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { collection, onSnapshot, query, where } from 'firebase/firestore';
import { db } from '../lib/firebase';
import { useAuth } from '../contexts/AuthContext';
import { 
  AlertTriangle, 
  ClipboardCheck, 
  Users, 
  Building2, 
  BarChart3, 
  TrendingUp, 
  ShieldCheck, 
  Globe, 
  ArrowUpRight, 
  ArrowDownRight,
  Activity,
  Map as MapIcon
} from 'lucide-react';
import { 
  BarChart, 
  Bar, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  Legend, 
  ResponsiveContainer, 
  PieChart, 
  Pie, 
  Cell,
  LineChart,
  Line,
  AreaChart,
  Area
} from 'recharts';
import SiteMap from '../components/SiteMap';

export default function ExecutiveDashboard() {
  const navigate = useNavigate();
  const { profile } = useAuth();
  const [incidents, setIncidents] = useState<any[]>([]);
  const [contractors, setContractors] = useState<any[]>([]);
  const [riskAssessments, setRiskAssessments] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!profile) return;

    // If admin, fetch all. If not, fetch only for site.
    const incidentQuery = profile.role === 'admin' 
      ? collection(db, 'incidents') 
      : query(collection(db, 'incidents'), where('siteId', '==', profile.siteId));

    const unsubIncidents = onSnapshot(incidentQuery, (snapshot) => {
      setIncidents(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
    });

    const contractorQuery = profile.role === 'admin'
      ? collection(db, 'contractors')
      : query(collection(db, 'contractors'), where('siteId', '==', profile.siteId));

    const unsubContractors = onSnapshot(contractorQuery, (snapshot) => {
      setContractors(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
    });

    const riskQuery = profile.role === 'admin'
      ? collection(db, 'risk_assessments')
      : query(collection(db, 'risk_assessments'), where('siteId', '==', profile.siteId));

    const unsubRisk = onSnapshot(riskQuery, (snapshot) => {
      setRiskAssessments(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
      setLoading(false);
    });

    return () => {
      unsubIncidents();
      unsubContractors();
      unsubRisk();
    };
  }, [profile]);

  const stats = [
    { 
      label: 'Total Incidents', 
      value: incidents.length, 
      trend: '+12%', 
      trendUp: false, 
      icon: AlertTriangle, 
      color: 'text-red-600',
      bg: 'bg-red-50',
      path: '/incidents-capa'
    },
    { 
      label: 'Compliance Score', 
      value: '94%', 
      trend: '+2.4%', 
      trendUp: true, 
      icon: ShieldCheck, 
      color: 'text-emerald-600',
      bg: 'bg-emerald-50',
      path: '/governance'
    },
    { 
      label: 'Active Contractors', 
      value: contractors.length, 
      trend: '-3', 
      trendUp: true, 
      icon: Users, 
      color: 'text-blue-600',
      bg: 'bg-blue-50',
      path: '/contractors-permits'
    },
    { 
      label: 'Risk Assessments', 
      value: riskAssessments.length, 
      trend: '+5', 
      trendUp: true, 
      icon: ClipboardCheck, 
      color: 'text-amber-600',
      bg: 'bg-amber-50',
      path: '/risk'
    },
  ];

  const incidentByType = Object.entries(
    incidents.reduce((acc: any, inc) => {
      acc[inc.type] = (acc[inc.type] || 0) + 1;
      return acc;
    }, {})
  ).map(([name, value]) => ({ name, value }));

  const COLORS = ['#3b82f6', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6'];

  const mockTrendData = [
    { month: 'Jan', incidents: 4, compliance: 88 },
    { month: 'Feb', incidents: 3, compliance: 90 },
    { month: 'Mar', incidents: 6, compliance: 85 },
    { month: 'Apr', incidents: 2, compliance: 92 },
    { month: 'May', incidents: 4, compliance: 94 },
    { month: 'Jun', incidents: 1, compliance: 96 },
  ];

  const sites = [
    { lat: -26.2041, lng: 28.0473, name: 'Johannesburg HQ', status: 'Green' as const },
    { lat: -33.9249, lng: 18.4241, name: 'Cape Town Facility', status: 'Amber' as const },
    { lat: -29.8587, lng: 31.0218, name: 'Durban Port Site', status: 'Green' as const },
  ];

  return (
    <div className="p-6 space-y-8 bg-slate-50/50 min-h-screen">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <h1 className="text-3xl font-black text-slate-900 tracking-tight flex items-center gap-3">
            Executive Command Center <Activity className="text-blue-600" size={28} />
          </h1>
          <p className="text-slate-500 font-medium mt-1">
            {profile?.role === 'admin' ? 'Global Enterprise Overview' : `Site Overview: ${profile?.siteId || 'Loading...'}`}
          </p>
        </div>
        <div className="flex gap-3">
          <button className="px-4 py-2 bg-white border border-slate-200 rounded-lg text-sm font-semibold text-slate-700 hover:bg-slate-50 transition-colors shadow-sm">
            Download Report
          </button>
          <button className="px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-semibold hover:bg-blue-700 transition-colors shadow-md shadow-blue-200">
            Share Insights
          </button>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((stat) => (
          <div 
            key={stat.label} 
            className="bg-white p-6 rounded-2xl shadow-sm border border-slate-200 hover:border-blue-300 transition-all cursor-pointer group"
            onClick={() => navigate(stat.path)}
          >
            <div className="flex justify-between items-start mb-4">
              <div className={`${stat.bg} p-3 rounded-xl transition-colors group-hover:bg-blue-50`}>
                <stat.icon className={`${stat.color} group-hover:text-blue-600`} size={24} />
              </div>
              <div className={`flex items-center gap-1 text-xs font-bold px-2 py-1 rounded-full ${stat.trendUp ? 'bg-emerald-50 text-emerald-600' : 'bg-red-50 text-red-600'}`}>
                {stat.trendUp ? <ArrowUpRight size={14} /> : <ArrowDownRight size={14} />}
                {stat.trend}
              </div>
            </div>
            <p className="text-slate-500 text-sm font-semibold">{stat.label}</p>
            <h3 className="text-2xl font-black text-slate-900 mt-1">{stat.value}</h3>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Main Chart */}
        <div className="lg:col-span-2 bg-white p-6 rounded-2xl shadow-sm border border-slate-200">
          <div className="flex justify-between items-center mb-6">
            <h2 className="text-lg font-bold text-slate-900 flex items-center gap-2">
              Safety & Compliance Trends <TrendingUp size={20} className="text-blue-600" />
            </h2>
            <select className="text-sm border-slate-200 rounded-lg bg-slate-50 font-medium">
              <option>Last 6 Months</option>
              <option>Last Year</option>
            </select>
          </div>
          <div className="h-[350px]">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={mockTrendData}>
                <defs>
                  <linearGradient id="colorCompliance" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.1}/>
                    <stop offset="95%" stopColor="#3b82f6" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
                <XAxis dataKey="month" axisLine={false} tickLine={false} tick={{fill: '#64748b', fontSize: 12}} />
                <YAxis axisLine={false} tickLine={false} tick={{fill: '#64748b', fontSize: 12}} />
                <Tooltip 
                  contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 10px 15px -3px rgb(0 0 0 / 0.1)' }}
                />
                <Area type="monotone" dataKey="compliance" stroke="#3b82f6" strokeWidth={3} fillOpacity={1} fill="url(#colorCompliance)" />
                <Line type="monotone" dataKey="incidents" stroke="#ef4444" strokeWidth={2} dot={{r: 4}} />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Distribution Chart */}
        <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-200">
          <h2 className="text-lg font-bold text-slate-900 mb-6">Incident Distribution</h2>
          <div className="h-[300px]">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={incidentByType.length > 0 ? incidentByType : [{name: 'No Data', value: 1}]}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={100}
                  paddingAngle={5}
                  dataKey="value"
                >
                  {(incidentByType.length > 0 ? incidentByType : [{name: 'No Data', value: 1}]).map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip />
                <Legend verticalAlign="bottom" height={36}/>
              </PieChart>
            </ResponsiveContainer>
          </div>
          <div className="mt-4 space-y-2">
            <div className="p-3 bg-slate-50 rounded-xl flex justify-between items-center">
              <span className="text-sm font-medium text-slate-600">Highest Risk Area</span>
              <span className="text-sm font-bold text-red-600">Production Floor</span>
            </div>
            <div className="p-3 bg-slate-50 rounded-xl flex justify-between items-center">
              <span className="text-sm font-medium text-slate-600">Average Severity</span>
              <span className="text-sm font-bold text-amber-600">Moderate</span>
            </div>
          </div>
        </div>
      </div>

      {/* Map and Site Overview */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <div className="lg:col-span-2 bg-white p-6 rounded-2xl shadow-sm border border-slate-200 min-h-[400px]">
          <div className="flex justify-between items-center mb-6">
            <h2 className="text-lg font-bold text-slate-900 flex items-center gap-2">
              Global Site Status <MapIcon size={20} className="text-blue-600" />
            </h2>
          </div>
          <div className="h-[400px] relative">
            <SiteMap locations={sites} />
          </div>
        </div>

        <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-200">
          <h2 className="text-lg font-bold text-slate-900 mb-6">Site Performance</h2>
          <div className="space-y-6">
            {sites.map((site) => (
              <div key={site.name} className="flex items-center justify-between p-4 bg-slate-50 rounded-2xl border border-slate-100 hover:border-blue-200 transition-colors cursor-pointer">
                <div className="flex items-center gap-4">
                  <div className={`w-3 h-3 rounded-full ${site.status === 'Green' ? 'bg-emerald-500 shadow-[0_0_10px_rgba(16,185,129,0.5)]' : 'bg-amber-500 shadow-[0_0_10px_rgba(245,158,11,0.5)]'}`} />
                  <div>
                    <h4 className="font-bold text-slate-900 text-sm">{site.name}</h4>
                    <p className="text-xs text-slate-500 font-medium">98% Compliance</p>
                  </div>
                </div>
                <button className="p-2 hover:bg-white rounded-lg transition-colors">
                  <ArrowUpRight size={18} className="text-slate-400" />
                </button>
              </div>
            ))}
          </div>
          <button className="w-full mt-6 py-3 bg-slate-900 text-white rounded-xl font-bold text-sm hover:bg-slate-800 transition-colors">
            View All Sites
          </button>
        </div>
      </div>
    </div>
  );
}
