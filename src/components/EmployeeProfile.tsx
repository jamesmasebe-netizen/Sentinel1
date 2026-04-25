import React, { useState, useEffect } from 'react';
import { 
  ArrowLeft, 
  Mail, 
  Phone, 
  Calendar, 
  MapPin, 
  Building2, 
  ShieldCheck, 
  HeartPulse, 
  GraduationCap, 
  ClipboardList, 
  AlertTriangle, 
  FileText, 
  BadgeCheck, 
  Clock, 
  Plus, 
  ChevronRight,
  ExternalLink,
  Download,
  Edit2,
  Trash2,
  CheckCircle2,
  XCircle,
  Truck,
  HardHat,
  Stethoscope,
  LifeBuoy,
  LayoutDashboard,
  Users
} from 'lucide-react';
import { collection, query, where, onSnapshot, orderBy, limit } from 'firebase/firestore';
import { db } from '../lib/firebase';
import { format } from 'date-fns';
import { motion } from 'framer-motion';
import EmployeeInduction from './EmployeeInduction';
import EmployeeAuthorizations from './EmployeeAuthorizations';
import EmployeePPETracker from './EmployeePPETracker';
import FatigueRisk from './FatigueRisk';

interface Employee {
  id: string;
  fullName: string;
  employeeCode: string;
  idNumber: string;
  jobTitle: string;
  department: string;
  status: 'Active' | 'Inactive' | 'On Leave' | 'Terminated';
  email?: string;
  phone?: string;
  dateOfBirth?: string;
  dateJoined?: string;
  emergencyContactName?: string;
  emergencyContactPhone?: string;
  bloodType?: string;
  inductionExpiry?: string;
  photoUrl?: string;
}

interface EmployeeProfileProps {
  employee: Employee;
  onBack: () => void;
}

type TabType = 'overview' | 'compliance' | 'health' | 'safety' | 'training' | 'documents';

