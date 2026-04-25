import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy, doc, updateDoc } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { 
  HeartPulse, 
  Activity, 
  FileText, 
  Plus, 
  XCircle, 
  Clock,
  AlertTriangle,
  CheckCircle,
  TrendingUp,
  ClipboardList,
  DollarSign,
  Award,
  Skull,
  ShieldAlert,
  FileCheck,
  Stethoscope,
  Calculator,
  Wallet,
  CheckSquare,
  Scale
} from 'lucide-react';
import CoidaFormGenerator from '../components/CoidaFormGenerator';
import MedicalProgressTracker from '../components/MedicalProgressTracker';
import ResumptionReportManager from '../components/ResumptionReportManager';
import ClaimStatusDashboard from '../components/ClaimStatusDashboard';
import EarningsIntegration from '../components/EarningsIntegration';
import PDAssessmentTracker from '../components/PDAssessmentTracker';
import FatalClaimManagement from '../components/FatalClaimManagement';
import Section56Investigation from '../components/Section56Investigation';
import LOGSTracker from '../components/LOGSTracker';
import OccupationalDiseaseWorkflow from '../components/OccupationalDiseaseWorkflow';
import CoidaAssessmentCalculator from '../components/CoidaAssessmentCalculator';
import MedicalAdjudicationTracker from '../components/MedicalAdjudicationTracker';
import ObjectionAppealManager from '../components/ObjectionAppealManager';
import PensionerManagement from '../components/PensionerManagement';
import CoidaComplianceChecklist from '../components/CoidaComplianceChecklist';

type TabType = 'coida' | 'dashboard' | 'forms' | 'medical' | 'resumption' | 'earnings' | 'pd' | 'fatal' | 'section56' | 'logs' | 'disease' | 'fatigue' | 'assessment' | 'adjudication' | 'objection' | 'pension' | 'checklist';

interface CoidaClaim {
  id: string;
  employeeName: string;
  idNumber: string;
  incidentDate: string;
  claimNumber: string;
  status: 'Submitted' | 'Accepted' | 'Rejected' | 'Closed';
  lostDays: number;
  rtwStatus: 'Off Sick' | 'Light Duty' | 'Full Duty';
  authorId: string;
  createdAt: string;
}

