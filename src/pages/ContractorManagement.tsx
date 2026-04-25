import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy, doc, updateDoc, deleteDoc, where, limit } from 'firebase/firestore';
import { db, auth, handleFirestoreError } from '../lib/firebase';
import { useAuth } from '../contexts/AuthContext';
import { 
  Users, 
  FileText, 
  ShieldCheck, 
  QrCode, 
  Plus, 
  Search,
  CheckCircle,
  XCircle,
  AlertTriangle,
  Upload,
  PenTool,
  RefreshCw,
  Clock,
  Network,
  Activity,
  BrainCircuit,
  Award,
  Zap,
  MessageSquare,
  HardHat,
  FileWarning,
  Send,
  Link,
  Star,
  Megaphone
} from 'lucide-react';
import { QRCodeSVG } from 'qrcode.react';
import { checkAndGenerateExpiries } from '../services/notificationService';
import { getGeminiClient } from '../lib/gemini';

interface Contractor {
  id: string;
  companyName: string;
  contactPerson: string;
  contactEmail: string;
  complianceStatus: 'Green' | 'Amber' | 'Red';
  section37Signed: boolean;
  safetyPassportQr: string;
  parentId?: string; // For Sub-contractor hierarchy
  isPrincipal?: boolean;
  scopeOfWork?: string;
  authorId: string;
  createdAt: string;
}

interface ContractorDocument {
  id: string;
  contractorId: string;
  workerId?: string;
  type: 'Letter of Good Standing' | 'Public Liability Insurance' | 'Medical Certificate' | 'Safety File' | 'Trade Certificate' | 'ID Document' | 'Method Statement' | 'Risk Assessment' | 'Appointment Letter' | 'Insurance Certificate' | 'Safety File Index' | 'Statutory Appointment' | 'Other';
  status: 'Pending' | 'Approved' | 'Rejected' | 'Expired';
  expiryDate: string;
  uploadedById: string;
  createdAt: string;
}

interface ContractorWorker {
  id: string;
  contractorId: string;
  fullName: string;
  idNumber: string;
  jobTitle?: string;
  safetyPassportQr: string;
  complianceStatus: 'Green' | 'Amber' | 'Red';
  authorId: string;
  createdAt: string;
}

interface MedicalRecord {
  id: string;
  idNumber: string;
  status: 'Fit' | 'Fit with Restrictions' | 'Unfit';
  nextDueDate: string;
}

interface TrainingRecord {
  id: string;
  idNumber: string;
  courseName: string;
  status: 'Active' | 'Expired';
  expiryDate: string;
}

interface AccessLog {
  id: string;
  workerId: string;
  contractorId: string;
  zone: string;
  type: 'IN' | 'OUT';
  timestamp: string;
  authorId: string;
}