export default function EmployeeProfile({ employee, onBack }: EmployeeProfileProps) {
  const [activeTab, setActiveTab] = useState<TabType>('overview');
  const [authorizations, setAuthorizations] = useState<any[]>([]);
  const [ppe, setPpe] = useState<any[]>([]);
  const [incidents, setIncidents] = useState<any[]>([]);
  const [training, setTraining] = useState<any[]>([]);
  const [medicals, setMedicals] = useState<any[]>([]);
  const [claims, setClaims] = useState<any[]>([]);

  useEffect(() => {
    // Fetch Authorizations
    const authQuery = query(collection(db, `employees/${employee.id}/authorizations`), orderBy('expiryDate', 'desc'));
    const unsubscribeAuth = onSnapshot(authQuery, (snapshot) => {
      setAuthorizations(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
    });

    // Fetch PPE
    const ppeQuery = query(collection(db, `employees/${employee.id}/ppe`), orderBy('issueDate', 'desc'));
    const unsubscribePpe = onSnapshot(ppeQuery, (snapshot) => {
      setPpe(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
    });

    // Fetch Incidents (where reporter or involved)
    const incidentQuery = query(collection(db, 'incidents'), where('reporterName', '==', employee.fullName), limit(5));
    const unsubscribeIncidents = onSnapshot(incidentQuery, (snapshot) => {
      setIncidents(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
    });

    // Fetch Training
    const trainingQuery = query(collection(db, 'training_records'), where('employeeName', '==', employee.fullName), limit(10));
    const unsubscribeTraining = onSnapshot(trainingQuery, (snapshot) => {
      setTraining(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
    });

    // Fetch Medicals
    const medicalQuery = query(collection(db, 'medical_records'), where('employeeName', '==', employee.fullName), limit(5));
    const unsubscribeMedicals = onSnapshot(medicalQuery, (snapshot) => {
      setMedicals(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
    });

    // Fetch COIDA Claims
    const claimQuery = query(collection(db, 'coida_claims'), where('employeeName', '==', employee.fullName), limit(5));
    const unsubscribeClaims = onSnapshot(claimQuery, (snapshot) => {
      setClaims(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
    });

    return () => {
      unsubscribeAuth();
      unsubscribePpe();
      unsubscribeIncidents();
      unsubscribeTraining();
      unsubscribeMedicals();
      unsubscribeClaims();
    };
  }, [employee.id, employee.fullName]);

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'Active': return 'bg-green-100 text-green-800';
      case 'On Leave': return 'bg-blue-100 text-blue-800';
      case 'Inactive': return 'bg-gray-100 text-gray-800';
      case 'Terminated': return 'bg-red-100 text-red-800';
      default: return 'bg-slate-100 text-slate-800';
    }
  };

  return (
    <div className="space-y-6">
      {/* Top Navigation */}
      <div className="flex items-center justify-between">
        <button 
          onClick={onBack}
          className="flex items-center gap-2 text-slate-600 hover:text-blue-600 transition-colors group"
        >
          <div className="p-2 rounded-lg group-hover:bg-blue-50 transition-colors">
            <ArrowLeft size={20} />
          </div>
          <span className="font-medium">Back to Workforce</span>
        </button>
        <div className="flex items-center gap-3">
          <button className="flex items-center gap-2 bg-white text-slate-700 px-4 py-2 rounded-lg border border-slate-200 hover:bg-slate-50 transition-colors shadow-sm">
            <Edit2 size={18} />
            Edit Profile
          </button>
          <button className="flex items-center gap-2 bg-white text-slate-700 px-4 py-2 rounded-lg border border-slate-200 hover:bg-slate-50 transition-colors shadow-sm">
            <Download size={18} />
            Employee File
          </button>
        </div>
      </div>

      {/* Profile Header Card */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
        <div className="h-32 bg-gradient-to-r from-blue-600 to-indigo-700"></div>
        <div className="px-8 pb-8">
          <div className="relative flex flex-col md:flex-row md:items-end gap-6 -mt-12">
            <div className="w-32 h-32 rounded-2xl bg-white p-1 shadow-lg">
              <div className="w-full h-full rounded-xl bg-slate-100 flex items-center justify-center overflow-hidden border border-slate-200">
                {employee.photoUrl ? (
                  <img src={employee.photoUrl} alt="" className="w-full h-full object-cover" />
                ) : (
                  <Users size={48} className="text-slate-400" />
                )}
              </div>
            </div>
            <div className="flex-1 space-y-2 mb-2">
              <div className="flex flex-wrap items-center gap-3">
                <h2 className="text-3xl font-bold text-slate-900">{employee.fullName}</h2>
                <span className={`px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider border ${getStatusColor(employee.status)}`}>
                  {employee.status}
                </span>
              </div>
              <div className="flex flex-wrap items-center gap-6 text-slate-500">
                <div className="flex items-center gap-1.5">
                  <Building2 size={18} />
                  <span className="font-medium">{employee.jobTitle}</span>
                  <span className="text-slate-300 mx-1">•</span>
                  <span>{employee.department}</span>
                </div>
                <div className="flex items-center gap-1.5">
                  <BadgeCheck size={18} className="text-blue-500" />
                  <span>ID: {employee.employeeCode}</span>
                </div>
              </div>
            </div>
            <div className="flex items-center gap-4 mb-2">
              <div className="text-center px-4 border-r border-slate-100">
                <p className="text-xs text-slate-400 uppercase font-bold tracking-wider">Compliance</p>
                <p className="text-xl font-bold text-green-600">92%</p>
              </div>
              <div className="text-center px-4">
                <p className="text-xs text-slate-400 uppercase font-bold tracking-wider">Safety Score</p>
                <p className="text-xl font-bold text-blue-600">4.8</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Main Content Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Column: Quick Info & Contact */}
        <div className="space-y-6">
          <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm space-y-6">
            <h3 className="font-bold text-slate-900 flex items-center gap-2">
              Contact Information
            </h3>
            <div className="space-y-4">
              <div className="flex items-center gap-3 text-slate-600">
                <div className="p-2 bg-slate-50 rounded-lg">
                  <Mail size={18} className="text-slate-400" />
                </div>
                <div>
                  <p className="text-xs text-slate-400 font-medium">Email Address</p>
                  <p className="text-sm font-medium">{employee.email || 'Not provided'}</p>
                </div>
              </div>
              <div className="flex items-center gap-3 text-slate-600">
                <div className="p-2 bg-slate-50 rounded-lg">
                  <Phone size={18} className="text-slate-400" />
                </div>
                <div>
                  <p className="text-xs text-slate-400 font-medium">Phone Number</p>
                  <p className="text-sm font-medium">{employee.phone || 'Not provided'}</p>
                </div>
              </div>
              <div className="flex items-center gap-3 text-slate-600">
                <div className="p-2 bg-slate-50 rounded-lg">
                  <Calendar size={18} className="text-slate-400" />
                </div>
                <div>
                  <p className="text-xs text-slate-400 font-medium">Date Joined</p>
                  <p className="text-sm font-medium">{employee.dateJoined ? format(new Date(employee.dateJoined), 'PPP') : 'Not set'}</p>
                </div>
              </div>
            </div>

            <div className="pt-6 border-t border-slate-100">
              <h3 className="font-bold text-slate-900 flex items-center gap-2 mb-4">
                Emergency Contact
              </h3>
              <div className="bg-orange-50 p-4 rounded-xl border border-orange-100 space-y-3">
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-full bg-orange-100 flex items-center justify-center text-orange-600">
                    <Users size={16} />
                  </div>
                  <div>
                    <p className="text-sm font-bold text-slate-900">{employee.emergencyContactName || 'No contact set'}</p>
                    <p className="text-xs text-slate-500">Next of Kin</p>
                  </div>
                </div>
                <div className="flex items-center gap-2 text-sm text-slate-700">
                  <Phone size={14} className="text-orange-400" />
                  {employee.emergencyContactPhone || 'N/A'}
                </div>
                <div className="flex items-center gap-2 text-sm text-slate-700">
                  <HeartPulse size={14} className="text-red-400" />
                  Blood Type: <span className="font-bold">{employee.bloodType || 'Unknown'}</span>
                </div>
              </div>
            </div>
          </div>

          {/* Quick Stats / Badges */}
          <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
            <h3 className="font-bold text-slate-900 mb-4">Certifications & Permits</h3>
            <div className="space-y-3">
              {authorizations.length === 0 ? (
                <p className="text-sm text-slate-500 italic">No active permits found.</p>
              ) : (
                authorizations.map((auth) => (
                  <div key={auth.id} className="flex items-center justify-between p-3 bg-slate-50 rounded-xl border border-slate-100">
                    <div className="flex items-center gap-3">
                      <div className="p-2 bg-white rounded-lg shadow-sm">
                        <Truck size={16} className="text-blue-600" />
                      </div>
                      <div>
                        <p className="text-sm font-bold text-slate-900">{auth.type}</p>
                        <p className="text-xs text-slate-500">Exp: {format(new Date(auth.expiryDate), 'MMM yyyy')}</p>
                      </div>
                    </div>
                    <BadgeCheck size={18} className="text-green-500" />
                  </div>
                ))
              )}
              <button className="w-full py-2 text-sm font-medium text-blue-600 hover:bg-blue-50 rounded-lg transition-colors flex items-center justify-center gap-2">
                <Plus size={16} />
                Add Permit
              </button>
            </div>
          </div>
        </div>

        {/* Right Column: Tabs & Detailed Info */}
        <div className="lg:col-span-2 space-y-6">
          {/* Tabs */}
          <div className="bg-white p-1 rounded-xl border border-slate-200 shadow-sm flex overflow-x-auto">
            {[
              { id: 'overview', label: 'Overview', icon: LayoutDashboard },
              { id: 'compliance', label: 'Compliance', icon: ShieldCheck },
              { id: 'health', label: 'Health', icon: HeartPulse },
              { id: 'safety', label: 'Safety', icon: AlertTriangle },
              { id: 'training', label: 'Training', icon: GraduationCap },
              { id: 'documents', label: 'Docs', icon: FileText },
            ].map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id as TabType)}
                className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all whitespace-nowrap ${
                  activeTab === tab.id 
                    ? 'bg-blue-600 text-white shadow-md' 
                    : 'text-slate-500 hover:text-slate-700 hover:bg-slate-50'
                }`}
              >
                <tab.icon size={16} />
                {tab.label}
              </button>
            ))}
          </div>

          {/* Tab Content */}
          <div className="min-h-[400px]">
            {activeTab === 'overview' && (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {/* Recent Training */}
                <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm space-y-4">
                  <div className="flex items-center justify-between">
                    <h4 className="font-bold text-slate-900 flex items-center gap-2">
                      <GraduationCap size={18} className="text-blue-600" />
                      Recent Training
                    </h4>
                    <button className="text-xs font-bold text-blue-600 hover:underline">View All</button>
                  </div>
                  <div className="space-y-3">
                    {training.length === 0 ? (
                      <p className="text-sm text-slate-500 italic">No training records found.</p>
                    ) : (
                      training.map((t) => (
                        <div key={t.id} className="flex items-center justify-between p-3 hover:bg-slate-50 rounded-xl transition-colors group">
                          <div className="flex items-center gap-3">
                            <div className="w-2 h-2 rounded-full bg-green-500"></div>
                            <div>
                              <p className="text-sm font-medium text-slate-900">{t.courseName}</p>
                              <p className="text-xs text-slate-500">{format(new Date(t.dateCompleted), 'PP')}</p>
                            </div>
                          </div>
                          <ChevronRight size={16} className="text-slate-300 group-hover:text-slate-400" />
                        </div>
                      ))
                    )}
                  </div>
                </div>

                {/* Safety Incidents */}
                <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm space-y-4">
                  <div className="flex items-center justify-between">
                    <h4 className="font-bold text-slate-900 flex items-center gap-2">
                      <AlertTriangle size={18} className="text-orange-600" />
                      Safety History
                    </h4>
                    <button className="text-xs font-bold text-blue-600 hover:underline">View All</button>
                  </div>
                  <div className="space-y-3">
                    {incidents.length === 0 ? (
                      <div className="flex flex-col items-center justify-center py-4 text-center">
                        <CheckCircle2 size={32} className="text-green-500 mb-2" />
                        <p className="text-sm font-medium text-slate-900">Zero Incidents</p>
                        <p className="text-xs text-slate-500">Clean safety record</p>
                      </div>
                    ) : (
                      incidents.map((i) => (
                        <div key={i.id} className="flex items-center justify-between p-3 hover:bg-slate-50 rounded-xl transition-colors group">
                          <div className="flex items-center gap-3">
                            <div className={`w-2 h-2 rounded-full ${i.severity === 'Critical' ? 'bg-red-500' : 'bg-orange-500'}`}></div>
                            <div>
                              <p className="text-sm font-medium text-slate-900">{i.title}</p>
                              <p className="text-xs text-slate-500">{format(new Date(i.dateOfIncident), 'PP')}</p>
                            </div>
                          </div>
                          <ChevronRight size={16} className="text-slate-300 group-hover:text-slate-400" />
                        </div>
                      ))
                    )}
                  </div>
                </div>

                {/* PPE Issued */}
                <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm space-y-4 md:col-span-2">
                  <div className="flex items-center justify-between">
                    <h4 className="font-bold text-slate-900 flex items-center gap-2">
                      <HardHat size={18} className="text-slate-700" />
                      PPE Inventory
                    </h4>
                    <button className="text-xs font-bold text-blue-600 hover:underline">Manage PPE</button>
                  </div>
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                    {ppe.length === 0 ? (
                      <p className="text-sm text-slate-500 italic col-span-3">No PPE issue records found.</p>
                    ) : (
                      ppe.map((p) => (
                        <div key={p.id} className="p-3 bg-slate-50 rounded-xl border border-slate-100 flex items-center gap-3">
                          <div className="p-2 bg-white rounded-lg shadow-sm">
                            <ShieldCheck size={16} className="text-slate-600" />
                          </div>
                          <div>
                            <p className="text-sm font-bold text-slate-900">{p.itemType}</p>
                            <p className="text-xs text-slate-500">Issued: {format(new Date(p.issueDate), 'PP')}</p>
                          </div>
                        </div>
                      ))
                    )}
                  </div>
                </div>
              </div>
            )}

            {activeTab === 'compliance' && (
              <div className="space-y-6">
                <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
                  <EmployeeInduction employeeId={employee.id} />
                </div>
                <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
                  <EmployeeAuthorizations employeeId={employee.id} />
                </div>
              </div>
            )}

            {activeTab === 'health' && (
              <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm space-y-6">
                <div className="flex items-center justify-between">
                  <h4 className="text-lg font-bold text-slate-900">Medical Surveillance & Health</h4>
                  <button className="flex items-center gap-2 text-blue-600 text-sm font-bold hover:underline">
                    <Plus size={16} />
                    New Medical
                  </button>
                </div>
                
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div className="p-4 bg-slate-50 rounded-2xl border border-slate-100 text-center">
                    <p className="text-xs text-slate-400 uppercase font-bold tracking-wider mb-1">Last Medical</p>
                    <p className="text-sm font-bold text-slate-900">12 Jan 2024</p>
                  </div>
                  <div className="p-4 bg-slate-50 rounded-2xl border border-slate-100 text-center">
                    <p className="text-xs text-slate-400 uppercase font-bold tracking-wider mb-1">Fitness Status</p>
                    <p className="text-sm font-bold text-green-600">FIT FOR DUTY</p>
                  </div>
                  <div className="p-4 bg-slate-50 rounded-2xl border border-slate-100 text-center">
                    <p className="text-xs text-slate-400 uppercase font-bold tracking-wider mb-1">Next Review</p>
                    <p className="text-sm font-bold text-orange-600">12 Jan 2025</p>
                  </div>
                </div>

                <div className="space-y-4">
                  <h5 className="font-bold text-slate-900 flex items-center gap-2">
                    <Stethoscope size={18} className="text-blue-600" />
                    Medical History
                  </h5>
                  <div className="space-y-3">
                    {medicals.length === 0 ? (
                      <p className="text-sm text-slate-500 italic">No medical records found.</p>
                    ) : (
                      medicals.map((m) => (
                        <div key={m.id} className="flex items-center justify-between p-4 bg-slate-50 rounded-xl border border-slate-100">
                          <div className="flex items-center gap-4">
                            <div className="p-2 bg-white rounded-lg shadow-sm">
                              <HeartPulse size={18} className="text-red-500" />
                            </div>
                            <div>
                              <p className="text-sm font-bold text-slate-900">{m.medicalType} Medical</p>
                              <p className="text-xs text-slate-500">Conducted by Dr. Smith • {format(new Date(m.dateConducted), 'PP')}</p>
                            </div>
                          </div>
                          <div className="flex items-center gap-3">
                            <span className={`px-2 py-0.5 rounded text-[10px] font-bold uppercase ${m.status === 'Fit' ? 'bg-green-100 text-green-700' : 'bg-orange-100 text-orange-700'}`}>
                              {m.status}
                            </span>
                            <button className="p-1 text-slate-400 hover:text-slate-600">
                              <Download size={16} />
                            </button>
                          </div>
                        </div>
                      ))
                    )}
                  </div>
                </div>

                {/* COIDA Claims Section */}
                <div className="pt-6 border-t border-slate-100 space-y-4">
                  <h5 className="font-bold text-slate-900 flex items-center gap-2">
                    <LifeBuoy size={18} className="text-indigo-600" />
                    COIDA Claims & RTW
                  </h5>
                  <div className="space-y-3">
                    {claims.length === 0 ? (
                      <p className="text-sm text-slate-500 italic">No injury claims found for this employee.</p>
                    ) : (
                      claims.map((c) => (
                        <div key={c.id} className="p-4 bg-indigo-50 rounded-2xl border border-indigo-100 flex items-center justify-between">
                          <div className="flex items-center gap-4">
                            <div className="p-2 bg-white rounded-lg shadow-sm">
                              <ClipboardList size={18} className="text-indigo-600" />
                            </div>
                            <div>
                              <p className="text-sm font-bold text-slate-900">Claim #{c.claimNumber}</p>
                              <p className="text-xs text-slate-500">Incident: {format(new Date(c.incidentDate), 'PP')}</p>
                            </div>
                          </div>
                          <div className="flex items-center gap-3">
                            <span className="px-2 py-0.5 rounded text-[10px] font-bold uppercase bg-indigo-100 text-indigo-700">
                              {c.status}
                            </span>
                            <span className="text-xs font-medium text-slate-600">{c.rtwStatus}</span>
                          </div>
                        </div>
                      ))
                    )}
                  </div>
                </div>
              </div>
            )}

            {/* Other tabs would follow similar patterns... */}
            {activeTab === 'training' && (
              <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm space-y-6">
                <div className="flex items-center justify-between">
                  <h4 className="text-lg font-bold text-slate-900">Training & Competency Matrix</h4>
                  <button className="flex items-center gap-2 text-blue-600 text-sm font-bold hover:underline">
                    <Plus size={16} />
                    Log Training
                  </button>
                </div>
                <div className="space-y-4">
                  {training.map((t) => (
                    <div key={t.id} className="flex items-center justify-between p-4 bg-slate-50 rounded-xl border border-slate-100">
                      <div className="flex items-center gap-4">
                        <div className="p-2 bg-white rounded-lg shadow-sm">
                          <GraduationCap size={18} className="text-blue-600" />
                        </div>
                        <div>
                          <p className="text-sm font-bold text-slate-900">{t.courseName}</p>
                          <p className="text-xs text-slate-500">Completed: {format(new Date(t.dateCompleted), 'PP')}</p>
                        </div>
                      </div>
                      <div className="flex items-center gap-4">
                        <div className="text-right">
                          <p className="text-xs text-slate-400 uppercase font-bold tracking-wider">Expires</p>
                          <p className={`text-sm font-bold ${new Date(t.expiryDate) < new Date() ? 'text-red-600' : 'text-slate-700'}`}>
                            {format(new Date(t.expiryDate), 'MMM yyyy')}
                          </p>
                        </div>
                        <button className="p-2 text-slate-400 hover:text-slate-600">
                          <FileText size={18} />
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {activeTab === 'safety' && (
              <div className="space-y-6">
                <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
                  <EmployeePPETracker employeeId={employee.id} />
                </div>
                <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
                  <FatigueRisk />
                </div>
                <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm space-y-6">
                  <h4 className="text-lg font-bold text-slate-900">Safety Performance & BBS</h4>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div className="p-6 bg-slate-50 rounded-2xl border border-slate-100 text-center space-y-2">
                      <p className="text-xs text-slate-400 uppercase font-bold tracking-wider">BBS Observations</p>
                      <p className="text-3xl font-bold text-blue-600">24</p>
                      <p className="text-xs text-green-600 font-medium">95% Safe Acts</p>
                    </div>
                    <div className="p-6 bg-slate-50 rounded-2xl border border-slate-100 text-center space-y-2">
                      <p className="text-xs text-slate-400 uppercase font-bold tracking-wider">Incident Involvement</p>
                      <p className="text-3xl font-bold text-slate-900">{incidents.length}</p>
                      <p className="text-xs text-slate-500 font-medium">Last 12 months</p>
                    </div>
                  </div>
                  <div className="space-y-4">
                    <h5 className="font-bold text-slate-900">Recent Safety Activity</h5>
                    {incidents.map((i) => (
                      <div key={i.id} className="p-4 bg-slate-50 rounded-xl border border-slate-100 flex items-center justify-between">
                        <div className="flex items-center gap-4">
                          <div className={`p-2 bg-white rounded-lg shadow-sm ${i.severity === 'Critical' ? 'text-red-600' : 'text-orange-600'}`}>
                            <AlertTriangle size={18} />
                          </div>
                          <div>
                            <p className="text-sm font-bold text-slate-900">{i.title}</p>
                            <p className="text-xs text-slate-500">{i.type} • {format(new Date(i.dateOfIncident), 'PP')}</p>
                          </div>
                        </div>
                        <button className="text-blue-600 text-xs font-bold hover:underline">View Report</button>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            )}

            {activeTab === 'documents' && (
              <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm space-y-6">
                <div className="flex items-center justify-between">
                  <h4 className="text-lg font-bold text-slate-900">Digital Personnel File</h4>
                  <button className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg text-sm font-bold hover:bg-blue-700 transition-colors">
                    <Plus size={16} />
                    Upload Document
                  </button>
                </div>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  {[
                    { name: 'ID Document.pdf', type: 'Identification', size: '1.2 MB' },
                    { name: 'Employment Contract.pdf', type: 'Legal', size: '2.4 MB' },
                    { name: 'Trade Certificate.pdf', type: 'Qualification', size: '0.8 MB' },
                    { name: 'Induction Record.pdf', type: 'Safety', size: '1.1 MB' },
                  ].map((doc, i) => (
                    <div key={i} className="p-4 bg-slate-50 rounded-xl border border-slate-100 flex items-center justify-between group">
                      <div className="flex items-center gap-3">
                        <div className="p-2 bg-white rounded-lg shadow-sm text-slate-400 group-hover:text-blue-600 transition-colors">
                          <FileText size={20} />
                        </div>
                        <div>
                          <p className="text-sm font-bold text-slate-900">{doc.name}</p>
                          <p className="text-xs text-slate-500">{doc.type} • {doc.size}</p>
                        </div>
                      </div>
                      <div className="flex items-center gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                        <button className="p-1.5 text-slate-400 hover:text-blue-600 rounded-md hover:bg-white">
                          <Download size={16} />
                        </button>
                        <button className="p-1.5 text-slate-400 hover:text-red-600 rounded-md hover:bg-white">
                          <Trash2 size={16} />
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
