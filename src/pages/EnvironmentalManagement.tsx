import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy, doc, updateDoc, where, limit } from 'firebase/firestore';
import { db, auth, handleFirestoreError } from '../lib/firebase';
import { useAuth } from '../contexts/AuthContext';
import { 
  Leaf, 
  Trash2, 
  AlertTriangle, 
  CloudRain, 
  Plus, 
  CheckCircle, 
  XCircle, 
  Truck,
  Factory,
  Scale,
  Droplets,
  Wind,
  BarChart3,
  Shield,
  PieChart,
  Zap,
  ClipboardCheck,
  Lightbulb,
  Beaker,
  GraduationCap,
  ShieldAlert,
  Users,
  RefreshCw
} from 'lucide-react';
import AspectsImpactsRegister from '../components/AspectsImpactsRegister';
import EnvironmentalLegalRegister from '../components/EnvironmentalLegalRegister';
import WaterBalanceTracker from '../components/WaterBalanceTracker';
import AirQualityMonitor from '../components/AirQualityMonitor';
import WasteHierarchyAnalytics from '../components/WasteHierarchyAnalytics';
import EnergyManagementDashboard from '../components/EnergyManagementDashboard';
import EnvironmentalIncidentLog from '../components/EnvironmentalIncidentLog';
import EnvironmentalInternalAudit from '../components/EnvironmentalInternalAudit';
import ResourceEfficiencyProjects from '../components/ResourceEfficiencyProjects';
import ChemicalSubstanceRegisterEnv from '../components/ChemicalSubstanceRegisterEnv';
import BiodiversityRegister from '../components/BiodiversityRegister';
import EnvironmentalTrainingMatrix from '../components/EnvironmentalTrainingMatrix';
import EnvironmentalEmergencyPreparedness from '../components/EnvironmentalEmergencyPreparedness';
import EnvironmentalStakeholderLog from '../components/EnvironmentalStakeholderLog';
import LifeCycleAssessmentTool from '../components/LifeCycleAssessmentTool';

type TabType = 'waste' | 'spills' | 'carbon' | 'aspects' | 'legal' | 'water' | 'air' | 'analytics' | 'energy' | 'incidents' | 'audits' | 'projects' | 'chemicals' | 'biodiversity' | 'training' | 'emergency' | 'stakeholders' | 'lca';

interface WasteManifest {
  id: string;
  wasteType: 'Hazardous' | 'General' | 'Recyclable' | 'Medical' | 'E-Waste';
  quantity: number;
  unit: 'kg' | 'tons' | 'liters' | 'm3';
  transporterName: string;
  disposalFacility: string;
  status: 'Pending Pickup' | 'In Transit' | 'Disposed';
  collectionDate: string;
  authorId: string;
  createdAt: string;
}

interface EnvironmentalSpill {
  id: string;
  substance: string;
  volume: string;
  location: string;
  contained: boolean;
  reportedToAuthorities: boolean;
  dateOfSpill: string;
  authorId: string;
  createdAt: string;
}