export default function ContractorManagement() {
  const { profile } = useAuth();
  const [activeTab, setActiveTab] = useState<'register' | 'workers' | 'documents' | 'section37' | 'passports' | 'access' | 'hierarchy' | 'competency' | 'toolbox' | 'scorecards' | 'ppe'>('register');
  const [contractors, setContractors] = useState<Contractor[]>([]);
  const [workers, setWorkers] = useState<ContractorWorker[]>([]);
  const [documents, setDocuments] = useState<ContractorDocument[]>([]);
  const [medicalRecords, setMedicalRecords] = useState<MedicalRecord[]>([]);
  const [trainingRecords, setTrainingRecords] = useState<TrainingRecord[]>([]);
  const [accessLogs, setAccessLogs] = useState<AccessLog[]>([]);
  
  const [isAddingContractor, setIsAddingContractor] = useState(false);
  const [isAddingWorker, setIsAddingWorker] = useState(false);
  const [isUploadingDoc, setIsUploadingDoc] = useState(false);
  const [checkingCompliance, setCheckingCompliance] = useState(false);
  
  const [isIssuingNCR, setIsIssuingNCR] = useState(false);
  const [isOnboarding, setIsOnboarding] = useState(false);
  const [ncrDescription, setNcrDescription] = useState('');
  const [ncrSeverity, setNcrSeverity] = useState('Minor');
  const [selectedContractorForNCR, setSelectedContractorForNCR] = useState('');
  
  const [selectedContractorId, setSelectedContractorId] = useState<string>('');
  const [selectedWorkerId, setSelectedWorkerId] = useState<string>('');
  const [searchQuery, setSearchQuery] = useState('');

  // Form states
  const [companyName, setCompanyName] = useState('');
  const [contactPerson, setContactPerson] = useState('');
  const [contactEmail, setContactEmail] = useState('');
  const [parentId, setParentId] = useState('');
  const [isPrincipal, setIsPrincipal] = useState(false);
  const [contractorScope, setContractorScope] = useState('General');
  
  const [workerName, setWorkerName] = useState('');
  const [selectedZone, setSelectedZone] = useState('Main Workshop');
  const [gateAccessResult, setGateAccessResult] = useState<{status: 'Granted' | 'Denied' | 'OverrideRequired', message: string} | null>(null);
  const [workerIdNumber, setWorkerIdNumber] = useState('');
  const [workerJobTitle, setWorkerJobTitle] = useState('');
  
  const [docType, setDocType] = useState<ContractorDocument['type']>('Letter of Good Standing');
  const [docExpiry, setDocExpiry] = useState('');
  const [safetyFileView, setSafetyFileView] = useState<string | null>(null);
  
  const [isAnalyzingDocument, setIsAnalyzingDocument] = useState(false);
  const [documentFile, setDocumentFile] = useState<File | null>(null);
  const [aiAnalysisResult, setAiAnalysisResult] = useState<string | null>(null);

  const [isGeneratingRiskProfile, setIsGeneratingRiskProfile] = useState(false);
  const [selectedContractorRiskProfile, setSelectedContractorRiskProfile] = useState<{contractorId: string, profile: string} | null>(null);

  const handleRunComplianceCheck = async () => {
    if (!profile?.uid) return;
    setCheckingCompliance(true);
    try {
      const count = await checkAndGenerateExpiries(profile.uid);
      alert(`Compliance check complete. ${count} new notifications generated.`);
    } catch (error) {
      console.error("Error running compliance check", error);
      alert("Error running compliance check. See console for details.");
    } finally {
      setCheckingCompliance(false);
    }
  };

  useEffect(() => {
    if (!profile?.siteId) return;

    const qContractors = query(collection(db, 'contractors'), where('siteId', '==', profile.siteId), orderBy('createdAt', 'desc'), limit(100));
    const unsubscribeContractors = onSnapshot(qContractors, (snapshot) => {
      const contractorData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as Contractor[];
      setContractors(contractorData);
    }, (error) => {
      handleFirestoreError(error, 'list' as any, 'contractors');
    });

    const qWorkers = query(collection(db, 'contractor_workers'), where('siteId', '==', profile.siteId), orderBy('createdAt', 'desc'), limit(100));
    const unsubscribeWorkers = onSnapshot(qWorkers, (snapshot) => {
      const workerData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as ContractorWorker[];
      setWorkers(workerData);
    }, (error) => {
      handleFirestoreError(error, 'list' as any, 'contractor_workers');
    });

    const qDocs = query(collection(db, 'contractor_documents'), where('siteId', '==', profile.siteId), orderBy('createdAt', 'desc'), limit(100));
    const unsubscribeDocs = onSnapshot(qDocs, (snapshot) => {
      const docData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as ContractorDocument[];
      setDocuments(docData);
    }, (error) => {
      handleFirestoreError(error, 'list' as any, 'contractor_documents');
    });

    const qMedicals = query(collection(db, 'medical_records'), where('siteId', '==', profile.siteId));
    const unsubscribeMedicals = onSnapshot(qMedicals, (snapshot) => {
      setMedicalRecords(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as MedicalRecord[]);
    });

    const qTraining = query(collection(db, 'training_records'), where('siteId', '==', profile.siteId));
    const unsubscribeTraining = onSnapshot(qTraining, (snapshot) => {
      setTrainingRecords(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as TrainingRecord[]);
    });

    const qAccessLogs = query(collection(db, 'contractor_access_logs'), where('siteId', '==', profile.siteId), orderBy('timestamp', 'desc'), limit(100));
    const unsubscribeAccessLogs = onSnapshot(qAccessLogs, (snapshot) => {
      setAccessLogs(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as AccessLog[]);
    });

    return () => {
      unsubscribeContractors();
      unsubscribeWorkers();
      unsubscribeDocs();
      unsubscribeMedicals();
      unsubscribeTraining();
      unsubscribeAccessLogs();
    };
  }, [profile?.siteId]);

  useEffect(() => {
    if (workers.length > 0) {
      workers.forEach(worker => {
        recalculateWorkerCompliance(worker.id);
      });
    }
  }, [workers, contractors, documents, medicalRecords, trainingRecords]);

  const recalculateWorkerCompliance = async (workerId: string) => {
    const worker = workers.find(w => w.id === workerId);
    if (!worker) return;

    const employer = contractors.find(c => c.id === worker.contractorId);
    const workerMedicals = medicalRecords.filter(m => m.idNumber === worker.idNumber);
    const workerTraining = trainingRecords.filter(t => t.idNumber === worker.idNumber);
    const workerDocs = documents.filter(d => d.workerId === worker.id && d.status === 'Approved');
    const employerDocs = documents.filter(d => d.contractorId === worker.contractorId && !d.workerId && d.status === 'Approved');

    // Logic for Green:
    // 1. Employer must have Section 37(2) signed
    // 2. Employer must have approved LOGS (Letter of Good Standing) that is not expired
    // 3. Worker must have a 'Fit' medical record that is not expired (Annexure 3)
    // 4. Worker must have an 'Active' Induction training record (CR 7(5))
    // 5. Worker must have an approved ID Document
    // 6. Employer must have an approved 'Safety File' (CR 7(1)(b))

    const hasSignedSec37 = employer?.section37Signed || false;
    const hasApprovedLogs = employerDocs.some(d => d.type === 'Letter of Good Standing' && new Date(d.expiryDate) > new Date());
    const hasFitMedical = workerMedicals.some(m => m.status === 'Fit' && new Date(m.nextDueDate) > new Date());
    const hasInduction = workerTraining.some(t => t.courseName.toLowerCase().includes('induction') && t.status === 'Active' && new Date(t.expiryDate) > new Date());
    const hasIdDoc = workerDocs.some(d => d.type === 'ID Document');
    const hasSafetyFile = employerDocs.some(d => d.type === 'Safety File');

    let newStatus: 'Green' | 'Amber' | 'Red' = 'Red';

    if (hasSignedSec37 && hasApprovedLogs && hasFitMedical && hasInduction && hasIdDoc && hasSafetyFile) {
      newStatus = 'Green';
    } else if (hasSignedSec37 && (hasFitMedical || hasInduction || hasSafetyFile)) {
      newStatus = 'Amber';
    }

    if (newStatus !== worker.complianceStatus) {
      try {
        await updateDoc(doc(db, 'contractor_workers', worker.id), { complianceStatus: newStatus });
      } catch (error) {
        console.error("Error updating worker compliance:", error);
      }
    }
  };

  const handleAddContractor = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!profile?.uid) return;

    try {
      const newContractor = {
        companyName,
        contactPerson,
        contactEmail,
        complianceStatus: 'Red',
        section37Signed: false,
        safetyPassportQr: `SP-CO-${Date.now()}`,
        parentId: parentId || null,
        isPrincipal,
        scopeOfWork: contractorScope,
        authorId: profile?.uid,
        siteId: profile?.siteId,
        createdAt: new Date().toISOString()
      };

      const docRef = await addDoc(collection(db, 'contractors'), newContractor);
      
      // Generate Site-Specific Safety File Templates
      const requiredDocs = ['Letter of Good Standing', 'Safety File Index', 'Risk Assessment', 'Method Statement', 'Appointment Letter'];
      
      if (contractorScope === 'Electrical') {
        requiredDocs.push('Trade Certificate', 'Other'); // e.g. Lockout Tagout
      } else if (contractorScope === 'Civil') {
        requiredDocs.push('Statutory Appointment', 'Other'); // e.g. Excavation Risk Assessment
      } else if (contractorScope === 'Working at Heights') {
        requiredDocs.push('Statutory Appointment', 'Other'); // e.g. Fall Protection Plan
      }

      for (const docType of requiredDocs) {
        await addDoc(collection(db, 'contractor_documents'), {
          contractorId: docRef.id,
          workerId: null,
          type: docType,
          status: 'Pending',
          expiryDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(), // 30 days placeholder
          uploadedById: profile?.uid,
          siteId: profile?.siteId,
          createdAt: new Date().toISOString()
        });
      }

      setIsAddingContractor(false);
      setCompanyName('');
      setContactPerson('');
      setContactEmail('');
      setParentId('');
      setIsPrincipal(false);
      setContractorScope('General');
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'contractors');
    }
  };

  const handleAddWorker = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!profile?.uid || !selectedContractorId) return;

    try {
      const newWorker = {
        contractorId: selectedContractorId,
        fullName: workerName,
        idNumber: workerIdNumber,
        jobTitle: workerJobTitle,
        safetyPassportQr: `SP-WK-${Date.now()}`,
        complianceStatus: 'Red',
        authorId: profile.uid,
        siteId: profile.siteId,
        createdAt: new Date().toISOString()
      };

      await addDoc(collection(db, 'contractor_workers'), newWorker);
      setIsAddingWorker(false);
      setWorkerName('');
      setWorkerIdNumber('');
      setWorkerJobTitle('');
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'contractor_workers');
    }
  };

  const handleUploadDocument = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!profile?.uid || !selectedContractorId) return;

    try {
      const newDoc = {
        contractorId: selectedContractorId,
        workerId: selectedWorkerId || null,
        type: docType,
        status: aiAnalysisResult ? 'Approved' : 'Pending', // Auto-approve if AI verified
        expiryDate: new Date(docExpiry).toISOString(),
        uploadedById: profile.uid,
        siteId: profile.siteId,
        createdAt: new Date().toISOString()
      };

      await addDoc(collection(db, 'contractor_documents'), newDoc);
      setIsUploadingDoc(false);
      setDocExpiry('');
      setSelectedWorkerId('');
      setDocumentFile(null);
      setAiAnalysisResult(null);
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'contractor_documents');
    }
  };

  const handleDocumentFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    
    setDocumentFile(file);
    setIsAnalyzingDocument(true);
    setAiAnalysisResult(null);

    try {
      // Convert file to base64 for Gemini
      const reader = new FileReader();
      reader.readAsDataURL(file);
      reader.onloadend = async () => {
        const base64data = reader.result as string;
        const base64String = base64data.split(',')[1];

        const prompt = `You are an expert SHEQ Auditor. Analyze this document. 
        1. Identify the document type (e.g., Letter of Good Standing, Medical Certificate, ID).
        2. Extract the Expiry Date or Valid Until date (format as YYYY-MM-DD).
        3. Determine if it appears valid and authentic.
        
        Respond with a JSON object ONLY: {"type": "Document Type", "expiryDate": "YYYY-MM-DD", "isValid": true/false, "reason": "Brief explanation"}`;

        const ai = getGeminiClient();
        const result = await ai.models.generateContent({
          model: "gemini-3-flash-preview",
          contents: [
            prompt,
            {
              inlineData: {
                data: base64String,
                mimeType: file.type
              }
            }
          ]
        });

        const text = result.text || "{}";
        try {
          const jsonMatch = text.match(/\{[\s\S]*\}/);
          if (jsonMatch) {
            const parsed = JSON.parse(jsonMatch[0]);
            if (parsed.expiryDate && parsed.expiryDate !== "YYYY-MM-DD") {
              setDocExpiry(parsed.expiryDate);
            }
            if (parsed.isValid) {
              setAiAnalysisResult(`AI Verified: ${parsed.type}. Valid until ${parsed.expiryDate}.`);
            } else {
              setAiAnalysisResult(`AI Flagged: ${parsed.reason}`);
            }
          }
        } catch (e) {
          console.error("Failed to parse AI response", e);
        }
        setIsAnalyzingDocument(false);
      };
    } catch (error) {
      console.error("AI Analysis failed", error);
      setIsAnalyzingDocument(false);
    }
  };

  const handleSignSection37 = async (contractorId: string) => {
    try {
      const contractorRef = doc(db, 'contractors', contractorId);
      await updateDoc(contractorRef, {
        section37Signed: true
      });
      // Recalculate compliance status
      recalculateCompliance(contractorId, true);
    } catch (error) {
      handleFirestoreError(error, 'update' as any, `contractors/${contractorId}`);
    }
  };

  const handleApproveDocument = async (docId: string, contractorId: string) => {
    try {
      const docRef = doc(db, 'contractor_documents', docId);
      await updateDoc(docRef, {
        status: 'Approved'
      });
      // Recalculate compliance status
      const contractor = contractors.find(c => c.id === contractorId);
      if (contractor) {
        recalculateCompliance(contractorId, contractor.section37Signed);
      }
    } catch (error) {
      handleFirestoreError(error, 'update' as any, `contractor_documents/${docId}`);
    }
  };

  const recalculateCompliance = async (contractorId: string, isSection37Signed: boolean) => {
    // Logic for Contractor Green:
    // 1. Section 37 signed
    // 2. Approved & Valid Letter of Good Standing (LOGS)
    // 3. Approved Safety File
    // 4. All mandatory Statutory Appointments (CR 8(1), 8(7)) approved
    
    const contractorDocs = documents.filter(d => d.contractorId === contractorId && !d.workerId && d.status === 'Approved');
    const hasApprovedLogs = contractorDocs.some(d => d.type === 'Letter of Good Standing' && new Date(d.expiryDate) > new Date());
    const hasApprovedSafetyFile = contractorDocs.some(d => d.type === 'Safety File');
    const hasStatutoryAppointments = contractorDocs.some(d => d.type === 'Statutory Appointment');

    let newStatus: 'Green' | 'Amber' | 'Red' = 'Red';
    if (isSection37Signed && hasApprovedLogs && hasApprovedSafetyFile && hasStatutoryAppointments) {
      newStatus = 'Green';
    } else if (isSection37Signed || hasApprovedLogs || hasApprovedSafetyFile) {
      newStatus = 'Amber';
    }

    try {
      const contractorRef = doc(db, 'contractors', contractorId);
      await updateDoc(contractorRef, {
        complianceStatus: newStatus
      });
    } catch (error) {
      console.error("Failed to update compliance status", error);
    }
  };

  const handleGenerateRiskProfile = async (contractor: Contractor) => {
    setIsGeneratingRiskProfile(true);
    try {
      const contractorWorkers = workers.filter(w => w.contractorId === contractor.id);
      const contractorDocs = documents.filter(d => d.contractorId === contractor.id);
      
      const prompt = `You are a Senior Safety Risk Analyst. Generate a brief, punchy Risk Profile for this contractor based on the following data:
      Company: ${contractor.companyName}
      Scope of Work: ${contractor.scopeOfWork || 'General'}
      Current Compliance Status: ${contractor.complianceStatus}
      Total Workers: ${contractorWorkers.length}
      Total Documents Uploaded: ${contractorDocs.length}
      
      Provide a 3-paragraph summary:
      1. Overall Risk Rating (Low/Medium/High) and why.
      2. Key Vulnerabilities (e.g., missing documents, high-risk scope).
      3. Recommended Actions.
      
      Format with markdown.`;

      const ai = getGeminiClient();
      const result = await ai.models.generateContent({
        model: "gemini-3-flash-preview",
        contents: prompt
      });

      setSelectedContractorRiskProfile({
        contractorId: contractor.id,
        profile: result.text || "Unable to generate profile."
      });
    } catch (error) {
      console.error("Error generating risk profile", error);
      alert("Failed to generate risk profile.");
    } finally {
      setIsGeneratingRiskProfile(false);
    }
  };

  const filteredContractors = contractors.filter(c => 
    c.companyName.toLowerCase().includes(searchQuery.toLowerCase()) ||
    c.contactPerson.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'Green': return 'bg-green-100 text-green-800 border-green-200';
      case 'Amber': return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      case 'Red': return 'bg-red-100 text-red-800 border-red-200';
      case 'Approved': return 'bg-green-100 text-green-800';
      case 'Pending': return 'bg-yellow-100 text-yellow-800';
      case 'Rejected':
      case 'Expired': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-end gap-2 w-full sm:w-auto">
        <button
          onClick={handleRunComplianceCheck}
          disabled={checkingCompliance}
          className="flex-1 sm:flex-none bg-white text-gray-700 border border-gray-300 px-4 py-2 rounded-lg hover:bg-gray-50 flex items-center justify-center gap-2 transition-colors"
        >
          <RefreshCw size={20} className={checkingCompliance ? 'animate-spin' : ''} />
          {checkingCompliance ? 'Checking...' : 'Compliance Check'}
        </button>
        <button 
          onClick={() => setIsAddingContractor(true)}
          className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
        >
          <Plus size={20} />
          Register Contractor
        </button>
        <button 
          onClick={() => setIsOnboarding(true)}
          className="flex items-center gap-2 bg-indigo-600 text-white px-4 py-2 rounded-lg hover:bg-indigo-700 transition-colors"
        >
          <Link size={20} />
          Self-Registration Link
        </button>
      </div>

      {/* Tabs */}
      <div className="flex overflow-x-auto border-b border-slate-200 hide-scrollbar">
        <button
          onClick={() => setActiveTab('register')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'register' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Users size={18} />
          Contractor Register
        </button>
        <button
          onClick={() => setActiveTab('workers')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'workers' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Users size={18} />
          Worker Management
        </button>
        <button
          onClick={() => setActiveTab('documents')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'documents' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <FileText size={18} />
          Document Portal
        </button>
        <button
          onClick={() => setActiveTab('section37')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'section37' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <PenTool size={18} />
          Section 37(2) Agreements
        </button>
        <button
          onClick={() => setActiveTab('passports')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'passports' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <QrCode size={18} />
          Safety Passports
        </button>
        <button
          onClick={() => setActiveTab('access')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'access' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Clock size={18} />
          Access Logs
        </button>
        <button
          onClick={() => setActiveTab('hierarchy')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'hierarchy' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Network size={18} />
          Tier Mapping
        </button>
        <button
          onClick={() => setActiveTab('competency')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'competency' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Award size={18} />
          Competency Matrix
        </button>
        <button
          onClick={() => setActiveTab('toolbox')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'toolbox' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <MessageSquare size={18} />
          Toolbox Talks
        </button>
        <button
          onClick={() => setActiveTab('scorecards')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'scorecards' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Star size={18} />
          Scorecards
        </button>
        <button
          onClick={() => setActiveTab('ppe')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'ppe' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <HardHat size={18} />
          PPE Tracking
        </button>
      </div>

      {/* Content Area */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        
        {/* Register Tab */}
        {activeTab === 'register' && (
          <div className="p-6">
            {/* Contractor Compliance Heatmap */}
            <div className="mb-8 grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="bg-slate-50 border border-slate-200 rounded-xl p-4 flex items-center justify-between">
                <div>
                  <p className="text-sm text-slate-500 font-medium">Total Contractors</p>
                  <p className="text-2xl font-bold text-slate-900">{contractors.length}</p>
                </div>
                <div className="w-12 h-12 bg-blue-100 text-blue-600 rounded-full flex items-center justify-center">
                  <Users size={24} />
                </div>
              </div>
              <div className="bg-green-50 border border-green-200 rounded-xl p-4 flex items-center justify-between">
                <div>
                  <p className="text-sm text-green-700 font-medium">Fully Compliant (Green)</p>
                  <p className="text-2xl font-bold text-green-900">
                    {contractors.filter(c => c.complianceStatus === 'Green').length}
                  </p>
                </div>
                <div className="w-12 h-12 bg-green-100 text-green-600 rounded-full flex items-center justify-center">
                  <ShieldCheck size={24} />
                </div>
              </div>
              <div className="bg-red-50 border border-red-200 rounded-xl p-4 flex items-center justify-between">
                <div>
                  <p className="text-sm text-red-700 font-medium">Non-Compliant (Red)</p>
                  <p className="text-2xl font-bold text-red-900">
                    {contractors.filter(c => c.complianceStatus === 'Red').length}
                  </p>
                </div>
                <div className="w-12 h-12 bg-red-100 text-red-600 rounded-full flex items-center justify-center">
                  <AlertTriangle size={24} />
                </div>
              </div>
            </div>

            <div className="flex items-center gap-4 mb-6">
              <div className="relative flex-1 max-w-md">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={20} />
                <input 
                  type="text" 
                  placeholder="Search contractors..." 
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
                    <th className="p-4 font-medium">Company Name</th>
                    <th className="p-4 font-medium">Type</th>
                    <th className="p-4 font-medium">Contact Person</th>
                    <th className="p-4 font-medium">Compliance</th>
                    <th className="p-4 font-medium">Section 37(2)</th>
                    <th className="p-4 font-medium">Workers</th>
                    <th className="p-4 font-medium">Registered</th>
                    <th className="p-4 font-medium text-right">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredContractors.length === 0 ? (
                    <tr>
                      <td colSpan={8} className="p-8 text-center text-slate-500">
                        No contractors found.
                      </td>
                    </tr>
                  ) : (
                    filteredContractors.map((contractor) => {
                      const parent = contractors.find(c => c.id === contractor.parentId);
                      const compliance = contractor.complianceStatus;
                      return (
                        <tr key={contractor.id} className="border-b border-slate-100 hover:bg-slate-50 transition-colors">
                          <td className="p-4">
                            <div className="flex flex-col">
                              <span className="font-medium text-slate-900">{contractor.companyName}</span>
                              {parent && <span className="text-[10px] text-slate-400 uppercase font-bold">Sub of: {parent.companyName}</span>}
                            </div>
                          </td>
                          <td className="p-4">
                            {contractor.isPrincipal ? (
                              <span className="text-xs font-bold text-blue-600 bg-blue-50 px-2 py-0.5 rounded">Principal</span>
                            ) : (
                              <span className="text-xs text-slate-500">Sub-contractor</span>
                            )}
                          </td>
                          <td className="p-4 text-slate-600">{contractor.contactPerson}</td>
                          <td className="p-4">
                            <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium border ${getStatusColor(compliance)}`}>
                              {compliance}
                            </span>
                          </td>
                          <td className="p-4">
                            {contractor.section37Signed ? (
                              <span className="flex items-center gap-1 text-green-600 text-sm font-medium">
                                <CheckCircle size={16} /> Signed
                              </span>
                            ) : (
                              <span className="flex items-center gap-1 text-red-600 text-sm font-medium">
                                <XCircle size={16} /> Pending
                              </span>
                            )}
                          </td>
                          <td className="p-4 text-slate-600">
                            {workers.filter(w => w.contractorId === contractor.id).length}
                          </td>
                          <td className="p-4 text-slate-600 text-sm">
                            {new Date(contractor.createdAt).toLocaleDateString()}
                          </td>
                          <td className="p-4 text-right">
                            <div className="flex items-center justify-end gap-2">
                              <button 
                                onClick={() => {
                                  setSelectedContractorForNCR(contractor.id);
                                  setIsIssuingNCR(true);
                                }}
                                className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-medium bg-red-50 text-red-700 rounded-lg hover:bg-red-100 transition-colors"
                              >
                                <FileWarning size={14} /> Issue NCR
                              </button>
                              <button 
                                onClick={() => handleGenerateRiskProfile(contractor)}
                                className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-medium bg-indigo-50 text-indigo-700 rounded-lg hover:bg-indigo-100 transition-colors"
                              >
                                <BrainCircuit size={14} /> AI Risk Profile
                              </button>
                            </div>
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

        {/* Workers Tab */}
        {activeTab === 'workers' && (
          <div className="p-6">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6">
              <div className="relative flex-1 max-w-md">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={20} />
                <input 
                  type="text" 
                  placeholder="Search workers..." 
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full pl-10 pr-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
              <button 
                onClick={() => setIsAddingWorker(true)}
                className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
              >
                <Plus size={20} />
                Add Worker
              </button>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 text-sm">
                    <th className="p-4 font-medium">Full Name</th>
                    <th className="p-4 font-medium">ID Number</th>
                    <th className="p-4 font-medium">Employer</th>
                    <th className="p-4 font-medium">Job Title</th>
                    <th className="p-4 font-medium">Compliance</th>
                    <th className="p-4 font-medium">Fatigue Risk</th>
                    <th className="p-4 font-medium">Passport ID</th>
                    <th className="p-4 font-medium">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {workers.filter(w => 
                    w.fullName.toLowerCase().includes(searchQuery.toLowerCase()) ||
                    w.idNumber.includes(searchQuery)
                  ).length === 0 ? (
                    <tr>
                      <td colSpan={8} className="p-8 text-center text-slate-500">
                        No workers found.
                      </td>
                    </tr>
                  ) : (
                    workers.filter(w => 
                      w.fullName.toLowerCase().includes(searchQuery.toLowerCase()) ||
                      w.idNumber.includes(searchQuery)
                    ).map((worker) => {
                      const employer = contractors.find(c => c.id === worker.contractorId);
                      
                      // Calculate Fatigue Risk based on Access Logs (last 7 days)
                      const sevenDaysAgo = new Date();
                      sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
                      
                      const recentLogs = accessLogs.filter(log => 
                        log.workerId === worker.id && 
                        new Date(log.timestamp) > sevenDaysAgo &&
                        log.type === 'IN'
                      );
                      
                      const shiftsIn7Days = recentLogs.length;
                      let fatigueStatus = 'Low';
                      let fatigueColor = 'text-green-600 bg-green-50';
                      
                      if (shiftsIn7Days >= 7) {
                        fatigueStatus = 'High (No Rest)';
                        fatigueColor = 'text-red-600 bg-red-50';
                      } else if (shiftsIn7Days === 6) {
                        fatigueStatus = 'Medium (Warning)';
                        fatigueColor = 'text-amber-600 bg-amber-50';
                      }

                      return (
                        <tr key={worker.id} className="border-b border-slate-100 hover:bg-slate-50 transition-colors">
                          <td className="p-4 font-medium text-slate-900">{worker.fullName}</td>
                          <td className="p-4 text-slate-600 font-mono text-sm">{worker.idNumber}</td>
                          <td className="p-4 text-slate-600">{employer?.companyName || 'Unknown'}</td>
                          <td className="p-4 text-slate-600">{worker.jobTitle || '-'}</td>
                          <td className="p-4">
                            <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium border ${getStatusColor(worker.complianceStatus)}`}>
                              {worker.complianceStatus}
                            </span>
                          </td>
                          <td className="p-4">
                            <span className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium border border-transparent ${fatigueColor}`}>
                              <Activity size={14} />
                              {fatigueStatus}
                            </span>
                          </td>
                          <td className="p-4 text-slate-500 font-mono text-xs">{worker.safetyPassportQr}</td>
                          <td className="p-4">
                            <button 
                              onClick={() => recalculateWorkerCompliance(worker.id)}
                              className="text-blue-600 hover:text-blue-800 text-sm font-medium flex items-center gap-1"
                            >
                              <ShieldCheck size={14} /> Verify
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

        {/* Documents Tab */}
        {activeTab === 'documents' && (
          <div className="p-6">
            <div className="flex justify-between items-center mb-6">
              <div>
                <h2 className="text-lg font-semibold text-slate-900">Digital Safety File & Compliance</h2>
                <p className="text-sm text-slate-500">Centralized portal for contractor safety documentation.</p>
              </div>
              <div className="flex gap-3">
                {safetyFileView && (
                  <button 
                    onClick={() => setSafetyFileView(null)}
                    className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg transition-colors text-sm font-medium"
                  >
                    Back to All Documents
                  </button>
                )}
                <button 
                  onClick={() => setIsUploadingDoc(true)}
                  className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
                >
                  <Upload size={20} />
                  Upload Document
                </button>
              </div>
            </div>

            {!safetyFileView ? (
              <div className="space-y-8">
                {/* Safety File Summaries by Contractor */}
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                  {contractors.map(contractor => {
                    const contractorDocs = documents.filter(d => d.contractorId === contractor.id);
                    const safetyFileDocs = contractorDocs.filter(d => 
                      ['Method Statement', 'Risk Assessment', 'Appointment Letter', 'Safety File Index', 'Safety File'].includes(d.type)
                    );
                    const approvedCount = safetyFileDocs.filter(d => d.status === 'Approved').length;
                    const totalRequired = 5; // Example requirement

                    return (
                      <div key={contractor.id} className="bg-slate-50 border border-slate-200 rounded-xl p-5">
                        <div className="flex justify-between items-start mb-4">
                          <h3 className="font-bold text-slate-900">{contractor.companyName}</h3>
                          <ShieldCheck className={approvedCount >= totalRequired ? 'text-green-600' : 'text-slate-300'} size={20} />
                        </div>
                        <div className="space-y-3 mb-6">
                          <div className="flex justify-between text-sm">
                            <span className="text-slate-500">Safety File Progress:</span>
                            <span className="font-medium">{approvedCount} / {totalRequired} Approved</span>
                          </div>
                          <div className="w-full bg-slate-200 rounded-full h-2">
                            <div 
                              className={`h-2 rounded-full ${approvedCount >= totalRequired ? 'bg-green-500' : 'bg-blue-500'}`}
                              style={{ width: `${Math.min((approvedCount / totalRequired) * 100, 100)}%` }}
                            ></div>
                          </div>
                        </div>
                        <button 
                          onClick={() => setSafetyFileView(contractor.id)}
                          className="w-full py-2 bg-white border border-slate-200 text-slate-700 rounded-lg hover:bg-slate-50 transition-colors text-sm font-medium"
                        >
                          Manage Safety File
                        </button>
                      </div>
                    );
                  })}
                </div>

                <hr className="border-slate-200" />

                <div>
                  <h3 className="text-sm font-bold text-slate-400 uppercase tracking-wider mb-4">Recent Document Submissions</h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    {documents.slice(0, 6).map((doc) => {
                      const contractor = contractors.find(c => c.id === doc.contractorId);
                      return (
                        <div key={doc.id} className="border border-slate-200 rounded-xl p-5 hover:shadow-md transition-shadow bg-white">
                          <div className="flex justify-between items-start mb-4">
                            <div className="bg-blue-50 p-3 rounded-lg text-blue-600">
                              <FileText size={24} />
                            </div>
                            <span className={`px-2.5 py-1 rounded-full text-xs font-medium ${getStatusColor(doc.status)}`}>
                              {doc.status}
                            </span>
                          </div>
                          <h3 className="font-semibold text-slate-900 mb-1">{doc.type}</h3>
                          <p className="text-sm text-slate-500 mb-4">{contractor?.companyName || 'Unknown Contractor'}</p>
                          
                          <div className="space-y-2 text-sm text-slate-600 mb-4">
                            <div className="flex justify-between">
                              <span>Expiry Date:</span>
                              <span className="font-medium">{new Date(doc.expiryDate).toLocaleDateString()}</span>
                            </div>
                          </div>

                          {doc.status === 'Pending' && (
                            <div className="flex items-center gap-2">
                              <button 
                                onClick={() => {
                                  alert(`Approval request sent to Microsoft Teams for ${doc.type}.`);
                                }}
                                className="flex-1 py-2 bg-indigo-50 text-indigo-700 rounded-lg hover:bg-indigo-100 transition-colors font-medium text-sm flex items-center justify-center gap-2"
                              >
                                <Send size={16} />
                                Teams
                              </button>
                              <button 
                                onClick={() => handleApproveDocument(doc.id, doc.contractorId)}
                                className="flex-1 py-2 bg-green-50 text-green-700 rounded-lg hover:bg-green-100 transition-colors font-medium text-sm flex items-center justify-center gap-2"
                              >
                                <CheckCircle size={16} />
                                Approve
                              </button>
                            </div>
                          )}
                        </div>
                      );
                    })}
                  </div>
                </div>
              </div>
            ) : (
              <div className="space-y-6">
                <div className="bg-blue-50 border border-blue-100 rounded-xl p-6">
                  <div className="flex items-center gap-4">
                    <div className="bg-white p-3 rounded-lg shadow-sm">
                      <ShieldCheck className="text-blue-600" size={32} />
                    </div>
                    <div>
                      <h3 className="text-xl font-bold text-slate-900">
                        {contractors.find(c => c.id === safetyFileView)?.companyName} - Digital Safety File
                      </h3>
                      <p className="text-blue-700 text-sm">Reviewing compliance against Construction Regulations 2014.</p>
                    </div>
                  </div>
                </div>

                <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
                  <div className="lg:col-span-1 space-y-4">
                    <div className="bg-white border border-slate-200 rounded-xl p-4">
                      <h4 className="font-bold text-slate-900 mb-4 text-sm uppercase tracking-wider">Required Components</h4>
                      <div className="space-y-3">
                        {[
                          'Safety File Index',
                          'Section 37(2) Agreement',
                          'Letter of Good Standing',
                          'Public Liability Insurance',
                          'Risk Assessment',
                          'Method Statement',
                          'Appointment Letters'
                        ].map(item => {
                          const isPresent = documents.some(d => d.contractorId === safetyFileView && d.type.includes(item) && d.status === 'Approved');
                          const isPending = documents.some(d => d.contractorId === safetyFileView && d.type.includes(item) && d.status === 'Pending');
                          
                          return (
                            <div key={item} className="flex items-center justify-between text-sm">
                              <span className="text-slate-600">{item}</span>
                              {isPresent ? (
                                <CheckCircle className="text-green-500" size={16} />
                              ) : isPending ? (
                                <AlertTriangle className="text-amber-500" size={16} />
                              ) : (
                                <XCircle className="text-slate-300" size={16} />
                              )}
                            </div>
                          );
                        })}
                      </div>
                    </div>
                  </div>

                  <div className="lg:col-span-3 space-y-4">
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      {documents.filter(d => d.contractorId === safetyFileView).map(doc => (
                        <div key={doc.id} className="border border-slate-200 rounded-xl p-4 bg-white flex justify-between items-center">
                          <div>
                            <h4 className="font-semibold text-slate-900">{doc.type}</h4>
                            <p className="text-xs text-slate-500">Expires: {new Date(doc.expiryDate).toLocaleDateString()}</p>
                            <span className={`mt-2 inline-block px-2 py-0.5 rounded-full text-[10px] font-bold uppercase ${getStatusColor(doc.status)}`}>
                              {doc.status}
                            </span>
                          </div>
                          <div className="flex gap-2">
                            {doc.status === 'Pending' && (
                              <button 
                                onClick={() => handleApproveDocument(doc.id, doc.contractorId)}
                                className="p-2 text-green-600 hover:bg-green-50 rounded-lg transition-colors"
                                title="Approve"
                              >
                                <CheckCircle size={20} />
                              </button>
                            )}
                            <button className="p-2 text-slate-400 hover:bg-slate-50 rounded-lg transition-colors" title="View File">
                              <FileText size={20} />
                            </button>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              </div>
            )}
          </div>
        )}

        {/* Section 37 Tab */}
        {activeTab === 'section37' && (
          <div className="p-6">
            <h2 className="text-lg font-semibold text-slate-900 mb-6">Section 37(2) Mandatory Agreements</h2>
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {contractors.map((contractor) => (
                <div key={contractor.id} className="border border-slate-200 rounded-xl p-6 flex flex-col sm:flex-row gap-6 items-start sm:items-center justify-between bg-white">
                  <div>
                    <h3 className="font-semibold text-slate-900 text-lg">{contractor.companyName}</h3>
                    <p className="text-slate-500 text-sm mb-2">Contact: {contractor.contactPerson}</p>
                    {contractor.section37Signed ? (
                      <span className="inline-flex items-center gap-1.5 text-green-600 text-sm font-medium bg-green-50 px-3 py-1 rounded-full">
                        <ShieldCheck size={16} />
                        Agreement Signed & Active
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1.5 text-amber-600 text-sm font-medium bg-amber-50 px-3 py-1 rounded-full">
                        <AlertTriangle size={16} />
                        Signature Required
                      </span>
                    )}
                  </div>
                  
                  {!contractor.section37Signed && (
                    <button 
                      onClick={() => handleSignSection37(contractor.id)}
                      className="w-full sm:w-auto px-4 py-2 bg-slate-900 text-white rounded-lg hover:bg-slate-800 transition-colors flex items-center justify-center gap-2 whitespace-nowrap"
                    >
                      <PenTool size={18} />
                      Sign Digitally
                    </button>
                  )}
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Passports Tab */}
        {activeTab === 'passports' && (
          <div className="p-6">
            <h2 className="text-lg font-semibold text-slate-900 mb-6">Digital Safety Passports (Workers)</h2>
            <p className="text-slate-600 mb-8 max-w-3xl">
              Safety Passports are dynamically linked to Medicals, Inductions, and LOGS. 
              A <span className="text-green-600 font-bold">Green</span> status grants physical gate access. 
              <span className="text-amber-600 font-bold"> Amber</span> requires manual override. 
              <span className="text-red-600 font-bold"> Red</span> denies access.
            </p>

            {/* Geofencing Simulation */}
            <div className="mb-8 bg-indigo-50 border border-indigo-100 rounded-xl p-6">
              <h3 className="font-bold text-indigo-900 mb-4 flex items-center gap-2">
                <ShieldCheck size={20} />
                Real-time Compliance Geofencing (Access Control Simulation)
              </h3>
              <div className="flex flex-wrap gap-4 items-end">
                <div>
                  <label className="block text-sm font-medium text-indigo-800 mb-1">Target Zone</label>
                  <select 
                    value={selectedZone}
                    onChange={(e) => setSelectedZone(e.target.value)}
                    className="p-2.5 border border-indigo-200 rounded-lg focus:ring-2 focus:ring-indigo-500"
                  >
                    <option value="Main Workshop">Main Workshop</option>
                    <option value="Chemical Storage">Chemical Storage (High Risk)</option>
                    <option value="High-Voltage Room">High-Voltage Room (Critical)</option>
                  </select>
                </div>
                <div className="text-sm text-indigo-700 bg-white p-2.5 rounded-lg border border-indigo-100">
                  Select a worker and scan their passport to check access.
                </div>
              </div>
              
              {gateAccessResult && (
                <div className={`mt-4 p-4 rounded-lg font-bold ${
                  gateAccessResult.status === 'Granted' ? 'bg-green-100 text-green-800' :
                  gateAccessResult.status === 'Denied' ? 'bg-red-100 text-red-800' :
                  'bg-amber-100 text-amber-800'
                }`}>
                  {gateAccessResult.message}
                </div>
              )}
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
              {workers.map((worker) => {
                const employer = contractors.find(c => c.id === worker.contractorId);
                
                const handleScanPassport = () => {
                  let status: 'Granted' | 'Denied' | 'OverrideRequired' = 'Denied';
                  let message = `Access to ${selectedZone} DENIED for ${worker.fullName}. Compliance: ${worker.complianceStatus}.`;
                  
                  if (worker.complianceStatus === 'Green') {
                    status = 'Granted';
                    message = `Access to ${selectedZone} GRANTED for ${worker.fullName}.`;
                  } else if (worker.complianceStatus === 'Amber') {
                    status = 'OverrideRequired';
                    message = `Access to ${selectedZone} REQUIRES MANUAL OVERRIDE for ${worker.fullName}. Compliance: ${worker.complianceStatus}.`;
                  }
                  
                  setGateAccessResult({status, message});
                };

                return (
                  <div key={worker.id} className="border border-slate-200 rounded-xl overflow-hidden bg-white flex flex-col shadow-sm">
                    <div className={`p-4 border-b ${
                      worker.complianceStatus === 'Green' ? 'bg-green-50 border-green-100' :
                      worker.complianceStatus === 'Amber' ? 'bg-amber-50 border-amber-100' :
                      'bg-red-50 border-red-100'
                    }`}>
                      <h3 className="font-bold text-slate-900 text-center truncate">{worker.fullName}</h3>
                      <p className="text-center text-xs text-slate-500 truncate">{employer?.companyName}</p>
                      <p className={`text-center text-sm font-bold mt-2 ${
                        worker.complianceStatus === 'Green' ? 'text-green-700' :
                        worker.complianceStatus === 'Amber' ? 'text-amber-700' :
                        'text-red-700'
                      }`}>
                        {worker.complianceStatus} STATUS
                      </p>
                    </div>
                    
                    <div className="p-6 flex-1 flex flex-col items-center justify-center">
                      <div className="bg-white p-2 rounded-lg shadow-sm border border-slate-100 mb-4 cursor-pointer hover:shadow-md transition-shadow" onClick={handleScanPassport}>
                        <QRCodeSVG 
                          value={JSON.stringify({
                            id: worker.id,
                            name: worker.fullName,
                            employer: employer?.companyName,
                            status: worker.complianceStatus,
                            qrId: worker.safetyPassportQr
                          })} 
                          size={140} 
                          level="H"
                          fgColor={
                            worker.complianceStatus === 'Green' ? '#16a34a' :
                            worker.complianceStatus === 'Amber' ? '#d97706' :
                            '#dc2626'
                          }
                        />
                      </div>
                      <p className="text-[10px] text-slate-400 font-mono text-center break-all">
                        {worker.safetyPassportQr}
                      </p>
                      <button 
                        onClick={handleScanPassport}
                        className="mt-4 w-full bg-slate-900 text-white py-2 rounded-lg text-sm font-medium hover:bg-slate-800 transition-colors"
                      >
                        Simulate Scan
                      </button>
                    </div>
                    
                    <div className="p-4 bg-slate-50 border-t border-slate-200 space-y-2">
                      {/* ... existing compliance details ... */}
                      <div className="flex justify-between text-xs">
                        <span className="text-slate-500">Medical (Annexure 3):</span>
                        <span className={medicalRecords.some(m => m.idNumber === worker.idNumber && m.status === 'Fit' && new Date(m.nextDueDate) > new Date()) ? 'text-green-600 font-medium' : 'text-red-600 font-medium'}>
                          {medicalRecords.some(m => m.idNumber === worker.idNumber && m.status === 'Fit' && new Date(m.nextDueDate) > new Date()) ? 'Valid' : 'Expired/Missing'}
                        </span>
                      </div>
                      <div className="flex justify-between text-xs">
                        <span className="text-slate-500">Induction (CR 7(5)):</span>
                        <span className={trainingRecords.some(t => t.idNumber === worker.idNumber && t.courseName.toLowerCase().includes('induction') && t.status === 'Active') ? 'text-green-600 font-medium' : 'text-red-600 font-medium'}>
                          {trainingRecords.some(t => t.idNumber === worker.idNumber && t.courseName.toLowerCase().includes('induction') && t.status === 'Active') ? 'Completed' : 'Pending'}
                        </span>
                      </div>
                      <div className="flex justify-between text-xs">
                        <span className="text-slate-500">ID Document:</span>
                        <span className={documents.some(d => d.workerId === worker.id && d.type === 'ID Document' && d.status === 'Approved') ? 'text-green-600 font-medium' : 'text-red-600 font-medium'}>
                          {documents.some(d => d.workerId === worker.id && d.type === 'ID Document' && d.status === 'Approved') ? 'Approved' : 'Missing'}
                        </span>
                      </div>
                      <div className="flex justify-between text-xs">
                        <span className="text-slate-500">Employer LOGS:</span>
                        <span className={documents.some(d => d.contractorId === worker.contractorId && !d.workerId && d.type === 'Letter of Good Standing' && d.status === 'Approved' && new Date(d.expiryDate) > new Date()) ? 'text-green-600 font-medium' : 'text-red-600 font-medium'}>
                          {documents.some(d => d.contractorId === worker.contractorId && !d.workerId && d.type === 'Letter of Good Standing' && d.status === 'Approved' && new Date(d.expiryDate) > new Date()) ? 'Valid' : 'Expired/Missing'}
                        </span>
                      </div>
                      <div className="flex justify-between text-xs">
                        <span className="text-slate-500">Employer Safety File:</span>
                        <span className={documents.some(d => d.contractorId === worker.contractorId && !d.workerId && d.type === 'Safety File' && d.status === 'Approved') ? 'text-green-600 font-medium' : 'text-red-600 font-medium'}>
                          {documents.some(d => d.contractorId === worker.contractorId && !d.workerId && d.type === 'Safety File' && d.status === 'Approved') ? 'Approved' : 'Missing'}
                        </span>
                      </div>
                      <div className="flex justify-between text-xs">
                        <span className="text-slate-500">Employer Sec 37:</span>
                        <span className={employer?.section37Signed ? 'text-green-600 font-medium' : 'text-red-600 font-medium'}>
                          {employer?.section37Signed ? 'Signed' : 'Missing'}
                        </span>
                      </div>
                      <button 
                        onClick={() => recalculateWorkerCompliance(worker.id)}
                        className="w-full mt-2 py-1.5 text-xs bg-white border border-slate-200 rounded text-slate-600 hover:bg-slate-50 transition-colors flex items-center justify-center gap-1"
                      >
                        <ShieldCheck size={12} /> Re-verify Compliance
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        )}
        {/* Access Logs Tab */}
        {activeTab === 'access' && (
          <div className="p-6">
            <div className="flex justify-between items-center mb-6">
              <div>
                <h2 className="text-lg font-semibold text-slate-900">Mobile Site Access Log</h2>
                <p className="text-sm text-slate-500">Real-time gate access and man-hour tracking.</p>
              </div>
            </div>
            
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 text-sm">
                    <th className="p-4 font-medium">Timestamp</th>
                    <th className="p-4 font-medium">Worker</th>
                    <th className="p-4 font-medium">Contractor</th>
                    <th className="p-4 font-medium">Zone</th>
                    <th className="p-4 font-medium">Direction</th>
                  </tr>
                </thead>
                <tbody>
                  {accessLogs.length === 0 ? (
                    <tr>
                      <td colSpan={5} className="p-8 text-center text-slate-500">
                        No access logs recorded yet.
                      </td>
                    </tr>
                  ) : (
                    accessLogs.map(log => {
                      const worker = workers.find(w => w.id === log.workerId);
                      const contractor = contractors.find(c => c.id === log.contractorId);
                      return (
                        <tr key={log.id} className="border-b border-slate-100 hover:bg-slate-50 transition-colors">
                          <td className="p-4 text-slate-600 text-sm">{new Date(log.timestamp).toLocaleString()}</td>
                          <td className="p-4 font-medium text-slate-900">{worker?.fullName || 'Unknown'}</td>
                          <td className="p-4 text-slate-600">{contractor?.companyName || 'Unknown'}</td>
                          <td className="p-4 text-slate-600">{log.zone}</td>
                          <td className="p-4">
                            <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-bold ${
                              log.type === 'IN' ? 'bg-green-100 text-green-800' : 'bg-slate-100 text-slate-800'
                            }`}>
                              {log.type}
                            </span>
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

        {/* Hierarchy Tab */}
        {activeTab === 'hierarchy' && (
          <div className="p-6">
            <h2 className="text-lg font-semibold text-slate-900 mb-6">Sub-Contractor Tier Mapping</h2>
            <p className="text-slate-600 mb-8">Visual representation of Principal Contractors and their Sub-Contractors.</p>
            
            <div className="space-y-6">
              {contractors.filter(c => c.isPrincipal).map(principal => {
                const subs = contractors.filter(c => c.parentId === principal.id);
                return (
                  <div key={principal.id} className="border border-slate-200 rounded-xl p-6 bg-white">
                    <div className="flex items-center gap-3 mb-4">
                      <div className="bg-blue-100 text-blue-600 p-2 rounded-lg">
                        <Network size={24} />
                      </div>
                      <div>
                        <h3 className="font-bold text-lg text-slate-900">{principal.companyName}</h3>
                        <span className="text-xs font-bold text-blue-600 bg-blue-50 px-2 py-0.5 rounded">Principal Contractor</span>
                      </div>
                    </div>
                    
                    {subs.length > 0 ? (
                      <div className="ml-8 pl-6 border-l-2 border-slate-200 space-y-4">
                        {subs.map(sub => (
                          <div key={sub.id} className="relative">
                            <div className="absolute -left-6 top-1/2 w-6 border-t-2 border-slate-200"></div>
                            <div className="bg-slate-50 border border-slate-200 rounded-lg p-4 flex justify-between items-center">
                              <div>
                                <h4 className="font-semibold text-slate-900">{sub.companyName}</h4>
                                <p className="text-xs text-slate-500">Contact: {sub.contactPerson}</p>
                              </div>
                              <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium border ${getStatusColor(sub.complianceStatus)}`}>
                                {sub.complianceStatus}
                              </span>
                            </div>
                          </div>
                        ))}
                      </div>
                    ) : (
                      <p className="ml-14 text-sm text-slate-500 italic">No sub-contractors registered under this principal.</p>
                    )}
                  </div>
                );
              })}
              {contractors.filter(c => c.isPrincipal).length === 0 && (
                <div className="text-center p-8 text-slate-500 bg-slate-50 rounded-xl border border-slate-200">
                  No Principal Contractors registered.
                </div>
              )}
            </div>
          </div>
        )}
        {/* Competency Matrix Tab */}
        {activeTab === 'competency' && (
          <div className="p-6">
            <div className="flex justify-between items-center mb-6">
              <div>
                <h2 className="text-lg font-semibold text-slate-900">Worker Competency Matrix</h2>
                <p className="text-sm text-slate-500">Real-time view of authorized machinery and high-risk skills.</p>
              </div>
            </div>
            
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 text-sm">
                    <th className="p-4 font-medium sticky left-0 bg-slate-50 z-10">Worker Name</th>
                    <th className="p-4 font-medium">Employer</th>
                    <th className="p-4 font-medium text-center">Working at Heights</th>
                    <th className="p-4 font-medium text-center">Confined Space</th>
                    <th className="p-4 font-medium text-center">Forklift Operator</th>
                    <th className="p-4 font-medium text-center">First Aid</th>
                    <th className="p-4 font-medium text-center">Hot Work</th>
                  </tr>
                </thead>
                <tbody>
                  {workers.length === 0 ? (
                    <tr>
                      <td colSpan={7} className="p-8 text-center text-slate-500">
                        No workers registered.
                      </td>
                    </tr>
                  ) : (
                    workers.map((worker) => {
                      const employer = contractors.find(c => c.id === worker.contractorId);
                      const workerTraining = trainingRecords.filter(t => t.idNumber === worker.idNumber && t.status === 'Active' && new Date(t.expiryDate) > new Date());
                      
                      const hasCompetency = (keyword: string) => {
                        return workerTraining.some(t => t.courseName.toLowerCase().includes(keyword.toLowerCase()));
                      };

                      return (
                        <tr key={worker.id} className="border-b border-slate-100 hover:bg-slate-50 transition-colors">
                          <td className="p-4 font-medium text-slate-900 sticky left-0 bg-white z-10">{worker.fullName}</td>
                          <td className="p-4 text-slate-600">{employer?.companyName || 'Unknown'}</td>
                          <td className="p-4 text-center">
                            {hasCompetency('height') ? <CheckCircle size={20} className="text-green-500 mx-auto" /> : <span className="text-slate-300">-</span>}
                          </td>
                          <td className="p-4 text-center">
                            {hasCompetency('confined') ? <CheckCircle size={20} className="text-green-500 mx-auto" /> : <span className="text-slate-300">-</span>}
                          </td>
                          <td className="p-4 text-center">
                            {hasCompetency('forklift') ? <CheckCircle size={20} className="text-green-500 mx-auto" /> : <span className="text-slate-300">-</span>}
                          </td>
                          <td className="p-4 text-center">
                            {hasCompetency('first aid') ? <CheckCircle size={20} className="text-green-500 mx-auto" /> : <span className="text-slate-300">-</span>}
                          </td>
                          <td className="p-4 text-center">
                            {hasCompetency('hot work') || hasCompetency('welding') ? <CheckCircle size={20} className="text-green-500 mx-auto" /> : <span className="text-slate-300">-</span>}
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
        {/* Toolbox Talks Tab */}
        {activeTab === 'toolbox' && (
          <div className="p-6">
            <div className="flex justify-between items-center mb-6">
              <div>
                <h2 className="text-lg font-semibold text-slate-900">Toolbox Talks & Briefings</h2>
                <p className="text-sm text-slate-500">Manage daily safety briefings and track attendance via QR.</p>
              </div>
              <button 
                onClick={() => alert("QR Code generated for today's Toolbox Talk. Workers can scan to log attendance.")}
                className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
              >
                <QrCode size={20} />
                Generate Today's QR
              </button>
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <div className="md:col-span-2 space-y-4">
                <div className="bg-white border border-slate-200 rounded-xl p-6">
                  <h3 className="font-bold text-slate-900 mb-4">Recent Toolbox Talks</h3>
                  <div className="space-y-4">
                    {[
                      { topic: 'Working at Heights - Harness Inspection', date: 'Today, 07:00 AM', attendees: 45, total: 50 },
                      { topic: 'Heat Stress Management', date: 'Yesterday, 07:00 AM', attendees: 48, total: 50 },
                      { topic: 'Safe Lifting Techniques', date: 'Mon, 07:00 AM', attendees: 49, total: 50 },
                    ].map((talk, i) => (
                      <div key={i} className="flex items-center justify-between p-4 bg-slate-50 rounded-lg border border-slate-100">
                        <div>
                          <h4 className="font-medium text-slate-900">{talk.topic}</h4>
                          <p className="text-sm text-slate-500 flex items-center gap-1 mt-1">
                            <Clock size={14} /> {talk.date}
                          </p>
                        </div>
                        <div className="text-right">
                          <span className="text-sm font-medium text-slate-900">{talk.attendees} / {talk.total}</span>
                          <p className="text-xs text-slate-500">Attended</p>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
              <div className="space-y-4">
                <div className="bg-blue-50 border border-blue-100 rounded-xl p-6">
                  <h3 className="font-bold text-blue-900 mb-2">Today's Attendance</h3>
                  <div className="text-4xl font-bold text-blue-600 mb-1">90%</div>
                  <p className="text-sm text-blue-700">45 of 50 workers on site attended the morning briefing.</p>
                </div>
                <div className="bg-amber-50 border border-amber-100 rounded-xl p-6">
                  <h3 className="font-bold text-amber-900 mb-2">Missing Attendance</h3>
                  <ul className="space-y-2 text-sm text-amber-800">
                    <li className="flex justify-between"><span>John Doe</span> <span>Electrician</span></li>
                    <li className="flex justify-between"><span>Jane Smith</span> <span>Welder</span></li>
                    <li className="flex justify-between"><span>Mike Johnson</span> <span>Laborer</span></li>
                  </ul>
                  <button className="mt-4 w-full py-2 bg-amber-100 text-amber-800 rounded-lg font-medium text-sm hover:bg-amber-200 transition-colors">
                    Send Reminder
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Scorecards Tab */}
        {activeTab === 'scorecards' && (
          <div className="p-6">
            <div className="flex justify-between items-center mb-6">
              <div>
                <h2 className="text-lg font-semibold text-slate-900">Contractor Performance Scorecards</h2>
                <p className="text-sm text-slate-500">Monthly safety ratings based on compliance, incidents, and NCRs.</p>
              </div>
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {contractors.map(contractor => {
                // Simulated Score Calculation
                let score = 100;
                if (contractor.complianceStatus === 'Amber') score -= 15;
                if (contractor.complianceStatus === 'Red') score -= 30;
                if (!contractor.section37Signed) score -= 10;
                
                let scoreColor = 'text-green-600';
                let scoreBg = 'bg-green-50 border-green-200';
                if (score < 80) { scoreColor = 'text-amber-600'; scoreBg = 'bg-amber-50 border-amber-200'; }
                if (score < 60) { scoreColor = 'text-red-600'; scoreBg = 'bg-red-50 border-red-200'; }

                return (
                  <div key={contractor.id} className={`border rounded-xl p-6 ${scoreBg}`}>
                    <div className="flex justify-between items-start mb-4">
                      <div>
                        <h3 className="font-bold text-slate-900">{contractor.companyName}</h3>
                        <p className="text-sm text-slate-600">{contractor.scopeOfWork || 'General'}</p>
                      </div>
                      <div className={`text-2xl font-bold ${scoreColor}`}>
                        {score}%
                      </div>
                    </div>
                    <div className="space-y-3 text-sm">
                      <div className="flex justify-between items-center">
                        <span className="text-slate-600">Compliance Status</span>
                        <span className={`font-medium ${getStatusColor(contractor.complianceStatus)} px-2 py-0.5 rounded-full text-xs border`}>
                          {contractor.complianceStatus}
                        </span>
                      </div>
                      <div className="flex justify-between items-center">
                        <span className="text-slate-600">Active NCRs</span>
                        <span className="font-medium text-slate-900">0</span>
                      </div>
                      <div className="flex justify-between items-center">
                        <span className="text-slate-600">Incidents (YTD)</span>
                        <span className="font-medium text-slate-900">0</span>
                      </div>
                    </div>
                    <button className="mt-6 w-full py-2 bg-white border border-slate-200 text-slate-700 rounded-lg hover:bg-slate-50 transition-colors text-sm font-medium">
                      View Detailed Report
                    </button>
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {/* PPE Tracking Tab */}
        {activeTab === 'ppe' && (
          <div className="p-6">
            <div className="flex justify-between items-center mb-6">
              <div>
                <h2 className="text-lg font-semibold text-slate-900">PPE Issue Tracking</h2>
                <p className="text-sm text-slate-500">Track Personal Protective Equipment issued to workers.</p>
              </div>
            </div>
            
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 text-sm">
                    <th className="p-4 font-medium sticky left-0 bg-slate-50 z-10">Worker Name</th>
                    <th className="p-4 font-medium">Employer</th>
                    <th className="p-4 font-medium text-center">Hard Hat</th>
                    <th className="p-4 font-medium text-center">Safety Boots</th>
                    <th className="p-4 font-medium text-center">Hi-Vis Vest</th>
                    <th className="p-4 font-medium text-center">Gloves</th>
                    <th className="p-4 font-medium text-center">Safety Glasses</th>
                  </tr>
                </thead>
                <tbody>
                  {workers.length === 0 ? (
                    <tr>
                      <td colSpan={7} className="p-8 text-center text-slate-500">
                        No workers registered.
                      </td>
                    </tr>
                  ) : (
                    workers.map((worker) => {
                      const employer = contractors.find(c => c.id === worker.contractorId);
                      // Simulated PPE state (all true for demo, in reality would be fetched from DB)
                      return (
                        <tr key={worker.id} className="border-b border-slate-100 hover:bg-slate-50 transition-colors">
                          <td className="p-4 font-medium text-slate-900 sticky left-0 bg-white z-10">{worker.fullName}</td>
                          <td className="p-4 text-slate-600">{employer?.companyName || 'Unknown'}</td>
                          <td className="p-4 text-center"><input type="checkbox" defaultChecked className="w-4 h-4 text-blue-600 rounded border-slate-300 focus:ring-blue-500" /></td>
                          <td className="p-4 text-center"><input type="checkbox" defaultChecked className="w-4 h-4 text-blue-600 rounded border-slate-300 focus:ring-blue-500" /></td>
                          <td className="p-4 text-center"><input type="checkbox" defaultChecked className="w-4 h-4 text-blue-600 rounded border-slate-300 focus:ring-blue-500" /></td>
                          <td className="p-4 text-center"><input type="checkbox" defaultChecked className="w-4 h-4 text-blue-600 rounded border-slate-300 focus:ring-blue-500" /></td>
                          <td className="p-4 text-center"><input type="checkbox" defaultChecked className="w-4 h-4 text-blue-600 rounded border-slate-300 focus:ring-blue-500" /></td>
                        </tr>
                      );
                    })
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>

      {/* Add Contractor Modal */}
      {isAddingContractor && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex justify-between items-center">
              <h2 className="text-xl font-bold text-slate-900">Register Contractor</h2>
              <button onClick={() => setIsAddingContractor(false)} className="text-slate-400 hover:text-slate-600">
                <XCircle size={24} />
              </button>
            </div>
            <form onSubmit={handleAddContractor} className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Company Name</label>
                <input 
                  type="text" 
                  required
                  value={companyName}
                  onChange={(e) => setCompanyName(e.target.value)}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Contact Person</label>
                <input 
                  type="text" 
                  required
                  value={contactPerson}
                  onChange={(e) => setContactPerson(e.target.value)}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Contact Email</label>
                <input 
                  type="email" 
                  required
                  value={contactEmail}
                  onChange={(e) => setContactEmail(e.target.value)}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
              <div className="flex items-center gap-2 py-2">
                <input 
                  type="checkbox" 
                  id="isPrincipal"
                  checked={isPrincipal}
                  onChange={(e) => setIsPrincipal(e.target.checked)}
                  className="w-4 h-4 text-blue-600 rounded border-slate-300 focus:ring-blue-500"
                />
                <label htmlFor="isPrincipal" className="text-sm font-medium text-slate-700">
                  Principal Contractor (CR 7(1))
                </label>
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Scope of Work</label>
                <select 
                  value={contractorScope}
                  onChange={(e) => setContractorScope(e.target.value)}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                >
                  <option value="General">General / Administrative</option>
                  <option value="Electrical">Electrical</option>
                  <option value="Civil">Civil / Earthworks</option>
                  <option value="Working at Heights">Working at Heights</option>
                  <option value="Hot Work">Hot Work / Welding</option>
                  <option value="Lifting Operations">Lifting Operations</option>
                </select>
                <p className="text-xs text-slate-500 mt-1">AI will auto-generate required safety file templates based on this scope.</p>
              </div>
              {!isPrincipal && (
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Parent Contractor (Principal)</label>
                  <select 
                    value={parentId}
                    onChange={(e) => setParentId(e.target.value)}
                    className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  >
                    <option value="">-- Select Principal --</option>
                    {contractors.filter(c => c.isPrincipal).map(c => (
                      <option key={c.id} value={c.id}>{c.companyName}</option>
                    ))}
                  </select>
                </div>
              )}
              <div className="pt-4 flex justify-end gap-3">
                <button 
                  type="button"
                  onClick={() => setIsAddingContractor(false)}
                  className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
                >
                  Cancel
                </button>
                <button 
                  type="submit"
                  className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                >
                  Register
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Upload Document Modal */}
      {isUploadingDoc && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex justify-between items-center">
              <h2 className="text-xl font-bold text-slate-900">Upload Document</h2>
              <button onClick={() => setIsUploadingDoc(false)} className="text-slate-400 hover:text-slate-600">
                <XCircle size={24} />
              </button>
            </div>
            <form onSubmit={handleUploadDocument} className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Select Contractor</label>
                <select 
                  required
                  value={selectedContractorId}
                  onChange={(e) => {
                    setSelectedContractorId(e.target.value);
                    setSelectedWorkerId(''); // Reset worker when contractor changes
                  }}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                >
                  <option value="">-- Select Contractor --</option>
                  {contractors.map(c => (
                    <option key={c.id} value={c.id}>{c.companyName}</option>
                  ))}
                </select>
              </div>
              
              {selectedContractorId && (
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Select Worker (Optional)</label>
                  <select 
                    value={selectedWorkerId}
                    onChange={(e) => setSelectedWorkerId(e.target.value)}
                    className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  >
                    <option value="">-- Company Level Document --</option>
                    {workers.filter(w => w.contractorId === selectedContractorId).map(w => (
                      <option key={w.id} value={w.id}>{w.fullName}</option>
                    ))}
                  </select>
                </div>
              )}

              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Document Type</label>
                <select 
                  required
                  value={docType}
                  onChange={(e) => setDocType(e.target.value as any)}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                >
                  <optgroup label="Core Compliance">
                    <option value="Letter of Good Standing">Letter of Good Standing</option>
                    <option value="Public Liability Insurance">Public Liability Insurance</option>
                    <option value="Insurance Certificate">Insurance Certificate</option>
                    <option value="Trade Certificate">Trade Certificate</option>
                  </optgroup>
                  <optgroup label="Safety File (Digital)">
                    <option value="Safety File Index">Safety File Index</option>
                    <option value="Method Statement">Method Statement</option>
                    <option value="Risk Assessment">Risk Assessment</option>
                    <option value="Appointment Letter">Appointment Letter</option>
                    <option value="Statutory Appointment">Statutory Appointment (CR 8)</option>
                    <option value="Safety File">Full Safety File (Legacy)</option>
                  </optgroup>
                  <optgroup label="Worker Specific">
                    <option value="Medical Certificate">Medical Certificate</option>
                    <option value="ID Document">ID Document</option>
                  </optgroup>
                  <option value="Other">Other</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Expiry Date</label>
                <input 
                  type="date" 
                  required
                  value={docExpiry}
                  onChange={(e) => setDocExpiry(e.target.value)}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">File (AI Auditor)</label>
                <div className="relative border-2 border-dashed border-slate-300 rounded-lg p-6 text-center hover:bg-slate-50 transition-colors cursor-pointer overflow-hidden">
                  <input 
                    type="file" 
                    accept="image/*,application/pdf" 
                    onChange={handleDocumentFileChange}
                    className="absolute inset-0 w-full h-full opacity-0 cursor-pointer z-20"
                  />
                  {isAnalyzingDocument ? (
                    <div className="flex flex-col items-center justify-center text-blue-600">
                      <RefreshCw className="animate-spin mb-2" size={24} />
                      <p className="text-sm font-bold">AI Auditor Scanning Document...</p>
                    </div>
                  ) : documentFile ? (
                    <div className="flex flex-col items-center justify-center text-green-600">
                      <CheckCircle className="mb-2" size={24} />
                      <p className="text-sm font-bold">{documentFile.name}</p>
                    </div>
                  ) : (
                    <>
                      <Upload className="mx-auto text-slate-400 mb-2" size={24} />
                      <p className="text-sm text-slate-600">Click to browse or drag and drop</p>
                      <p className="text-xs text-slate-400 mt-1">PDF, JPG, PNG up to 10MB</p>
                    </>
                  )}
                </div>
                {aiAnalysisResult && (
                  <div className={`mt-2 p-3 rounded-lg text-sm border ${aiAnalysisResult.includes('Verified') ? 'bg-green-50 border-green-200 text-green-800' : 'bg-amber-50 border-amber-200 text-amber-800'}`}>
                    <div className="flex items-start gap-2">
                      <ShieldCheck size={16} className="mt-0.5 flex-shrink-0" />
                      <p>{aiAnalysisResult}</p>
                    </div>
                  </div>
                )}
              </div>
              <div className="pt-4 flex justify-end gap-3">
                <button 
                  type="button"
                  onClick={() => setIsUploadingDoc(false)}
                  className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
                >
                  Cancel
                </button>
                <button 
                  type="submit"
                  className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                >
                  Upload
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Add Worker Modal */}
      {isAddingWorker && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex justify-between items-center">
              <h2 className="text-xl font-bold text-slate-900">Add Contractor Worker</h2>
              <button onClick={() => setIsAddingWorker(false)} className="text-slate-400 hover:text-slate-600">
                <XCircle size={24} />
              </button>
            </div>
            <form onSubmit={handleAddWorker} className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Employer (Contractor)</label>
                <select 
                  required
                  value={selectedContractorId}
                  onChange={(e) => setSelectedContractorId(e.target.value)}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                >
                  <option value="">-- Select Employer --</option>
                  {contractors.map(c => (
                    <option key={c.id} value={c.id}>{c.companyName}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Full Name</label>
                <input 
                  type="text" 
                  required
                  value={workerName}
                  onChange={(e) => setWorkerName(e.target.value)}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">ID / Passport Number</label>
                <input 
                  type="text" 
                  required
                  value={workerIdNumber}
                  onChange={(e) => setWorkerIdNumber(e.target.value)}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent font-mono"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Job Title</label>
                <input 
                  type="text" 
                  value={workerJobTitle}
                  onChange={(e) => setWorkerJobTitle(e.target.value)}
                  placeholder="e.g., Electrician, Welder"
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
              <div className="pt-4 flex justify-end gap-3">
                <button 
                  type="button"
                  onClick={() => setIsAddingWorker(false)}
                  className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
                >
                  Cancel
                </button>
                <button 
                  type="submit"
                  className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                >
                  Add Worker
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* AI Risk Profile Modal */}
      {selectedContractorRiskProfile && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-2xl overflow-hidden flex flex-col max-h-[90vh]">
            <div className="p-6 border-b border-slate-100 flex justify-between items-center bg-indigo-50">
              <div className="flex items-center gap-3">
                <div className="bg-indigo-100 text-indigo-600 p-2 rounded-lg">
                  <BrainCircuit size={24} />
                </div>
                <div>
                  <h2 className="text-xl font-bold text-indigo-900">AI Risk Profile</h2>
                  <p className="text-sm text-indigo-700">
                    {contractors.find(c => c.id === selectedContractorRiskProfile.contractorId)?.companyName}
                  </p>
                </div>
              </div>
              <button onClick={() => setSelectedContractorRiskProfile(null)} className="text-indigo-400 hover:text-indigo-600">
                <XCircle size={24} />
              </button>
            </div>
            <div className="p-6 overflow-y-auto">
              <div className="prose prose-indigo max-w-none">
                {selectedContractorRiskProfile.profile.split('\n').map((line, i) => (
                  <p key={i} className="mb-2 text-slate-700">{line}</p>
                ))}
              </div>
            </div>
            <div className="p-6 border-t border-slate-100 bg-slate-50 flex justify-end">
              <button 
                onClick={() => setSelectedContractorRiskProfile(null)}
                className="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors"
              >
                Close Profile
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Generating Risk Profile Overlay */}
      {isGeneratingRiskProfile && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-xl p-8 flex flex-col items-center max-w-sm text-center">
            <RefreshCw className="animate-spin text-indigo-600 mb-4" size={48} />
            <h3 className="text-lg font-bold text-slate-900 mb-2">Analyzing Contractor Data</h3>
            <p className="text-sm text-slate-500">Gemini AI is generating a comprehensive risk profile based on compliance history, scope of work, and worker data...</p>
          </div>
        </div>
      )}

      {/* Issue NCR Modal */}
      {isIssuingNCR && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex justify-between items-center bg-red-50">
              <div className="flex items-center gap-3">
                <div className="bg-red-100 text-red-600 p-2 rounded-lg">
                  <FileWarning size={24} />
                </div>
                <div>
                  <h2 className="text-xl font-bold text-red-900">Issue Non-Conformance</h2>
                  <p className="text-sm text-red-700">
                    {contractors.find(c => c.id === selectedContractorForNCR)?.companyName}
                  </p>
                </div>
              </div>
              <button onClick={() => setIsIssuingNCR(false)} className="text-red-400 hover:text-red-600">
                <XCircle size={24} />
              </button>
            </div>
            <form onSubmit={(e) => {
              e.preventDefault();
              alert(`NCR Issued to ${contractors.find(c => c.id === selectedContractorForNCR)?.companyName}. Notification sent via email.`);
              setIsIssuingNCR(false);
              setNcrDescription('');
            }} className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Severity</label>
                <select 
                  value={ncrSeverity}
                  onChange={(e) => setNcrSeverity(e.target.value)}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                >
                  <option value="Minor">Minor (Warning)</option>
                  <option value="Major">Major (Requires Immediate Action)</option>
                  <option value="Critical">Critical (Stop Work Order)</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Description of Non-Conformance</label>
                <textarea 
                  required
                  rows={4}
                  value={ncrDescription}
                  onChange={(e) => setNcrDescription(e.target.value)}
                  placeholder="Describe the safety violation or non-conformance..."
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Attach Photo Evidence</label>
                <input type="file" accept="image/*" className="w-full text-sm text-slate-500 file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-sm file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100" />
              </div>
              <div className="pt-4 flex justify-end gap-3">
                <button 
                  type="button"
                  onClick={() => setIsIssuingNCR(false)}
                  className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
                >
                  Cancel
                </button>
                <button 
                  type="submit"
                  className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
                >
                  Issue NCR
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Onboarding Wizard Modal (Simulated) */}
      {isOnboarding && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-3xl overflow-hidden flex flex-col h-[80vh]">
            <div className="p-6 border-b border-slate-100 flex justify-between items-center bg-indigo-600 text-white">
              <div className="flex items-center gap-3">
                <Megaphone size={24} />
                <div>
                  <h2 className="text-xl font-bold">Contractor Self-Registration Portal</h2>
                  <p className="text-sm text-indigo-200">Simulated external view for contractors</p>
                </div>
              </div>
              <button onClick={() => setIsOnboarding(false)} className="text-indigo-200 hover:text-white">
                <XCircle size={24} />
              </button>
            </div>
            <div className="flex-1 overflow-y-auto p-8 bg-slate-50">
              <div className="max-w-xl mx-auto space-y-8">
                <div className="text-center">
                  <h3 className="text-2xl font-bold text-slate-900 mb-2">Welcome to the Safety Portal</h3>
                  <p className="text-slate-600">Please complete your company profile and upload required safety documents to begin the onboarding process.</p>
                </div>
                
                <div className="bg-white p-6 rounded-xl shadow-sm border border-slate-200 space-y-4">
                  <h4 className="font-bold text-slate-900 border-b pb-2">Step 1: Company Details</h4>
                  <input type="text" placeholder="Company Name" className="w-full p-2.5 border border-slate-300 rounded-lg" />
                  <input type="email" placeholder="Contact Email" className="w-full p-2.5 border border-slate-300 rounded-lg" />
                  <select className="w-full p-2.5 border border-slate-300 rounded-lg">
                    <option>Select Scope of Work...</option>
                    <option>Electrical</option>
                    <option>Civil / Earthworks</option>
                  </select>
                </div>
                
                <div className="bg-white p-6 rounded-xl shadow-sm border border-slate-200 space-y-4 opacity-50 pointer-events-none">
                  <h4 className="font-bold text-slate-900 border-b pb-2">Step 2: Required Documents</h4>
                  <p className="text-sm text-slate-500">Complete Step 1 to unlock document uploads.</p>
                </div>
              </div>
            </div>
            <div className="p-6 border-t border-slate-100 bg-white flex justify-between items-center">
              <button 
                onClick={() => setIsOnboarding(false)}
                className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
              >
                Exit Simulation
              </button>
              <button 
                onClick={() => {
                  alert("Registration submitted! The SHEQ Manager will review your application.");
                  setIsOnboarding(false);
                }}
                className="px-6 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors font-medium"
              >
                Submit Registration
              </button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
}
