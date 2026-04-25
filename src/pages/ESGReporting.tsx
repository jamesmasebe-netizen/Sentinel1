import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy, doc, updateDoc, where } from 'firebase/firestore';
import { db, auth, handleFirestoreError } from '../lib/firebase';
import { useAuth } from '../contexts/AuthContext';
import { 
  Leaf, 
  BarChart3, 
  Droplets, 
  Trash2, 
  Plus, 
  XCircle, 
  TrendingUp,
  Globe,
  Users,
  ShieldCheck,
  FileText,
  Download,
  Calendar,
  Filter,
  Brain,
  Upload,
  Loader2
} from 'lucide-react';
import { Type } from "@google/genai";
import { getGeminiClient } from '../lib/gemini';
import { 
  BarChart, 
  Bar, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer, 
  Legend,
  PieChart,
  Pie,
  Cell,
  LineChart,
  Line
} from 'recharts';

interface EsgMetric {
  id: string;
  category: 'Scope 1' | 'Scope 2' | 'Scope 3' | 'Water' | 'Waste' | 'Diversity' | 'Training' | 'Board' | 'Ethics';
  value: number;
  unit: string;
  period: string;
  authorId: string;
  createdAt: string;
}

export default function ESGReporting() {
  const { profile } = useAuth();
  const [activeTab, setActiveTab] = useState<'emissions' | 'water_waste' | 'social' | 'governance' | 'reports' | 'calculator'>('emissions');
  const [metrics, setMetrics] = useState<EsgMetric[]>([]);
  const [isAddingMetric, setIsAddingMetric] = useState(false);

  // Form State
  const [category, setCategory] = useState<EsgMetric['category']>('Scope 1');
  const [value, setValue] = useState(0);
  const [unit, setUnit] = useState('tCO2e');
  const [period, setPeriod] = useState(new Date().getFullYear().toString());

  useEffect(() => {
    if (!profile?.siteId) return;

    const qMetrics = query(collection(db, 'esg_metrics'), where('siteId', '==', profile.siteId), orderBy('createdAt', 'desc'));
    const unsubMetrics = onSnapshot(qMetrics, (snapshot) => {
      setMetrics(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as EsgMetric[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'esg_metrics'));

    return () => unsubMetrics();
  }, [profile?.siteId]);

  const handleAddMetric = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      await addDoc(collection(db, 'esg_metrics'), {
        category,
        value: Number(value),
        unit,
        period,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAddingMetric(false);
      setCategory('Scope 1'); setValue(0); setUnit('tCO2e'); setPeriod('');
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'esg_metrics');
    }
  };

  const emissions = metrics.filter(m => m.category.startsWith('Scope'));
  const waterWaste = metrics.filter(m => m.category === 'Water' || m.category === 'Waste');
  const social = metrics.filter(m => m.category === 'Diversity' || m.category === 'Training');
  const governance = metrics.filter(m => m.category === 'Board' || m.category === 'Ethics');
  
  // Calculator State
  const [calcElectricity, setCalcElectricity] = useState(0);
  const [calcGas, setCalcGas] = useState(0);
  const [calcDiesel, setCalcDiesel] = useState(0);
  const [calcPetrol, setCalcPetrol] = useState(0);
  const [calcPeriod, setCalcPeriod] = useState(new Date().getFullYear().toString());
  const [isAnalyzing, setIsAnalyzing] = useState(false);

  const handleBillUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setIsAnalyzing(true);
    try {
      const reader = new FileReader();
      reader.onloadend = async () => {
        const base64Data = (reader.result as string).split(',')[1];
        await extractDataFromBill(base64Data, file.type);
      };
      reader.readAsDataURL(file);
    } catch (error) {
      console.error("Error reading file:", error);
      setIsAnalyzing(false);
    }
  };

  const extractDataFromBill = async (base64Data: string, mimeType: string) => {
    try {
      const ai = getGeminiClient();
      const response = await ai.models.generateContent({
        model: "gemini-3-flash-preview",
        contents: [
          {
            inlineData: {
              data: base64Data,
              mimeType: mimeType
            }
          },
          {
            text: "Analyze this utility bill and extract the usage values for electricity (kWh), natural gas (m3), diesel (liters), and petrol (liters). Also extract the billing period or year if available. Return the data in JSON format."
          }
        ],
        config: {
          responseMimeType: "application/json",
          responseSchema: {
            type: Type.OBJECT,
            properties: {
              electricity: { type: Type.NUMBER, description: "Electricity usage in kWh" },
              naturalGas: { type: Type.NUMBER, description: "Natural gas usage in m3" },
              diesel: { type: Type.NUMBER, description: "Diesel usage in liters" },
              petrol: { type: Type.NUMBER, description: "Petrol usage in liters" },
              period: { type: Type.STRING, description: "Billing period or year" }
            }
          }
        }
      });

      const result = JSON.parse(response.text || '{}');
      if (result.electricity) setCalcElectricity(result.electricity);
      if (result.naturalGas) setCalcGas(result.naturalGas);
      if (result.diesel) setCalcDiesel(result.diesel);
      if (result.petrol) setCalcPetrol(result.petrol);
      if (result.period) setCalcPeriod(result.period);
      
      alert("AI Analysis Complete: Data extracted successfully!");
    } catch (error) {
      console.error("AI Extraction Error:", error);
      alert("Failed to extract data from bill. Please enter manually.");
    } finally {
      setIsAnalyzing(false);
    }
  };

  // Emission Factors (kg CO2e per unit)
  const FACTORS = {
    electricity: 0.417, // per kWh
    naturalGas: 2.02,   // per m3
    diesel: 2.68,       // per liter
    petrol: 2.31        // per liter
  };

  const calculatedScope1 = (calcGas * FACTORS.naturalGas + calcDiesel * FACTORS.diesel + calcPetrol * FACTORS.petrol) / 1000; // to tCO2e
  const calculatedScope2 = (calcElectricity * FACTORS.electricity) / 1000; // to tCO2e

  const handleSaveCalculated = async (scope: 'Scope 1' | 'Scope 2', value: number) => {
    if (!auth.currentUser || value <= 0) return;
    try {
      await addDoc(collection(db, 'esg_metrics'), {
        category: scope,
        value: Number(value.toFixed(2)),
        unit: 'tCO2e',
        period: calcPeriod,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      alert(`${scope} metric saved successfully!`);
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'esg_metrics');
    }
  };

  // Chart Data Preparation
  const emissionsData = Array.from(new Set(emissions.map(m => m.period))).sort().map(p => {
    const pMetrics = emissions.filter(m => m.period === p);
    return {
      period: p,
      'Scope 1': pMetrics.filter(m => m.category === 'Scope 1').reduce((sum, m) => sum + m.value, 0),
      'Scope 2': pMetrics.filter(m => m.category === 'Scope 2').reduce((sum, m) => sum + m.value, 0),
      'Scope 3': pMetrics.filter(m => m.category === 'Scope 3').reduce((sum, m) => sum + m.value, 0),
    };
  });

  const waterWasteData = Array.from(new Set(waterWaste.map(m => m.period))).sort().map(p => {
    const pMetrics = waterWaste.filter(m => m.period === p);
    return {
      period: p,
      'Water': pMetrics.filter(m => m.category === 'Water').reduce((sum, m) => sum + m.value, 0),
      'Waste': pMetrics.filter(m => m.category === 'Waste').reduce((sum, m) => sum + m.value, 0),
    };
  });

  // Calculate totals
  const totalScope1 = emissions.filter(m => m.category === 'Scope 1').reduce((sum, m) => sum + m.value, 0);
  const totalScope2 = emissions.filter(m => m.category === 'Scope 2').reduce((sum, m) => sum + m.value, 0);
  const totalScope3 = emissions.filter(m => m.category === 'Scope 3').reduce((sum, m) => sum + m.value, 0);
  const totalEmissions = totalScope1 + totalScope2 + totalScope3;

  const COLORS = ['#10b981', '#3b82f6', '#8b5cf6', '#f59e0b', '#ef4444'];

  return (
    <div className="space-y-6 pb-12">
      <div className="flex justify-end gap-3">
        <button onClick={() => setIsAddingMetric(true)} className="flex items-center gap-2 bg-emerald-600 text-white px-4 py-2 rounded-lg hover:bg-emerald-700 transition-colors shadow-sm">
          <Plus size={20} /> Log ESG Metric
        </button>
      </div>

      {/* Dashboard Summary */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm flex items-center gap-4">
          <div className="w-12 h-12 bg-emerald-100 text-emerald-600 rounded-full flex items-center justify-center shrink-0">
            <Leaf size={24} />
          </div>
          <div>
            <p className="text-xs font-bold text-slate-400 uppercase tracking-wider">Total Emissions</p>
            <p className="text-xl font-bold text-slate-900">{totalEmissions.toLocaleString()} <span className="text-xs font-normal text-slate-500">tCO2e</span></p>
          </div>
        </div>
        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm flex items-center gap-4">
          <div className="w-12 h-12 bg-blue-100 text-blue-600 rounded-full flex items-center justify-center shrink-0">
            <Droplets size={24} />
          </div>
          <div>
            <p className="text-xs font-bold text-slate-400 uppercase tracking-wider">Water Consumed</p>
            <p className="text-xl font-bold text-slate-900">
              {waterWaste.filter(m => m.category === 'Water').reduce((sum, m) => sum + m.value, 0).toLocaleString()} <span className="text-xs font-normal text-slate-500">kL</span>
            </p>
          </div>
        </div>
        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm flex items-center gap-4">
          <div className="w-12 h-12 bg-purple-100 text-purple-600 rounded-full flex items-center justify-center shrink-0">
            <Users size={24} />
          </div>
          <div>
            <p className="text-xs font-bold text-slate-400 uppercase tracking-wider">Social Impact</p>
            <p className="text-xl font-bold text-slate-900">
              {social.length} <span className="text-xs font-normal text-slate-500">Metrics</span>
            </p>
          </div>
        </div>
        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm flex items-center gap-4">
          <div className="w-12 h-12 bg-slate-100 text-slate-600 rounded-full flex items-center justify-center shrink-0">
            <ShieldCheck size={24} />
          </div>
          <div>
            <p className="text-xs font-bold text-slate-400 uppercase tracking-wider">Governance</p>
            <p className="text-xl font-bold text-slate-900">
              {governance.length} <span className="text-xs font-normal text-slate-500">Metrics</span>
            </p>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex overflow-x-auto border-b border-slate-200 hide-scrollbar bg-white rounded-t-xl px-2">
        <button
          onClick={() => setActiveTab('emissions')}
          className={`flex items-center gap-2 px-6 py-4 border-b-2 font-bold text-sm whitespace-nowrap transition-colors ${
            activeTab === 'emissions' ? 'border-emerald-600 text-emerald-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Leaf size={18} />
          Carbon Footprint
        </button>
        <button
          onClick={() => setActiveTab('water_waste')}
          className={`flex items-center gap-2 px-6 py-4 border-b-2 font-bold text-sm whitespace-nowrap transition-colors ${
            activeTab === 'water_waste' ? 'border-emerald-600 text-emerald-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Droplets size={18} />
          Water & Waste
        </button>
        <button
          onClick={() => setActiveTab('social')}
          className={`flex items-center gap-2 px-6 py-4 border-b-2 font-bold text-sm whitespace-nowrap transition-colors ${
            activeTab === 'social' ? 'border-emerald-600 text-emerald-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Users size={18} />
          Social
        </button>
        <button
          onClick={() => setActiveTab('governance')}
          className={`flex items-center gap-2 px-6 py-4 border-b-2 font-bold text-sm whitespace-nowrap transition-colors ${
            activeTab === 'governance' ? 'border-emerald-600 text-emerald-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <ShieldCheck size={18} />
          Governance
        </button>
        <button
          onClick={() => setActiveTab('calculator')}
          className={`flex items-center gap-2 px-6 py-4 border-b-2 font-bold text-sm whitespace-nowrap transition-colors ${
            activeTab === 'calculator' ? 'border-emerald-600 text-emerald-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <TrendingUp size={18} />
          Carbon Calculator
        </button>
        <button
          onClick={() => setActiveTab('reports')}
          className={`flex items-center gap-2 px-6 py-4 border-b-2 font-bold text-sm whitespace-nowrap transition-colors ${
            activeTab === 'reports' ? 'border-emerald-600 text-emerald-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <TrendingUp size={18} />
          Reporting
        </button>
      </div>

      {/* Content Area */}
      <div className="bg-white rounded-b-xl shadow-sm border-x border-b border-slate-200 overflow-hidden min-h-[500px]">
        
        {/* Emissions Tab */}
        {activeTab === 'emissions' && (
          <div className="p-6 space-y-8">
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
              <div className="bg-slate-50 p-6 rounded-xl border border-slate-100">
                <h3 className="text-sm font-bold text-slate-900 mb-6 flex items-center gap-2">
                  <BarChart3 size={18} className="text-emerald-600" /> Emissions Trend by Period
                </h3>
                <div className="h-64 w-full">
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={emissionsData}>
                      <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e2e8f0" />
                      <XAxis dataKey="period" stroke="#64748b" fontSize={12} tickLine={false} axisLine={false} />
                      <YAxis stroke="#64748b" fontSize={12} tickLine={false} axisLine={false} />
                      <Tooltip 
                        contentStyle={{ backgroundColor: '#fff', borderRadius: '8px', border: '1px solid #e2e8f0', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}
                      />
                      <Legend iconType="circle" wrapperStyle={{ paddingTop: '20px' }} />
                      <Bar dataKey="Scope 1" fill="#10b981" radius={[4, 4, 0, 0]} />
                      <Bar dataKey="Scope 2" fill="#3b82f6" radius={[4, 4, 0, 0]} />
                      <Bar dataKey="Scope 3" fill="#8b5cf6" radius={[4, 4, 0, 0]} />
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              </div>

              <div className="bg-slate-50 p-6 rounded-xl border border-slate-100">
                <h3 className="text-sm font-bold text-slate-900 mb-6 flex items-center gap-2">
                  <Leaf size={18} className="text-emerald-600" /> Emissions Breakdown (Total)
                </h3>
                <div className="h-64 w-full">
                  <ResponsiveContainer width="100%" height="100%">
                    <PieChart>
                      <Pie
                        data={[
                          { name: 'Scope 1', value: totalScope1 },
                          { name: 'Scope 2', value: totalScope2 },
                          { name: 'Scope 3', value: totalScope3 },
                        ]}
                        cx="50%"
                        cy="50%"
                        innerRadius={60}
                        outerRadius={80}
                        paddingAngle={5}
                        dataKey="value"
                      >
                        {emissionsData.map((entry, index) => (
                          <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                        ))}
                      </Pie>
                      <Tooltip />
                      <Legend verticalAlign="bottom" height={36}/>
                    </PieChart>
                  </ResponsiveContainer>
                </div>
              </div>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 text-sm">
                    <th className="p-4 font-medium">Period</th>
                    <th className="p-4 font-medium">Category</th>
                    <th className="p-4 font-medium">Value</th>
                    <th className="p-4 font-medium">Unit</th>
                    <th className="p-4 font-medium">Logged On</th>
                  </tr>
                </thead>
                <tbody>
                  {emissions.length === 0 ? (
                    <tr><td colSpan={5} className="p-8 text-center text-slate-500">No emissions logged yet.</td></tr>
                  ) : (
                    emissions.map((metric) => (
                      <tr key={metric.id} className="border-b border-slate-100 hover:bg-slate-50 transition-colors">
                        <td className="p-4 font-medium text-slate-900">{metric.period}</td>
                        <td className="p-4">
                          <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                            metric.category === 'Scope 1' ? 'bg-emerald-100 text-emerald-700' :
                            metric.category === 'Scope 2' ? 'bg-blue-100 text-blue-700' :
                            'bg-purple-100 text-purple-700'
                          }`}>
                            {metric.category}
                          </span>
                        </td>
                        <td className="p-4 text-slate-900 font-mono font-bold">{metric.value.toLocaleString()}</td>
                        <td className="p-4 text-slate-500 text-xs">{metric.unit}</td>
                        <td className="p-4 text-slate-500 text-sm">{new Date(metric.createdAt).toLocaleDateString()}</td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* Water & Waste Tab */}
        {activeTab === 'water_waste' && (
          <div className="p-6 space-y-8">
            <div className="bg-slate-50 p-6 rounded-xl border border-slate-100">
              <h3 className="text-sm font-bold text-slate-900 mb-6 flex items-center gap-2">
                <Droplets size={18} className="text-blue-600" /> Usage Trends
              </h3>
              <div className="h-64 w-full">
                <ResponsiveContainer width="100%" height="100%">
                  <LineChart data={waterWasteData}>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e2e8f0" />
                    <XAxis dataKey="period" stroke="#64748b" fontSize={12} tickLine={false} axisLine={false} />
                    <YAxis stroke="#64748b" fontSize={12} tickLine={false} axisLine={false} />
                    <Tooltip />
                    <Legend />
                    <Line type="monotone" dataKey="Water" stroke="#3b82f6" strokeWidth={2} dot={{ r: 4 }} />
                    <Line type="monotone" dataKey="Waste" stroke="#f59e0b" strokeWidth={2} dot={{ r: 4 }} />
                  </LineChart>
                </ResponsiveContainer>
              </div>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 text-sm">
                    <th className="p-4 font-medium">Period</th>
                    <th className="p-4 font-medium">Category</th>
                    <th className="p-4 font-medium">Value</th>
                    <th className="p-4 font-medium">Unit</th>
                    <th className="p-4 font-medium">Logged On</th>
                  </tr>
                </thead>
                <tbody>
                  {waterWaste.length === 0 ? (
                    <tr><td colSpan={5} className="p-8 text-center text-slate-500">No water/waste metrics logged yet.</td></tr>
                  ) : (
                    waterWaste.map((metric) => (
                      <tr key={metric.id} className="border-b border-slate-100 hover:bg-slate-50 transition-colors">
                        <td className="p-4 font-medium text-slate-900">{metric.period}</td>
                        <td className="p-4">
                          <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                            metric.category === 'Water' ? 'bg-blue-100 text-blue-700' : 'bg-amber-100 text-amber-700'
                          }`}>
                            {metric.category}
                          </span>
                        </td>
                        <td className="p-4 text-slate-900 font-mono font-bold">{metric.value.toLocaleString()}</td>
                        <td className="p-4 text-slate-500 text-xs">{metric.unit}</td>
                        <td className="p-4 text-slate-500 text-sm">{new Date(metric.createdAt).toLocaleDateString()}</td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* Social Tab */}
        {activeTab === 'social' && (
          <div className="p-6 space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="bg-purple-50 p-6 rounded-xl border border-purple-100">
                <h3 className="text-sm font-bold text-purple-900 mb-4 flex items-center gap-2">
                  <Users size={18} /> Social Metrics Summary
                </h3>
                <div className="space-y-4">
                  <div className="flex justify-between items-center bg-white p-3 rounded-lg shadow-sm">
                    <span className="text-sm text-slate-600">Gender Diversity (Board)</span>
                    <span className="font-bold text-purple-700">42%</span>
                  </div>
                  <div className="flex justify-between items-center bg-white p-3 rounded-lg shadow-sm">
                    <span className="text-sm text-slate-600">Avg. Training Hours / Employee</span>
                    <span className="font-bold text-purple-700">28.5 hrs</span>
                  </div>
                  <div className="flex justify-between items-center bg-white p-3 rounded-lg shadow-sm">
                    <span className="text-sm text-slate-600">Employee Turnover Rate</span>
                    <span className="font-bold text-purple-700">8.2%</span>
                  </div>
                </div>
              </div>
              <div className="bg-slate-50 p-6 rounded-xl border border-slate-200 flex flex-col justify-center items-center text-center">
                <Users size={48} className="text-slate-300 mb-4" />
                <h4 className="font-bold text-slate-900 mb-2">Social Responsibility</h4>
                <p className="text-sm text-slate-500 max-w-xs">Track diversity, equity, inclusion, and employee development metrics.</p>
              </div>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 text-sm">
                    <th className="p-4 font-medium">Period</th>
                    <th className="p-4 font-medium">Category</th>
                    <th className="p-4 font-medium">Value</th>
                    <th className="p-4 font-medium">Unit</th>
                    <th className="p-4 font-medium">Logged On</th>
                  </tr>
                </thead>
                <tbody>
                  {social.length === 0 ? (
                    <tr><td colSpan={5} className="p-8 text-center text-slate-500">No social metrics logged yet.</td></tr>
                  ) : (
                    social.map((metric) => (
                      <tr key={metric.id} className="border-b border-slate-100 hover:bg-slate-50 transition-colors">
                        <td className="p-4 font-medium text-slate-900">{metric.period}</td>
                        <td className="p-4">
                          <span className="px-2 py-1 rounded-full text-xs font-medium bg-purple-100 text-purple-700">
                            {metric.category}
                          </span>
                        </td>
                        <td className="p-4 text-slate-900 font-mono font-bold">{metric.value.toLocaleString()}</td>
                        <td className="p-4 text-slate-500 text-xs">{metric.unit}</td>
                        <td className="p-4 text-slate-500 text-sm">{new Date(metric.createdAt).toLocaleDateString()}</td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* Governance Tab */}
        {activeTab === 'governance' && (
          <div className="p-6 space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm">
                <ShieldCheck size={32} className="text-slate-400 mb-4" />
                <h4 className="font-bold text-slate-900 mb-1">Board Composition</h4>
                <p className="text-xs text-slate-500">Independence and diversity of the board of directors.</p>
              </div>
              <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm">
                <FileText size={32} className="text-slate-400 mb-4" />
                <h4 className="font-bold text-slate-900 mb-1">Ethics & Compliance</h4>
                <p className="text-xs text-slate-500">Whistleblower reports and anti-corruption training completion.</p>
              </div>
              <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm">
                <Globe size={32} className="text-slate-400 mb-4" />
                <h4 className="font-bold text-slate-900 mb-1">Executive Pay</h4>
                <p className="text-xs text-slate-500">Alignment of executive compensation with ESG targets.</p>
              </div>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 text-sm">
                    <th className="p-4 font-medium">Period</th>
                    <th className="p-4 font-medium">Category</th>
                    <th className="p-4 font-medium">Value</th>
                    <th className="p-4 font-medium">Unit</th>
                    <th className="p-4 font-medium">Logged On</th>
                  </tr>
                </thead>
                <tbody>
                  {governance.length === 0 ? (
                    <tr><td colSpan={5} className="p-8 text-center text-slate-500">No governance metrics logged yet.</td></tr>
                  ) : (
                    governance.map((metric) => (
                      <tr key={metric.id} className="border-b border-slate-100 hover:bg-slate-50 transition-colors">
                        <td className="p-4 font-medium text-slate-900">{metric.period}</td>
                        <td className="p-4">
                          <span className="px-2 py-1 rounded-full text-xs font-medium bg-slate-100 text-slate-700">
                            {metric.category}
                          </span>
                        </td>
                        <td className="p-4 text-slate-900 font-mono font-bold">{metric.value.toLocaleString()}</td>
                        <td className="p-4 text-slate-500 text-xs">{metric.unit}</td>
                        <td className="p-4 text-slate-500 text-sm">{new Date(metric.createdAt).toLocaleDateString()}</td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* Carbon Calculator Tab */}
        {activeTab === 'calculator' && (
          <div className="p-6 space-y-8">
            {/* AI Bill Upload Section */}
            <div className="bg-gradient-to-r from-emerald-50 to-blue-50 p-6 rounded-xl border border-emerald-100 flex flex-col md:flex-row items-center justify-between gap-6">
              <div className="flex items-center gap-4">
                <div className="w-12 h-12 bg-white rounded-full flex items-center justify-center shadow-sm text-emerald-600">
                  <Brain size={28} />
                </div>
                <div>
                  <h3 className="font-bold text-slate-900">Smart Bill Extraction</h3>
                  <p className="text-sm text-slate-500">Upload a utility bill (PDF/Image) and let AI extract the usage data for you.</p>
                </div>
              </div>
              <div className="shrink-0">
                <label className={`flex items-center gap-2 px-6 py-3 rounded-lg font-bold transition-all cursor-pointer shadow-sm ${
                  isAnalyzing ? 'bg-slate-100 text-slate-400 cursor-not-allowed' : 'bg-white text-emerald-600 hover:bg-emerald-50 border border-emerald-200'
                }`}>
                  {isAnalyzing ? (
                    <>
                      <Loader2 size={20} className="animate-spin" />
                      Analyzing Bill...
                    </>
                  ) : (
                    <>
                      <Upload size={20} />
                      Upload Utility Bill
                    </>
                  )}
                  <input 
                    type="file" 
                    className="hidden" 
                    accept="image/*,application/pdf" 
                    onChange={handleBillUpload}
                    disabled={isAnalyzing}
                  />
                </label>
              </div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
              <div className="lg:col-span-2 space-y-6">
                <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm">
                  <h3 className="text-lg font-bold text-slate-900 mb-6 flex items-center gap-2">
                    <TrendingUp size={20} className="text-emerald-600" /> Utility-Based Carbon Calculator
                  </h3>
                  
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div className="space-y-4">
                      <h4 className="text-sm font-bold text-slate-700 uppercase tracking-wider border-b pb-2">Electricity (Scope 2)</h4>
                      <div>
                        <label className="block text-xs font-medium text-slate-500 mb-1">Electricity Usage (kWh)</label>
                        <input 
                          type="number" 
                          value={calcElectricity} 
                          onChange={e => setCalcElectricity(Number(e.target.value))}
                          className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-emerald-500"
                          placeholder="0"
                        />
                      </div>
                    </div>

                    <div className="space-y-4">
                      <h4 className="text-sm font-bold text-slate-700 uppercase tracking-wider border-b pb-2">Direct Fuels (Scope 1)</h4>
                      <div>
                        <label className="block text-xs font-medium text-slate-500 mb-1">Natural Gas (m³)</label>
                        <input 
                          type="number" 
                          value={calcGas} 
                          onChange={e => setCalcGas(Number(e.target.value))}
                          className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-emerald-500"
                          placeholder="0"
                        />
                      </div>
                      <div>
                        <label className="block text-xs font-medium text-slate-500 mb-1">Diesel (Liters)</label>
                        <input 
                          type="number" 
                          value={calcDiesel} 
                          onChange={e => setCalcDiesel(Number(e.target.value))}
                          className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-emerald-500"
                          placeholder="0"
                        />
                      </div>
                      <div>
                        <label className="block text-xs font-medium text-slate-500 mb-1">Petrol (Liters)</label>
                        <input 
                          type="number" 
                          value={calcPetrol} 
                          onChange={e => setCalcPetrol(Number(e.target.value))}
                          className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-emerald-500"
                          placeholder="0"
                        />
                      </div>
                    </div>
                  </div>

                  <div className="mt-8 pt-6 border-t border-slate-100">
                    <label className="block text-sm font-medium text-slate-700 mb-2 flex items-center gap-2">
                      <Calendar size={16} /> Calculation Period
                    </label>
                    <input 
                      type="text" 
                      value={calcPeriod} 
                      onChange={e => setCalcPeriod(e.target.value)}
                      className="w-full md:w-1/3 p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-emerald-500"
                      placeholder="e.g. 2024"
                    />
                  </div>
                </div>
              </div>

              <div className="space-y-6">
                <div className="bg-emerald-900 text-white p-6 rounded-xl shadow-lg">
                  <h3 className="text-lg font-bold mb-6 flex items-center gap-2">
                    <Leaf size={20} /> Estimated Footprint
                  </h3>
                  
                  <div className="space-y-6">
                    <div className="pb-4 border-b border-emerald-800">
                      <p className="text-emerald-300 text-xs uppercase font-bold tracking-widest mb-1">Scope 1 (Direct)</p>
                      <div className="flex items-baseline gap-2">
                        <span className="text-3xl font-bold">{calculatedScope1.toFixed(3)}</span>
                        <span className="text-emerald-400 text-sm">tCO2e</span>
                      </div>
                      <button 
                        onClick={() => handleSaveCalculated('Scope 1', calculatedScope1)}
                        className="mt-3 text-xs bg-emerald-800 hover:bg-emerald-700 text-white px-3 py-1.5 rounded-md transition-colors flex items-center gap-1"
                      >
                        <Plus size={12} /> Save to Metrics
                      </button>
                    </div>

                    <div className="pb-4 border-b border-emerald-800">
                      <p className="text-emerald-300 text-xs uppercase font-bold tracking-widest mb-1">Scope 2 (Indirect)</p>
                      <div className="flex items-baseline gap-2">
                        <span className="text-3xl font-bold">{calculatedScope2.toFixed(3)}</span>
                        <span className="text-emerald-400 text-sm">tCO2e</span>
                      </div>
                      <button 
                        onClick={() => handleSaveCalculated('Scope 2', calculatedScope2)}
                        className="mt-3 text-xs bg-emerald-800 hover:bg-emerald-700 text-white px-3 py-1.5 rounded-md transition-colors flex items-center gap-1"
                      >
                        <Plus size={12} /> Save to Metrics
                      </button>
                    </div>

                    <div>
                      <p className="text-emerald-300 text-xs uppercase font-bold tracking-widest mb-1">Total Impact</p>
                      <div className="flex items-baseline gap-2">
                        <span className="text-4xl font-black text-emerald-400">{(calculatedScope1 + calculatedScope2).toFixed(3)}</span>
                        <span className="text-emerald-400 text-sm font-bold">tCO2e</span>
                      </div>
                    </div>
                  </div>
                </div>

                <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm">
                  <h4 className="text-sm font-bold text-slate-900 mb-3 flex items-center gap-2">
                    <Globe size={16} className="text-blue-500" /> Methodology
                  </h4>
                  <p className="text-xs text-slate-500 leading-relaxed">
                    Calculations are based on standard emission factors (DEFRA/EPA averages). 
                    Factors used: 
                    <br/>• Electricity: {FACTORS.electricity} kg/kWh
                    <br/>• Gas: {FACTORS.naturalGas} kg/m³
                    <br/>• Diesel: {FACTORS.diesel} kg/L
                    <br/>• Petrol: {FACTORS.petrol} kg/L
                  </p>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Reports Tab */}
        {activeTab === 'reports' && (
          <div className="p-6 bg-slate-50">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
              <div className="bg-white p-8 rounded-xl border border-slate-200 shadow-sm text-center">
                <Globe size={48} className="mx-auto text-emerald-200 mb-4" />
                <h3 className="text-xl font-bold text-slate-900 mb-2">Sustainability Report</h3>
                <p className="text-slate-500 mb-6 text-sm">
                  Compile all Scope 1, 2, 3 emissions, water usage, and waste generation into a board-ready sustainability report aligned with GRI standards.
                </p>
                <button className="w-full bg-emerald-600 text-white px-6 py-3 rounded-lg font-bold hover:bg-emerald-700 transition-colors shadow-sm flex items-center justify-center gap-2">
                  <Download size={20} /> Generate Annual Report (PDF)
                </button>
              </div>

              <div className="bg-white p-8 rounded-xl border border-slate-200 shadow-sm">
                <h3 className="text-lg font-bold text-slate-900 mb-4">Recent Reports</h3>
                <div className="space-y-3">
                  <div className="flex items-center justify-between p-3 bg-slate-50 rounded-lg border border-slate-100">
                    <div className="flex items-center gap-3">
                      <div className="p-2 bg-red-100 text-red-600 rounded">
                        <FileText size={18} />
                      </div>
                      <div>
                        <p className="text-sm font-bold text-slate-900">ESG_Report_2024_Q1.pdf</p>
                        <p className="text-xs text-slate-500">Generated on 2024-04-01</p>
                      </div>
                    </div>
                    <button className="text-slate-400 hover:text-emerald-600"><Download size={18} /></button>
                  </div>
                  <div className="flex items-center justify-between p-3 bg-slate-50 rounded-lg border border-slate-100">
                    <div className="flex items-center gap-3">
                      <div className="p-2 bg-red-100 text-red-600 rounded">
                        <FileText size={18} />
                      </div>
                      <div>
                        <p className="text-sm font-bold text-slate-900">Sustainability_Annual_2023.pdf</p>
                        <p className="text-xs text-slate-500">Generated on 2024-01-15</p>
                      </div>
                    </div>
                    <button className="text-slate-400 hover:text-emerald-600"><Download size={18} /></button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Add Metric Modal */}
      {isAddingMetric && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex justify-between items-center">
              <h2 className="text-xl font-bold text-slate-900">Log ESG Metric</h2>
              <button onClick={() => setIsAddingMetric(false)} className="text-slate-400 hover:text-slate-600"><XCircle size={24} /></button>
            </div>
            <form onSubmit={handleAddMetric} className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Category</label>
                <select required value={category} onChange={e => {
                  const newCat = e.target.value as any;
                  setCategory(newCat);
                  if (newCat.startsWith('Scope')) setUnit('tCO2e');
                  else if (newCat === 'Water') setUnit('kL');
                  else if (newCat === 'Waste') setUnit('tons');
                  else if (newCat === 'Diversity') setUnit('%');
                  else if (newCat === 'Training') setUnit('hrs/emp');
                  else if (newCat === 'Board') setUnit('% Independent');
                  else if (newCat === 'Ethics') setUnit('% Completion');
                }} className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-emerald-500">
                  <optgroup label="Environmental">
                    <option value="Scope 1">Scope 1 (Direct Emissions)</option>
                    <option value="Scope 2">Scope 2 (Indirect - Electricity)</option>
                    <option value="Scope 3">Scope 3 (Value Chain)</option>
                    <option value="Water">Water Consumption</option>
                    <option value="Waste">Waste Generation</option>
                  </optgroup>
                  <optgroup label="Social">
                    <option value="Diversity">Gender Diversity (%)</option>
                    <option value="Training">Training Hours</option>
                  </optgroup>
                  <optgroup label="Governance">
                    <option value="Board">Board Independence (%)</option>
                    <option value="Ethics">Ethics Training (%)</option>
                  </optgroup>
                </select>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Value</label>
                  <input type="number" step="0.01" min="0" required value={value} onChange={e => setValue(Number(e.target.value))} className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-emerald-500" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Unit</label>
                  <input type="text" required value={unit} onChange={e => setUnit(e.target.value)} className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-emerald-500 bg-slate-50" />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1 flex items-center gap-2">
                  <Calendar size={14} /> Period (e.g., 2024, Q1 2024)
                </label>
                <input type="text" required value={period} onChange={e => setPeriod(e.target.value)} placeholder="2024" className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-emerald-500" />
              </div>
              <div className="pt-4 flex justify-end gap-3">
                <button type="button" onClick={() => setIsAddingMetric(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg">Cancel</button>
                <button type="submit" className="px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 font-bold shadow-sm">Save Metric</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
