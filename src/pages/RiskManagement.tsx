import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy, doc, deleteDoc, where, limit } from 'firebase/firestore';
import { db, handleFirestoreError, OperationType } from '../lib/firebase';
import { useAuth } from '../contexts/AuthContext';
import { Box, Typography, Button, Paper, Tabs, Tab , TextField, MenuItem, InputLabel, FormControl } from '@mui/material';

// Icons
import ShieldAlert from '@mui/icons-material/Security';
import Plus from '@mui/icons-material/Add';
import Brain from '@mui/icons-material/Psychology';
import Loader2 from '@mui/icons-material/Sync';
import AlertTriangle from '@mui/icons-material/Warning';
import CheckCircle from '@mui/icons-material/CheckCircle';
import Trash2 from '@mui/icons-material/Delete';
import CalendarClock from '@mui/icons-material/Update';
import Shield from '@mui/icons-material/Shield';
import MapPin from '@mui/icons-material/LocationOn';
import BoxIcon from '@mui/icons-material/Inventory2';
import FileText from '@mui/icons-material/Description';
import PenTool from '@mui/icons-material/Create';
import Eye from '@mui/icons-material/Visibility';
import UserCheck from '@mui/icons-material/HowToReg';
import MessageSquare from '@mui/icons-material/Chat';
import Download from '@mui/icons-material/Download';
import FileSpreadsheet from '@mui/icons-material/GridOn';
import X from '@mui/icons-material/Close';

import { jsPDF } from 'jspdf';
import 'jspdf-autotable';
import * as XLSX from 'xlsx';
import ActionItemsList from '../components/ActionItemsList';
import RiskMatrix from '../components/RiskMatrix';
import SWPModal from '../components/SWPModal';
import { getGeminiClient } from '../lib/gemini';

export interface Control {
  type: 'Elimination' | 'Substitution' | 'Engineering' | 'Administrative' | 'PPE';
  description: string;
  isCritical: boolean;
}

export interface RiskAssessment {
  id: string;
  taskName: string;
  hazard: string;
  inherentProbability: number;
  inherentSeverity: number;
  inherentRiskScore: number;
  controls: Control[];
  residualProbability: number;
  residualSeverity: number;
  residualRiskScore: number;
  requiredPPE?: string[];
  requiredCompetencies?: string[];
  applicableLegislation?: string[];
  environmentalImpacts?: string[];
  consultedStakeholders?: string[];
  location?: string;
  assetId?: string;
  assetName?: string;
  contractorId?: string;
  contractorName?: string;
  version?: number;
  originalId?: string;
  previousId?: string;
  reviewDate?: string;
  reviewTriggers?: string[];
  authorId: string;
  authorName: string;
  reviewerId?: string;
  reviewerName?: string;
  reviewComments?: string;
  reviewedAt?: string;
  approverId?: string;
  approverName?: string;
  approvalComments?: string;
  approvedAt?: string;
  createdAt: string;
  status: string;
}

export interface ActionItem {
  id: string;
  assessmentId: string;
  description: string;
  assigneeId: string;
  assigneeName: string;
  dueDate: string;
  status: 'Pending' | 'In Progress' | 'Completed' | 'Overdue';
  completedAt?: string;
  completedBy?: string;
}

export interface RiskSignOff {
  id: string;
  assessmentId: string;
  userId: string;
  userName: string;
  signedAt: string;
  version: number;
}

export interface BBSObservation {
  id: string;
  assessmentId?: string;
  observerName?: string;
  location: string;
  observationType: 'Safe Act' | 'Unsafe Act' | 'Unsafe Condition';
  description: string;
  interventionAction?: string;
  pointsAwarded: number;
  authorId: string;
  createdAt: string;
}

export interface ContractorAudit {
  id: string;
  contractorId: string;
  contractorName: string;
  auditDate: string;
  auditorName: string;
  score: number;
  findings: string[];
  status: 'Scheduled' | 'Completed' | 'Overdue';
  authorId: string;
  createdAt: string;
}

const CONTROL_TYPES = ['Elimination', 'Substitution', 'Engineering', 'Administrative', 'PPE'] as const;
const REVIEW_TRIGGERS = ['Annual Review', 'Incident Occurred', 'MoC Approved', 'Legal Update', 'Process Change'];

