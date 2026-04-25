import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy, doc, updateDoc } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { 
  HeartPulse, 
  Activity, 
  Lock, 
  Plus, 
  CheckCircle, 
  XCircle, 
  AlertTriangle,
  Search,
  Watch,
  Camera,
  Heart,
  Stethoscope,
  UserCheck,
  Syringe,
  BriefcaseMedical,
  BatteryWarning,
  FlaskConical,
  HeartHandshake,
  LineChart,
  Video,
  Ambulance,
  Beaker,
  ClipboardList,
  Ear,
  Shield,
  Thermometer,
  Package,
  LayoutDashboard,
  Download,
  User,
  Calendar,
  FileText
} from 'lucide-react';
import {
  Container,
  Paper,
  Box,
  Typography,
  Tabs,
  Tab,
  TextField,
  MenuItem,
  Button,
} from '@mui/material';
import { PieChart, Pie, Cell, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip as RechartsTooltip, Legend, ResponsiveContainer } from 'recharts';
import HealthSurveillanceRecords from '../components/HealthSurveillanceRecords';
import WearableBiometrics from '../components/WearableBiometrics';
import AIErgonomicAssessment from '../components/AIErgonomicAssessment';
import WellbeingPulse from '../components/WellbeingPulse';
import ReturnToWork from '../components/ReturnToWork';
import VaccinationManager from '../components/VaccinationManager';
import IllnessInvestigation from '../components/IllnessInvestigation';
import FirstAidLog from '../components/FirstAidLog';
import FatigueRisk from '../components/FatigueRisk';
import SubstanceTestingLog from '../components/SubstanceTestingLog';
import WellnessCampaigns from '../components/WellnessCampaigns';
import HealthAnalytics from '../components/HealthAnalytics';
import TelemedicineConsults from '../components/TelemedicineConsults';
import MedevacPlanning from '../components/MedevacPlanning';
import BiologicalMonitoring from '../components/BiologicalMonitoring';
import HealthRiskAssessment from '../components/HealthRiskAssessment';
import AudiometricAnalysis from '../components/AudiometricAnalysis';
import RespiratoryFitTesting from '../components/RespiratoryFitTesting';
import HeatStressMonitor from '../components/HeatStressMonitor';
import OccHealthInventory from '../components/OccHealthInventory';

interface MedicalRecord {
  id: string;
  employeeName: string;
  idNumber: string;
  medicalType: 'Pre-employment' | 'Annual' | 'Exit' | 'Baseline' | 'Other';
  status: 'Fit' | 'Fit with Restrictions' | 'Unfit';
  restrictions?: string;
  dateConducted: string;
  nextDueDate: string;
  authorId: string;
  createdAt: string;
}

interface HygieneSurvey {
  id: string;
  zoneName: string;
  hazardType: 'Noise' | 'Dust' | 'Chemical' | 'Ergonomic' | 'Illumination' | 'Thermal' | 'Other';
  readingValue: string;
  legalLimit: string;
  requiresMedicalSurveillance: boolean;
  dateConducted: string;
  authorId: string;
  createdAt: string;
}