export default function EnvironmentalManagement() {
  const { profile } = useAuth();
  const [activeTab, setActiveTab] = useState<TabType>('waste');
  const [wasteManifests, setWasteManifests] = useState<WasteManifest[]>([]);
  const [spills, setSpills] = useState<EnvironmentalSpill[]>([]);
  
  const [isAddingManifest, setIsAddingManifest] = useState(false);
  const [isAddingSpill, setIsAddingSpill] = useState(false);

  // Waste Form
  const [wasteType, setWasteType] = useState<WasteManifest['wasteType']>('General');
  const [quantity, setQuantity] = useState('');
  const [unit, setUnit] = useState<WasteManifest['unit']>('kg');
  const [transporterName, setTransporterName] = useState('');
  const [disposalFacility, setDisposalFacility] = useState('');
  const [collectionDate, setCollectionDate] = useState('');

  // Spill Form
  const [substance, setSubstance] = useState('');
  const [volume, setVolume] = useState('');
  const [location, setLocation] = useState('');
  const [contained, setContained] = useState(false);
  const [reportedToAuthorities, setReportedToAuthorities] = useState(false);
  const [dateOfSpill, setDateOfSpill] = useState('');

  useEffect(() => {
    if (!profile?.siteId) return;

    const qWaste = query(collection(db, 'waste_manifests'), where('siteId', '==', profile.siteId), orderBy('createdAt', 'desc'), limit(100));
    const unsubscribeWaste = onSnapshot(qWaste, (snapshot) => {
      const manifests = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as WasteManifest[];
      setWasteManifests(manifests);
    }, (error) => {
      handleFirestoreError(error, 'list' as any, 'waste_manifests');
    });

    const qSpills = query(collection(db, 'environmental_spills'), where('siteId', '==', profile.siteId), orderBy('createdAt', 'desc'), limit(100));
    const unsubscribeSpills = onSnapshot(qSpills, (snapshot) => {
      const spillRecords = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as EnvironmentalSpill[];
      setSpills(spillRecords);
    }, (error) => {
      handleFirestoreError(error, 'list' as any, 'environmental_spills');
    });

    return () => {
      unsubscribeWaste();
      unsubscribeSpills();
    };
  }, [profile?.siteId]);

  const handleAddManifest = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;

    try {
      const newManifest = {
        wasteType,
        quantity: Number(quantity),
        unit,
        transporterName,
        disposalFacility,
        status: 'Pending Pickup',
        collectionDate: new Date(collectionDate).toISOString(),
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      };

      await addDoc(collection(db, 'waste_manifests'), newManifest);
      setIsAddingManifest(false);
      // Reset form
      setWasteType('General');
      setQuantity('');
      setUnit('kg');
      setTransporterName('');
      setDisposalFacility('');
      setCollectionDate('');
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'waste_manifests');
    }
  };

  const handleAddSpill = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;

    try {
      const newSpill = {
        substance,
        volume,
        location,
        contained,
        reportedToAuthorities,
        dateOfSpill: new Date(dateOfSpill).toISOString(),
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      };

      await addDoc(collection(db, 'environmental_spills'), newSpill);
      setIsAddingSpill(false);
      // Reset form
      setSubstance('');
      setVolume('');
      setLocation('');
      setContained(false);
      setReportedToAuthorities(false);
      setDateOfSpill('');
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'environmental_spills');
    }
  };

  const updateManifestStatus = async (id: string, newStatus: WasteManifest['status']) => {
    try {
      await updateDoc(doc(db, 'waste_manifests', id), { status: newStatus });
    } catch (error) {
      handleFirestoreError(error, 'update' as any, 'waste_manifests');
    }
  };

  return (
    <div className="max-w-7xl mx-auto space-y-6">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 flex items-center gap-2">
            Environmental Management <Leaf size={24} className="text-green-600" />
          </h1>
          <p className="text-slate-500">ISO 14001 compliance, waste tracking, and spill reporting.</p>
        </div>
        <div className="flex gap-3">
          {activeTab === 'waste' && (
            <button 
              onClick={() => setIsAddingManifest(true)}
              className="flex items-center gap-2 bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700 transition-colors"
            >
              <Plus size={20} />
              Log Waste Manifest
            </button>
          )}
          {activeTab === 'spills' && (
            <button 
              onClick={() => setIsAddingSpill(true)}
              className="flex items-center gap-2 bg-amber-600 text-white px-4 py-2 rounded-lg hover:bg-amber-700 transition-colors"
            >
              <Plus size={20} />
              Report Spill
            </button>
          )}
        </div>
      </div>

      {/* Tabs */}
      <div className="flex overflow-x-auto border-b border-slate-200 hide-scrollbar">
        <button
          onClick={() => setActiveTab('waste')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'waste' ? 'border-green-600 text-green-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Trash2 size={18} />
          Waste Manifests
        </button>
        <button
          onClick={() => setActiveTab('spills')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'spills' ? 'border-green-600 text-green-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <CloudRain size={18} />
          Spill Register
        </button>
        <button
          onClick={() => setActiveTab('carbon')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'carbon' ? 'border-green-600 text-green-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Factory size={18} />
          Carbon Footprint
        </button>
        <button
          onClick={() => setActiveTab('aspects')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'aspects' ? 'border-green-600 text-green-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Shield size={18} />
          Aspects & Impacts
        </button>
        <button
          onClick={() => setActiveTab('legal')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'legal' ? 'border-green-600 text-green-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Scale size={18} />
          Legal Register
        </button>
        <button
          onClick={() => setActiveTab('water')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'water' ? 'border-green-600 text-green-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Droplets size={18} />
          Water Balance
        </button>
        <button
          onClick={() => setActiveTab('air')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'air' ? 'border-green-600 text-green-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Wind size={18} />
          Air Quality
        </button>
        <button
          onClick={() => setActiveTab('analytics')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'analytics' ? 'border-green-600 text-green-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <PieChart size={18} />
          Waste Analytics
        </button>
        <button
          onClick={() => setActiveTab('energy')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'energy' ? 'border-green-600 text-green-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Zap size={18} />
          Energy Management
        </button>
        <button
          onClick={() => setActiveTab('incidents')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'incidents' ? 'border-green-600 text-green-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <AlertTriangle size={18} />
          Env. Incidents
        </button>
        <button
          onClick={() => setActiveTab('audits')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'audits' ? 'border-green-600 text-green-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <ClipboardCheck size={18} />
          Internal Audits
        </button>
        <button
          onClick={() => setActiveTab('projects')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'projects' ? 'border-green-600 text-green-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Lightbulb size={18} />
          Efficiency Projects
        </button>
        <button
          onClick={() => setActiveTab('chemicals')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'chemicals' ? 'border-green-600 text-green-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Beaker size={18} />
          Chemical Register
        </button>
        <button
          onClick={() => setActiveTab('biodiversity')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'biodiversity' ? 'border-green-600 text-green-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Leaf size={18} />
          Biodiversity
        </button>
        <button
          onClick={() => setActiveTab('training')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'training' ? 'border-green-600 text-green-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <GraduationCap size={18} />
          Training Matrix
        </button>
        <button
          onClick={() => setActiveTab('emergency')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'emergency' ? 'border-green-600 text-green-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <ShieldAlert size={18} />
          Emergency Prep.
        </button>
        <button
          onClick={() => setActiveTab('stakeholders')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'stakeholders' ? 'border-green-600 text-green-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Users size={18} />
          Stakeholders
        </button>
        <button
          onClick={() => setActiveTab('lca')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'lca' ? 'border-green-600 text-green-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <RefreshCw size={18} />
          LCA Tool
        </button>
      </div>

      {/* Content Area */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        
        {/* Waste Tab */}
        {activeTab === 'waste' && (
          <div className="p-6">
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 text-sm">
                    <th className="p-4 font-medium">Waste Type</th>
                    <th className="p-4 font-medium">Quantity</th>
                    <th className="p-4 font-medium">Transporter</th>
                    <th className="p-4 font-medium">Disposal Facility</th>
                    <th className="p-4 font-medium">Collection Date</th>
                    <th className="p-4 font-medium">Status</th>
                  </tr>
                </thead>
                <tbody>
                  {wasteManifests.length === 0 ? (
                    <tr>
                      <td colSpan={6} className="p-8 text-center text-slate-500">
                        No waste manifests logged yet.
                      </td>
                    </tr>
                  ) : (
                    wasteManifests.map((manifest) => (
                      <tr key={manifest.id} className="border-b border-slate-100 hover:bg-slate-50 transition-colors">
                        <td className="p-4">
                          <span className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium border ${
                            manifest.wasteType === 'Hazardous' || manifest.wasteType === 'Medical' ? 'bg-red-50 text-red-700 border-red-200' :
                            manifest.wasteType === 'Recyclable' ? 'bg-green-50 text-green-700 border-green-200' :
                            'bg-slate-100 text-slate-700 border-slate-200'
                          }`}>
                            {manifest.wasteType}
                          </span>
                        </td>
                        <td className="p-4 font-medium text-slate-900">{manifest.quantity} {manifest.unit}</td>
                        <td className="p-4 text-slate-600">
                          <div className="flex items-center gap-2">
                            <Truck size={14} className="text-slate-400" />
                            {manifest.transporterName}
                          </div>
                        </td>
                        <td className="p-4 text-slate-600">{manifest.disposalFacility}</td>
                        <td className="p-4 text-slate-600">{new Date(manifest.collectionDate).toLocaleDateString()}</td>
                        <td className="p-4">
                          <select
                            value={manifest.status}
                            onChange={(e) => updateManifestStatus(manifest.id, e.target.value as any)}
                            className={`text-sm rounded-lg border-slate-300 focus:ring-green-500 focus:border-green-500 ${
                              manifest.status === 'Disposed' ? 'bg-green-50 text-green-700' :
                              manifest.status === 'In Transit' ? 'bg-blue-50 text-blue-700' :
                              'bg-amber-50 text-amber-700'
                            }`}
                          >
                            <option value="Pending Pickup">Pending Pickup</option>
                            <option value="In Transit">In Transit</option>
                            <option value="Disposed">Disposed</option>
                          </select>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* Spills Tab */}
        {activeTab === 'spills' && (
          <div className="p-6">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {spills.map((spill) => (
                <div key={spill.id} className="border border-slate-200 rounded-xl p-5 bg-white hover:shadow-md transition-shadow">
                  <div className="flex items-start gap-3 mb-4">
                    <div className="bg-amber-50 p-2 rounded-lg text-amber-600 shrink-0">
                      <CloudRain size={24} />
                    </div>
                    <div>
                      <h3 className="font-semibold text-slate-900">{spill.substance} Spill</h3>
                      <p className="text-sm text-slate-500">{new Date(spill.dateOfSpill).toLocaleDateString()}</p>
                    </div>
                  </div>
                  
                  <div className="space-y-2 text-sm text-slate-600 mb-4">
                    <p><span className="font-medium text-slate-700">Volume:</span> {spill.volume}</p>
                    <p><span className="font-medium text-slate-700">Location:</span> {spill.location}</p>
                  </div>

                  <div className="flex flex-col gap-2 border-t border-slate-100 pt-4">
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-slate-600">Containment Status:</span>
                      {spill.contained ? (
                        <span className="flex items-center gap-1 text-green-600 font-medium">
                          <CheckCircle size={14} /> Contained
                        </span>
                      ) : (
                        <span className="flex items-center gap-1 text-red-600 font-medium">
                          <XCircle size={14} /> Uncontained
                        </span>
                      )}
                    </div>
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-slate-600">Reported to DEA:</span>
                      {spill.reportedToAuthorities ? (
                        <span className="flex items-center gap-1 text-green-600 font-medium">
                          <CheckCircle size={14} /> Yes
                        </span>
                      ) : (
                        <span className="flex items-center gap-1 text-amber-600 font-medium">
                          <AlertTriangle size={14} /> Pending
                        </span>
                      )}
                    </div>
                  </div>
                </div>
              ))}
              {spills.length === 0 && (
                <div className="col-span-full p-8 text-center text-slate-500 bg-slate-50 rounded-xl border border-dashed border-slate-300">
                  No environmental spills logged.
                </div>
              )}
            </div>
          </div>
        )}

        {/* Carbon Tab */}
        {activeTab === 'carbon' && (
          <div className="p-6">
            <div className="max-w-3xl mx-auto text-center py-12">
              <div className="bg-green-50 w-20 h-20 rounded-full flex items-center justify-center mx-auto mb-6 text-green-600">
                <Factory size={40} />
              </div>
              <h2 className="text-2xl font-bold text-slate-900 mb-4">Carbon Footprint Calculator</h2>
              <p className="text-slate-600 mb-8">
                Track Scope 1 (Direct) and Scope 2 (Indirect) emissions. Integration with smart meters and fleet management systems coming soon.
              </p>
              
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-6 text-left">
                <div className="border border-slate-200 rounded-xl p-6 bg-white shadow-sm">
                  <h3 className="font-semibold text-slate-900 mb-2 flex items-center gap-2">
                    Scope 1 Emissions
                  </h3>
                  <p className="text-sm text-slate-500 mb-4">Direct emissions from owned or controlled sources (e.g., company vehicles, generators).</p>
                  <div className="text-3xl font-bold text-slate-900 mb-1">124.5 <span className="text-lg text-slate-500 font-normal">tCO2e</span></div>
                  <p className="text-xs text-green-600 font-medium">↓ 5% from last month</p>
                </div>
                
                <div className="border border-slate-200 rounded-xl p-6 bg-white shadow-sm">
                  <h3 className="font-semibold text-slate-900 mb-2 flex items-center gap-2">
                    Scope 2 Emissions
                  </h3>
                  <p className="text-sm text-slate-500 mb-4">Indirect emissions from the generation of purchased electricity, steam, heating and cooling.</p>
                  <div className="text-3xl font-bold text-slate-900 mb-1">89.2 <span className="text-lg text-slate-500 font-normal">tCO2e</span></div>
                  <p className="text-xs text-red-600 font-medium">↑ 2% from last month</p>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Aspects & Impacts Tab */}
        {activeTab === 'aspects' && (
          <div className="p-6">
            <AspectsImpactsRegister />
          </div>
        )}

        {/* Legal Register Tab */}
        {activeTab === 'legal' && (
          <div className="p-6">
            <EnvironmentalLegalRegister />
          </div>
        )}

        {/* Water Balance Tab */}
        {activeTab === 'water' && (
          <div className="p-6">
            <WaterBalanceTracker />
          </div>
        )}

        {/* Air Quality Tab */}
        {activeTab === 'air' && (
          <div className="p-6">
            <AirQualityMonitor />
          </div>
        )}

        {/* Waste Analytics Tab */}
        {activeTab === 'analytics' && (
          <div className="p-6">
            <WasteHierarchyAnalytics />
          </div>
        )}

        {/* Energy Management Tab */}
        {activeTab === 'energy' && (
          <div className="p-6">
            <EnergyManagementDashboard />
          </div>
        )}

        {/* Environmental Incident Tab */}
        {activeTab === 'incidents' && (
          <div className="p-6">
            <EnvironmentalIncidentLog />
          </div>
        )}

        {/* Internal Audit Tab */}
        {activeTab === 'audits' && (
          <div className="p-6">
            <EnvironmentalInternalAudit />
          </div>
        )}

        {/* Efficiency Projects Tab */}
        {activeTab === 'projects' && (
          <div className="p-6">
            <ResourceEfficiencyProjects />
          </div>
        )}

        {/* Chemical Register Tab */}
        {activeTab === 'chemicals' && (
          <div className="p-6">
            <ChemicalSubstanceRegisterEnv />
          </div>
        )}

        {/* Biodiversity Tab */}
        {activeTab === 'biodiversity' && (
          <div className="p-6">
            <BiodiversityRegister />
          </div>
        )}

        {/* Training Tab */}
        {activeTab === 'training' && (
          <div className="p-6">
            <EnvironmentalTrainingMatrix />
          </div>
        )}

        {/* Emergency Tab */}
        {activeTab === 'emergency' && (
          <div className="p-6">
            <EnvironmentalEmergencyPreparedness />
          </div>
        )}

        {/* Stakeholders Tab */}
        {activeTab === 'stakeholders' && (
          <div className="p-6">
            <EnvironmentalStakeholderLog />
          </div>
        )}

        {/* LCA Tab */}
        {activeTab === 'lca' && (
          <div className="p-6">
            <LifeCycleAssessmentTool />
          </div>
        )}
      </div>

      {/* Add Manifest Modal */}
      {isAddingManifest && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex justify-between items-center">
              <h2 className="text-xl font-bold text-slate-900">Log Waste Manifest</h2>
              <button onClick={() => setIsAddingManifest(false)} className="text-slate-400 hover:text-slate-600">
                <XCircle size={24} />
              </button>
            </div>
            <form onSubmit={handleAddManifest} className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Waste Type</label>
                <select 
                  required
                  value={wasteType}
                  onChange={(e) => setWasteType(e.target.value as any)}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                >
                  <option value="General">General</option>
                  <option value="Recyclable">Recyclable</option>
                  <option value="Hazardous">Hazardous</option>
                  <option value="Medical">Medical</option>
                  <option value="E-Waste">E-Waste</option>
                </select>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Quantity</label>
                  <input 
                    type="number" 
                    required
                    min="0"
                    step="0.01"
                    value={quantity}
                    onChange={(e) => setQuantity(e.target.value)}
                    className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Unit</label>
                  <select 
                    required
                    value={unit}
                    onChange={(e) => setUnit(e.target.value as any)}
                    className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                  >
                    <option value="kg">kg</option>
                    <option value="tons">tons</option>
                    <option value="liters">liters</option>
                    <option value="m3">m³</option>
                  </select>
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Transporter Name</label>
                <input 
                  type="text" 
                  required
                  value={transporterName}
                  onChange={(e) => setTransporterName(e.target.value)}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Disposal Facility</label>
                <input 
                  type="text" 
                  required
                  value={disposalFacility}
                  onChange={(e) => setDisposalFacility(e.target.value)}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Collection Date</label>
                <input 
                  type="date" 
                  required
                  value={collectionDate}
                  onChange={(e) => setCollectionDate(e.target.value)}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                />
              </div>
              <div className="pt-4 flex justify-end gap-3">
                <button 
                  type="button"
                  onClick={() => setIsAddingManifest(false)}
                  className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
                >
                  Cancel
                </button>
                <button 
                  type="submit"
                  className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
                >
                  Save Manifest
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Add Spill Modal */}
      {isAddingSpill && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex justify-between items-center">
              <h2 className="text-xl font-bold text-slate-900">Report Environmental Spill</h2>
              <button onClick={() => setIsAddingSpill(false)} className="text-slate-400 hover:text-slate-600">
                <XCircle size={24} />
              </button>
            </div>
            <form onSubmit={handleAddSpill} className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Substance Spilled</label>
                <input 
                  type="text" 
                  required
                  value={substance}
                  onChange={(e) => setSubstance(e.target.value)}
                  placeholder="e.g., Diesel, Hydraulic Oil"
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-amber-500 focus:border-transparent"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Estimated Volume</label>
                <input 
                  type="text" 
                  required
                  value={volume}
                  onChange={(e) => setVolume(e.target.value)}
                  placeholder="e.g., 50 Liters"
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-amber-500 focus:border-transparent"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Location</label>
                <input 
                  type="text" 
                  required
                  value={location}
                  onChange={(e) => setLocation(e.target.value)}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-amber-500 focus:border-transparent"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Date & Time of Spill</label>
                <input 
                  type="datetime-local" 
                  required
                  value={dateOfSpill}
                  onChange={(e) => setDateOfSpill(e.target.value)}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-amber-500 focus:border-transparent"
                />
              </div>
              
              <div className="space-y-3 pt-2">
                <div className="flex items-center gap-2">
                  <input 
                    type="checkbox" 
                    id="contained"
                    checked={contained}
                    onChange={(e) => setContained(e.target.checked)}
                    className="w-4 h-4 text-amber-600 rounded border-slate-300 focus:ring-amber-500"
                  />
                  <label htmlFor="contained" className="text-sm font-medium text-slate-700">
                    Spill is fully contained
                  </label>
                </div>
                <div className="flex items-center gap-2">
                  <input 
                    type="checkbox" 
                    id="reported"
                    checked={reportedToAuthorities}
                    onChange={(e) => setReportedToAuthorities(e.target.checked)}
                    className="w-4 h-4 text-amber-600 rounded border-slate-300 focus:ring-amber-500"
                  />
                  <label htmlFor="reported" className="text-sm font-medium text-slate-700">
                    Reported to Environmental Authorities (DEA)
                  </label>
                </div>
              </div>

              <div className="pt-4 flex justify-end gap-3">
                <button 
                  type="button"
                  onClick={() => setIsAddingSpill(false)}
                  className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
                >
                  Cancel
                </button>
                <button 
                  type="submit"
                  className="px-4 py-2 bg-amber-600 text-white rounded-lg hover:bg-amber-700 transition-colors"
                >
                  Save Record
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

    </div>
  );
}