export default function RiskManagement() {
  const { profile } = useAuth();
  const [activeTab, setActiveTab] = useState<'hira' | 'audits'>('hira');
  const [assessments, setAssessments] = useState<RiskAssessment[]>([]);
  const [audits, setAudits] = useState<ContractorAudit[]>([]);
  const [contractors, setContractors] = useState<{id: string, companyName: string}[]>([]);
  const [isCreating, setIsCreating] = useState(false);
  const [isAddingAudit, setIsAddingAudit] = useState(false);
  const [loading, setLoading] = useState(true);
  const [taskName, setTaskName] = useState('');
  
  // Audit Form State
  const [selectedContractorId, setSelectedContractorId] = useState('');
  const [auditDate, setAuditDate] = useState('');
  const [auditorName, setAuditorName] = useState('');
  const [auditScore, setAuditScore] = useState(0);
  const [auditFindings, setAuditFindings] = useState('');
  const [hazard, setHazard] = useState('');
  const [inherentProbability, setInherentProbability] = useState(1);
  const [inherentSeverity, setInherentSeverity] = useState(1);
  const [residualProbability, setResidualProbability] = useState(1);
  const [residualSeverity, setResidualSeverity] = useState(1);
  const [controls, setControls] = useState<Control[]>([]);
  const [currentControlDesc, setCurrentControlDesc] = useState('');
  const [currentControlType, setCurrentControlType] = useState<Control['type']>('Administrative');
  const [currentControlCritical, setCurrentControlCritical] = useState(false);
  const [requiredPPE, setRequiredPPE] = useState<string[]>([]);
  const [requiredCompetencies, setRequiredCompetencies] = useState<string[]>([]);
  const [applicableLegislation, setApplicableLegislation] = useState<string[]>([]);
  const [environmentalImpacts, setEnvironmentalImpacts] = useState<string[]>([]);
  const [consultedStakeholders, setConsultedStakeholders] = useState<string[]>([]);
  const [location, setLocation] = useState('');
  const [assetId, setAssetId] = useState('');
  const [assetName, setAssetName] = useState('');
  const [reviewDate, setReviewDate] = useState('');
  const [selectedTriggers, setSelectedTriggers] = useState<string[]>(['Annual Review']);
  const [selectedContractorIdForHira, setSelectedContractorIdForHira] = useState('');
  const [availableAssets, setAvailableAssets] = useState<{id: string, name: string}[]>([]);
  
  // AI State
  const [aiLoading, setAiLoading] = useState(false);
  const [aiSuggestion, setAiSuggestion] = useState('');
  
  // SWP Modal State
  const [swpAssessment, setSwpAssessment] = useState<RiskAssessment | null>(null);

  useEffect(() => {
    if (!profile?.siteId) return;
    
    const q = query(collection(db, 'risk_assessments'), where('siteId', '==', profile.siteId), orderBy('createdAt', 'desc'), limit(100));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data: RiskAssessment[] = [];
      snapshot.forEach((doc) => {
        data.push({ id: doc.id, ...doc.data() } as RiskAssessment);
      });
      setAssessments(data);
      setLoading(false);
    }, (error) => {
      handleFirestoreError(error, OperationType.LIST, 'risk_assessments');
      setLoading(false);
    });

    const assetsQ = query(collection(db, 'assets'), where('siteId', '==', profile.siteId));
    const unsubAssets = onSnapshot(assetsQ, (snapshot) => {
      const data: {id: string, name: string}[] = [];
      snapshot.forEach((doc) => {
        data.push({ id: doc.id, name: doc.data().name });
      });
      setAvailableAssets(data);
    }, (error) => {
      console.error("Error fetching assets:", error);
    });

    return () => {
      unsubscribe();
      unsubAssets();
    };
  }, [profile?.siteId]);

  useEffect(() => {
    if (!profile?.siteId) return;

    const qAudits = query(collection(db, 'contractor_audits'), where('siteId', '==', profile.siteId), orderBy('createdAt', 'desc'), limit(100));
    const unsubAudits = onSnapshot(qAudits, (snapshot) => {
      setAudits(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as ContractorAudit[]);
    });

    const qContractors = query(collection(db, 'contractors'), where('siteId', '==', profile.siteId));
    const unsubContractors = onSnapshot(qContractors, (snapshot) => {
      setContractors(snapshot.docs.map(doc => ({ id: doc.id, companyName: doc.data().companyName })));
    });

    return () => {
      unsubAudits();
      unsubContractors();
    };
  }, [profile]);

  const exportToExcel = () => {
    const data = assessments.map(a => ({
      'Task Name': a.taskName,
      'Location': a.location,
      'Status': a.status,
      'Inherent Risk': `${a.inherentRiskScore}`,
      'Residual Risk': `${a.residualRiskScore}`,
      'Author': a.authorName,
      'Created At': new Date(a.createdAt).toLocaleDateString(),
      'Review Date': a.reviewDate ? new Date(a.reviewDate).toLocaleDateString() : 'N/A'
    }));

    const ws = XLSX.utils.json_to_sheet(data);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, "Risk Register");
    XLSX.writeFile(wb, `Risk_Register_${new Date().toISOString().split('T')[0]}.xlsx`);
  };

  const exportToPDF = () => {
    const doc = new jsPDF();
    doc.setFontSize(18);
    doc.text('Risk Management Register', 14, 22);
    doc.setFontSize(11);
    doc.setTextColor(100);
    doc.text(`Generated on: ${new Date().toLocaleString()}`, 14, 30);

    const tableData = assessments.map(a => [
      a.taskName,
      a.location,
      a.status,
      a.residualRiskScore.toString(),
      new Date(a.createdAt).toLocaleDateString()
    ]);

    (doc as any).autoTable({
      startY: 40,
      head: [['Task Name', 'Location', 'Status', 'Risk Score', 'Created']],
      body: tableData,
      theme: 'striped',
      headStyles: { fillColor: [51, 65, 85] }
    });

    doc.save(`Risk_Register_${new Date().toISOString().split('T')[0]}.pdf`);
  };

  const handlePredictHazards = async () => {
    if (!taskName) return;
    setAiLoading(true);
    setAiSuggestion('');
    try {
      const ai = getGeminiClient();
      const response = await ai.models.generateContent({
        model: 'gemini-3.1-pro-preview',
        contents: `As an OHS expert, identify 1 primary hazard and suggest 1 control measure for the task: "${taskName}". Format as a short, concise paragraph.`,
      });
      setAiSuggestion(response.text || 'No suggestions found.');
    } catch (error) {
      console.error(error);
      setAiSuggestion('Error generating suggestions.');
    }
    setAiLoading(false);
  };

  const handleAddAudit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!profile) return;

    const contractor = contractors.find(c => c.id === selectedContractorId);
    if (!contractor) return;

    try {
      await addDoc(collection(db, 'contractor_audits'), {
        contractorId: selectedContractorId,
        contractorName: contractor.companyName,
        auditDate: new Date(auditDate).toISOString(),
        auditorName,
        score: Number(auditScore),
        findings: auditFindings.split('\n').filter(Boolean),
        status: new Date(auditDate) < new Date() ? 'Overdue' : 'Scheduled',
        authorId: profile.uid,
        siteId: profile.siteId,
        createdAt: new Date().toISOString()
      });
      setIsAddingAudit(false);
      setSelectedContractorId('');
      setAuditDate('');
      setAuditorName('');
      setAuditScore(0);
      setAuditFindings('');
    } catch (error) {
      handleFirestoreError(error, OperationType.CREATE, 'contractor_audits');
    }
  };

  const addControl = () => {
    if (!currentControlDesc) return;
    setControls([...controls, { type: currentControlType, description: currentControlDesc, isCritical: currentControlCritical }]);
    setCurrentControlDesc('');
    setCurrentControlCritical(false);
  };

  const removeControl = (index: number) => {
    setControls(controls.filter((_, i) => i !== index));
  };

  const toggleTrigger = (trigger: string) => {
    if (selectedTriggers.includes(trigger)) {
      setSelectedTriggers(selectedTriggers.filter(t => t !== trigger));
    } else {
      setSelectedTriggers([...selectedTriggers, trigger]);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!profile) return;
    if (controls.length === 0) {
      alert("Please add at least one control measure.");
      return;
    }

    const inherentRiskScore = inherentProbability * inherentSeverity;
    const residualRiskScore = residualProbability * residualSeverity;

    if (residualRiskScore > inherentRiskScore) {
      alert("Residual risk cannot be higher than inherent risk.");
      return;
    }

    try {
      const contractor = contractors.find(c => c.id === selectedContractorIdForHira);
      const newAssessment = {
        taskName,
        hazard,
        inherentProbability,
        inherentSeverity,
        inherentRiskScore,
        controls,
        residualProbability,
        residualSeverity,
        residualRiskScore,
        requiredPPE,
        requiredCompetencies,
        applicableLegislation,
        environmentalImpacts,
        consultedStakeholders,
        location,
        assetId,
        assetName,
        contractorId: selectedContractorIdForHira,
        contractorName: contractor?.companyName || '',
        version: 1,
        originalId: '',
        previousId: '',
        reviewDate: reviewDate ? new Date(reviewDate).toISOString() : null,
        reviewTriggers: selectedTriggers,
        authorId: profile.uid,
        authorName: profile.fullName || 'Unknown User',
        siteId: profile.siteId,
        createdAt: new Date().toISOString(),
        status: 'Draft'
      };

      await addDoc(collection(db, 'risk_assessments'), newAssessment);
      
      // Reset form
      setIsCreating(false);
      setTaskName('');
      setHazard('');
      setInherentProbability(1);
      setInherentSeverity(1);
      setResidualProbability(1);
      setResidualSeverity(1);
      setControls([]);
      setRequiredPPE([]);
      setRequiredCompetencies([]);
      setApplicableLegislation([]);
      setEnvironmentalImpacts([]);
      setConsultedStakeholders([]);
      setLocation('');
      setAssetId('');
      setAssetName('');
      setSelectedContractorIdForHira('');
      setReviewDate('');
      setSelectedTriggers(['Annual Review']);
      setAiSuggestion('');
    } catch (error) {
      handleFirestoreError(error, OperationType.CREATE, 'risk_assessments');
    }
  };

  const handleRevise = async (assessment: RiskAssessment) => {
    if (!window.confirm('Create a new revision of this assessment?')) return;
    try {
      const newAssessment = {
        ...assessment,
        status: 'Draft',
        version: (assessment.version || 1) + 1,
        previousId: assessment.id,
        originalId: assessment.originalId || assessment.id,
        createdAt: new Date().toISOString(),
        reviewDate: null,
        reviewerId: null,
        reviewerName: null,
        reviewComments: null,
        reviewedAt: null,
        approverId: null,
        approverName: null,
        approvalComments: null,
        approvedAt: null,
      };
      delete (newAssessment as any).id;
      
      await addDoc(collection(db, 'risk_assessments'), newAssessment);
    } catch (error) {
      handleFirestoreError(error, OperationType.CREATE, 'risk_assessments');
    }
  };

  const handleDelete = async (id: string) => {
    if (!window.confirm('Are you sure you want to delete this assessment?')) return;
    try {
      await deleteDoc(doc(db, 'risk_assessments', id));
    } catch (error) {
      handleFirestoreError(error, OperationType.DELETE, `risk_assessments/${id}`);
    }
  };

  const updateAssessmentStatus = async (assessment: RiskAssessment, newStatus: string, additionalData: any = {}) => {
    if (!profile) return;
    try {
      const { updateDoc } = await import('firebase/firestore');
      await updateDoc(doc(db, 'risk_assessments', assessment.id), {
        status: newStatus,
        ...additionalData
      });

      if (newStatus === 'Active' && assessment.previousId) {
        await updateDoc(doc(db, 'risk_assessments', assessment.previousId), {
          status: 'Archived'
        });
      }
    } catch (error) {
      handleFirestoreError(error, OperationType.UPDATE, `risk_assessments/${assessment.id}`);
    }
  };

  const getRiskLevel = (score: number) => {
    if (score >= 15) return { label: 'High', color: 'bg-red-100 text-red-800 border-red-200' };
    if (score >= 8) return { label: 'Medium', color: 'bg-amber-100 text-amber-800 border-amber-200' };
    return { label: 'Low', color: 'bg-green-100 text-green-800 border-green-200' };
  };

  // Hierarchy of Controls Enforcer Check
  const hasHigherControls = controls.some(c => ['Elimination', 'Substitution', 'Engineering'].includes(c.type));
  const isAddingPPEWithoutHigher = currentControlType === 'PPE' && !hasHigherControls;

  const isReviewDue = (dateStr?: string) => {
    if (!dateStr) return false;
    return new Date(dateStr) < new Date();
  };

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
      <Box sx={{ display: 'flex', justifyContent: 'flex-end', alignItems: 'center' }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          {activeTab === 'hira' && (
            <>
              <Box sx={{ display: 'flex', alignItems: 'center', bgcolor: 'background.paper', border: 1, borderColor: 'divider', borderRadius: 1, p: 0.5, boxShadow: 1 }}>
                <Button
                  onClick={exportToExcel}
                  color="success"
                  startIcon={<FileSpreadsheet   sx={{ fontSize: 18 }} />}
                  sx={{ textTransform: 'none', '&:hover': { bgcolor: 'success.50' } }}
                >
                  <Box component="span" sx={{ display: { xs: 'none', sm: 'inline' } }}>Excel</Box>
                </Button>
                <Box sx={{ width: '1px', height: 24, bgcolor: 'divider', mx: 0.5 }} />
                <Button
                  onClick={exportToPDF}
                  color="error"
                  startIcon={<Download   sx={{ fontSize: 18 }} />}
                  sx={{ textTransform: 'none', '&:hover': { bgcolor: 'error.50' } }}
                >
                  <Box component="span" sx={{ display: { xs: 'none', sm: 'inline' } }}>PDF</Box>
                </Button>
              </Box>
              <Button
                variant="contained"
                onClick={() => setIsCreating(!isCreating)}
                startIcon={<Plus   sx={{ fontSize: 20 }} />}
              >
                {isCreating ? 'Cancel' : 'New Assessment'}
              </Button>
            </>
          )}
          {activeTab === 'audits' && (
            <Button
              variant="contained"
              onClick={() => setIsAddingAudit(true)}
              startIcon={<Plus   sx={{ fontSize: 20 }} />}
            >
              Schedule Audit
            </Button>
          )}
        </Box>
      </Box>

      {/* Tabs */}
      <Paper elevation={0} sx={{ borderBottom: 1, borderColor: 'divider', bgcolor: 'transparent' }}>
        <Tabs 
          value={activeTab} 
          onChange={(e, val) => setActiveTab(val)}
          variant="scrollable"
          scrollButtons="auto"
          sx={{
            '& .MuiTab-root': {
              minHeight: 48,
              textTransform: 'none',
              fontWeight: 600,
              fontSize: '0.875rem'
            }
          }}
        >
          <Tab 
            icon={<Shield   sx={{ fontSize: 16 }} />} 
            iconPosition="start" 
            label="HIRA Register" 
            value="hira" 
          />
          <Tab 
            icon={<UserCheck   sx={{ fontSize: 16 }} />} 
            iconPosition="start" 
            label="Contractor Audits (CR 7)" 
            value="audits" 
          />
        </Tabs>
      </Paper>

      {activeTab === 'hira' ? (
        <>
          {isCreating && (
        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-200">
          <h2 className="text-lg font-semibold mb-6 border-b pb-2">Create New Risk Assessment</h2>
          <form onSubmit={handleSubmit} className="space-y-8">
            
            {/* Step 1: Task & Hazard */}
            <div className="space-y-4">
              <h3 className="font-medium text-gray-900 flex items-center gap-2"><Shield   sx={{ fontSize: 18 }} /> 1. Task & Hazard Identification</h3>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="md:col-span-2">
                  <label className="block text-sm font-medium text-gray-700 mb-1">Task Name</label>
                  <TextField
                    type="text"
                    required
                    value={taskName}
                    onChange={(e) => setTaskName(e.target.value)}
                    className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:ring-2 focus:ring-blue-500"
                    placeholder="e.g., Working at heights on scaffolding"
                  />
                  <button
                    type="button"
                    onClick={handlePredictHazards}
                    disabled={!taskName || aiLoading}
                    className="mt-2 w-full bg-slate-100 text-slate-700 px-4 py-2 rounded-lg hover:bg-slate-200 flex items-center justify-center gap-2 transition-colors disabled:opacity-50 text-sm"
                  >
                    {aiLoading ? <Loader2 className="animate-spin"   sx={{ fontSize: 16 }} /> : <Brain   sx={{ fontSize: 16 }} />}
                    Suggest Hazards with AI
                  </button>
                  {aiSuggestion && (
                    <div className="mt-2 p-3 bg-blue-50 text-blue-800 rounded-lg text-sm border border-blue-100">
                      <strong>AI Suggestion:</strong>
                      <p className="mt-1">{aiSuggestion}</p>
                    </div>
                  )}
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Location / Area</label>
                  <TextField
                    type="text"
                    value={location}
                    onChange={(e) => setLocation(e.target.value)}
                    className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:ring-2 focus:ring-blue-500"
                    placeholder="e.g., Warehouse A, Sector 4"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Linked Asset / Equipment (Optional)</label>
                  <TextField select
                    value={assetId}
                    onChange={(e) => {
                      const val = e.target.value;
                      setAssetId(val);
                      const selectedAsset = availableAssets.find(a => a.id === val);
                      setAssetName(selectedAsset ? selectedAsset.name : '');
                    }}
                    className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:ring-2 focus:ring-blue-500"
                  >
                    <MenuItem value="">None</MenuItem>
                    {availableAssets.map(asset => (
                      <MenuItem key={asset.id} value={asset.id}>{asset.name}</MenuItem>
                    ))}
                  </TextField>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Contractor (CR 7 Linkage)</label>
                  <TextField select
                    value={selectedContractorIdForHira}
                    onChange={(e) => setSelectedContractorIdForHira(e.target.value)}
                    className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:ring-2 focus:ring-blue-500"
                  >
                    <MenuItem value="">-- Internal / No Contractor --</MenuItem>
                    {contractors.map(c => (
                      <MenuItem key={c.id} value={c.id}>{c.companyName}</MenuItem>
                    ))}
                  </TextField>
                </div>
                <div className="md:col-span-2">
                  <label className="block text-sm font-medium text-gray-700 mb-1">Identified Hazard</label>
                  <textarea
                    required
                    value={hazard}
                    onChange={(e) => setHazard(e.target.value)}
                    className="w-full rounded-lg border border-gray-300 px-4 py-2 h-24 focus:ring-2 focus:ring-blue-500"
                    placeholder="Describe the hazard..."
                  />
                </div>
              </div>
            </div>

            {/* Step 2: Inherent Risk */}
            <div className="space-y-4 bg-red-50 p-4 rounded-lg border border-red-100">
              <h3 className="font-medium text-red-900">2. Inherent Risk (Before Controls)</h3>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6 items-center">
                <div>
                  <label className="block text-sm font-medium text-red-800 mb-1">Probability (1-5)</label>
                  <TextField
                    type="number" inputProps={{ min: 1, max: 5 }} required
                    value={inherentProbability}
                    onChange={(e) => setInherentProbability(Number(e.target.value))}
                    className="w-full rounded-lg border border-red-300 px-4 py-2 focus:ring-2 focus:ring-red-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-red-800 mb-1">Severity (1-5)</label>
                  <TextField
                    type="number" inputProps={{ min: 1, max: 5 }} required
                    value={inherentSeverity}
                    onChange={(e) => setInherentSeverity(Number(e.target.value))}
                    className="w-full rounded-lg border border-red-300 px-4 py-2 focus:ring-2 focus:ring-red-500"
                  />
                </div>
                <div className="flex flex-col items-center justify-center p-4 bg-white rounded-lg border border-red-200">
                  <span className="text-sm text-gray-500 mb-1">Inherent Score</span>
                  <span className={`px-4 py-1 rounded-full text-sm font-bold border ${getRiskLevel(inherentProbability * inherentSeverity).color} mb-3`}>
                    {inherentProbability * inherentSeverity} - {getRiskLevel(inherentProbability * inherentSeverity).label}
                  </span>
                  <RiskMatrix probability={inherentProbability} severity={inherentSeverity} />
                </div>
              </div>
            </div>

            {/* Step 3: Hierarchy of Controls */}
            <div className="space-y-4">
              <h3 className="font-medium text-gray-900">3. Hierarchy of Controls</h3>
              
              <div className="bg-gray-50 p-4 rounded-lg border border-gray-200 space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-12 gap-4">
                  <div className="md:col-span-3">
                    <label className="block text-sm font-medium text-gray-700 mb-1">Control Type</label>
                    <TextField select
                      value={currentControlType}
                      onChange={(e) => setCurrentControlType(e.target.value as Control['type'])}
                      className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-blue-500"
                    >
                      {CONTROL_TYPES.map(t => <MenuItem key={t} value={t}>{t}</MenuItem>)}
                    </TextField>
                  </div>
                  <div className="md:col-span-6">
                    <label className="block text-sm font-medium text-gray-700 mb-1">Description</label>
                    <TextField
                      type="text"
                      value={currentControlDesc}
                      onChange={(e) => setCurrentControlDesc(e.target.value)}
                      className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-blue-500"
                      placeholder="Describe the control..."
                    />
                  </div>
                  <div className="md:col-span-3 flex flex-col justify-end">
                    <label className="flex items-center gap-2 text-sm text-gray-700 mb-2">
                      <input 
                        type="checkbox" 
                        checked={currentControlCritical}
                        onChange={(e) => setCurrentControlCritical(e.target.checked)}
                        className="rounded text-blue-600"
                      />
                      Critical Control?
                    </label>
                    <button
                      type="button"
                      onClick={addControl}
                      disabled={!currentControlDesc}
                      className="w-full bg-slate-800 text-white px-3 py-2 rounded-lg text-sm hover:bg-slate-700 disabled:opacity-50"
                    >
                      Add Control
                    </button>
                  </div>
                </div>
                
                {isAddingPPEWithoutHigher && (
                  <div className="flex items-center gap-2 text-amber-700 bg-amber-50 p-3 rounded-lg border border-amber-200 text-sm">
                    <AlertTriangle   sx={{ fontSize: 16 }} />
                    <span><strong>Hierarchy Enforcer:</strong> You are adding PPE without higher-level controls (Elimination, Engineering). Please justify or consider higher controls first.</span>
                  </div>
                )}

                {controls.length > 0 && (
                  <div className="mt-4 space-y-2">
                    <h4 className="text-sm font-medium text-gray-700">Applied Controls:</h4>
                    {controls.map((c, idx) => (
                      <div key={idx} className="flex items-center justify-between bg-white p-3 rounded border border-gray-200 text-sm">
                        <div className="flex items-center gap-3">
                          <span className={`px-2 py-1 rounded text-xs font-medium ${
                            c.type === 'Elimination' ? 'bg-green-100 text-green-800' :
                            c.type === 'Engineering' ? 'bg-blue-100 text-blue-800' :
                            'bg-gray-100 text-gray-800'
                          }`}>
                            {c.type}
                          </span>
                          <span>{c.description}</span>
                          {c.isCritical && <span className="text-xs bg-red-100 text-red-800 px-2 py-0.5 rounded-full font-bold">CRITICAL</span>}
                        </div>
                        <button type="button" onClick={() => removeControl(idx)} className="text-gray-400 hover:text-red-600">
                          <Trash2   sx={{ fontSize: 16 }} />
                        </button>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>

            {/* Step 4: Residual Risk */}
            <div className="space-y-4 bg-green-50 p-4 rounded-lg border border-green-100">
              <h3 className="font-medium text-green-900">4. Residual Risk (After Controls)</h3>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6 items-center">
                <div>
                  <label className="block text-sm font-medium text-green-800 mb-1">Probability (1-5)</label>
                  <TextField
                    type="number" inputProps={{ min: 1, max: 5 }} required
                    value={residualProbability}
                    onChange={(e) => setResidualProbability(Number(e.target.value))}
                    className="w-full rounded-lg border border-green-300 px-4 py-2 focus:ring-2 focus:ring-green-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-green-800 mb-1">Severity (1-5)</label>
                  <TextField
                    type="number" inputProps={{ min: 1, max: 5 }} required
                    value={residualSeverity}
                    onChange={(e) => setResidualSeverity(Number(e.target.value))}
                    className="w-full rounded-lg border border-green-300 px-4 py-2 focus:ring-2 focus:ring-green-500"
                  />
                </div>
                <div className="flex flex-col items-center justify-center p-4 bg-white rounded-lg border border-green-200">
                  <span className="text-sm text-gray-500 mb-1">Residual Score</span>
                  <span className={`px-4 py-1 rounded-full text-sm font-bold border ${getRiskLevel(residualProbability * residualSeverity).color} mb-3`}>
                    {residualProbability * residualSeverity} - {getRiskLevel(residualProbability * residualSeverity).label}
                  </span>
                  <RiskMatrix probability={residualProbability} severity={residualSeverity} />
                </div>
              </div>
            </div>

            {/* Step 5: Additional Requirements */}
            <div className="space-y-4">
              <h3 className="font-medium text-gray-900 flex items-center gap-2"><Shield   sx={{ fontSize: 18 }} /> 5. Additional Requirements</h3>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Required PPE (comma separated)</label>
                  <TextField
                    type="text"
                    value={requiredPPE.join(', ')}
                    onChange={(e) => setRequiredPPE(e.target.value.split(',').map(s => s.trim()).filter(Boolean))}
                    className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:ring-2 focus:ring-blue-500"
                    placeholder="e.g., Hard hat, Safety glasses"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Required Competencies</label>
                  <TextField
                    type="text"
                    value={requiredCompetencies.join(', ')}
                    onChange={(e) => setRequiredCompetencies(e.target.value.split(',').map(s => s.trim()).filter(Boolean))}
                    className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:ring-2 focus:ring-blue-500"
                    placeholder="e.g., Working at Heights"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Applicable Legislation</label>
                  <TextField
                    type="text"
                    value={applicableLegislation.join(', ')}
                    onChange={(e) => setApplicableLegislation(e.target.value.split(',').map(s => s.trim()).filter(Boolean))}
                    className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:ring-2 focus:ring-blue-500"
                    placeholder="e.g., OSHA 1910.132"
                  />
                </div>
                <div className="md:col-span-3 grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Environmental Impacts (HSEQ)</label>
                    <TextField
                      type="text"
                      value={environmentalImpacts.join(', ')}
                      onChange={(e) => setEnvironmentalImpacts(e.target.value.split(',').map(s => s.trim()).filter(Boolean))}
                      className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:ring-2 focus:ring-blue-500"
                      placeholder="e.g., Soil contamination, Noise pollution"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Consulted Stakeholders</label>
                    <TextField
                      type="text"
                      value={consultedStakeholders.join(', ')}
                      onChange={(e) => setConsultedStakeholders(e.target.value.split(',').map(s => s.trim()).filter(Boolean))}
                      className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:ring-2 focus:ring-blue-500"
                      placeholder="e.g., John Doe (Operator), Jane Smith (Rep)"
                    />
                  </div>
                </div>
              </div>
            </div>

            {/* Step 6: Review Triggers */}
            <div className="space-y-4">
              <h3 className="font-medium text-gray-900 flex items-center gap-2"><CalendarClock   sx={{ fontSize: 18 }} /> 6. Automated Review Triggers</h3>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Next Scheduled Review Date</label>
                  <TextField InputLabelProps={{ shrink: true }}
                    type="date"
                    required
                    value={reviewDate}
                    onChange={(e) => setReviewDate(e.target.value)}
                    className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Trigger Events (Auto-flags for review)</label>
                  <div className="flex flex-wrap gap-2">
                    {REVIEW_TRIGGERS.map(trigger => (
                      <button
                        key={trigger}
                        type="button"
                        onClick={() => toggleTrigger(trigger)}
                        className={`px-3 py-1.5 rounded-full text-sm border transition-colors ${
                          selectedTriggers.includes(trigger) 
                            ? 'bg-blue-100 border-blue-300 text-blue-800 font-medium' 
                            : 'bg-white border-gray-300 text-gray-600 hover:bg-gray-50'
                        }`}
                      >
                        {trigger}
                      </button>
                    ))}
                  </div>
                </div>
              </div>
            </div>

            <div className="flex justify-end pt-6 border-t border-gray-200">
              <button
                type="submit"
                className="bg-blue-600 text-white px-8 py-3 rounded-lg hover:bg-blue-700 transition-colors font-bold text-lg shadow-sm"
              >
                Save Assessment
              </button>
            </div>
          </form>
        </div>
      )}

      <div className="bg-white shadow-sm rounded-xl border border-gray-200 overflow-hidden">
        <div className="p-4 border-b border-gray-200 bg-gray-50">
          <h2 className="font-semibold text-gray-900">HIRA Register</h2>
        </div>
        
        {loading ? (
          <div className="p-8 text-center text-gray-500">Loading assessments...</div>
        ) : assessments.length === 0 ? (
          <div className="p-8 text-center text-gray-500 flex flex-col items-center">
            <ShieldAlert className="w-12 h-12 text-gray-300 mb-3"   />
            <p>No risk assessments found. Create one to get started.</p>
          </div>
        ) : (
          <div className="divide-y divide-gray-200">
            {assessments.map((assessment) => (
              <div key={assessment.id} className="p-6 hover:bg-gray-50 transition-colors">
                <div className="flex justify-between items-start mb-4">
                  <div>
                    <div className="flex items-center gap-3">
                      <h3 className="font-bold text-lg text-gray-900">{assessment.taskName}</h3>
                      <span className="text-xs font-bold text-gray-500 bg-gray-100 px-2 py-1 rounded-full">
                        v{assessment.version || 1}
                      </span>
                      <span className={`px-2 py-1 rounded-full text-xs font-medium border ${
                        assessment.status === 'Active' ? 'bg-green-100 text-green-800 border-green-200' :
                        assessment.status === 'Draft' ? 'bg-gray-100 text-gray-800 border-gray-200' :
                        assessment.status === 'Awaiting Review' ? 'bg-yellow-100 text-yellow-800 border-yellow-200' :
                        assessment.status === 'Awaiting Approval' ? 'bg-blue-100 text-blue-800 border-blue-200' :
                        assessment.status === 'Rejected' ? 'bg-red-100 text-red-800 border-red-200' :
                        assessment.status === 'Archived' ? 'bg-slate-100 text-slate-800 border-slate-200' :
                        'bg-gray-100 text-gray-800 border-gray-200'
                      }`}>
                        {assessment.status}
                      </span>
                    </div>
                    <p className="text-sm text-gray-500 mt-1">Hazard: {assessment.hazard}</p>
                    <div className="flex items-center gap-4 mt-2 text-sm text-gray-600">
                      {assessment.location && (
                        <span className="flex items-center gap-1"><MapPin  className="text-gray-400"  sx={{ fontSize: 14 }} /> {assessment.location}</span>
                      )}
                      {assessment.assetName && (
                        <span className="flex items-center gap-1"><BoxIcon  className="text-gray-400"  sx={{ fontSize: 14 }}  /> {assessment.assetName}</span>
                      )}
                    </div>
                  </div>
                  <div className="flex flex-col items-end gap-2">
                    {isReviewDue(assessment.reviewDate) && assessment.status === 'Active' && (
                      <span className="flex items-center gap-1 text-xs font-bold text-red-600 bg-red-50 px-2 py-1 rounded border border-red-200">
                        <AlertTriangle   sx={{ fontSize: 14 }} /> REVIEW OVERDUE
                      </span>
                    )}
                    <div className="flex items-center gap-2">
                      {assessment.status === 'Draft' && profile?.uid === assessment.authorId && (
                        <button
                          onClick={() => updateAssessmentStatus(assessment, 'Awaiting Review')}
                          className="text-xs bg-blue-50 text-blue-600 hover:bg-blue-100 px-3 py-1.5 rounded-lg font-medium transition-colors border border-blue-200"
                        >
                          Submit for Review
                        </button>
                      )}
                      {assessment.status === 'Awaiting Review' && (
                        <button
                          onClick={() => updateAssessmentStatus(assessment, 'Awaiting Approval', {
                            reviewerId: profile?.uid,
                            reviewerName: profile?.fullName || 'Unknown',
                            reviewedAt: new Date().toISOString()
                          })}
                          className="text-xs bg-yellow-50 text-yellow-700 hover:bg-yellow-100 px-3 py-1.5 rounded-lg font-medium transition-colors border border-yellow-200"
                        >
                          Review Assessment
                        </button>
                      )}
                      {assessment.status === 'Awaiting Approval' && (
                        <button
                          onClick={() => updateAssessmentStatus(assessment, 'Active', {
                            approverId: profile?.uid,
                            approverName: profile?.fullName || 'Unknown',
                            approvedAt: new Date().toISOString()
                          })}
                          className="text-xs bg-green-50 text-green-700 hover:bg-green-100 px-3 py-1.5 rounded-lg font-medium transition-colors border border-green-200"
                        >
                          Approve Assessment
                        </button>
                      )}
                      {assessment.status === 'Active' && (
                        <>
                          <button
                            onClick={() => setSwpAssessment(assessment)}
                            className="text-xs bg-teal-50 text-teal-700 hover:bg-teal-100 px-3 py-1.5 rounded-lg font-medium transition-colors border border-teal-200 flex items-center gap-1"
                          >
                            <FileText   sx={{ fontSize: 14 }} /> View SWP
                          </button>
                          <button
                            onClick={() => handleRevise(assessment)}
                            className="text-xs bg-indigo-50 text-indigo-700 hover:bg-indigo-100 px-3 py-1.5 rounded-lg font-medium transition-colors border border-indigo-200"
                          >
                            Create Revision
                          </button>
                        </>
                      )}
                      {profile?.uid === assessment.authorId && assessment.status !== 'Archived' && (
                        <button 
                          onClick={() => handleDelete(assessment.id)}
                          className="text-gray-400 hover:text-red-600 transition-colors p-1"
                          title="Delete Assessment"
                        >
                          <Trash2   sx={{ fontSize: 18 }} />
                        </button>
                      )}
                    </div>
                  </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
                  <div className="bg-red-50 p-3 rounded-lg border border-red-100 flex flex-col items-center justify-center">
                    <span className="text-xs text-red-800 uppercase font-bold mb-1">Inherent Risk</span>
                    <span className={`px-3 py-1 rounded-full text-sm font-bold border ${getRiskLevel(assessment.inherentRiskScore).color} mb-3`}>
                      {assessment.inherentRiskScore} - {getRiskLevel(assessment.inherentRiskScore).label}
                    </span>
                    <RiskMatrix probability={assessment.inherentProbability} severity={assessment.inherentSeverity} />
                  </div>
                  <div className="bg-gray-50 p-3 rounded-lg border border-gray-200 flex flex-col items-center justify-center">
                    <span className="text-xs text-gray-600 uppercase font-bold mb-1">Controls Applied</span>
                    <span className="text-3xl font-bold text-gray-800">{assessment.controls?.length || 0}</span>
                  </div>
                  <div className="bg-green-50 p-3 rounded-lg border border-green-100 flex flex-col items-center justify-center">
                    <span className="text-xs text-green-800 uppercase font-bold mb-1">Residual Risk</span>
                    <span className={`px-3 py-1 rounded-full text-sm font-bold border ${getRiskLevel(assessment.residualRiskScore).color} mb-3`}>
                      {assessment.residualRiskScore} - {getRiskLevel(assessment.residualRiskScore).label}
                    </span>
                    <RiskMatrix probability={assessment.residualProbability} severity={assessment.residualSeverity} />
                  </div>
                </div>

                <div className="bg-white border border-gray-100 rounded-lg p-3 mb-3">
                  <h4 className="text-xs font-bold text-gray-500 uppercase mb-2">Hierarchy of Controls</h4>
                  <div className="flex flex-wrap gap-2">
                    {assessment.controls?.map((c, i) => (
                      <span key={i} className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium border ${
                        c.type === 'Elimination' ? 'bg-green-50 text-green-700 border-green-200' :
                        c.type === 'Engineering' ? 'bg-blue-50 text-blue-700 border-blue-200' :
                        'bg-gray-50 text-gray-700 border-gray-200'
                      }`}>
                        {c.type}: {c.description}
                        {c.isCritical && <AlertTriangle  className="text-red-500"  sx={{ fontSize: 12 }} />}
                      </span>
                    ))}
                  </div>
                </div>

                {(assessment.requiredPPE?.length > 0 || assessment.requiredCompetencies?.length > 0 || assessment.applicableLegislation?.length > 0 || assessment.environmentalImpacts?.length > 0 || assessment.consultedStakeholders?.length > 0) && (
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-3">
                    {assessment.requiredPPE?.length > 0 && (
                      <div className="bg-white border border-gray-100 rounded-lg p-3">
                        <h4 className="text-xs font-bold text-gray-500 uppercase mb-2">Required PPE</h4>
                        <div className="flex flex-wrap gap-2">
                          {assessment.requiredPPE.map((ppe, i) => (
                            <span key={i} className="px-2 py-1 bg-gray-100 text-gray-700 rounded text-xs">{ppe}</span>
                          ))}
                        </div>
                      </div>
                    )}
                    {assessment.requiredCompetencies?.length > 0 && (
                      <div className="bg-white border border-gray-100 rounded-lg p-3">
                        <h4 className="text-xs font-bold text-gray-500 uppercase mb-2">Required Competencies</h4>
                        <div className="flex flex-wrap gap-2">
                          {assessment.requiredCompetencies.map((comp, i) => (
                            <span key={i} className="px-2 py-1 bg-blue-50 text-blue-700 rounded text-xs">{comp}</span>
                          ))}
                        </div>
                      </div>
                    )}
                    {assessment.applicableLegislation?.length > 0 && (
                      <div className="bg-white border border-gray-100 rounded-lg p-3">
                        <h4 className="text-xs font-bold text-gray-500 uppercase mb-2">Applicable Legislation</h4>
                        <div className="flex flex-wrap gap-2">
                          {assessment.applicableLegislation.map((leg, i) => (
                            <span key={i} className="px-2 py-1 bg-purple-50 text-purple-700 rounded text-xs">{leg}</span>
                          ))}
                        </div>
                      </div>
                    )}
                    {assessment.environmentalImpacts?.length > 0 && (
                      <div className="bg-white border border-gray-100 rounded-lg p-3">
                        <h4 className="text-xs font-bold text-gray-500 uppercase mb-2">Environmental Impacts</h4>
                        <div className="flex flex-wrap gap-2">
                          {assessment.environmentalImpacts.map((env, i) => (
                            <span key={i} className="px-2 py-1 bg-emerald-50 text-emerald-700 rounded text-xs border border-emerald-100">{env}</span>
                          ))}
                        </div>
                      </div>
                    )}
                    {assessment.consultedStakeholders?.length > 0 && (
                      <div className="bg-white border border-gray-100 rounded-lg p-3">
                        <h4 className="text-xs font-bold text-gray-500 uppercase mb-2">Consulted Stakeholders</h4>
                        <div className="flex flex-wrap gap-2">
                          {assessment.consultedStakeholders.map((stakeholder, i) => (
                            <span key={i} className="px-2 py-1 bg-amber-50 text-amber-700 rounded text-xs border border-amber-100">{stakeholder}</span>
                          ))}
                        </div>
                      </div>
                    )}
                  </div>
                )}

                <div className="flex items-center justify-between text-xs text-gray-400 mt-4 pt-4 border-t border-gray-100">
                  <div className="flex items-center gap-4">
                    <span>By {assessment.authorName}</span>
                    <span>Created: {new Date(assessment.createdAt).toLocaleDateString()}</span>
                    {assessment.reviewDate && (
                      <span className={isReviewDue(assessment.reviewDate) ? 'text-red-500 font-bold' : ''}>
                        Next Review: {new Date(assessment.reviewDate).toLocaleDateString()}
                      </span>
                    )}
                  </div>
                  <div className="flex items-center gap-2">
                    <span className="font-medium">Triggers:</span>
                    {assessment.reviewTriggers?.join(', ') || 'None'}
                  </div>
                </div>

                {/* Action Items Section */}
                <ActionItemsList assessmentId={assessment.id} />

                {/* Digital Sign-off Section */}
                <SignOffSection assessment={assessment} />

                {/* BBS Observations Section */}
                <BBSObservationSection assessment={assessment} />
              </div>
            ))}
          </div>
        )}
      </div>
      </>
    ) : (
      <div className="space-y-6">
        <div className="bg-white shadow-sm rounded-xl border border-gray-200 overflow-hidden">
          <div className="p-4 border-b border-gray-200 bg-gray-50 flex justify-between items-center">
            <h2 className="font-semibold text-gray-900">Contractor Audit Register (CR 7)</h2>
            <div className="flex gap-2">
              <span className="flex items-center gap-1 text-xs font-medium text-green-700 bg-green-50 px-2 py-1 rounded-full border border-green-100">
                <CheckCircle   sx={{ fontSize: 12 }} /> {audits.filter(a => a.status === 'Completed').length} Completed
              </span>
              <span className="flex items-center gap-1 text-xs font-medium text-red-700 bg-red-50 px-2 py-1 rounded-full border border-red-100">
                <AlertTriangle   sx={{ fontSize: 12 }} /> {audits.filter(a => a.status === 'Overdue').length} Overdue
              </span>
            </div>
          </div>
          
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 text-sm">
                  <th className="p-4 font-medium">Contractor</th>
                  <th className="p-4 font-medium">Audit Date</th>
                  <th className="p-4 font-medium">Auditor</th>
                  <th className="p-4 font-medium">Score</th>
                  <th className="p-4 font-medium">Status</th>
                  <th className="p-4 font-medium">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {audits.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="p-8 text-center text-slate-500">
                      No audits scheduled. Click "Schedule Audit" to begin.
                    </td>
                  </tr>
                ) : (
                  audits.map((audit) => (
                    <tr key={audit.id} className="hover:bg-slate-50 transition-colors">
                      <td className="p-4">
                        <div className="font-medium text-slate-900">{audit.contractorName}</div>
                        <div className="text-xs text-slate-500">ID: {audit.contractorId}</div>
                      </td>
                      <td className="p-4 text-slate-600">
                        {new Date(audit.auditDate).toLocaleDateString()}
                      </td>
                      <td className="p-4 text-slate-600">{audit.auditorName}</td>
                      <td className="p-4">
                        <div className="flex items-center gap-2">
                          <div className="w-16 bg-slate-100 rounded-full h-2 overflow-hidden">
                            <div 
                              className={`h-full rounded-full ${
                                audit.score >= 80 ? 'bg-green-500' :
                                audit.score >= 60 ? 'bg-amber-500' : 'bg-red-500'
                              }`}
                              style={{ width: `${audit.score}%` }}
                            />
                          </div>
                          <span className="text-sm font-bold text-slate-700">{audit.score}%</span>
                        </div>
                      </td>
                      <td className="p-4">
                        <span className={`px-2 py-1 rounded-full text-xs font-medium border ${
                          audit.status === 'Completed' ? 'bg-green-100 text-green-800 border-green-200' :
                          audit.status === 'Overdue' ? 'bg-red-100 text-red-800 border-red-200' :
                          'bg-blue-100 text-blue-800 border-blue-200'
                        }`}>
                          {audit.status}
                        </span>
                      </td>
                      <td className="p-4">
                        <button className="text-slate-400 hover:text-blue-600 p-1 transition-colors">
                          <Eye   sx={{ fontSize: 18 }} />
                        </button>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    )}

    {/* Schedule Audit Modal */}
    {isAddingAudit && (
      <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
        <div className="bg-white rounded-xl shadow-xl w-full max-w-md overflow-hidden animate-in fade-in zoom-in duration-200">
          <div className="p-6 border-b border-slate-100 flex justify-between items-center bg-slate-50">
            <h2 className="text-xl font-bold text-slate-900">Schedule Contractor Audit</h2>
            <button onClick={() => setIsAddingAudit(false)} className="text-slate-400 hover:text-slate-600 transition-colors">
              <X   sx={{ fontSize: 24 }} />
            </button>
          </div>
          <form onSubmit={handleAddAudit} className="p-6 space-y-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Select Contractor</label>
              <TextField select 
                required
                value={selectedContractorId}
                onChange={(e) => setSelectedContractorId(e.target.value)}
                className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              >
                <MenuItem value="">-- Select Contractor --</MenuItem>
                {contractors.map(c => (
                  <MenuItem key={c.id} value={c.id}>{c.companyName}</MenuItem>
                ))}
              </TextField>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Audit Date</label>
                <TextField InputLabelProps={{ shrink: true }} 
                  type="date" 
                  required
                  value={auditDate}
                  onChange={(e) => setAuditDate(e.target.value)}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Score (%)</label>
                <TextField 
                  type="number" 
                  inputProps={{ min: 0, max: 100 }}
                  required
                  value={auditScore}
                  onChange={(e) => setAuditScore(Number(e.target.value))}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                />
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Auditor Name</label>
              <TextField 
                type="text" 
                required
                value={auditorName}
                onChange={(e) => setAuditorName(e.target.value)}
                className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                placeholder="e.g., John Smith"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Key Findings (One per line)</label>
              <textarea 
                value={auditFindings}
                onChange={(e) => setAuditFindings(e.target.value)}
                className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 h-24"
                placeholder="e.g., PPE compliance good&#10;Scaffolding needs inspection"
              />
            </div>
            <div className="pt-4 flex justify-end gap-3">
              <button 
                type="button"
                onClick={() => setIsAddingAudit(false)}
                className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
              >
                Cancel
              </button>
              <button 
                type="submit"
                className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors shadow-sm"
              >
                Schedule Audit
              </button>
            </div>
          </form>
        </div>
      </div>
    )}

    {swpAssessment && (
      <SWPModal 
        assessment={swpAssessment} 
        onClose={() => setSwpAssessment(null)} 
      />
    )}
  </Box>
);
}

function SignOffSection({ assessment }: { assessment: RiskAssessment }) {
  const { user } = useAuth();
  const [signOffs, setSignOffs] = useState<RiskSignOff[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const q = query(
      collection(db, 'risk_signoffs'),
      where('assessmentId', '==', assessment.id),
      where('version', '==', assessment.version || 1)
    );
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data: RiskSignOff[] = [];
      snapshot.forEach((doc) => {
        data.push({ id: doc.id, ...doc.data() } as RiskSignOff);
      });
      setSignOffs(data);
      setLoading(false);
    }, (error) => {
      console.error("Error fetching sign-offs:", error);
      setLoading(false);
    });
    return () => unsubscribe();
  }, [assessment.id, assessment.version]);

  const handleSignOff = async () => {
    if (!user) return;
    if (signOffs.some(s => s.userId === user.uid)) {
      alert("You have already signed off on this assessment.");
      return;
    }
    try {
      await addDoc(collection(db, 'risk_signoffs'), {
        assessmentId: assessment.id,
        userId: user.uid,
        userName: user.displayName || 'Unknown User',
        signedAt: new Date().toISOString(),
        version: assessment.version || 1
      });
    } catch (error) {
      handleFirestoreError(error, OperationType.CREATE, 'risk_signoffs');
    }
  };

  if (assessment.status !== 'Active') return null;

  return (
    <div className="mt-6 bg-slate-50 rounded-lg p-4 border border-slate-200">
      <div className="flex justify-between items-center mb-4">
        <h4 className="text-sm font-bold text-slate-700 flex items-center gap-2">
          <UserCheck   sx={{ fontSize: 16 }} /> Digital Sign-off Register
        </h4>
        <button
          onClick={handleSignOff}
          disabled={signOffs.some(s => s.userId === user?.uid)}
          className="text-xs bg-blue-600 text-white px-3 py-1.5 rounded-lg hover:bg-blue-700 disabled:opacity-50 transition-colors flex items-center gap-1"
        >
          <PenTool   sx={{ fontSize: 14 }} /> Sign Off
        </button>
      </div>
      
      {loading ? (
        <div className="text-xs text-gray-500">Loading sign-offs...</div>
      ) : signOffs.length === 0 ? (
        <div className="text-xs text-gray-500 italic">No sign-offs yet. All workers must sign off before starting task.</div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-2">
          {signOffs.map((signOff) => (
            <div key={signOff.id} className="bg-white p-2 rounded border border-slate-200 flex items-center justify-between">
              <div className="flex flex-col">
                <span className="text-xs font-medium text-gray-900">{signOff.userName}</span>
                <span className="text-[10px] text-gray-500">{new Date(signOff.signedAt).toLocaleString()}</span>
              </div>
              <CheckCircle  className="text-green-500"  sx={{ fontSize: 14 }} />
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

function BBSObservationSection({ assessment }: { assessment: RiskAssessment }) {
  const { user } = useAuth();
  const [observations, setObservations] = useState<BBSObservation[]>([]);
  const [isLogging, setIsLogging] = useState(false);
  const [loading, setLoading] = useState(true);

  // Form state
  const [observationType, setObservationType] = useState<BBSObservation['observationType']>('Safe Act');
  const [description, setDescription] = useState('');
  const [intervention, setIntervention] = useState('');

  useEffect(() => {
    const q = query(
      collection(db, 'bbs_observations'),
      where('assessmentId', '==', assessment.id)
    );
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data: BBSObservation[] = [];
      snapshot.forEach((doc) => {
        data.push({ id: doc.id, ...doc.data() } as BBSObservation);
      });
      setObservations(data);
      setLoading(false);
    }, (error) => {
      console.error("Error fetching BBS observations:", error);
      setLoading(false);
    });
    return () => unsubscribe();
  }, [assessment.id]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user) return;
    try {
      await addDoc(collection(db, 'bbs_observations'), {
        assessmentId: assessment.id,
        location: assessment.location || 'Site',
        observationType,
        description,
        interventionAction: intervention,
        pointsAwarded: observationType === 'Safe Act' ? 10 : 5,
        authorId: user.uid,
        observerName: user.displayName || 'Anonymous',
        createdAt: new Date().toISOString()
      });
      setIsLogging(false);
      setDescription('');
      setIntervention('');
    } catch (error) {
      handleFirestoreError(error, OperationType.CREATE, 'bbs_observations');
    }
  };

  if (assessment.status !== 'Active') return null;

  return (
    <div className="mt-4 bg-amber-50 rounded-lg p-4 border border-amber-200">
      <div className="flex justify-between items-center mb-4">
        <h4 className="text-sm font-bold text-amber-800 flex items-center gap-2">
          <Eye   sx={{ fontSize: 16 }} /> BBS Observation Linkage
        </h4>
        <button
          onClick={() => setIsLogging(!isLogging)}
          className="text-xs bg-amber-600 text-white px-3 py-1.5 rounded-lg hover:bg-amber-700 transition-colors flex items-center gap-1"
        >
          {isLogging ? 'Cancel' : <><Plus   sx={{ fontSize: 14 }} /> Log Observation</>}
        </button>
      </div>

      {isLogging && (
        <form onSubmit={handleSubmit} className="bg-white p-4 rounded-lg border border-amber-200 mb-4 space-y-3">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-medium text-gray-700 mb-1">Observation Type</label>
              <TextField select
                value={observationType}
                onChange={(e) => setObservationType(e.target.value as BBSObservation['observationType'])}
                className="w-full rounded border border-gray-300 px-2 py-1 text-sm"
              >
                <MenuItem value="Safe Act">Safe Act (Positive Reinforcement)</MenuItem>
                <MenuItem value="Unsafe Act">Unsafe Act (Intervention Required)</MenuItem>
                <MenuItem value="Unsafe Condition">Unsafe Condition</MenuItem>
              </TextField>
            </div>
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-700 mb-1">Description</label>
            <textarea
              required
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              className="w-full rounded border border-gray-300 px-2 py-1 text-sm h-20"
              placeholder="What did you observe?"
            />
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-700 mb-1">Intervention / Action Taken</label>
            <TextField
              type="text"
              value={intervention}
              onChange={(e) => setIntervention(e.target.value)}
              className="w-full rounded border border-gray-300 px-2 py-1 text-sm"
              placeholder="How did you address it?"
            />
          </div>
          <div className="flex justify-end">
            <button
              type="submit"
              className="bg-amber-600 text-white px-4 py-1.5 rounded text-sm font-medium hover:bg-amber-700"
            >
              Save Observation
            </button>
          </div>
        </form>
      )}
      
      {loading ? (
        <div className="text-xs text-gray-500">Loading observations...</div>
      ) : observations.length === 0 ? (
        <div className="text-xs text-gray-500 italic">No BBS observations linked to this assessment yet.</div>
      ) : (
        <div className="space-y-2">
          {observations.map((obs) => (
            <div key={obs.id} className="bg-white p-3 rounded border border-amber-200 text-xs">
              <div className="flex justify-between items-start mb-1">
                <span className={`font-bold ${
                  obs.observationType === 'Safe Act' ? 'text-green-600' : 'text-red-600'
                }`}>
                  {obs.observationType}
                </span>
                <span className="text-gray-400">{new Date(obs.createdAt).toLocaleDateString()}</span>
              </div>
              <p className="text-gray-700 mb-1">{obs.description}</p>
              {obs.interventionAction && (
                <p className="text-gray-500 italic flex items-center gap-1">
                  <MessageSquare   sx={{ fontSize: 12 }} /> {obs.interventionAction}
                </p>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