export default function WorkersComp() {
  const [activeTab, setActiveTab] = useState<TabType>('coida');
  const [claims, setClaims] = useState<CoidaClaim[]>([]);
  const [isAddingClaim, setIsAddingClaim] = useState(false);

  // Form State
  const [employeeName, setEmployeeName] = useState('');
  const [idNumber, setIdNumber] = useState('');
  const [incidentDate, setIncidentDate] = useState('');
  const [claimNumber, setClaimNumber] = useState('');
  const [lostDays, setLostDays] = useState(0);

  useEffect(() => {
    if (!auth.currentUser) return;

    const qClaims = query(collection(db, 'coida_claims'), orderBy('createdAt', 'desc'));
    const unsubClaims = onSnapshot(qClaims, (snapshot) => {
      setClaims(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as CoidaClaim[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'coida_claims'));

    return () => unsubClaims();
  }, []);

  const handleAddClaim = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      await addDoc(collection(db, 'coida_claims'), {
        employeeName,
        idNumber,
        incidentDate: new Date(incidentDate).toISOString(),
        claimNumber,
        status: 'Submitted',
        lostDays: Number(lostDays),
        rtwStatus: 'Off Sick',
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAddingClaim(false);
      setEmployeeName(''); setIdNumber(''); setIncidentDate(''); setClaimNumber(''); setLostDays(0);
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'coida_claims');
    }
  };

  const updateClaimStatus = async (id: string, field: 'status' | 'rtwStatus', value: string) => {
    try {
      await updateDoc(doc(db, 'coida_claims', id), { [field]: value });
    } catch (error) {
      handleFirestoreError(error, 'update' as any, 'coida_claims');
    }
  };

  return (
    <div className="max-w-7xl mx-auto space-y-6">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 flex items-center gap-2">
            Workers Compensation & RTW <HeartPulse size={24} className="text-rose-600" />
          </h1>
          <p className="text-slate-500">Manage COIDA claims, Return to Work plans, and Fatigue Risk.</p>
        </div>
        <div className="flex gap-3">
          {activeTab === 'coida' && (
            <button onClick={() => setIsAddingClaim(true)} className="flex items-center gap-2 bg-rose-600 text-white px-4 py-2 rounded-lg hover:bg-rose-700 transition-colors">
              <Plus size={20} /> Log COIDA Claim
            </button>
          )}
        </div>
      </div>

      {/* Tabs */}
      <div className="flex overflow-x-auto border-b border-slate-200 hide-scrollbar">
        <button
          onClick={() => setActiveTab('dashboard')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'dashboard' ? 'border-rose-600 text-rose-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <TrendingUp size={18} />
          Dashboard
        </button>
        <button
          onClick={() => setActiveTab('coida')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'coida' ? 'border-rose-600 text-rose-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Activity size={18} />
          Claims Register
        </button>
        <button
          onClick={() => setActiveTab('forms')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'forms' ? 'border-rose-600 text-rose-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <FileText size={18} />
          W.Cl.2 Generator
        </button>
        <button
          onClick={() => setActiveTab('medical')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'medical' ? 'border-rose-600 text-rose-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <ClipboardList size={18} />
          Medical Reports
        </button>
        <button
          onClick={() => setActiveTab('resumption')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'resumption' ? 'border-rose-600 text-rose-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <CheckCircle size={18} />
          Resumption (W.Cl.6)
        </button>
        <button
          onClick={() => setActiveTab('earnings')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'earnings' ? 'border-rose-600 text-rose-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <DollarSign size={18} />
          Earnings (W.Cl.3)
        </button>
        <button
          onClick={() => setActiveTab('pd')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'pd' ? 'border-rose-600 text-rose-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Award size={18} />
          PD Assessment
        </button>
        <button
          onClick={() => setActiveTab('fatal')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'fatal' ? 'border-rose-600 text-rose-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Skull size={18} />
          Fatal Claims
        </button>
        <button
          onClick={() => setActiveTab('section56')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'section56' ? 'border-rose-600 text-rose-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <ShieldAlert size={18} />
          Section 56
        </button>
        <button
          onClick={() => setActiveTab('logs')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'logs' ? 'border-rose-600 text-rose-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <FileCheck size={18} />
          LOGS Tracker
        </button>
        <button
          onClick={() => setActiveTab('disease')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'disease' ? 'border-rose-600 text-rose-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Stethoscope size={18} />
          Occ. Disease
        </button>
        <button
          onClick={() => setActiveTab('assessment')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'assessment' ? 'border-rose-600 text-rose-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Calculator size={18} />
          Assessment Calc
        </button>
        <button
          onClick={() => setActiveTab('adjudication')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'adjudication' ? 'border-rose-600 text-rose-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Activity size={18} />
          Medical Adjudication
        </button>
        <button
          onClick={() => setActiveTab('objection')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'objection' ? 'border-rose-600 text-rose-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Scale size={18} />
          Objections (Sec 91)
        </button>
        <button
          onClick={() => setActiveTab('pension')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'pension' ? 'border-rose-600 text-rose-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Wallet size={18} />
          Pensioner Mgmt
        </button>
        <button
          onClick={() => setActiveTab('checklist')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'checklist' ? 'border-rose-600 text-rose-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <CheckSquare size={18} />
          Compliance Checklist
        </button>
        <button
          onClick={() => setActiveTab('fatigue')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'fatigue' ? 'border-rose-600 text-rose-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Clock size={18} />
          Fatigue Risk
        </button>
      </div>

      {/* Content Area */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        
        {/* Dashboard Tab */}
        {activeTab === 'dashboard' && (
          <div className="p-6">
            <ClaimStatusDashboard />
          </div>
        )}

        {/* COIDA Tab */}
        {activeTab === 'coida' && (
          <div className="p-6">
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 text-sm">
                    <th className="p-4 font-medium">Employee</th>
                    <th className="p-4 font-medium">Incident Date</th>
                    <th className="p-4 font-medium">Claim Number</th>
                    <th className="p-4 font-medium">Lost Days</th>
                    <th className="p-4 font-medium">Claim Status</th>
                    <th className="p-4 font-medium">RTW Status</th>
                  </tr>
                </thead>
                <tbody>
                  {claims.length === 0 ? (
                    <tr><td colSpan={6} className="p-8 text-center text-slate-500">No claims logged yet.</td></tr>
                  ) : (
                    claims.map((claim) => (
                      <tr key={claim.id} className="border-b border-slate-100 hover:bg-slate-50 transition-colors">
                        <td className="p-4 font-medium text-slate-900">{claim.employeeName}</td>
                        <td className="p-4 text-slate-600">{new Date(claim.incidentDate).toLocaleDateString()}</td>
                        <td className="p-4 text-slate-600 font-mono text-sm">{claim.claimNumber}</td>
                        <td className="p-4 text-slate-600">{claim.lostDays}</td>
                        <td className="p-4">
                          <select
                            value={claim.status}
                            onChange={(e) => updateClaimStatus(claim.id, 'status', e.target.value)}
                            className={`text-sm rounded-lg border-slate-300 focus:ring-rose-500 focus:border-rose-500 ${
                              claim.status === 'Accepted' ? 'bg-green-50 text-green-700' :
                              claim.status === 'Rejected' ? 'bg-red-50 text-red-700' :
                              claim.status === 'Closed' ? 'bg-slate-100 text-slate-700' :
                              'bg-amber-50 text-amber-700'
                            }`}
                          >
                            <option value="Submitted">Submitted</option>
                            <option value="Accepted">Accepted</option>
                            <option value="Rejected">Rejected</option>
                            <option value="Closed">Closed</option>
                          </select>
                        </td>
                        <td className="p-4">
                          <select
                            value={claim.rtwStatus}
                            onChange={(e) => updateClaimStatus(claim.id, 'rtwStatus', e.target.value)}
                            className={`text-sm rounded-lg border-slate-300 focus:ring-rose-500 focus:border-rose-500 ${
                              claim.rtwStatus === 'Full Duty' ? 'bg-green-50 text-green-700' :
                              claim.rtwStatus === 'Light Duty' ? 'bg-amber-50 text-amber-700' :
                              'bg-red-50 text-red-700'
                            }`}
                          >
                            <option value="Off Sick">Off Sick</option>
                            <option value="Light Duty">Light Duty</option>
                            <option value="Full Duty">Full Duty</option>
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

        {/* Forms Tab */}
        {activeTab === 'forms' && (
          <div className="p-6">
            <CoidaFormGenerator />
          </div>
        )}

        {/* Medical Tab */}
        {activeTab === 'medical' && (
          <div className="p-6">
            <MedicalProgressTracker />
          </div>
        )}

        {/* Resumption Tab */}
        {activeTab === 'resumption' && (
          <div className="p-6">
            <ResumptionReportManager />
          </div>
        )}

        {/* Earnings Tab */}
        {activeTab === 'earnings' && (
          <div className="p-6">
            <EarningsIntegration />
          </div>
        )}

        {/* PD Tab */}
        {activeTab === 'pd' && (
          <div className="p-6">
            <PDAssessmentTracker />
          </div>
        )}

        {/* Fatal Tab */}
        {activeTab === 'fatal' && (
          <div className="p-6">
            <FatalClaimManagement />
          </div>
        )}

        {/* Section 56 Tab */}
        {activeTab === 'section56' && (
          <div className="p-6">
            <Section56Investigation />
          </div>
        )}

        {/* LOGS Tab */}
        {activeTab === 'logs' && (
          <div className="p-6">
            <LOGSTracker />
          </div>
        )}

        {/* Disease Tab */}
        {activeTab === 'disease' && (
          <div className="p-6">
            <OccupationalDiseaseWorkflow />
          </div>
        )}

        {/* Assessment Tab */}
        {activeTab === 'assessment' && (
          <div className="p-6">
            <CoidaAssessmentCalculator />
          </div>
        )}

        {/* Adjudication Tab */}
        {activeTab === 'adjudication' && (
          <div className="p-6">
            <MedicalAdjudicationTracker />
          </div>
        )}

        {/* Objection Tab */}
        {activeTab === 'objection' && (
          <div className="p-6">
            <ObjectionAppealManager />
          </div>
        )}

        {/* Pension Tab */}
        {activeTab === 'pension' && (
          <div className="p-6">
            <PensionerManagement />
          </div>
        )}

        {/* Checklist Tab */}
        {activeTab === 'checklist' && (
          <div className="p-6">
            <CoidaComplianceChecklist />
          </div>
        )}

        {/* Fatigue Tab */}
        {activeTab === 'fatigue' && (
          <div className="p-6 bg-slate-50">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              
              <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm flex flex-col items-center text-center">
                <div className="w-16 h-16 bg-rose-100 text-rose-600 rounded-full flex items-center justify-center mb-4">
                  <Clock size={32} />
                </div>
                <h3 className="text-lg font-bold text-slate-900 mb-2">Shift Pattern Analysis</h3>
                <p className="text-sm text-slate-500 mb-4">Automatically flag workers exceeding 60 hours/week or 14 consecutive days.</p>
                <button className="mt-auto px-4 py-2 text-sm font-medium text-rose-600 bg-rose-50 rounded-lg hover:bg-rose-100">
                  Run Analysis
                </button>
              </div>

              <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm flex flex-col items-center text-center">
                <div className="w-16 h-16 bg-amber-100 text-amber-600 rounded-full flex items-center justify-center mb-4">
                  <AlertTriangle size={32} />
                </div>
                <h3 className="text-lg font-bold text-slate-900 mb-2">Fitness for Duty</h3>
                <p className="text-sm text-slate-500 mb-4">Digital micro-assessments (reaction tests) before issuing high-risk PTWs.</p>
                <button className="mt-auto px-4 py-2 text-sm font-medium text-amber-600 bg-amber-50 rounded-lg hover:bg-amber-100">
                  Configure Tests
                </button>
              </div>

              <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm flex flex-col items-center text-center">
                <div className="w-16 h-16 bg-emerald-100 text-emerald-600 rounded-full flex items-center justify-center mb-4">
                  <CheckCircle size={32} />
                </div>
                <h3 className="text-lg font-bold text-slate-900 mb-2">Fatigue Clearances</h3>
                <p className="text-sm text-slate-500 mb-4">Review and approve overrides for critical path work requiring extended hours.</p>
                <button className="mt-auto px-4 py-2 text-sm font-medium text-emerald-600 bg-emerald-50 rounded-lg hover:bg-emerald-100">
                  View Pending
                </button>
              </div>

            </div>
          </div>
        )}
      </div>

      {/* Add Claim Modal */}
      {isAddingClaim && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex justify-between items-center">
              <h2 className="text-xl font-bold text-slate-900">Log COIDA Claim</h2>
              <button onClick={() => setIsAddingClaim(false)} className="text-slate-400 hover:text-slate-600"><XCircle size={24} /></button>
            </div>
            <form onSubmit={handleAddClaim} className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Employee Name</label>
                <input type="text" required value={employeeName} onChange={e => setEmployeeName(e.target.value)} className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-rose-500" />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">ID / Passport Number</label>
                <input type="text" required value={idNumber} onChange={e => setIdNumber(e.target.value)} className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-rose-500 font-mono" />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Incident Date</label>
                  <input type="date" required value={incidentDate} onChange={e => setIncidentDate(e.target.value)} className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-rose-500" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Lost Days</label>
                  <input type="number" min="0" required value={lostDays} onChange={e => setLostDays(Number(e.target.value))} className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-rose-500" />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">W.Cl.2 / Claim Number</label>
                <input type="text" required value={claimNumber} onChange={e => setClaimNumber(e.target.value)} placeholder="e.g., 12345678" className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-rose-500" />
              </div>
              <div className="pt-4 flex justify-end gap-3">
                <button type="button" onClick={() => setIsAddingClaim(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg">Cancel</button>
                <button type="submit" className="px-4 py-2 bg-rose-600 text-white rounded-lg hover:bg-rose-700">Submit Claim</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
