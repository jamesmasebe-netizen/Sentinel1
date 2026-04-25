import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy, doc, updateDoc, deleteDoc, where, limit } from 'firebase/firestore';
import { db, auth, handleFirestoreError } from '../lib/firebase';
import { useAuth } from '../contexts/AuthContext';
import { 
  Truck, 
  Settings, 
  AlertTriangle, 
  CheckSquare, 
  QrCode, 
  Search, 
  Plus, 
  Wrench,
  XCircle,
  CheckCircle,
  FileText,
  Activity,
  Brain,
  BarChart3,
  Trash2
} from 'lucide-react';
import { QRCodeSVG } from 'qrcode.react';
import { PieChart, Pie, Cell, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, LineChart, Line } from 'recharts';
import { getGeminiClient } from '../lib/gemini';

interface Equipment {
  id: string;
  name: string;
  category: string;
  serialNumber: string;
  status: 'Active' | 'Quarantined' | 'Maintenance';
  nextInspectionDate: string;
  qrCode: string;
  authorId: string;
  createdAt: string;
}

interface InspectionLog {
  id: string;
  equipmentId: string;
  type: 'Daily Pre-Start' | 'Weekly' | 'Monthly' | 'Annual Statutory';
  status: 'Pass' | 'Fail';
  notes: string;
  inspectorId: string;
  timestamp: string;
}

const CR_CATEGORIES = [
  'CR 16: Scaffolding',
  'CR 17: Suspended Platforms',
  'CR 18: Rope Access Equipment',
  'CR 19: Material Hoists',
  'CR 20: Bulk Mixing Plant',
  'CR 21: Explosive Actuated Fastening Device',
  'CR 22: Cranes',
  'CR 23: Construction Vehicles & Mobile Plant',
  'CR 24: Temporary Electrical Installations',
  'Lifting Machinery & Tackle',
  'CR 29: Fire Extinguishers'
];