export default function OccupationalHealth() {
  const [activeTab, setActiveTab] = useState<'dashboard' | 'chemicals' | 'medicals' | 'hygiene' | 'surveillance' | 'biometrics' | 'ergonomics' | 'wellbeing' | 'rtw' | 'vaccination' | 'illness' | 'firstaid' | 'fatigue' | 'substance' | 'wellness' | 'analytics' | 'telemedicine' | 'medevac' | 'biological' | 'hra' | 'audiometry' | 'fit-test' | 'heat' | 'inventory'>('dashboard');
  const [medicalRecords, setMedicalRecords] = useState<MedicalRecord[]>([]);
  const [hygieneSurveys, setHygieneSurveys] = useState<HygieneSurvey[]>([]);
  
  const [isAddingMedical, setIsAddingMedical] = useState(false);
  const [isAddingSurvey, setIsAddingSurvey] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [viewingWorker, setViewingWorker] = useState<MedicalRecord | null>(null);

  // Mock Data for Dashboard Charts
  const fitnessData = [
    { name: 'Fit', value: 145, color: '#10b981' },
    { name: 'Fit with Restrictions', value: 32, color: '#f59e0b' },
    { name: 'Unfit', value: 8, color: '#ef4444' },
  ];

  const chemicalHazardData = [
    { name: 'Flammable', count: 45 },
    { name: 'Corrosive', count: 28 },
    { name: 'Toxic', count: 15 },
    { name: 'Oxidizing', count: 12 },
    { name: 'Explosive', count: 4 },
  ];

  // Mock data for Chemicals
  const [chemicals] = useState([
    { id: 'CHEM-001', name: 'Acetone', unNumber: 'UN 1090', hazardClass: 'Flammable Liquid (Class 3)', location: 'Flammable Store A' },
    { id: 'CHEM-002', name: 'Hydrochloric Acid (32%)', unNumber: 'UN 1789', hazardClass: 'Corrosive (Class 8)', location: 'Acid Store B' },
    { id: 'CHEM-003', name: 'Sodium Cyanide', unNumber: 'UN 1689', hazardClass: 'Toxic (Class 6.1)', location: 'Secure Poison Store' },
  ]);

  // Medical Form
  const [employeeName, setEmployeeName] = useState('');
  const [idNumber, setIdNumber] = useState('');
  const [medicalType, setMedicalType] = useState<MedicalRecord['medicalType']>('Annual');
  const [medicalStatus, setMedicalStatus] = useState<MedicalRecord['status']>('Fit');
  const [restrictions, setRestrictions] = useState('');
  const [dateConducted, setDateConducted] = useState('');
  const [nextDueDate, setNextDueDate] = useState('');

  // Hygiene Form
  const [zoneName, setZoneName] = useState('');
  const [hazardType, setHazardType] = useState<HygieneSurvey['hazardType']>('Noise');
  const [readingValue, setReadingValue] = useState('');
  const [legalLimit, setLegalLimit] = useState('');
  const [requiresMedicalSurveillance, setRequiresMedicalSurveillance] = useState(false);
  const [surveyDate, setSurveyDate] = useState('');

  useEffect(() => {
    if (!auth.currentUser) return;

    const qMedicals = query(collection(db, 'medical_records'), orderBy('createdAt', 'desc'));
    const unsubscribeMedicals = onSnapshot(qMedicals, (snapshot) => {
      const records = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as MedicalRecord[];
      setMedicalRecords(records);
    }, (error) => {
      handleFirestoreError(error, 'list' as any, 'medical_records');
    });

    const qSurveys = query(collection(db, 'hygiene_surveys'), orderBy('createdAt', 'desc'));
    const unsubscribeSurveys = onSnapshot(qSurveys, (snapshot) => {
      const surveys = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as HygieneSurvey[];
      setHygieneSurveys(surveys);
    }, (error) => {
      handleFirestoreError(error, 'list' as any, 'hygiene_surveys');
    });

    return () => {
      unsubscribeMedicals();
      unsubscribeSurveys();
    };
  }, []);

  const handleAddMedical = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;

    try {
      const newRecord = {
        employeeName,
        idNumber,
        medicalType,
        status: medicalStatus,
        restrictions: medicalStatus === 'Fit with Restrictions' ? restrictions : '',
        dateConducted: new Date(dateConducted).toISOString(),
        nextDueDate: new Date(nextDueDate).toISOString(),
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      };

      await addDoc(collection(db, 'medical_records'), newRecord);
      setIsAddingMedical(false);
      // Reset form
      setEmployeeName('');
      setIdNumber('');
      setMedicalType('Annual');
      setMedicalStatus('Fit');
      setRestrictions('');
      setDateConducted('');
      setNextDueDate('');
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'medical_records');
    }
  };

  const handleAddSurvey = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;

    try {
      const newSurvey = {
        zoneName,
        hazardType,
        readingValue,
        legalLimit,
        requiresMedicalSurveillance,
        dateConducted: new Date(surveyDate).toISOString(),
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      };

      await addDoc(collection(db, 'hygiene_surveys'), newSurvey);
      setIsAddingSurvey(false);
      // Reset form
      setZoneName('');
      setHazardType('Noise');
      setReadingValue('');
      setLegalLimit('');
      setRequiresMedicalSurveillance(false);
      setSurveyDate('');
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'hygiene_surveys');
    }
  };

  const filteredMedicals = medicalRecords.filter(m => 
    m.employeeName.toLowerCase().includes(searchQuery.toLowerCase()) ||
    m.idNumber.includes(searchQuery)
  );

  return (
    <Container maxWidth="xl" sx={{ mt: 4, mb: 4 }}>
      <Box sx={{ mb: 4, display: 'flex', flexDirection: { xs: 'column', md: 'row' }, alignItems: 'center', justifyContent: 'space-between', gap: 2 }}>
        <Box>
          <Typography variant="h4" component="h1" sx={{ fontWeight: 800, display: 'flex', alignItems: 'center', gap: 1 }}>
            Occupational Health <Lock size={20} className="text-slate-400" />
          </Typography>
          <Typography variant="body1" color="text.secondary">POPIA-gated medical surveillance and hygiene surveys.</Typography>
        </Box>
        <Box sx={{ display: 'flex', gap: 2 }}>
          {activeTab === 'medicals' && (
            <button 
              onClick={() => setIsAddingMedical(true)}
              className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
            >
              <Plus size={20} />
              Log Medical
            </button>
          )}
          {activeTab === 'hygiene' && (
            <button 
              onClick={() => setIsAddingSurvey(true)}
              className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
            >
              <Plus size={20} />
              Log Survey
            </button>
          )}
        </Box>
      </Box>

      <Paper elevation={3} sx={{ overflow: 'hidden' }}>
        <Tabs 
          value={activeTab === 'dashboard' ? 0 : activeTab === 'medicals' ? 1 : activeTab === 'chemicals' ? 2 : activeTab === 'hygiene' ? 3 : 4 } 
          onChange={(_, newValue) => {
            const tabs = ['dashboard', 'medicals', 'chemicals', 'hygiene', 'surveillance'];
            setActiveTab(tabs[newValue] as any);
          }} 
          variant="scrollable"
          scrollButtons="auto"
          sx={{ borderBottom: 1, borderColor: 'divider' }}
        >
          <Tab icon={<LayoutDashboard size={18} />} iconPosition="start" label="Command Center" />
          <Tab icon={<HeartPulse size={18} />} iconPosition="start" label="Medical Surveillance" />
          <Tab icon={<FlaskConical size={18} />} iconPosition="start" label="Chemical Register (SDS)" />
          <Tab icon={<Activity size={18} />} iconPosition="start" label="Occupational Hygiene" />
          <Tab icon={<Stethoscope size={18} />} iconPosition="start" label="Health Surveillance" />
        </Tabs>
        <button
          onClick={() => setActiveTab('medicals')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'medicals' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <HeartPulse size={18} />
          Medical Surveillance
        </button>
        <button
          onClick={() => setActiveTab('chemicals')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'chemicals' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <FlaskConical size={18} />
          Chemical Register (SDS)
        </button>
        <button
          onClick={() => setActiveTab('hygiene')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'hygiene' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Activity size={18} />
          Occupational Hygiene
        </button>
        <button
          onClick={() => setActiveTab('surveillance')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'surveillance' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Stethoscope size={18} />
          Health Surveillance
        </button>
        <button
          onClick={() => setActiveTab('biometrics')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'biometrics' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Watch size={18} />
          Wearable Biometrics
        </button>
        <button
          onClick={() => setActiveTab('ergonomics')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'ergonomics' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Camera size={18} />
          AI Ergonomics
        </button>
        <button
          onClick={() => setActiveTab('wellbeing')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'wellbeing' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Heart size={18} />
          Wellbeing Pulse
        </button>
        <button
          onClick={() => setActiveTab('rtw')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'rtw' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <UserCheck size={18} />
          Return to Work
        </button>
        <button
          onClick={() => setActiveTab('vaccination')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'vaccination' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Syringe size={18} />
          Vaccinations
        </button>
        <button
          onClick={() => setActiveTab('illness')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'illness' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Stethoscope size={18} />
          Illness Investigation
        </button>
        <button
          onClick={() => setActiveTab('firstaid')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'firstaid' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <BriefcaseMedical size={18} />
          First Aid Log
        </button>
        <button
          onClick={() => setActiveTab('fatigue')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'fatigue' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <BatteryWarning size={18} />
          Fatigue Risk
        </button>
        <button
          onClick={() => setActiveTab('substance')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'substance' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <FlaskConical size={18} />
          Substance Testing
        </button>
        <button
          onClick={() => setActiveTab('wellness')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'wellness' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <HeartHandshake size={18} />
          Wellness Campaigns
        </button>
        <button
          onClick={() => setActiveTab('analytics')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'analytics' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <LineChart size={18} />
          Health Analytics
        </button>
        <button
          onClick={() => setActiveTab('telemedicine')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'telemedicine' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Video size={18} />
          Telemedicine
        </button>
        <button
          onClick={() => setActiveTab('medevac')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'medevac' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Ambulance size={18} />
          Medevac Planning
        </button>
        <button
          onClick={() => setActiveTab('hra')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'hra' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <ClipboardList size={18} />
          HRA Builder
        </button>
        <button
          onClick={() => setActiveTab('biological')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'biological' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Beaker size={18} />
          Biological Monitoring
        </button>
        <button
          onClick={() => setActiveTab('audiometry')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'audiometry' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Ear size={18} />
          Audiometric Analysis
        </button>
        <button
          onClick={() => setActiveTab('fit-test')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'fit-test' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Shield size={18} />
          Mask Fit Testing
        </button>
        <button
          onClick={() => setActiveTab('heat')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'heat' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Thermometer size={18} />
          Heat Stress
        </button>
        <button
          onClick={() => setActiveTab('inventory')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'inventory' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Package size={18} />
          Clinic Inventory
        </button>
      
      {/* Content Area */}
      {/* Dashboard Tab */}
      {activeTab === 'dashboard' && (
          <div className="p-6 space-y-6">
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Fitness Overview */}
              <div className="bg-white border border-slate-200 rounded-xl p-6">
                <h3 className="text-lg font-bold text-slate-800 mb-4">Workforce Medical Fitness</h3>
                <div className="h-64">
                  <ResponsiveContainer width="100%" height="100%">
                    <PieChart>
                      <Pie
                        data={fitnessData}
                        cx="50%"
                        cy="50%"
                        innerRadius={60}
                        outerRadius={80}
                        paddingAngle={5}
                        dataKey="value"
                      >
                        {fitnessData.map((entry, index) => (
                          <Cell key={`cell-${index}`} fill={entry.color} />
                        ))}
                      </Pie>
                      <RechartsTooltip />
                      <Legend verticalAlign="bottom" height={36} />
                    </PieChart>
                  </ResponsiveContainer>
                </div>
              </div>

              {/* Chemical Hazards */}
              <div className="bg-white border border-slate-200 rounded-xl p-6">
                <h3 className="text-lg font-bold text-slate-800 mb-4">Chemical Inventory by Hazard Class</h3>
                <div className="h-64">
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={chemicalHazardData} layout="vertical" margin={{ top: 5, right: 30, left: 40, bottom: 5 }}>
                      <CartesianGrid strokeDasharray="3 3" horizontal={false} />
                      <XAxis type="number" />
                      <YAxis dataKey="name" type="category" width={80} tick={{ fontSize: 12 }} />
                      <RechartsTooltip />
                      <Bar dataKey="count" fill="#3b82f6" radius={[0, 4, 4, 0]} />
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Chemicals Tab */}
        {activeTab === 'chemicals' && (
          <div className="p-6">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6">
              <div className="relative flex-1 max-w-md">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={20} />
                <input 
                  type="text" 
                  placeholder="Search chemicals or UN numbers..." 
                  className="w-full pl-10 pr-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
              <button className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors font-medium">
                <Plus size={20} />
                Add Chemical
              </button>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 text-sm">
                    <th className="p-4 font-medium">Product Name</th>
                    <th className="p-4 font-medium">UN Number</th>
                    <th className="p-4 font-medium">Hazard Class</th>
                    <th className="p-4 font-medium">Location</th>
                    <th className="p-4 font-medium text-right">SDS</th>
                  </tr>
                </thead>
                <tbody>
                  {chemicals.map((chem) => (
                    <tr key={chem.id} className="border-b border-slate-100 hover:bg-slate-50 transition-colors">
                      <td className="p-4 font-medium text-slate-900">{chem.name}</td>
                      <td className="p-4 text-slate-600 font-mono text-sm">{chem.unNumber}</td>
                      <td className="p-4">
                        <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium border ${
                          chem.hazardClass.includes('Flammable') ? 'bg-red-50 text-red-700 border-red-200' :
                          chem.hazardClass.includes('Corrosive') ? 'bg-orange-50 text-orange-700 border-orange-200' :
                          'bg-purple-50 text-purple-700 border-purple-200'
                        }`}>
                          {chem.hazardClass}
                        </span>
                      </td>
                      <td className="p-4 text-slate-600">{chem.location}</td>
                      <td className="p-4 text-right">
                        <button className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-medium bg-slate-100 text-slate-700 rounded-lg hover:bg-slate-200 transition-colors">
                          <Download size={14} /> Download SDS
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
        {activeTab === 'surveillance' && (
          <div className="p-6">
            <HealthSurveillanceRecords />
          </div>
        )}

        {/* Biometrics Tab */}
        {activeTab === 'biometrics' && (
          <div className="p-6">
            <WearableBiometrics />
          </div>
        )}

        {/* Ergonomics Tab */}
        {activeTab === 'ergonomics' && (
          <div className="p-6">
            <AIErgonomicAssessment />
          </div>
        )}

        {/* Wellbeing Tab */}
        {activeTab === 'wellbeing' && (
          <div className="p-6">
            <WellbeingPulse />
          </div>
        )}

        {/* RTW Tab */}
        {activeTab === 'rtw' && (
          <div className="p-6">
            <ReturnToWork />
          </div>
        )}

        {/* Vaccination Tab */}
        {activeTab === 'vaccination' && (
          <div className="p-6">
            <VaccinationManager />
          </div>
        )}

        {/* Illness Investigation Tab */}
        {activeTab === 'illness' && (
          <div className="p-6">
            <IllnessInvestigation />
          </div>
        )}

        {/* First Aid Log Tab */}
        {activeTab === 'firstaid' && (
          <div className="p-6">
            <FirstAidLog />
          </div>
        )}

        {/* Fatigue Risk Tab */}
        {activeTab === 'fatigue' && (
          <div className="p-6">
            <FatigueRisk />
          </div>
        )}

        {/* Substance Testing Tab */}
        {activeTab === 'substance' && (
          <div className="p-6">
            <SubstanceTestingLog />
          </div>
        )}

        {/* Wellness Campaigns Tab */}
        {activeTab === 'wellness' && (
          <div className="p-6">
            <WellnessCampaigns />
          </div>
        )}

        {/* Health Analytics Tab */}
        {activeTab === 'analytics' && (
          <div className="p-6">
            <HealthAnalytics />
          </div>
        )}

        {/* Telemedicine Tab */}
        {activeTab === 'telemedicine' && (
          <div className="p-6">
            <TelemedicineConsults />
          </div>
        )}

        {/* Medevac Planning Tab */}
        {activeTab === 'medevac' && (
          <div className="p-6">
            <MedevacPlanning />
          </div>
        )}

        {/* HRA Builder Tab */}
        {activeTab === 'hra' && (
          <div className="p-6">
            <HealthRiskAssessment />
          </div>
        )}

        {/* Biological Monitoring Tab */}
        {activeTab === 'biological' && (
          <div className="p-6">
            <BiologicalMonitoring />
          </div>
        )}

        {/* Audiometry Tab */}
        {activeTab === 'audiometry' && (
          <div className="p-6">
            <AudiometricAnalysis />
          </div>
        )}

        {/* Fit Testing Tab */}
        {activeTab === 'fit-test' && (
          <div className="p-6">
            <RespiratoryFitTesting />
          </div>
        )}

        {/* Heat Stress Tab */}
        {activeTab === 'heat' && (
          <div className="p-6">
            <HeatStressMonitor />
          </div>
        )}

        {/* Inventory Tab */}
        {activeTab === 'inventory' && (
          <div className="p-6">
            <OccHealthInventory />
          </div>
        )}

        {/* Medicals Tab */}
        {activeTab === 'medicals' && (
          <div className="p-6">
            <div className="flex items-center gap-4 mb-6">
              <div className="relative flex-1 max-w-md">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={20} />
                <input 
                  type="text" 
                  placeholder="Search by name or ID..." 
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full pl-10 pr-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 text-sm">
                    <th className="p-4 font-medium">Employee</th>
                    <th className="p-4 font-medium">Type</th>
                    <th className="p-4 font-medium">Status</th>
                    <th className="p-4 font-medium">Date Conducted</th>
                    <th className="p-4 font-medium">Next Due</th>
                    <th className="p-4 font-medium text-right">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredMedicals.length === 0 ? (
                    <tr>
                      <td colSpan={6} className="p-8 text-center text-slate-500">
                        <Lock className="mx-auto mb-2 text-slate-300" size={32} />
                        No medical records found. Access is restricted.
                      </td>
                    </tr>
                  ) : (
                    filteredMedicals.map((record) => {
                      const isDueSoon = new Date(record.nextDueDate).getTime() - new Date().getTime() < 30 * 24 * 60 * 60 * 1000;
                      
                      return (
                        <tr key={record.id} className="border-b border-slate-100 hover:bg-slate-50 transition-colors">
                          <td className="p-4">
                            <p className="font-medium text-slate-900">{record.employeeName}</p>
                            <p className="text-xs text-slate-500 font-mono">{record.idNumber}</p>
                          </td>
                          <td className="p-4 text-slate-600">{record.medicalType}</td>
                          <td className="p-4">
                            {record.status === 'Fit' && (
                              <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800 border border-green-200">
                                <CheckCircle size={12} /> Fit
                              </span>
                            )}
                            {record.status === 'Fit with Restrictions' && (
                              <div className="flex flex-col gap-1">
                                <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-amber-100 text-amber-800 border border-amber-200 w-fit">
                                  <AlertTriangle size={12} /> Restricted
                                </span>
                                <span className="text-xs text-amber-700 max-w-[200px] truncate" title={record.restrictions}>
                                  {record.restrictions}
                                </span>
                              </div>
                            )}
                            {record.status === 'Unfit' && (
                              <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-red-100 text-red-800 border border-red-200">
                                <XCircle size={12} /> Unfit
                              </span>
                            )}
                          </td>
                          <td className="p-4 text-slate-600">{new Date(record.dateConducted).toLocaleDateString()}</td>
                          <td className="p-4">
                            <div className="flex items-center gap-2">
                              <span className={isDueSoon ? 'text-amber-600 font-medium' : 'text-slate-600'}>
                                {new Date(record.nextDueDate).toLocaleDateString()}
                              </span>
                              {isDueSoon && <span title="Due soon"><AlertTriangle size={16} className="text-amber-500" /></span>}
                            </div>
                          </td>
                          <td className="p-4 text-right">
                            <button 
                              onClick={() => setViewingWorker(record)}
                              className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-medium bg-blue-50 text-blue-700 rounded-lg hover:bg-blue-100 transition-colors"
                            >
                              <User size={14} /> 360° View
                            </button>
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

        {/* Hygiene Tab */}
        {activeTab === 'hygiene' && (
          <div className="p-6">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {hygieneSurveys.map((survey) => (
                <div key={survey.id} className="border border-slate-200 rounded-xl p-5 bg-white hover:shadow-md transition-shadow">
                  <div className="flex items-start gap-3 mb-4">
                    <div className="bg-blue-50 p-2 rounded-lg text-blue-600 shrink-0">
                      <Activity size={24} />
                    </div>
                    <div>
                      <h3 className="font-semibold text-slate-900">{survey.zoneName}</h3>
                      <p className="text-sm text-slate-500">{survey.hazardType} Survey</p>
                    </div>
                  </div>
                  
                  <div className="grid grid-cols-2 gap-4 mb-4">
                    <div className="bg-slate-50 p-3 rounded-lg border border-slate-100">
                      <p className="text-xs text-slate-500 mb-1">Reading</p>
                      <p className="font-semibold text-slate-900">{survey.readingValue}</p>
                    </div>
                    <div className="bg-slate-50 p-3 rounded-lg border border-slate-100">
                      <p className="text-xs text-slate-500 mb-1">Legal Limit</p>
                      <p className="font-semibold text-slate-900">{survey.legalLimit}</p>
                    </div>
                  </div>

                  <div className="flex justify-between items-center text-sm border-t border-slate-100 pt-4">
                    <span className="text-slate-500">{new Date(survey.dateConducted).toLocaleDateString()}</span>
                    {survey.requiresMedicalSurveillance ? (
                      <span className="flex items-center gap-1 text-amber-600 font-medium bg-amber-50 px-2 py-1 rounded">
                        <HeartPulse size={14} /> Medicals Req.
                      </span>
                    ) : (
                      <span className="text-slate-400">No medicals req.</span>
                    )}
                  </div>
                </div>
              ))}
              {hygieneSurveys.length === 0 && (
                <div className="col-span-full p-8 text-center text-slate-500 bg-slate-50 rounded-xl border border-dashed border-slate-300">
                  No hygiene surveys logged yet.
                </div>
              )}
            </div>
          </div>
        )}
      </Paper>
      {/* Add Medical Modal */}
      {isAddingMedical && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex justify-between items-center">
              <h2 className="text-xl font-bold text-slate-900 flex items-center gap-2">
                Log Medical Record <Lock size={18} className="text-slate-400" />
              </h2>
              <button onClick={() => setIsAddingMedical(false)} className="text-slate-400 hover:text-slate-600">
                <XCircle size={24} />
              </button>
            </div>
            <form onSubmit={handleAddMedical} className="p-6 space-y-4">
              <TextField 
                fullWidth
                label="Employee Name"
                required
                value={employeeName}
                onChange={(e) => setEmployeeName(e.target.value)}
              />
              <TextField 
                fullWidth
                label="ID / Passport Number"
                required
                value={idNumber}
                onChange={(e) => setIdNumber(e.target.value)}
                inputProps={{ style: { fontFamily: 'monospace' } }}
              />
              <Box sx={{ display: 'flex', gap: 2 }}>
                <TextField 
                  select
                  fullWidth
                  label="Medical Type"
                  required
                  value={medicalType}
                  onChange={(e) => setMedicalType(e.target.value as any)}
                >
                  {['Pre-employment', 'Annual', 'Exit', 'Baseline', 'Other'].map(option => (
                    <MenuItem key={option} value={option}>{option}</MenuItem>
                  ))}
                </TextField>
                <TextField 
                  select
                  fullWidth
                  label="Status"
                  required
                  value={medicalStatus}
                  onChange={(e) => setMedicalStatus(e.target.value as any)}
                >
                  {['Fit', 'Fit with Restrictions', 'Unfit'].map(option => (
                    <MenuItem key={option} value={option}>{option}</MenuItem>
                  ))}
                </TextField>
              </Box>
              
              {medicalStatus === 'Fit with Restrictions' && (
                <TextField 
                  fullWidth
                  label="Restrictions"
                  required
                  value={restrictions}
                  onChange={(e) => setRestrictions(e.target.value)}
                  placeholder="e.g., No heavy lifting > 10kg"
                  multiline
                  rows={2}
                />
              )}

              <Box sx={{ display: 'flex', gap: 2 }}>
                <TextField 
                  fullWidth
                  type="date"
                  label="Date Conducted"
                  InputLabelProps={{ shrink: true }}
                  required
                  value={dateConducted}
                  onChange={(e) => setDateConducted(e.target.value)}
                />
                <TextField 
                  fullWidth
                  type="date"
                  label="Next Due Date"
                  InputLabelProps={{ shrink: true }}
                  required
                  value={nextDueDate}
                  onChange={(e) => setNextDueDate(e.target.value)}
                />
              </Box>
              <Box sx={{ pt: 4, display: 'flex', justifyContent: 'flex-end', gap: 2 }}>
                <Button onClick={() => setIsAddingMedical(false)}>Cancel</Button>
                <Button type="submit" variant="contained">Save Record</Button>
              </Box>
            </form>
          </div>
        </div>
      )}

      {/* Add Survey Modal */}
      {isAddingSurvey && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex justify-between items-center">
              <h2 className="text-xl font-bold text-slate-900">Log Hygiene Survey</h2>
              <button onClick={() => setIsAddingSurvey(false)} className="text-slate-400 hover:text-slate-600">
                <XCircle size={24} />
              </button>
            </div>
            <form onSubmit={handleAddSurvey} className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Zone / Area Name</label>
                <input 
                  type="text" 
                  required
                  value={zoneName}
                  onChange={(e) => setZoneName(e.target.value)}
                  placeholder="e.g., Generator Room"
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Hazard Type</label>
                <select 
                  required
                  value={hazardType}
                  onChange={(e) => setHazardType(e.target.value as any)}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                >
                  <option value="Noise">Noise</option>
                  <option value="Dust">Dust</option>
                  <option value="Chemical">Chemical</option>
                  <option value="Ergonomic">Ergonomic</option>
                  <option value="Illumination">Illumination</option>
                  <option value="Thermal">Thermal</option>
                  <option value="Other">Other</option>
                </select>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Reading Value</label>
                  <input 
                    type="text" 
                    required
                    value={readingValue}
                    onChange={(e) => setReadingValue(e.target.value)}
                    placeholder="e.g., 88 dB(A)"
                    className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Legal Limit</label>
                  <input 
                    type="text" 
                    required
                    value={legalLimit}
                    onChange={(e) => setLegalLimit(e.target.value)}
                    placeholder="e.g., 85 dB(A)"
                    className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Date Conducted</label>
                <input 
                  type="date" 
                  required
                  value={surveyDate}
                  onChange={(e) => setSurveyDate(e.target.value)}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
              <div className="flex items-center gap-2 pt-2">
                <input 
                  type="checkbox" 
                  id="reqMed"
                  checked={requiresMedicalSurveillance}
                  onChange={(e) => setRequiresMedicalSurveillance(e.target.checked)}
                  className="w-4 h-4 text-blue-600 rounded border-slate-300 focus:ring-blue-500"
                />
                <label htmlFor="reqMed" className="text-sm font-medium text-slate-700">
                  Triggers Medical Surveillance for Zone
                </label>
              </div>
              <div className="pt-4 flex justify-end gap-3">
                <button 
                  type="button"
                  onClick={() => setIsAddingSurvey(false)}
                  className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
                >
                  Cancel
                </button>
                <button 
                  type="submit"
                  className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                >
                  Save Survey
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Deep View Modal */}
      {viewingWorker && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-slate-50 rounded-2xl shadow-2xl w-full max-w-5xl max-h-[90vh] overflow-hidden flex flex-col border border-slate-200">
            {/* Header */}
            <div className="bg-white p-6 border-b border-slate-200 flex justify-between items-start shrink-0">
              <div className="flex items-center gap-4">
                <div className="w-16 h-16 bg-blue-100 text-blue-600 rounded-2xl flex items-center justify-center">
                  <User size={32} />
                </div>
                <div>
                  <h2 className="text-2xl font-black text-slate-900 tracking-tight">{viewingWorker.employeeName}</h2>
                  <div className="flex items-center gap-3 mt-1 text-sm text-slate-500 font-medium">
                    <span className="font-mono bg-slate-100 px-2 py-0.5 rounded">{viewingWorker.idNumber}</span>
                    <span>•</span>
                    <span className="flex items-center gap-1">
                      <HeartPulse size={14} /> {viewingWorker.medicalType}
                    </span>
                  </div>
                </div>
              </div>
              <button 
                onClick={() => setViewingWorker(null)}
                className="p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded-xl transition-colors"
              >
                <XCircle size={24} />
              </button>
            </div>

            {/* Content */}
            <div className="flex-1 overflow-y-auto p-6">
              <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                
                {/* Left Column: Quick Stats & Status */}
                <div className="space-y-6">
                  <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-sm">
                    <h3 className="text-sm font-bold text-slate-900 uppercase tracking-wider mb-4">Current Status</h3>
                    <div className={`p-4 rounded-xl border ${
                      viewingWorker.status === 'Fit' ? 'bg-green-50 border-green-200 text-green-800' :
                      viewingWorker.status === 'Fit with Restrictions' ? 'bg-amber-50 border-amber-200 text-amber-800' :
                      'bg-red-50 border-red-200 text-red-800'
                    }`}>
                      <div className="flex items-center gap-2 font-bold mb-2">
                        {viewingWorker.status === 'Fit' && <CheckCircle size={20} />}
                        {viewingWorker.status === 'Fit with Restrictions' && <AlertTriangle size={20} />}
                        {viewingWorker.status === 'Unfit' && <XCircle size={20} />}
                        {viewingWorker.status}
                      </div>
                      {viewingWorker.restrictions && (
                        <p className="text-sm opacity-90">{viewingWorker.restrictions}</p>
                      )}
                    </div>
                    <div className="mt-4 space-y-3">
                      <div className="flex justify-between items-center text-sm">
                        <span className="text-slate-500">Last Exam</span>
                        <span className="font-medium text-slate-900">{new Date(viewingWorker.dateConducted).toLocaleDateString()}</span>
                      </div>
                      <div className="flex justify-between items-center text-sm">
                        <span className="text-slate-500">Next Due</span>
                        <span className="font-medium text-slate-900">{new Date(viewingWorker.nextDueDate).toLocaleDateString()}</span>
                      </div>
                    </div>
                  </div>

                  <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-sm">
                    <h3 className="text-sm font-bold text-slate-900 uppercase tracking-wider mb-4">Fatigue Risk Score</h3>
                    <div className="flex items-center gap-4">
                      <div className="w-16 h-16 rounded-full border-4 border-green-500 flex items-center justify-center font-black text-xl text-green-600">
                        12
                      </div>
                      <div>
                        <p className="font-bold text-slate-900">Low Risk</p>
                        <p className="text-xs text-slate-500 mt-1">Based on recent shift patterns and biometric data.</p>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Right Column: History & Details */}
                <div className="lg:col-span-2 space-y-6">
                  <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-sm">
                    <h3 className="text-sm font-bold text-slate-900 uppercase tracking-wider mb-4 flex items-center gap-2">
                      <FileText size={16} className="text-blue-600" />
                      Medical History (Annexure 3)
                    </h3>
                    <div className="space-y-4">
                      <div className="flex items-start gap-4 p-4 rounded-xl bg-slate-50 border border-slate-100">
                        <div className="bg-blue-100 p-2 rounded-lg text-blue-600 shrink-0">
                          <Stethoscope size={20} />
                        </div>
                        <div className="flex-1">
                          <div className="flex justify-between items-start">
                            <h4 className="font-bold text-slate-900">Periodic Medical</h4>
                            <span className="text-xs font-medium text-slate-500 bg-white px-2 py-1 rounded border border-slate-200">
                              {new Date(viewingWorker.dateConducted).toLocaleDateString()}
                            </span>
                          </div>
                          <p className="text-sm text-slate-600 mt-1">Routine annual checkup. Audiometric and lung function tests within normal parameters.</p>
                          <div className="mt-3 flex gap-2">
                            <button className="text-xs font-medium text-blue-600 bg-blue-50 px-3 py-1.5 rounded-lg hover:bg-blue-100 transition-colors">
                              View Full Report
                            </button>
                            <button className="text-xs font-medium text-slate-600 bg-white border border-slate-200 px-3 py-1.5 rounded-lg hover:bg-slate-50 transition-colors">
                              Download PDF
                            </button>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>

                  <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-sm">
                    <h3 className="text-sm font-bold text-slate-900 uppercase tracking-wider mb-4 flex items-center gap-2">
                      <Activity size={16} className="text-purple-600" />
                      Chemical Exposure Log
                    </h3>
                    <table className="w-full text-left text-sm">
                      <thead>
                        <tr className="border-b border-slate-200 text-slate-500">
                          <th className="pb-2 font-medium">Chemical</th>
                          <th className="pb-2 font-medium">Date</th>
                          <th className="pb-2 font-medium">Duration</th>
                          <th className="pb-2 font-medium">PPE Used</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-slate-100">
                        <tr>
                          <td className="py-3 font-medium text-slate-900">Acetone</td>
                          <td className="py-3 text-slate-600">2025-10-12</td>
                          <td className="py-3 text-slate-600">4 Hours</td>
                          <td className="py-3 text-slate-600">Half-mask respirator</td>
                        </tr>
                        <tr>
                          <td className="py-3 font-medium text-slate-900">Hydrochloric Acid</td>
                          <td className="py-3 text-slate-600">2025-09-05</td>
                          <td className="py-3 text-slate-600">2 Hours</td>
                          <td className="py-3 text-slate-600">Full face shield, gloves</td>
                        </tr>
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </Container>
  );
}
