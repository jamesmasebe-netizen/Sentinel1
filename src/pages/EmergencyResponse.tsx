import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy, doc, updateDoc } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { 
  Siren, 
  Flame, 
  Map as MapIcon, 
  Users, 
  Plus, 
  CheckCircle, 
  XCircle, 
  AlertTriangle,
  FileText,
  BookOpen,
  Navigation,
  ShieldCheck,
  Sparkles,
  Wrench,
  HeartPulse,
  Droplets,
  Send,
  ClipboardList,
  Contact,
  Layout,
  Package,
  Bot
} from 'lucide-react';
import EmergencyProcedures from '../components/EmergencyProcedures';
import EmergencyMaps from '../components/EmergencyMaps';
import WardenManagement from '../components/WardenManagement';
import MusterRoll from '../components/MusterRoll';
import DrillAnalysis from '../components/DrillAnalysis';
import EquipmentMaintenance from '../components/EquipmentMaintenance';
import MedicalResponse from '../components/MedicalResponse';
import SpillResponse from '../components/SpillResponse';
import EmergencyBroadcast from '../components/EmergencyBroadcast';
import PostIncidentReview from '../components/PostIncidentReview';
import EmergencyContacts from '../components/EmergencyContacts';
import IncidentCommandBoard from '../components/IncidentCommandBoard';
import ResourceInventory from '../components/ResourceInventory';
import AIProtocolAssistant from '../components/AIProtocolAssistant';

interface EmergencyDrill {
  id: string;
  drillType: 'Fire' | 'Medical' | 'Spill' | 'Security' | 'Other';
  dateConducted: string;
  durationMinutes: number;
  evaluatorName: string;
  scenarioDescription: string;
  areasForImprovement?: string;
  authorId: string;
  createdAt: string;
}

interface EmergencyEquipment {
  id: string;
  equipmentType: 'Extinguisher' | 'First Aid Kit' | 'Spill Kit' | 'AED' | 'Other';
  location: string;
  nextInspectionDate: string;
  status: 'Operational' | 'Needs Inspection' | 'Out of Service';
  authorId: string;
  createdAt: string;
}