export default function EquipmentManagement() {
  const { profile } = useAuth();
  const [activeTab, setActiveTab] = useState<'dashboard' | 'register' | 'inspections' | 'maintenance'>('dashboard');
  const [equipmentList, setEquipmentList] = useState<Equipment[]>([]);
  const [inspectionLogs, setInspectionLogs] = useState<InspectionLog[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  
  const [isAddingEquipment, setIsAddingEquipment] = useState(false);
  const [isLoggingInspection, setIsLoggingInspection] = useState(false);
  const [selectedEquipmentId, setSelectedEquipmentId] = useState('');
  
  // Deep View State
  const [viewingAsset, setViewingAsset] = useState<Equipment | null>(null);
  const [isPredicting, setIsPredicting] = useState(false);
  const [aiPrediction, setAiPrediction] = useState<{
    riskScore: number;
    predictedFailureWindow: string;
    recommendedAction: string;
    reasoning: string;
  } | null>(null);

  // Form States
  const [name, setName] = useState('');
  const [category, setCategory] = useState(CR_CATEGORIES[0]);
  const [serialNumber, setSerialNumber] = useState('');
  const [nextInspectionDate, setNextInspectionDate] = useState('');

  const [inspectionType, setInspectionType] = useState<InspectionLog['type']>('Daily Pre-Start');
  const [inspectionStatus, setInspectionStatus] = useState<InspectionLog['status']>('Pass');
  const [inspectionNotes, setInspectionNotes] = useState('');

  useEffect(() => {
    if (!profile?.siteId) return;

    const qEquipment = query(collection(db, 'equipment'), where('siteId', '==', profile.siteId), orderBy('createdAt', 'desc'), limit(100));
    const unsubscribeEq = onSnapshot(qEquipment, (snapshot) => {
      setEquipmentList(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as Equipment[]);
    });

    const qInspections = query(collection(db, 'equipment_inspections'), where('siteId', '==', profile.siteId), orderBy('timestamp', 'desc'), limit(100));
    const unsubscribeInsp = onSnapshot(qInspections, (snapshot) => {
      setInspectionLogs(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as InspectionLog[]);
    });

    return () => {
      unsubscribeEq();
      unsubscribeInsp();
    };
  }, [profile?.siteId]);

  const handleAddEquipment = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;

    try {
      const newEquipment = {
        name,
        category,
        serialNumber,
        status: 'Active',
        nextInspectionDate,
        qrCode: `EQ-${Date.now()}`,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      };

      await addDoc(collection(db, 'equipment'), newEquipment);
      setIsAddingEquipment(false);
      setName('');
      setSerialNumber('');
      setNextInspectionDate('');
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'equipment');
    }
  };

  const handleLogInspection = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser || !selectedEquipmentId) return;

    try {
      const newLog = {
        equipmentId: selectedEquipmentId,
        type: inspectionType,
        status: inspectionStatus,
        notes: inspectionNotes,
        inspectorId: auth.currentUser.uid,
        timestamp: new Date().toISOString()
      };

      await addDoc(collection(db, 'equipment_inspections'), newLog);

      // If inspection fails, quarantine the equipment
      if (inspectionStatus === 'Fail') {
        await updateDoc(doc(db, 'equipment', selectedEquipmentId), { status: 'Quarantined' });
      }

      setIsLoggingInspection(false);
      setInspectionNotes('');
      setInspectionStatus('Pass');
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'equipment_inspections');
    }
  };

  const filteredEquipment = equipmentList.filter(eq => 
    eq.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    eq.serialNumber.toLowerCase().includes(searchQuery.toLowerCase()) ||
    eq.category.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'Active': return 'bg-green-50 text-green-700 border-green-200';
      case 'Quarantined': return 'bg-red-50 text-red-700 border-red-200';
      case 'Maintenance': return 'bg-amber-50 text-amber-700 border-amber-200';
      default: return 'bg-slate-50 text-slate-700 border-slate-200';
    }
  };

  const handlePredictFailure = async (asset: Equipment) => {
    setIsPredicting(true);
    setAiPrediction(null);
    try {
      const assetLogs = inspectionLogs.filter(l => l.equipmentId === asset.id);
      const historyText = assetLogs.map(l => `- ${new Date(l.timestamp).toLocaleDateString()}: [${l.type}] ${l.status} - ${l.notes}`).join('\n');
      
      const prompt = `You are an expert Reliability Engineer and AI Predictive Maintenance system.
Analyze the following asset and its inspection history to predict potential failures.

Asset Name: ${asset.name}
Category: ${asset.category}
Current Status: ${asset.status}
Age/Created: ${new Date(asset.createdAt).toLocaleDateString()}

Inspection History:
${historyText || 'No inspection history available.'}

Based on this data, provide a predictive failure analysis. Format your response exactly as a JSON object with the following keys:
- "riskScore": a number from 0 to 100 representing the risk of failure in the next 30 days.
- "predictedFailureWindow": a short string (e.g., "Next 14 days", "1-3 months", "Low risk currently").
- "recommendedAction": a specific, actionable preventative maintenance recommendation.
- "reasoning": a brief explanation of why this prediction was made based on the data.`;

      const ai = getGeminiClient();
      const response = await ai.models.generateContent({
        model: 'gemini-3.1-pro-preview',
        contents: prompt,
        config: {
          responseMimeType: "application/json",
        }
      });

      const prediction = JSON.parse(response.text || '{}');
      setAiPrediction(prediction);
    } catch (error) {
      console.error("Prediction error:", error);
      alert("Failed to generate prediction.");
    }
    setIsPredicting(false);
  };

  // Chart Data Preparation
  const statusData = [
    { name: 'Active', value: equipmentList.filter(e => e.status === 'Active').length },
    { name: 'Maintenance', value: equipmentList.filter(e => e.status === 'Maintenance').length },
    { name: 'Quarantined', value: equipmentList.filter(e => e.status === 'Quarantined').length },
  ];
  const COLORS = ['#10b981', '#f59e0b', '#ef4444'];

  const categoryData = CR_CATEGORIES.map(cat => ({
    name: cat.split(':')[0], // Shorten name
    count: equipmentList.filter(e => e.category === cat).length
  })).filter(d => d.count > 0);

  return (
    <div className="space-y-6">
      <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
        <div className="flex overflow-x-auto border-b border-slate-200 hide-scrollbar">
          <button
            onClick={() => setActiveTab('dashboard')}
            className={`flex items-center gap-2 px-6 py-4 font-medium whitespace-nowrap transition-colors ${
              activeTab === 'dashboard' ? 'border-b-2 border-blue-600 text-blue-600' : 'text-slate-500 hover:text-slate-700 hover:bg-slate-50'
            }`}
          >
            <BarChart3 size={18} />
            Command Center
          </button>
          <button
            onClick={() => setActiveTab('register')}
            className={`flex items-center gap-2 px-6 py-4 font-medium whitespace-nowrap transition-colors ${
              activeTab === 'register' ? 'border-b-2 border-blue-600 text-blue-600' : 'text-slate-500 hover:text-slate-700 hover:bg-slate-50'
            }`}
          >
            <Truck size={18} />
            Equipment Register
          </button>
          <button
            onClick={() => setActiveTab('inspections')}
            className={`flex items-center gap-2 px-6 py-4 font-medium whitespace-nowrap transition-colors ${
              activeTab === 'inspections' ? 'border-b-2 border-blue-600 text-blue-600' : 'text-slate-500 hover:text-slate-700 hover:bg-slate-50'
            }`}
          >
            <CheckSquare size={18} />
            Inspection Logs
          </button>
          <button
            onClick={() => setActiveTab('maintenance')}
            className={`flex items-center gap-2 px-6 py-4 font-medium whitespace-nowrap transition-colors ${
              activeTab === 'maintenance' ? 'border-b-2 border-blue-600 text-blue-600' : 'text-slate-500 hover:text-slate-700 hover:bg-slate-50'
            }`}
          >
            <Wrench size={18} />
            Maintenance & Quarantine
          </button>
        </div>

        {activeTab === 'dashboard' && (
          <div className="p-6 space-y-6 bg-slate-50">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              {/* Status Overview */}
              <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm">
                <h3 className="text-lg font-bold text-slate-800 mb-4">Asset Status Overview</h3>
                <div className="h-64">
                  <ResponsiveContainer width="100%" height="100%">
                    <PieChart>
                      <Pie
                        data={statusData}
                        cx="50%"
                        cy="50%"
                        innerRadius={60}
                        outerRadius={80}
                        paddingAngle={5}
                        dataKey="value"
                      >
                        {statusData.map((entry, index) => (
                          <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                        ))}
                      </Pie>
                      <Tooltip />
                      <Legend />
                    </PieChart>
                  </ResponsiveContainer>
                </div>
              </div>

              {/* Category Distribution */}
              <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm md:col-span-2">
                <h3 className="text-lg font-bold text-slate-800 mb-4">Assets by CR Category</h3>
                <div className="h-64">
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={categoryData}>
                      <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e2e8f0" />
                      <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{fill: '#64748b', fontSize: 12}} />
                      <YAxis axisLine={false} tickLine={false} tick={{fill: '#64748b', fontSize: 12}} />
                      <Tooltip cursor={{fill: '#f1f5f9'}} contentStyle={{borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)'}} />
                      <Bar dataKey="count" fill="#3b82f6" radius={[4, 4, 0, 0]} />
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              </div>
            </div>
            
            {/* Recent Inspections Timeline */}
            <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm">
              <h3 className="text-lg font-bold text-slate-800 mb-4">Recent Inspection Activity</h3>
              <div className="space-y-4">
                {inspectionLogs.slice(0, 5).map(log => {
                  const eq = equipmentList.find(e => e.id === log.equipmentId);
                  return (
                    <div key={log.id} className="flex items-center gap-4 p-3 hover:bg-slate-50 rounded-lg transition-colors border border-transparent hover:border-slate-100">
                      <div className={`w-2 h-2 rounded-full ${log.status === 'Pass' ? 'bg-green-500' : 'bg-red-500'}`}></div>
                      <div className="flex-1">
                        <p className="text-sm font-medium text-slate-900">{eq?.name || 'Unknown'}</p>
                        <p className="text-xs text-slate-500">{log.type} - {new Date(log.timestamp).toLocaleString()}</p>
                      </div>
                      <span className={`px-2.5 py-1 rounded-full text-xs font-medium border ${log.status === 'Pass' ? 'bg-green-50 text-green-700 border-green-200' : 'bg-red-50 text-red-700 border-red-200'}`}>
                        {log.status}
                      </span>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>
        )}

        {activeTab === 'register' && (
          <div className="p-6">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6">
              <div className="relative flex-1 max-w-md">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={20} />
                <input 
                  type="text" 
                  placeholder="Search equipment..." 
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full pl-10 pr-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
              <button 
                onClick={() => setIsAddingEquipment(true)}
                className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors font-medium"
              >
                <Plus size={20} />
                Add Equipment
              </button>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 text-sm">
                    <th className="p-4 font-medium">Equipment Name</th>
                    <th className="p-4 font-medium">CR Category</th>
                    <th className="p-4 font-medium">Serial Number</th>
                    <th className="p-4 font-medium">Status</th>
                    <th className="p-4 font-medium">Next Inspection</th>
                    <th className="p-4 font-medium">QR Code</th>
                    <th className="p-4 font-medium text-right">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredEquipment.length === 0 ? (
                    <tr>
                      <td colSpan={7} className="p-8 text-center text-slate-500">No equipment found.</td>
                    </tr>
                  ) : (
                    filteredEquipment.map(eq => (
                      <tr key={eq.id} className="border-b border-slate-100 hover:bg-slate-50 transition-colors">
                        <td className="p-4 font-medium text-slate-900">{eq.name}</td>
                        <td className="p-4 text-slate-600 text-sm">{eq.category}</td>
                        <td className="p-4 text-slate-600 font-mono text-sm">{eq.serialNumber}</td>
                        <td className="p-4">
                          <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium border ${getStatusColor(eq.status)}`}>
                            {eq.status}
                          </span>
                        </td>
                        <td className="p-4 text-slate-600 text-sm">
                          {new Date(eq.nextInspectionDate).toLocaleDateString()}
                        </td>
                        <td className="p-4">
                          <div className="w-8 h-8 bg-white border border-slate-200 p-1 rounded">
                            <QRCodeSVG value={eq.qrCode} size={22} />
                          </div>
                        </td>
                        <td className="p-4 text-right">
                          <button 
                            onClick={(e) => {
                              e.stopPropagation();
                              setViewingAsset(eq);
                            }}
                            className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-medium bg-slate-100 text-slate-700 rounded-lg hover:bg-slate-200 transition-colors mr-2"
                          >
                            <Search size={14} /> View
                          </button>
                          <button 
                            onClick={(e) => {
                              e.stopPropagation();
                              setSelectedEquipmentId(eq.id);
                              setIsLoggingInspection(true);
                            }}
                            className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-medium bg-blue-50 text-blue-700 rounded-lg hover:bg-blue-100 transition-colors"
                          >
                            <CheckSquare size={14} /> Log Inspection
                          </button>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {activeTab === 'inspections' && (
          <div className="p-6">
            <h2 className="text-lg font-semibold text-slate-900 mb-6">Recent Inspection Logs</h2>
            <div className="space-y-4">
              {inspectionLogs.length === 0 ? (
                <p className="text-slate-500 text-center p-8">No inspections logged yet.</p>
              ) : (
                inspectionLogs.map(log => {
                  const eq = equipmentList.find(e => e.id === log.equipmentId);
                  return (
                    <div key={log.id} className="flex items-start gap-4 p-4 border border-slate-200 rounded-xl hover:bg-slate-50 transition-colors">
                      <div className={`p-3 rounded-lg ${log.status === 'Pass' ? 'bg-green-100 text-green-600' : 'bg-red-100 text-red-600'}`}>
                        {log.status === 'Pass' ? <CheckCircle size={24} /> : <AlertTriangle size={24} />}
                      </div>
                      <div className="flex-1">
                        <div className="flex justify-between items-start">
                          <div>
                            <h3 className="font-bold text-slate-900">{eq?.name || 'Unknown Equipment'}</h3>
                            <p className="text-sm text-slate-500">{log.type} - {new Date(log.timestamp).toLocaleString()}</p>
                          </div>
                          <span className={`px-2.5 py-1 rounded-full text-xs font-medium border ${log.status === 'Pass' ? 'bg-green-50 text-green-700 border-green-200' : 'bg-red-50 text-red-700 border-red-200'}`}>
                            {log.status}
                          </span>
                        </div>
                        {log.notes && (
                          <p className="mt-2 text-sm text-slate-700 bg-white p-3 rounded border border-slate-100">
                            "{log.notes}"
                          </p>
                        )}
                      </div>
                    </div>
                  );
                })
              )}
            </div>
          </div>
        )}

        {activeTab === 'maintenance' && (
          <div className="p-6">
            <h2 className="text-lg font-semibold text-slate-900 mb-6">Quarantined & Maintenance Equipment</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {equipmentList.filter(eq => eq.status !== 'Active').length === 0 ? (
                <div className="col-span-full text-center p-8 text-slate-500 bg-slate-50 rounded-xl border border-slate-200">
                  No equipment currently in quarantine or maintenance.
                </div>
              ) : (
                equipmentList.filter(eq => eq.status !== 'Active').map(eq => (
                  <div key={eq.id} className="border border-red-200 bg-red-50 rounded-xl p-6 relative overflow-hidden">
                    <div className="absolute top-0 right-0 p-4 opacity-10">
                      <AlertTriangle size={64} className="text-red-600" />
                    </div>
                    <div className="relative z-10">
                      <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-bold bg-red-100 text-red-800 mb-3">
                        {eq.status.toUpperCase()}
                      </span>
                      <h3 className="font-bold text-slate-900 text-lg">{eq.name}</h3>
                      <p className="text-sm text-slate-600 mb-4">{eq.category}</p>
                      <div className="space-y-2 text-sm text-slate-700 mb-6">
                        <div className="flex justify-between">
                          <span className="text-slate-500">S/N:</span>
                          <span className="font-mono">{eq.serialNumber}</span>
                        </div>
                      </div>
                      <button 
                        onClick={async () => {
                          await updateDoc(doc(db, 'equipment', eq.id), { status: 'Active' });
                        }}
                        className="w-full py-2 bg-white border border-slate-200 text-slate-700 rounded-lg hover:bg-slate-50 transition-colors text-sm font-medium flex items-center justify-center gap-2"
                      >
                        <Wrench size={16} /> Release to Service
                      </button>
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        )}
      </div>

      {/* Add Equipment Modal */}
      {isAddingEquipment && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex justify-between items-center">
              <h2 className="text-xl font-bold text-slate-900">Register Equipment</h2>
              <button onClick={() => setIsAddingEquipment(false)} className="text-slate-400 hover:text-slate-600">
                <XCircle size={24} />
              </button>
            </div>
            <form onSubmit={handleAddEquipment} className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Equipment Name</label>
                <input 
                  type="text" 
                  required
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">CR Category</label>
                <select 
                  required
                  value={category}
                  onChange={(e) => setCategory(e.target.value)}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                >
                  {CR_CATEGORIES.map(cat => (
                    <option key={cat} value={cat}>{cat}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Serial Number / Asset ID</label>
                <input 
                  type="text" 
                  required
                  value={serialNumber}
                  onChange={(e) => setSerialNumber(e.target.value)}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent font-mono"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Next Statutory Inspection Date</label>
                <input 
                  type="date" 
                  required
                  value={nextInspectionDate}
                  onChange={(e) => setNextInspectionDate(e.target.value)}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
              <div className="pt-4 flex justify-end gap-3">
                <button 
                  type="button"
                  onClick={() => setIsAddingEquipment(false)}
                  className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
                >
                  Cancel
                </button>
                <button 
                  type="submit"
                  className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                >
                  Register Asset
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Log Inspection Modal */}
      {isLoggingInspection && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex justify-between items-center">
              <h2 className="text-xl font-bold text-slate-900">Log Inspection</h2>
              <button onClick={() => setIsLoggingInspection(false)} className="text-slate-400 hover:text-slate-600">
                <XCircle size={24} />
              </button>
            </div>
            <form onSubmit={handleLogInspection} className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Inspection Type</label>
                <select 
                  required
                  value={inspectionType}
                  onChange={(e) => setInspectionType(e.target.value as any)}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                >
                  <option value="Daily Pre-Start">Daily Pre-Start Checklist</option>
                  <option value="Weekly">Weekly Inspection</option>
                  <option value="Monthly">Monthly Inspection</option>
                  <option value="Annual Statutory">Annual Statutory (LMI)</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Result</label>
                <select 
                  required
                  value={inspectionStatus}
                  onChange={(e) => setInspectionStatus(e.target.value as any)}
                  className={`w-full p-2.5 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent font-bold ${inspectionStatus === 'Pass' ? 'bg-green-50 text-green-700 border-green-200' : 'bg-red-50 text-red-700 border-red-200'}`}
                >
                  <option value="Pass">PASS - Safe to Use</option>
                  <option value="Fail">FAIL - Quarantine Immediately</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Notes / Defects Found</label>
                <textarea 
                  rows={3}
                  value={inspectionNotes}
                  onChange={(e) => setInspectionNotes(e.target.value)}
                  placeholder="Describe any issues..."
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
              <div className="pt-4 flex justify-end gap-3">
                <button 
                  type="button"
                  onClick={() => setIsLoggingInspection(false)}
                  className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
                >
                  Cancel
                </button>
                <button 
                  type="submit"
                  className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                >
                  Submit Log
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
      {/* Deep View Modal */}
      {viewingAsset && (
        <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4 backdrop-blur-sm">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-4xl max-h-[90vh] flex flex-col overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex justify-between items-start bg-slate-50">
              <div>
                <div className="flex items-center gap-3 mb-2">
                  <h2 className="text-2xl font-black text-slate-900">{viewingAsset.name}</h2>
                  <span className={`px-2.5 py-1 rounded-full text-xs font-bold border ${getStatusColor(viewingAsset.status)}`}>
                    {viewingAsset.status.toUpperCase()}
                  </span>
                </div>
                <p className="text-sm text-slate-500 font-medium">{viewingAsset.category} • S/N: {viewingAsset.serialNumber}</p>
              </div>
              <button onClick={() => { setViewingAsset(null); setAiPrediction(null); }} className="text-slate-400 hover:text-slate-600 bg-white p-2 rounded-full shadow-sm">
                <XCircle size={24} />
              </button>
            </div>
            
            <div className="flex-1 overflow-y-auto p-6">
              <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                {/* Left Column: Details & QR */}
                <div className="space-y-6">
                  <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
                    <h3 className="text-sm font-bold text-slate-800 mb-4 uppercase tracking-wider">Asset Identity</h3>
                    <div className="flex justify-center mb-4 bg-slate-50 p-4 rounded-lg">
                      <QRCodeSVG value={viewingAsset.qrCode} size={120} />
                    </div>
                    <div className="space-y-3 text-sm">
                      <div className="flex justify-between border-b border-slate-100 pb-2">
                        <span className="text-slate-500">System ID</span>
                        <span className="font-mono text-slate-900">{viewingAsset.qrCode}</span>
                      </div>
                      <div className="flex justify-between border-b border-slate-100 pb-2">
                        <span className="text-slate-500">Added Date</span>
                        <span className="text-slate-900">{new Date(viewingAsset.createdAt).toLocaleDateString()}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-slate-500">Next Inspection</span>
                        <span className="font-medium text-amber-600">{new Date(viewingAsset.nextInspectionDate).toLocaleDateString()}</span>
                      </div>
                    </div>
                  </div>

                  {/* AI Prediction Card */}
                  <div className="bg-gradient-to-br from-indigo-50 to-purple-50 p-5 rounded-xl border border-indigo-100 shadow-sm relative overflow-hidden">
                    <div className="absolute top-0 right-0 p-2 opacity-5">
                      <Brain size={80} />
                    </div>
                    <h3 className="text-sm font-bold text-indigo-900 mb-3 flex items-center gap-2">
                      <Brain size={18} className="text-indigo-600" /> AI Predictive Analysis
                    </h3>
                    
                    {!aiPrediction ? (
                      <div className="text-center py-4">
                        <p className="text-xs text-indigo-700 mb-4">Analyze inspection history to predict failures and optimize uptime.</p>
                        <button 
                          onClick={() => handlePredictFailure(viewingAsset)}
                          disabled={isPredicting}
                          className="w-full bg-indigo-600 text-white px-4 py-2.5 rounded-lg text-sm font-bold hover:bg-indigo-700 disabled:opacity-50 flex items-center justify-center gap-2 transition-all shadow-sm"
                        >
                          {isPredicting ? (
                            <><Activity size={16} className="animate-pulse" /> Analyzing Data...</>
                          ) : (
                            <><Brain size={16} /> Run Prediction</>
                          )}
                        </button>
                      </div>
                    ) : (
                      <div className="space-y-4 relative z-10 animate-in fade-in slide-in-from-bottom-2 duration-300">
                        <div className="flex items-center justify-between bg-white p-3 rounded-lg border border-indigo-100 shadow-sm">
                          <span className="text-xs font-bold text-indigo-900 uppercase tracking-wider">Failure Risk (30 Days)</span>
                          <span className={`text-lg font-black ${aiPrediction.riskScore > 70 ? 'text-red-600' : aiPrediction.riskScore > 40 ? 'text-amber-600' : 'text-green-600'}`}>
                            {aiPrediction.riskScore}%
                          </span>
                        </div>
                        <div>
                          <span className="block text-[10px] uppercase tracking-wider text-indigo-500 font-bold mb-1">Predicted Window</span>
                          <p className="text-sm font-medium text-indigo-900">{aiPrediction.predictedFailureWindow}</p>
                        </div>
                        <div>
                          <span className="block text-[10px] uppercase tracking-wider text-indigo-500 font-bold mb-1">Recommended Action</span>
                          <p className="text-sm text-indigo-900 bg-white p-3 rounded-lg border border-indigo-100 shadow-sm">{aiPrediction.recommendedAction}</p>
                        </div>
                        <div>
                          <span className="block text-[10px] uppercase tracking-wider text-indigo-500 font-bold mb-1">AI Reasoning</span>
                          <p className="text-xs text-indigo-800 italic leading-relaxed">{aiPrediction.reasoning}</p>
                        </div>
                      </div>
                    )}
                  </div>
                </div>

                {/* Right Column: History */}
                <div className="lg:col-span-2 space-y-6">
                  <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm h-full">
                    <div className="flex justify-between items-center mb-6">
                      <h3 className="text-lg font-bold text-slate-800">Inspection & Maintenance History</h3>
                      <button 
                        onClick={() => {
                          setSelectedEquipmentId(viewingAsset.id);
                          setIsLoggingInspection(true);
                        }}
                        className="text-sm bg-blue-50 text-blue-700 px-3 py-1.5 rounded-lg hover:bg-blue-100 font-medium flex items-center gap-1"
                      >
                        <Plus size={16} /> Log New
                      </button>
                    </div>
                    
                    <div className="space-y-4">
                      {inspectionLogs.filter(l => l.equipmentId === viewingAsset.id).length === 0 ? (
                        <div className="text-center py-12 text-slate-500 bg-slate-50 rounded-lg border border-slate-100 border-dashed">
                          No history recorded for this asset.
                        </div>
                      ) : (
                        inspectionLogs.filter(l => l.equipmentId === viewingAsset.id).map(log => (
                          <div key={log.id} className="flex gap-4 p-4 rounded-lg border border-slate-100 bg-slate-50 hover:bg-slate-100 transition-colors">
                            <div className={`p-2 rounded-full h-fit ${log.status === 'Pass' ? 'bg-green-100 text-green-600' : 'bg-red-100 text-red-600'}`}>
                              {log.status === 'Pass' ? <CheckCircle size={20} /> : <AlertTriangle size={20} />}
                            </div>
                            <div className="flex-1">
                              <div className="flex justify-between items-start mb-1">
                                <span className="font-bold text-slate-900">{log.type}</span>
                                <span className="text-xs text-slate-500 font-medium">{new Date(log.timestamp).toLocaleString()}</span>
                              </div>
                              <p className="text-sm text-slate-700 mt-1">{log.notes || 'No notes provided.'}</p>
                            </div>
                          </div>
                        ))
                      )}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

    </div>
  );
}
