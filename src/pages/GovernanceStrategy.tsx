import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy, doc, updateDoc } from 'firebase/firestore';
import { db, auth, handleFirestoreError } from '../lib/firebase';
import { 
  ShieldCheck, 
  Globe, 
  TrendingUp, 
  Plus, 
  AlertTriangle, 
  CheckCircle2, 
  Brain, 
  FileText, 
  Scale, 
  History,
  Target,
  BarChart3,
  Leaf,
  Droplets,
  Trash2,
  Users,
  Download,
  Calendar,
  Filter,
  Upload,
  Loader2,
  XCircle
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
import RiskActionPipeline from '../components/RiskActionPipeline';
import StrategicRiskRegister from '../components/StrategicRiskRegister';
import ManagementOfChange from '../components/ManagementOfChange';
import LegalRegister from '../components/LegalRegister';
import BowTieAnalysis from '../components/BowTieAnalysis';
import ESGReporting from './ESGReporting';
import ComplianceDocs from './ComplianceDocs';

interface EsgMetric {
  id: string;
  category: 'Scope 1' | 'Scope 2' | 'Scope 3' | 'Water' | 'Waste' | 'Diversity' | 'Training' | 'Board' | 'Ethics';
  value: number;
  unit: string;
  period: string;
  authorId: string;
  createdAt: string;
}

interface Risk {
  id: string;
  title: string;
  category: 'Strategic' | 'Operational' | 'Financial' | 'Compliance' | 'Reputational';
  inherentImpact: number;
  inherentLikelihood: number;
  residualImpact: number;
  residualLikelihood: number;
  status: 'Active' | 'Mitigated' | 'Archived';
  owner: string;
  createdAt: string;
}

export default function GovernanceStrategy() {
  const [activeTab, setActiveTab] = useState<'risk' | 'moc' | 'legal' | 'bowtie' | 'esg' | 'calculator' | 'pipeline' | 'compliance'>('risk');
  const [risks, setRisks] = useState<Risk[]>([]);
  const [metrics, setMetrics] = useState<EsgMetric[]>([]);
  const [isAddingMetric, setIsAddingMetric] = useState(false);
  const [isAnalyzing, setIsAnalyzing] = useState(false);

  // ESG Calculator State
  const [calcElectricity, setCalcElectricity] = useState(0);
  const [calcGas, setCalcGas] = useState(0);
  const [calcDiesel, setCalcDiesel] = useState(0);
  const [calcPetrol, setCalcPetrol] = useState(0);
  const [calcPeriod, setCalcPeriod] = useState(new Date().getFullYear().toString());

  useEffect(() => {
    if (!auth.currentUser) return;

    const qRisks = query(collection(db, 'enterprise_risks'), orderBy('createdAt', 'desc'));
    const unsubRisks = onSnapshot(qRisks, (snapshot) => {
      setRisks(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as Risk[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'enterprise_risks'));

    const qMetrics = query(collection(db, 'esg_metrics'), orderBy('createdAt', 'desc'));
    const unsubMetrics = onSnapshot(qMetrics, (snapshot) => {
      setMetrics(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as EsgMetric[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'esg_metrics'));

    return () => {
      unsubRisks();
      unsubMetrics();
    };
  }, []);

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

  const FACTORS = { electricity: 0.417, naturalGas: 2.02, diesel: 2.68, petrol: 2.31 };
  const calculatedScope1 = (calcGas * FACTORS.naturalGas + calcDiesel * FACTORS.diesel + calcPetrol * FACTORS.petrol) / 1000;
  const calculatedScope2 = (calcElectricity * FACTORS.electricity) / 1000;

  const emissions = metrics.filter(m => m.category.startsWith('Scope'));
  const totalEmissions = emissions.reduce((sum, m) => sum + m.value, 0);

  const tabs = [
    { id: 'risk', label: 'Strategic Risk', icon: ShieldCheck },
    { id: 'pipeline', label: 'Risk-to-Action', icon: TrendingUp },
    { id: 'moc', label: 'Management of Change', icon: History },
    { id: 'compliance', label: 'Compliance & Docs', icon: FileText },
    { id: 'bowtie', label: 'BowTie Analysis', icon: Target },
    { id: 'esg', label: 'ESG Reporting', icon: Globe },
  ];

  return (
    <div className="max-w-7xl mx-auto space-y-6">
      {/* ... (header remains the same) */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 flex items-center gap-2">
            Governance & Strategy <Globe size={24} className="text-blue-600" />
          </h1>
          <p className="text-slate-500">Integrated enterprise risk management and ESG performance tracking.</p>
        </div>
        <div className="flex gap-3">
          <button className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors shadow-sm">
            <Plus size={20} /> New Strategy Item
          </button>
        </div>
      </div>

      {/* Dashboard Summary */}
      {/* ... (summary cards remain the same) */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm flex items-center gap-4">
          <div className="w-12 h-12 bg-red-100 text-red-600 rounded-full flex items-center justify-center shrink-0">
            <AlertTriangle size={24} />
          </div>
          <div>
            <p className="text-xs font-bold text-slate-400 uppercase tracking-wider">Critical Risks</p>
            <p className="text-xl font-bold text-slate-900">{risks.filter(r => r.residualImpact * r.residualLikelihood >= 15).length}</p>
          </div>
        </div>
        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm flex items-center gap-4">
          <div className="w-12 h-12 bg-emerald-100 text-emerald-600 rounded-full flex items-center justify-center shrink-0">
            <Leaf size={24} />
          </div>
          <div>
            <p className="text-xs font-bold text-slate-400 uppercase tracking-wider">Total Emissions</p>
            <p className="text-xl font-bold text-slate-900">{totalEmissions.toFixed(1)} <span className="text-xs font-normal text-slate-500">tCO2e</span></p>
          </div>
        </div>
        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm flex items-center gap-4">
          <div className="w-12 h-12 bg-blue-100 text-blue-600 rounded-full flex items-center justify-center shrink-0">
            <Scale size={24} />
          </div>
          <div>
            <p className="text-xs font-bold text-slate-400 uppercase tracking-wider">Compliance Rate</p>
            <p className="text-xl font-bold text-slate-900">94.2%</p>
          </div>
        </div>
        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm flex items-center gap-4">
          <div className="w-12 h-12 bg-purple-100 text-purple-600 rounded-full flex items-center justify-center shrink-0">
            <Brain size={24} />
          </div>
          <div>
            <p className="text-xs font-bold text-slate-400 uppercase tracking-wider">AI Insights</p>
            <p className="text-xl font-bold text-slate-900">12 <span className="text-xs font-normal text-slate-500">Active</span></p>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex overflow-x-auto border-b border-slate-200 hide-scrollbar bg-white rounded-t-xl px-2">
        {tabs.map(tab => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id as any)}
            className={`flex items-center gap-2 px-6 py-4 border-b-2 font-bold text-sm whitespace-nowrap transition-colors ${
              activeTab === tab.id ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
            }`}
          >
            <tab.icon size={18} />
            {tab.label}
          </button>
        ))}
      </div>

      <div className="bg-white rounded-b-xl shadow-sm border-x border-b border-slate-200 overflow-hidden min-h-[600px]">
        {activeTab === 'risk' && <div className="p-6"><StrategicRiskRegister /></div>}
        {activeTab === 'pipeline' && <RiskActionPipeline />}
        {activeTab === 'moc' && <div className="p-6"><ManagementOfChange /></div>}
        {activeTab === 'compliance' && <div className="p-6"><ComplianceDocs /></div>}
        {activeTab === 'bowtie' && <div className="p-6"><BowTieAnalysis /></div>}
        
        {activeTab === 'esg' && (
          <div className="p-6">
            <ESGReporting />
          </div>
        )}
      </div>
    </div>
  );
}
