import React, { useState, useEffect } from 'react';
import { collection, onSnapshot, query } from 'firebase/firestore';
import { db } from '../lib/firebase';
import { 
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer,
  PieChart, Pie, Cell, LineChart, Line, AreaChart, Area
} from 'recharts';
import { 
  ShieldAlert, 
  TrendingUp, 
  AlertTriangle, 
  CheckCircle, 
  Zap, 
  Eye, 
  Activity,
  ArrowUpRight,
  ArrowDownRight
} from 'lucide-react';

const COLORS = ['#3b82f6', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#ec4899'];

export default function RiskDashboard() {
  const [assessments, setAssessments] = useState<any[]>([]);
  const [observations, setObservations] = useState<any[]>([]);
  const [dras, setDras] = useState<any[]>([]);
  const [incidents, setIncidents] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsubAssessments = onSnapshot(collection(db, 'risk_assessments'), (snapshot) => {
      setAssessments(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
    });
    const unsubObservations = onSnapshot(collection(db, 'bbs_observations'), (snapshot) => {
      setObservations(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
    });
    const unsubDras = onSnapshot(collection(db, 'dynamic_risk_assessments'), (snapshot) => {
      setDras(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
    });
    const unsubIncidents = onSnapshot(collection(db, 'incidents'), (snapshot) => {
      setIncidents(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
    });

    setLoading(false);
    return () => {
      unsubAssessments();
      unsubObservations();
      unsubDras();
      unsubIncidents();
    };
  }, []);

  // Data Processing
  const statusData = [
    { name: 'Draft', value: assessments.filter(a => a.status === 'Draft').length },
    { name: 'Active', value: assessments.filter(a => a.status === 'Active').length },
    { name: 'Review Due', value: assessments.filter(a => a.status === 'Review Due').length },
    { name: 'Archived', value: assessments.filter(a => a.status === 'Archived').length },
  ].filter(d => d.value > 0);

  const riskLevelData = [
    { name: 'Low', value: assessments.filter(a => a.residualRisk?.level === 'Low').length },
    { name: 'Medium', value: assessments.filter(a => a.residualRisk?.level === 'Medium').length },
    { name: 'High', value: assessments.filter(a => a.residualRisk?.level === 'High').length },
    { name: 'Critical', value: assessments.filter(a => a.residualRisk?.level === 'Critical').length },
  ].filter(d => d.value > 0);

  const bbsTypeData = [
    { name: 'Safe Act', value: observations.filter(o => o.observationType === 'Safe Act').length },
    { name: 'Unsafe Act', value: observations.filter(o => o.observationType === 'Unsafe Act').length },
    { name: 'Unsafe Condition', value: observations.filter(o => o.observationType === 'Unsafe Condition').length },
  ].filter(d => d.value > 0);

  const incidentSeverityData = [
    { name: 'Near Miss', value: incidents.filter(i => i.severity === 'Near Miss').length },
    { name: 'Minor', value: incidents.filter(i => i.severity === 'Minor').length },
    { name: 'Major', value: incidents.filter(i => i.severity === 'Major').length },
    { name: 'Critical', value: incidents.filter(i => i.severity === 'Critical').length },
  ].filter(d => d.value > 0);

  const draStats = {
    total: dras.length,
    safe: dras.filter(d => d.isSafeToProceed).length,
    unsafe: dras.filter(d => !d.isSafeToProceed).length,
  };

  if (loading) return <div className="flex items-center justify-center h-full"><Loader2 className="animate-spin" /></div>;

  return (
    <div className="space-y-8 pb-12">
      {/* Top Stats */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard 
          title="Total Risk Assessments" 
          value={assessments.length} 
          icon={ShieldAlert} 
          color="blue" 
          trend="+5% vs last month" 
          isUp={true}
        />
        <StatCard 
          title="Total Incidents" 
          value={incidents.length} 
          icon={AlertTriangle} 
          color="red" 
          trend="-2 vs last month" 
          isUp={false}
        />
        <StatCard 
          title="BBS Participation" 
          value={observations.length} 
          icon={Eye} 
          color="amber" 
          trend="+12% vs last month" 
          isUp={true}
        />
        <StatCard 
          title="DRA Compliance" 
          value={dras.length > 0 ? `${Math.round((draStats.safe / dras.length) * 100)}%` : '0%'} 
          icon={Zap} 
          color="emerald" 
          trend="Safe to Proceed" 
          isUp={true}
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Risk Level Distribution */}
        <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
          <h3 className="text-lg font-bold text-gray-900 mb-6 flex items-center gap-2">
            <TrendingUp size={20} className="text-blue-600" /> Residual Risk Distribution
          </h3>
          <div className="h-80">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={riskLevelData}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} />
                <XAxis dataKey="name" />
                <YAxis />
                <Tooltip 
                  contentStyle={{ borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}
                />
                <Bar dataKey="value" radius={[4, 4, 0, 0]}>
                  {riskLevelData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={
                      entry.name === 'Low' ? '#10b981' :
                      entry.name === 'Medium' ? '#f59e0b' :
                      entry.name === 'High' ? '#ef4444' : '#7f1d1d'
                    } />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* BBS Observation Types */}
        <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
          <h3 className="text-lg font-bold text-gray-900 mb-6 flex items-center gap-2">
            <Eye size={20} className="text-amber-600" /> BBS Observation Trends
          </h3>
          <div className="h-80">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={bbsTypeData}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={100}
                  paddingAngle={5}
                  dataKey="value"
                >
                  {bbsTypeData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip />
                <Legend verticalAlign="bottom" height={36}/>
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Incident Severity */}
        <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
          <h3 className="text-lg font-bold text-gray-900 mb-6 flex items-center gap-2">
            <AlertTriangle size={20} className="text-red-600" /> Incident Severity
          </h3>
          <div className="h-80">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={incidentSeverityData}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} />
                <XAxis dataKey="name" />
                <YAxis />
                <Tooltip 
                  contentStyle={{ borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}
                />
                <Bar dataKey="value" radius={[4, 4, 0, 0]}>
                  {incidentSeverityData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={
                      entry.name === 'Near Miss' ? '#10b981' :
                      entry.name === 'Minor' ? '#f59e0b' :
                      entry.name === 'Major' ? '#ef4444' : '#7f1d1d'
                    } />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Assessment Status */}
        <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
          <h3 className="text-lg font-bold text-gray-900 mb-6 flex items-center gap-2">
            <CheckCircle size={20} className="text-emerald-600" /> Assessment Status
          </h3>
          <div className="h-80">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={statusData}>
                <defs>
                  <linearGradient id="colorValue" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.1}/>
                    <stop offset="95%" stopColor="#3b82f6" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" vertical={false} />
                <XAxis dataKey="name" />
                <YAxis />
                <Tooltip />
                <Area type="monotone" dataKey="value" stroke="#3b82f6" fillOpacity={1} fill="url(#colorValue)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* DRA Summary */}
        <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
          <h3 className="text-lg font-bold text-gray-900 mb-6 flex items-center gap-2">
            <Zap size={20} className="text-amber-500" /> Dynamic Risk Compliance
          </h3>
          <div className="space-y-6">
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-500">Total DRAs Logged</span>
              <span className="text-xl font-bold text-gray-900">{draStats.total}</span>
            </div>
            <div className="space-y-2">
              <div className="flex justify-between text-xs font-medium">
                <span className="text-emerald-600">Safe to Proceed</span>
                <span>{draStats.safe} ({draStats.total > 0 ? Math.round((draStats.safe / draStats.total) * 100) : 0}%)</span>
              </div>
              <div className="w-full bg-gray-100 rounded-full h-2">
                <div 
                  className="bg-emerald-500 h-2 rounded-full transition-all duration-500" 
                  style={{ width: `${draStats.total > 0 ? (draStats.safe / draStats.total) * 100 : 0}%` }}
                />
              </div>
            </div>
            <div className="space-y-2">
              <div className="flex justify-between text-xs font-medium">
                <span className="text-red-600">Unsafe / Stopped</span>
                <span>{draStats.unsafe} ({draStats.total > 0 ? Math.round((draStats.unsafe / draStats.total) * 100) : 0}%)</span>
              </div>
              <div className="w-full bg-gray-100 rounded-full h-2">
                <div 
                  className="bg-red-500 h-2 rounded-full transition-all duration-500" 
                  style={{ width: `${draStats.total > 0 ? (draStats.unsafe / draStats.total) * 100 : 0}%` }}
                />
              </div>
            </div>
            
            <div className="p-4 bg-blue-50 rounded-lg border border-blue-100 mt-4">
              <p className="text-xs text-blue-700 leading-relaxed">
                <strong>Insight:</strong> {draStats.unsafe > 0 
                  ? `There were ${draStats.unsafe} instances where work was stopped due to dynamic hazards. This indicates a strong safety culture of Stop Work Authority.`
                  : "All dynamic assessments resulted in safe conditions. Ensure workers are identifying all potential hazards in changing environments."}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function StatCard({ title, value, icon: Icon, color, trend, isUp }: any) {
  const colorClasses: any = {
    blue: 'bg-blue-50 text-blue-600 border-blue-100',
    red: 'bg-red-50 text-red-600 border-red-100',
    amber: 'bg-amber-50 text-amber-600 border-amber-100',
    emerald: 'bg-emerald-50 text-emerald-600 border-emerald-100',
  };

  return (
    <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
      <div className="flex justify-between items-start mb-4">
        <div className={`p-3 rounded-lg border ${colorClasses[color]}`}>
          <Icon size={24} />
        </div>
        <div className={`flex items-center gap-1 text-xs font-medium ${isUp ? 'text-emerald-600' : 'text-red-600'}`}>
          {isUp ? <ArrowUpRight size={14} /> : <ArrowDownRight size={14} />}
          {trend}
        </div>
      </div>
      <h3 className="text-sm font-medium text-gray-500 mb-1">{title}</h3>
      <p className="text-3xl font-bold text-gray-900">{value}</p>
    </div>
  );
}

function Loader2({ className }: { className?: string }) {
  return (
    <svg 
      className={`animate-spin ${className}`} 
      xmlns="http://www.w3.org/2000/svg" 
      fill="none" 
      viewBox="0 0 24 24"
    >
      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
    </svg>
  );
}