export default function EmergencyResponse() {
  const [activeTab, setActiveTab] = useState<'drills' | 'equipment' | 'muster' | 'erp' | 'maps' | 'wardens' | 'analysis' | 'maintenance' | 'medical' | 'spill' | 'broadcast' | 'pir' | 'contacts' | 'ics' | 'resources' | 'ai-assistant'>('drills');
  const [drills, setDrills] = useState<EmergencyDrill[]>([]);
  const [equipment, setEquipment] = useState<EmergencyEquipment[]>([]);
  
  const [isAddingDrill, setIsAddingDrill] = useState(false);
  const [isAddingEquipment, setIsAddingEquipment] = useState(false);

  // Drill Form
  const [drillType, setDrillType] = useState<EmergencyDrill['drillType']>('Fire');
  const [drillDate, setDrillDate] = useState('');
  const [duration, setDuration] = useState('');
  const [evaluator, setEvaluator] = useState('');
  const [scenario, setScenario] = useState('');
  const [improvements, setImprovements] = useState('');

  // Equipment Form
  const [equipmentType, setEquipmentType] = useState<EmergencyEquipment['equipmentType']>('Extinguisher');
  const [location, setLocation] = useState('');
  const [inspectionDate, setInspectionDate] = useState('');
  const [equipmentStatus, setEquipmentStatus] = useState<EmergencyEquipment['status']>('Operational');

  useEffect(() => {
    if (!auth.currentUser) return;

    const qDrills = query(collection(db, 'emergency_drills'), orderBy('createdAt', 'desc'));
    const unsubscribeDrills = onSnapshot(qDrills, (snapshot) => {
      const drillRecords = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as EmergencyDrill[];
      setDrills(drillRecords);
    }, (error) => {
      handleFirestoreError(error, 'list' as any, 'emergency_drills');
    });

    const qEquipment = query(collection(db, 'emergency_equipment'), orderBy('createdAt', 'desc'));
    const unsubscribeEquipment = onSnapshot(qEquipment, (snapshot) => {
      const equipRecords = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as EmergencyEquipment[];
      
      // Auto-update status if inspection is overdue
      const now = new Date().getTime();
      equipRecords.forEach(eq => {
        if (eq.status === 'Operational' && new Date(eq.nextInspectionDate).getTime() < now) {
          updateDoc(doc(db, 'emergency_equipment', eq.id), { status: 'Needs Inspection' }).catch(console.error);
        }
      });

      setEquipment(equipRecords);
    }, (error) => {
      handleFirestoreError(error, 'list' as any, 'emergency_equipment');
    });

    return () => {
      unsubscribeDrills();
      unsubscribeEquipment();
    };
  }, []);

  const handleAddDrill = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;

    try {
      const newDrill = {
        drillType,
        dateConducted: new Date(drillDate).toISOString(),
        durationMinutes: Number(duration),
        evaluatorName: evaluator,
        scenarioDescription: scenario,
        areasForImprovement: improvements,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      };

      await addDoc(collection(db, 'emergency_drills'), newDrill);
      setIsAddingDrill(false);
      // Reset form
      setDrillType('Fire');
      setDrillDate('');
      setDuration('');
      setEvaluator('');
      setScenario('');
      setImprovements('');
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'emergency_drills');
    }
  };

  const handleAddEquipment = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;

    try {
      const newEquipment = {
        equipmentType,
        location,
        nextInspectionDate: new Date(inspectionDate).toISOString(),
        status: equipmentStatus,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      };

      await addDoc(collection(db, 'emergency_equipment'), newEquipment);
      setIsAddingEquipment(false);
      // Reset form
      setEquipmentType('Extinguisher');
      setLocation('');
      setInspectionDate('');
      setEquipmentStatus('Operational');
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'emergency_equipment');
    }
  };

  const updateEquipmentStatus = async (id: string, newStatus: EmergencyEquipment['status']) => {
    try {
      await updateDoc(doc(db, 'emergency_equipment', id), { status: newStatus });
    } catch (error) {
      handleFirestoreError(error, 'update' as any, 'emergency_equipment');
    }
  };

  return (
    <div className="max-w-7xl mx-auto space-y-6">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 flex items-center gap-2">
            Emergency Response <Siren size={24} className="text-red-600" />
          </h1>
          <p className="text-slate-500">Manage drills, equipment, and live evacuations.</p>
        </div>
        <div className="flex gap-3">
          {activeTab === 'drills' && (
            <button 
              onClick={() => setIsAddingDrill(true)}
              className="flex items-center gap-2 bg-red-600 text-white px-4 py-2 rounded-lg hover:bg-red-700 transition-colors"
            >
              <Plus size={20} />
              Log Drill
            </button>
          )}
          {activeTab === 'equipment' && (
            <button 
              onClick={() => setIsAddingEquipment(true)}
              className="flex items-center gap-2 bg-red-600 text-white px-4 py-2 rounded-lg hover:bg-red-700 transition-colors"
            >
              <Plus size={20} />
              Add Equipment
            </button>
          )}
        </div>
      </div>

      {/* Tabs */}
      <div className="flex overflow-x-auto border-b border-slate-200 hide-scrollbar">
        <button
          onClick={() => setActiveTab('drills')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'drills' ? 'border-red-600 text-red-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <FileText size={18} />
          Drill Logs
        </button>
        <button
          onClick={() => setActiveTab('equipment')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'equipment' ? 'border-red-600 text-red-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Flame size={18} />
          Equipment Tracking
        </button>
        <button
          onClick={() => setActiveTab('muster')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'muster' ? 'border-red-600 text-red-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Users size={18} />
          Live Muster Roll
        </button>
        <button
          onClick={() => setActiveTab('erp')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'erp' ? 'border-red-600 text-red-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <BookOpen size={18} />
          Emergency Procedures (ERP)
        </button>
        <button
          onClick={() => setActiveTab('maps')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'maps' ? 'border-red-600 text-red-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <MapIcon size={18} />
          Interactive Maps
        </button>
        <button
          onClick={() => setActiveTab('wardens')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'wardens' ? 'border-red-600 text-red-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <ShieldCheck size={18} />
          Warden Management
        </button>
        <button
          onClick={() => setActiveTab('analysis')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'analysis' ? 'border-red-600 text-red-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Sparkles size={18} />
          AI Drill Analysis
        </button>
        <button
          onClick={() => setActiveTab('maintenance')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'maintenance' ? 'border-red-600 text-red-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Wrench size={18} />
          Advanced Maintenance
        </button>
        <button
          onClick={() => setActiveTab('medical')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'medical' ? 'border-red-600 text-red-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <HeartPulse size={18} />
          Medical Response
        </button>
        <button
          onClick={() => setActiveTab('spill')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'spill' ? 'border-red-600 text-red-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Droplets size={18} />
          HAZMAT/Spill
        </button>
        <button
          onClick={() => setActiveTab('broadcast')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'broadcast' ? 'border-red-600 text-red-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Send size={18} />
          Broadcast Hub
        </button>
        <button
          onClick={() => setActiveTab('pir')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'pir' ? 'border-red-600 text-red-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <ClipboardList size={18} />
          PIR & CAPA
        </button>
        <button
          onClick={() => setActiveTab('contacts')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'contacts' ? 'border-red-600 text-red-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Contact size={18} />
          Contacts & NOK
        </button>
        <button
          onClick={() => setActiveTab('ics')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'ics' ? 'border-red-600 text-red-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Layout size={18} />
          ICS Board
        </button>
        <button
          onClick={() => setActiveTab('resources')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'resources' ? 'border-red-600 text-red-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Package size={18} />
          Resource Inventory
        </button>
        <button
          onClick={() => setActiveTab('ai-assistant')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'ai-assistant' ? 'border-red-600 text-red-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Bot size={18} />
          AI Assistant
        </button>
      </div>

      {/* Content Area */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        
        {/* Drills Tab */}
        {activeTab === 'drills' && (
          <div className="p-6">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {drills.map((drill) => (
                <div key={drill.id} className="border border-slate-200 rounded-xl p-5 bg-white hover:shadow-md transition-shadow">
                  <div className="flex items-start gap-3 mb-4">
                    <div className="bg-red-50 p-2 rounded-lg text-red-600 shrink-0">
                      <Siren size={24} />
                    </div>
                    <div>
                      <h3 className="font-semibold text-slate-900">{drill.drillType} Drill</h3>
                      <p className="text-sm text-slate-500">{new Date(drill.dateConducted).toLocaleDateString()}</p>
                    </div>
                  </div>
                  
                  <div className="space-y-2 text-sm text-slate-600 mb-4">
                    <p><span className="font-medium text-slate-700">Duration:</span> {drill.durationMinutes} mins</p>
                    <p><span className="font-medium text-slate-700">Evaluator:</span> {drill.evaluatorName}</p>
                  </div>

                  <div className="bg-slate-50 p-3 rounded-lg border border-slate-100 mb-3">
                    <p className="text-xs font-semibold text-slate-500 uppercase mb-1">Scenario</p>
                    <p className="text-sm text-slate-700 line-clamp-2" title={drill.scenarioDescription}>
                      {drill.scenarioDescription}
                    </p>
                  </div>

                  {drill.areasForImprovement && (
                    <div className="bg-amber-50 p-3 rounded-lg border border-amber-100">
                      <p className="text-xs font-semibold text-amber-700 uppercase mb-1">Needs Improvement</p>
                      <p className="text-sm text-amber-800 line-clamp-2" title={drill.areasForImprovement}>
                        {drill.areasForImprovement}
                      </p>
                    </div>
                  )}
                </div>
              ))}
              {drills.length === 0 && (
                <div className="col-span-full p-8 text-center text-slate-500 bg-slate-50 rounded-xl border border-dashed border-slate-300">
                  No emergency drills logged yet.
                </div>
              )}
            </div>
          </div>
        )}

        {/* Equipment Tab */}
        {activeTab === 'equipment' && (
          <div className="p-6">
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 text-sm">
                    <th className="p-4 font-medium">Equipment Type</th>
                    <th className="p-4 font-medium">Location</th>
                    <th className="p-4 font-medium">Next Inspection</th>
                    <th className="p-4 font-medium">Status</th>
                  </tr>
                </thead>
                <tbody>
                  {equipment.length === 0 ? (
                    <tr>
                      <td colSpan={4} className="p-8 text-center text-slate-500">
                        No emergency equipment tracked yet.
                      </td>
                    </tr>
                  ) : (
                    equipment.map((eq) => {
                      const isOverdue = new Date(eq.nextInspectionDate).getTime() < new Date().getTime();
                      
                      return (
                        <tr key={eq.id} className="border-b border-slate-100 hover:bg-slate-50 transition-colors">
                          <td className="p-4 font-medium text-slate-900 flex items-center gap-2">
                            {eq.equipmentType === 'Extinguisher' && <Flame size={16} className="text-red-500" />}
                            {eq.equipmentType}
                          </td>
                          <td className="p-4 text-slate-600">{eq.location}</td>
                          <td className="p-4">
                            <div className="flex items-center gap-2">
                              <span className={isOverdue ? 'text-red-600 font-medium' : 'text-slate-600'}>
                                {new Date(eq.nextInspectionDate).toLocaleDateString()}
                              </span>
                              {isOverdue && <span title="Inspection Overdue"><AlertTriangle size={16} className="text-red-500" /></span>}
                            </div>
                          </td>
                          <td className="p-4">
                            <select
                              value={eq.status}
                              onChange={(e) => updateEquipmentStatus(eq.id, e.target.value as any)}
                              className={`text-sm rounded-lg border-slate-300 focus:ring-red-500 focus:border-red-500 ${
                                eq.status === 'Operational' ? 'bg-green-50 text-green-700' :
                                eq.status === 'Needs Inspection' ? 'bg-amber-50 text-amber-700' :
                                'bg-red-50 text-red-700'
                              }`}
                            >
                              <option value="Operational">Operational</option>
                              <option value="Needs Inspection">Needs Inspection</option>
                              <option value="Out of Service">Out of Service</option>
                            </select>
                          </td>
                        </tr>
                      );
                    })
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* Muster Roll Tab */}
        {activeTab === 'muster' && (
          <div className="p-6">
            <MusterRoll />
          </div>
        )}

        {/* ERP Tab */}
        {activeTab === 'erp' && (
          <div className="p-6">
            <EmergencyProcedures />
          </div>
        )}

        {/* Maps Tab */}
        {activeTab === 'maps' && (
          <div className="p-6">
            <EmergencyMaps />
          </div>
        )}

        {/* Warden Tab */}
        {activeTab === 'wardens' && (
          <div className="p-6">
            <WardenManagement />
          </div>
        )}

        {/* Analysis Tab */}
        {activeTab === 'analysis' && (
          <div className="p-6">
            <DrillAnalysis />
          </div>
        )}

        {/* Maintenance Tab */}
        {activeTab === 'maintenance' && (
          <div className="p-6">
            <EquipmentMaintenance />
          </div>
        )}

        {/* Medical Tab */}
        {activeTab === 'medical' && (
          <div className="p-6">
            <MedicalResponse />
          </div>
        )}

        {/* Spill Tab */}
        {activeTab === 'spill' && (
          <div className="p-6">
            <SpillResponse />
          </div>
        )}

        {/* Broadcast Tab */}
        {activeTab === 'broadcast' && (
          <div className="p-6">
            <EmergencyBroadcast />
          </div>
        )}

        {/* PIR Tab */}
        {activeTab === 'pir' && (
          <div className="p-6">
            <PostIncidentReview />
          </div>
        )}

        {/* Contacts Tab */}
        {activeTab === 'contacts' && (
          <div className="p-6">
            <EmergencyContacts />
          </div>
        )}

        {/* ICS Tab */}
        {activeTab === 'ics' && (
          <div className="p-6">
            <IncidentCommandBoard />
          </div>
        )}

        {/* Resources Tab */}
        {activeTab === 'resources' && (
          <div className="p-6">
            <ResourceInventory />
          </div>
        )}

        {/* AI Assistant Tab */}
        {activeTab === 'ai-assistant' && (
          <div className="p-6">
            <AIProtocolAssistant />
          </div>
        )}
      </div>

      {/* Add Drill Modal */}
      {isAddingDrill && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex justify-between items-center">
              <h2 className="text-xl font-bold text-slate-900">Log Emergency Drill</h2>
              <button onClick={() => setIsAddingDrill(false)} className="text-slate-400 hover:text-slate-600">
                <XCircle size={24} />
              </button>
            </div>
            <form onSubmit={handleAddDrill} className="p-6 space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Drill Type</label>
                  <select 
                    required
                    value={drillType}
                    onChange={(e) => setDrillType(e.target.value as any)}
                    className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-transparent"
                  >
                    <option value="Fire">Fire</option>
                    <option value="Medical">Medical</option>
                    <option value="Spill">Spill</option>
                    <option value="Security">Security</option>
                    <option value="Other">Other</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Date</label>
                  <input 
                    type="date" 
                    required
                    value={drillDate}
                    onChange={(e) => setDrillDate(e.target.value)}
                    className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-transparent"
                  />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Duration (mins)</label>
                  <input 
                    type="number" 
                    required
                    min="1"
                    value={duration}
                    onChange={(e) => setDuration(e.target.value)}
                    className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-transparent"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Evaluator Name</label>
                  <input 
                    type="text" 
                    required
                    value={evaluator}
                    onChange={(e) => setEvaluator(e.target.value)}
                    className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-transparent"
                  />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Scenario Description</label>
                <textarea 
                  required
                  value={scenario}
                  onChange={(e) => setScenario(e.target.value)}
                  rows={2}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-transparent"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Areas for Improvement</label>
                <textarea 
                  value={improvements}
                  onChange={(e) => setImprovements(e.target.value)}
                  rows={2}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-transparent"
                />
              </div>
              <div className="pt-4 flex justify-end gap-3">
                <button 
                  type="button"
                  onClick={() => setIsAddingDrill(false)}
                  className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
                >
                  Cancel
                </button>
                <button 
                  type="submit"
                  className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
                >
                  Save Drill
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Add Equipment Modal */}
      {isAddingEquipment && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex justify-between items-center">
              <h2 className="text-xl font-bold text-slate-900">Add Emergency Equipment</h2>
              <button onClick={() => setIsAddingEquipment(false)} className="text-slate-400 hover:text-slate-600">
                <XCircle size={24} />
              </button>
            </div>
            <form onSubmit={handleAddEquipment} className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Equipment Type</label>
                <select 
                  required
                  value={equipmentType}
                  onChange={(e) => setEquipmentType(e.target.value as any)}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-transparent"
                >
                  <option value="Extinguisher">Fire Extinguisher</option>
                  <option value="First Aid Kit">First Aid Kit</option>
                  <option value="Spill Kit">Spill Kit</option>
                  <option value="AED">AED</option>
                  <option value="Other">Other</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Location</label>
                <input 
                  type="text" 
                  required
                  value={location}
                  onChange={(e) => setLocation(e.target.value)}
                  placeholder="e.g., Main Office Hallway"
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-transparent"
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Next Inspection Date</label>
                  <input 
                    type="date" 
                    required
                    value={inspectionDate}
                    onChange={(e) => setInspectionDate(e.target.value)}
                    className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-transparent"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Status</label>
                  <select 
                    required
                    value={equipmentStatus}
                    onChange={(e) => setEquipmentStatus(e.target.value as any)}
                    className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-transparent"
                  >
                    <option value="Operational">Operational</option>
                    <option value="Needs Inspection">Needs Inspection</option>
                    <option value="Out of Service">Out of Service</option>
                  </select>
                </div>
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
                  className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
                >
                  Save Equipment
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

    </div>
  );
}
