import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy, doc, updateDoc, where, limit } from 'firebase/firestore';
import { db, auth, handleFirestoreError } from '../lib/firebase';
import { getGeminiClient } from '../lib/gemini';
import { useAuth } from '../contexts/AuthContext';
import { 
  Box,
  Typography,
  Button,
  Grid,
  Card,
  CardContent,
  Chip,
  Tabs,
  Tab,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  IconButton,
  TextField,
  Select,
  MenuItem,
  FormControlLabel,
  Checkbox,
  LinearProgress,
  Avatar,
  CircularProgress
} from '@mui/material';

import FileSignatureIcon from '@mui/icons-material/Assignment';
import LockIcon from '@mui/icons-material/Lock';
import ClockIcon from '@mui/icons-material/AccessTime';
import MapPinIcon from '@mui/icons-material/LocationOn';
import PlusIcon from '@mui/icons-material/Add';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import XCircleIcon from '@mui/icons-material/Cancel';
import AlertTriangleIcon from '@mui/icons-material/Warning';
import ShieldAlertIcon from '@mui/icons-material/Security';
import PlayCircleIcon from '@mui/icons-material/PlayCircleOutline';
import StopCircleIcon from '@mui/icons-material/StopCircle';
import BrainIcon from '@mui/icons-material/Psychology';
import QrCodeIcon from '@mui/icons-material/QrCode';
import CameraIcon from '@mui/icons-material/CameraAlt';
import ImageIcon from '@mui/icons-material/Image';
import ShieldCheckIcon from '@mui/icons-material/VerifiedUser';
import SparklesIcon from '@mui/icons-material/AutoAwesome';
import ZapIcon from '@mui/icons-material/Bolt';

interface PermitToWork {
  id: string;
  type: 'Hot Work' | 'Working at Heights' | 'Confined Space' | 'Electrical' | 'Excavation' | 'Other';
  location: string;
  assetId?: string;
  status: 'Requested' | 'Approved' | 'Active' | 'Suspended' | 'Closed';
  validFrom: string;
  validTo: string;
  applicantId: string;
  applicantName: string;
  approverId?: string;
  lotoRequired: boolean;
  createdAt: string;
  contractorId?: string;
  contractorName?: string;
  workerIds?: string[];
}

interface Contractor {
  id: string;
  companyName: string;
  complianceStatus: 'Green' | 'Amber' | 'Red';
}

interface Worker {
  id: string;
  fullName: string;
  idNumber: string;
  complianceStatus: 'Green' | 'Amber' | 'Red';
  contractorId: string;
}

interface LOTO {
  id: string;
  permitId: string;
  assetId?: string;
  equipmentName: string;
  isolationPoints: string[];
  appliedById: string;
  appliedByName: string;
  appliedAt: string;
  removedById?: string;
  removedAt?: string;
  status: 'Active' | 'Removed';
  photoEvidence?: string;
}

export default function PermitToWorkModule() {
  const { profile } = useAuth();
  const [activeTab, setActiveTab] = useState<'permits' | 'loto'>('permits');
  const [permits, setPermits] = useState<PermitToWork[]>([]);
  const [lotoRecords, setLotoRecords] = useState<LOTO[]>([]);
  const [contractors, setContractors] = useState<Contractor[]>([]);
  const [workers, setWorkers] = useState<Worker[]>([]);
  
  const [isRequestingPermit, setIsRequestingPermit] = useState(false);
  const [isApplyingLOTO, setIsApplyingLOTO] = useState(false);
  const [selectedPermitId, setSelectedPermitId] = useState<string>('');

  // Permit Form
  const [permitType, setPermitType] = useState<PermitToWork['type']>('Hot Work');
  const [location, setLocation] = useState('');
  const [validFrom, setValidFrom] = useState('');
  const [validTo, setValidTo] = useState('');
  const [lotoRequired, setLotoRequired] = useState(false);
  const [selectedContractorId, setSelectedContractorId] = useState('');
  const [selectedWorkerIds, setSelectedWorkerIds] = useState<string[]>([]);

  // LOTO Form
  const [equipmentName, setEquipmentName] = useState('');
  const [isolationPoints, setIsolationPoints] = useState(''); // Comma separated

  // AI Risk State
  const [isAnalyzingRisk, setIsAnalyzingRisk] = useState(false);
  const [riskProfile, setRiskProfile] = useState<{
    riskLevel: 'Low' | 'Medium' | 'High' | 'Critical';
    clashDetected: boolean;
    clashDetails: string;
    requiredPrecautions: string[];
  } | null>(null);

  // LOTO Enhancements State
  const [lotoQrVerified, setLotoQrVerified] = useState(false);
  const [lotoPhoto, setLotoPhoto] = useState<string | null>(null);

  // AI Drafting State
  const [aiPrompt, setAiPrompt] = useState('');
  const [isDrafting, setIsDrafting] = useState(false);

  // Predictive LOTO State
  const [isPredicting, setIsPredicting] = useState(false);
  const [predictiveAlerts, setPredictiveAlerts] = useState<{equipment: string, riskScore: number, reason: string}[]>([]);

  useEffect(() => {
    if (!profile?.siteId) return;

    const qPermits = query(collection(db, 'permits'), where('siteId', '==', profile.siteId), orderBy('createdAt', 'desc'), limit(100));
    const unsubscribePermits = onSnapshot(qPermits, (snapshot) => {
      const permitData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as PermitToWork[];
      setPermits(permitData);
    }, (error) => {
      handleFirestoreError(error, 'list' as any, 'permits');
    });

    const qLoto = query(collection(db, 'loto_records'), where('siteId', '==', profile.siteId), orderBy('appliedAt', 'desc'), limit(100));
    const unsubscribeLoto = onSnapshot(qLoto, (snapshot) => {
      const lotoData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as LOTO[];
      setLotoRecords(lotoData);
    }, (error) => {
      handleFirestoreError(error, 'list' as any, 'loto_records');
    });

    const qContractors = query(collection(db, 'contractors'), where('siteId', '==', profile.siteId));
    const unsubscribeContractors = onSnapshot(qContractors, (snapshot) => {
      const contractorData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as Contractor[];
      setContractors(contractorData);
    });

    const qWorkers = query(collection(db, 'contractor_workers'), where('siteId', '==', profile.siteId));
    const unsubscribeWorkers = onSnapshot(qWorkers, (snapshot) => {
      const workerData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as Worker[];
      setWorkers(workerData);
    });

    return () => {
      unsubscribePermits();
      unsubscribeLoto();
      unsubscribeContractors();
      unsubscribeWorkers();
    };
  }, [profile?.siteId]);

  const handleRequestPermit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;

    // Compliance Check
    if (selectedContractorId) {
      const contractor = contractors.find(c => c.id === selectedContractorId);
      if (contractor && contractor.complianceStatus !== 'Green') {
        alert(`Cannot request permit: Contractor ${contractor.companyName} is not compliant (Status: ${contractor.complianceStatus}).`);
        return;
      }

      const nonCompliantWorkers = workers.filter(w => 
        selectedWorkerIds.includes(w.id) && w.complianceStatus !== 'Green'
      );

      if (nonCompliantWorkers.length > 0) {
        alert(`Cannot request permit: The following workers are not compliant: ${nonCompliantWorkers.map(w => w.fullName).join(', ')}.`);
        return;
      }
    }

    try {
      const contractor = contractors.find(c => c.id === selectedContractorId);
      const newPermit = {
        type: permitType,
        location,
        status: 'Requested',
        validFrom: new Date(validFrom).toISOString(),
        validTo: new Date(validTo).toISOString(),
        applicantId: auth.currentUser.uid,
        applicantName: auth.currentUser.displayName || 'Unknown User',
        lotoRequired,
        createdAt: new Date().toISOString(),
        contractorId: selectedContractorId || null,
        contractorName: contractor?.companyName || null,
        workerIds: selectedWorkerIds
      };

      await addDoc(collection(db, 'permits'), newPermit);
      setIsRequestingPermit(false);
      setLocation('');
      setValidFrom('');
      setValidTo('');
      setLotoRequired(false);
      setSelectedContractorId('');
      setSelectedWorkerIds([]);
      setRiskProfile(null);
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'permits');
    }
  };

  const fileToBase64 = (file: File): Promise<string> => {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.readAsDataURL(file);
      reader.onload = () => resolve(reader.result as string);
      reader.onerror = error => reject(error);
    });
  };

  const handleLotoPhotoUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    try {
      const base64 = await fileToBase64(file);
      setLotoPhoto(base64);
    } catch (error) {
      console.error("Photo upload error:", error);
    }
  };

  const handleApplyLOTO = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser || !selectedPermitId) return;

    if (!lotoQrVerified) {
      alert("You must verify presence by scanning the equipment QR code.");
      return;
    }
    if (!lotoPhoto) {
      alert("Visual evidence of zero-energy state is required.");
      return;
    }

    try {
      const pointsArray = isolationPoints.split(',').map(p => p.trim()).filter(p => p);
      
      const newLoto = {
        permitId: selectedPermitId,
        equipmentName,
        isolationPoints: pointsArray,
        appliedById: auth.currentUser.uid,
        appliedByName: auth.currentUser.displayName || 'Unknown User',
        appliedAt: new Date().toISOString(),
        status: 'Active',
        photoEvidence: lotoPhoto
      };

      await addDoc(collection(db, 'loto_records'), newLoto);
      setIsApplyingLOTO(false);
      setEquipmentName('');
      setIsolationPoints('');
      setLotoQrVerified(false);
      setLotoPhoto(null);
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'loto_records');
    }
  };

  const updatePermitStatus = async (permitId: string, newStatus: PermitToWork['status']) => {
    if (!auth.currentUser) return;
    
    const permit = permits.find(p => p.id === permitId);
    if (!permit) return;

    // Re-verify compliance on Approval or Start Work
    if (newStatus === 'Approved' || newStatus === 'Active') {
      if (permit.contractorId) {
        const contractor = contractors.find(c => c.id === permit.contractorId);
        if (contractor && contractor.complianceStatus !== 'Green') {
          alert(`Cannot ${newStatus.toLowerCase()} permit: Contractor ${contractor.companyName} is no longer compliant.`);
          return;
        }

        const nonCompliantWorkers = workers.filter(w => 
          permit.workerIds?.includes(w.id) && w.complianceStatus !== 'Green'
        );

        if (nonCompliantWorkers.length > 0) {
          alert(`Cannot ${newStatus.toLowerCase()} permit: Some workers are no longer compliant.`);
          return;
        }
      }
    }

    try {
      const permitRef = doc(db, 'permits', permitId);
      const updates: any = { status: newStatus };
      
      if (newStatus === 'Approved') {
        updates.approverId = auth.currentUser.uid;
        // Simulate geofencing check
        if (!window.confirm("Geofence Check: Are you physically at the asset location to approve this permit?")) {
          return;
        }
      }
      
      await updateDoc(permitRef, updates);
    } catch (error) {
      handleFirestoreError(error, 'update' as any, `permits/${permitId}`);
    }
  };

  const removeLOTO = async (lotoId: string) => {
    if (!auth.currentUser) return;
    try {
      const lotoRef = doc(db, 'loto_records', lotoId);
      await updateDoc(lotoRef, {
        status: 'Removed',
        removedById: auth.currentUser.uid,
        removedAt: new Date().toISOString()
      });
    } catch (error) {
      handleFirestoreError(error, 'update' as any, `loto_records/${lotoId}`);
    }
  };

  const handleAnalyzeRisk = async () => {
    setIsAnalyzingRisk(true);
    setRiskProfile(null);
    try {
      const activePermitsContext = permits
        .filter(p => p.status === 'Active' || p.status === 'Approved')
        .map(p => `- ${p.type} at ${p.location} (Valid until ${new Date(p.validTo).toLocaleString()})`)
        .join('\n');

      const prompt = `You are an expert HSE Manager and AI Risk Profiler.
Analyze the following Permit to Work request for potential risks and clashes with existing active permits.

Requested Permit:
- Type: ${permitType}
- Location: ${location}
- Valid From: ${validFrom}
- Valid To: ${validTo}
- LOTO Required: ${lotoRequired}

Dynamic Environmental & Operational Factors:
- Current Weather: High Wind (35 km/h), Temp: 38°C
- Simultaneous Operations (SIMOPS) in zone: 3 active teams
- Asset Health: Maintenance overdue on adjacent pipeline

Currently Active Permits in Facility:
${activePermitsContext || 'None'}

Provide a risk assessment in JSON format:
- "riskLevel": "Low", "Medium", "High", or "Critical"
- "clashDetected": boolean (true if the requested permit location/time conflicts dangerously with active permits or environmental factors)
- "clashDetails": string explaining the clash if detected, or "No clashes detected."
- "requiredPrecautions": array of strings listing 3-5 specific safety precautions required for this work, considering the dynamic factors.`;

      const ai = getGeminiClient();
      const response = await ai.models.generateContent({
        model: 'gemini-3.1-pro-preview',
        contents: prompt,
        config: { responseMimeType: "application/json" }
      });

      const profile = JSON.parse(response.text || '{}');
      setRiskProfile(profile);
    } catch (error) {
      console.error("Risk analysis error:", error);
      alert("Failed to analyze risk.");
    }
    setIsAnalyzingRisk(false);
  };

  const handleDraftPermit = async () => {
    if (!aiPrompt) return;
    setIsDrafting(true);
    try {
      const prompt = `You are an AI assistant for a Permit to Work system.
Parse the following user request and extract the permit details.
User Request: "${aiPrompt}"

Return a JSON object with:
- "type": one of 'Hot Work', 'Working at Heights', 'Confined Space', 'Electrical', 'Excavation', 'Other'
- "location": string (extracted location)
- "validFrom": ISO date string (guess based on request, assume current date/time if not specified, e.g. ${new Date().toISOString()})
- "validTo": ISO date string (guess based on request, default to 8 hours after validFrom)
- "lotoRequired": boolean (true if electrical, mechanical, or isolation is mentioned)
`;

      const ai = getGeminiClient();
      const response = await ai.models.generateContent({
        model: 'gemini-3.1-pro-preview',
        contents: prompt,
        config: { responseMimeType: "application/json" }
      });

      const draft = JSON.parse(response.text || '{}');
      if (draft.type) setPermitType(draft.type);
      if (draft.location) setLocation(draft.location);
      if (draft.validFrom) setValidFrom(draft.validFrom.slice(0, 16));
      if (draft.validTo) setValidTo(draft.validTo.slice(0, 16));
      if (draft.lotoRequired !== undefined) setLotoRequired(draft.lotoRequired);
      
      setAiPrompt('');
    } catch (error) {
      console.error("Drafting error:", error);
      alert("Failed to draft permit.");
    }
    setIsDrafting(false);
  };

  const handlePredictLotoRisks = async () => {
    setIsPredicting(true);
    try {
      const activeLotos = lotoRecords.filter(l => l.status === 'Active').map(l => l.equipmentName).join(', ');
      const prompt = `You are an AI Predictive Maintenance system. 
Analyze the following active LOTO equipment and predict potential isolation failures or risks based on typical industrial failure modes (e.g., aging valves, residual pressure, electrical bleed).
Active Equipment: ${activeLotos || 'Main Boiler, Substation B, Conveyor Belt 3'}

Return a JSON array of objects, each with:
- "equipment": string (name of equipment)
- "riskScore": number (0-100, probability of failure)
- "reason": string (brief explanation of the predictive risk)
Limit to 2 high-risk alerts.`;

      const ai = getGeminiClient();
      const response = await ai.models.generateContent({
        model: 'gemini-3.1-pro-preview',
        contents: prompt,
        config: { responseMimeType: "application/json" }
      });

      const alerts = JSON.parse(response.text || '[]');
      setPredictiveAlerts(alerts);
    } catch (error) {
      console.error("Prediction error:", error);
    }
    setIsPredicting(false);
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'Approved':
      case 'Active': return 'bg-green-100 text-green-800 border-green-200';
      case 'Requested': return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      case 'Suspended': return 'bg-red-100 text-red-800 border-red-200';
      case 'Closed':
      case 'Removed': return 'bg-gray-100 text-gray-800 border-gray-200';
      default: return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  return (
    <Box sx={{ spaceY: 3 }}>
      <Box sx={{ display: 'flex', flexDirection: { xs: 'column', md: 'row' }, alignItems: { md: 'center' }, justifyContent: 'space-between', gap: 2, mb: 4 }}>
        <Box>
          <Typography variant="h5" fontWeight={700}>Permit to Work & LOTO</Typography>
          <Typography variant="body2" color="text.secondary">Manage high-risk work permits and energy isolation workflows.</Typography>
        </Box>
        <Box sx={{ display: 'flex', gap: 2 }}>
          <Button 
            variant="contained" 
            color="primary" 
            startIcon={<PlusIcon   sx={{ fontSize: 20 }} />}
            onClick={() => setIsRequestingPermit(true)}
            sx={{ boxShadow: 1 }}
          >
            Request Permit
          </Button>
        </Box>
      </Box>

      {/* Tabs */}
      <Box sx={{ borderBottom: 1, borderColor: 'divider', mb: 3 }}>
        <Tabs 
          value={activeTab} 
          onChange={(_, newValue) => setActiveTab(newValue)} 
          variant="scrollable"
          scrollButtons="auto"
        >
          <Tab icon={<FileSignatureIcon   sx={{ fontSize: 18 }} />} iconPosition="start" label="Active Permits" value="permits" sx={{ fontWeight: 600 }} />
          <Tab icon={<LockIcon   sx={{ fontSize: 18 }} />} iconPosition="start" label="LOTO Boards" value="loto" sx={{ fontWeight: 600 }} />
        </Tabs>
      </Box>

      {/* Content Area */}
      <Box>
        
        {/* Permits Tab */}
        {activeTab === 'permits' && (
          <Grid container spacing={3}>
            {permits.map((permit) => {
              const now = new Date();
              const validToDate = new Date(permit.validTo);
              const isExpiringSoon = permit.status === 'Active' && validToDate.getTime() - now.getTime() < 3600000 && validToDate.getTime() > now.getTime(); // Less than 1 hour
              const isExpired = validToDate.getTime() < now.getTime() && permit.status !== 'Closed';

              return (
                <Grid item xs={12} lg={6} key={permit.id}>
                  <Card elevation={1} sx={{ borderRadius: 2, height: '100%', ...(isExpired ? { bgcolor: 'error.50', borderColor: 'error.300', border: 1 } : {}) }}>
                    <CardContent sx={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
                      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 3 }}>
                        <Box sx={{ display: 'flex', gap: 2 }}>
                          <Avatar sx={{ bgcolor: 'primary.50', color: 'primary.main', borderRadius: 2 }}>
                            <FileSignatureIcon   sx={{ fontSize: 24 }} />
                          </Avatar>
                          <Box>
                            <Typography variant="subtitle1" fontWeight={700}>{permit.type}</Typography>
                            <Typography variant="body2" color="text.secondary" sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                              <MapPinIcon   sx={{ fontSize: 14 }} /> {permit.location}
                            </Typography>
                          </Box>
                        </Box>
                        <Chip 
                          size="small" 
                          label={permit.status} 
                          color={
                            permit.status === 'Approved' || permit.status === 'Active' ? 'success' : 
                            permit.status === 'Requested' ? 'warning' : 
                            permit.status === 'Suspended' ? 'error' : 'default'
                          } 
                          variant="outlined" 
                          sx={{ fontWeight: 600 }}
                        />
                      </Box>

                      <Grid container spacing={2} sx={{ mb: 3 }}>
                        <Grid item xs={6}>
                          <Typography variant="caption" color="text.secondary" display="block">Applicant</Typography>
                          <Typography variant="body2" fontWeight={600}>{permit.applicantName}</Typography>
                        </Grid>
                        <Grid item xs={6}>
                          <Typography variant="caption" color="text.secondary" display="block">Contractor</Typography>
                          <Typography variant="body2" fontWeight={600}>{permit.contractorName || 'Internal'}</Typography>
                        </Grid>
                        {permit.workerIds && permit.workerIds.length > 0 && (
                          <Grid item xs={12}>
                            <Typography variant="caption" color="text.secondary" display="block" mb={0.5}>Assigned Workers</Typography>
                            <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1 }}>
                              {permit.workerIds.map(wId => {
                                const worker = workers.find(w => w.id === wId);
                                return (
                                  <Chip key={wId} label={worker ? worker.fullName : 'Unknown'} size="small" variant="outlined" />
                                );
                              })}
                            </Box>
                          </Grid>
                        )}
                        <Grid item xs={12}>
                          <Typography variant="caption" color="text.secondary" display="block">LOTO Required</Typography>
                          <Typography variant="body2" fontWeight={600} sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                            {permit.lotoRequired ? <LockIcon    sx={{ fontSize: 14, color: '#d97706' }} /> : null}
                            {permit.lotoRequired ? 'Yes' : 'No'}
                          </Typography>
                        </Grid>
                        <Grid item xs={12}>
                          <Box sx={{ bgcolor: 'background.default', p: 1.5, borderRadius: 2, display: 'flex', alignItems: 'flex-start', gap: 1.5 }}>
                            <ClockIcon style={{ marginTop: 2, flexShrink: 0 }} sx={{ fontSize: 18, color: isExpiringSoon || isExpired ? '#ef4444' : '#94a3b8' }} />
                            <Box sx={{ flex: 1, width: '100%' }}>
                              <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
                                <Typography variant="caption" color="text.secondary">Valid From: {new Date(permit.validFrom).toLocaleString()}</Typography>
                                <Typography variant="caption" color="text.secondary">Valid To: {new Date(permit.validTo).toLocaleString()}</Typography>
                              </Box>
                              {isExpiringSoon && (
                                <Typography variant="caption" color="error.main" fontWeight={600} sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mt: 0.5 }}>
                                  <AlertTriangleIcon   sx={{ fontSize: 12 }} /> Expiring soon!
                                </Typography>
                              )}
                              {isExpired && (
                                <Typography variant="caption" color="error.main" fontWeight={600} sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mt: 0.5 }}>
                                  <XCircleIcon   sx={{ fontSize: 12 }} /> Permit Expired
                                </Typography>
                              )}
                            </Box>
                          </Box>
                        </Grid>
                      </Grid>

                      <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1, mt: 'auto', pt: 2, borderTop: 1, borderColor: 'divider' }}>
                        {permit.status === 'Requested' && (
                          <Button 
                            fullWidth 
                            variant="contained" 
                            color="success" 
                            startIcon={<CheckCircleIcon   sx={{ fontSize: 16 }} />}
                            onClick={() => updatePermitStatus(permit.id, 'Approved')}
                          >
                            Approve (Geofenced)
                          </Button>
                        )}
                        {permit.status === 'Approved' && (
                          <Button 
                            fullWidth 
                            variant="contained" 
                            color="primary" 
                            startIcon={<PlayCircleIcon   sx={{ fontSize: 16 }} />}
                            onClick={() => updatePermitStatus(permit.id, 'Active')}
                          >
                            Start Work
                          </Button>
                        )}
                        {permit.status === 'Active' && (
                          <Grid container spacing={1}>
                            <Grid item xs={6}>
                              <Button 
                                fullWidth 
                                variant="contained" 
                                color="warning" 
                                startIcon={<AlertTriangleIcon   sx={{ fontSize: 16 }} />}
                                onClick={() => updatePermitStatus(permit.id, 'Suspended')}
                              >
                                Suspend
                              </Button>
                            </Grid>
                            <Grid item xs={6}>
                               <Button 
                                fullWidth 
                                variant="outlined" 
                                color="inherit" 
                                startIcon={<StopCircleIcon   sx={{ fontSize: 16 }} />}
                                onClick={() => updatePermitStatus(permit.id, 'Closed')}
                              >
                                Close
                              </Button>
                            </Grid>
                          </Grid>
                        )}
                        {permit.status === 'Suspended' && (
                          <Button 
                            fullWidth 
                            variant="contained" 
                            color="info" 
                            startIcon={<PlayCircleIcon   sx={{ fontSize: 16 }} />}
                            onClick={() => updatePermitStatus(permit.id, 'Active')}
                          >
                            Resume Work
                          </Button>
                        )}
                        {permit.lotoRequired && permit.status !== 'Closed' && (
                          <Button 
                            fullWidth 
                            variant="contained" 
                            color="error"
                            sx={{ mt: 1 }}
                            startIcon={<LockIcon   sx={{ fontSize: 16 }} />}
                            onClick={() => {
                              setSelectedPermitId(permit.id);
                              setIsApplyingLOTO(true);
                            }}
                          >
                            Apply LOTO
                          </Button>
                        )}
                      </Box>
                    </CardContent>
                  </Card>
                </Grid>
              );
            })}
            {permits.length === 0 && (
              <Grid item xs={12}>
                <Box sx={{ p: 6, textAlign: 'center', bgcolor: 'background.default', borderRadius: 2, border: '1px dashed', borderColor: 'divider' }}>
                  <Typography color="text.secondary">No permits found.</Typography>
                </Box>
              </Grid>
            )}
          </Grid>
        )}

        {/* LOTO Tab */}
        {activeTab === 'loto' && (
          <Box sx={{ p: 3 }}>
            
            {/* Predictive LOTO Alerts */}
            <Box sx={{ mb: 4, bgcolor: 'background.default', border: '1px solid', borderColor: 'divider', borderRadius: 2, p: 3 }}>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
                <Typography variant="h6" fontWeight={700} sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <ZapIcon   sx={{ color: 'warning.main' }} />
                  Predictive LOTO Failure Alerts
                </Typography>
                <Button 
                  onClick={handlePredictLotoRisks}
                  disabled={isPredicting}
                  variant="outlined"
                  color="inherit"
                  startIcon={isPredicting ? <CircularProgress size={16} color="inherit"   sx={{ fontSize: 16 }} /> : <BrainIcon    sx={{ fontSize: 16, color: '#4f46e5' }} />}
                >
                  Run Predictive Scan
                </Button>
              </Box>
              
              {predictiveAlerts.length > 0 ? (
                <Grid container spacing={2}>
                  {predictiveAlerts.map((alert, idx) => (
                    <Grid item xs={12} md={6} key={idx}>
                      <Card elevation={0} sx={{ border: '1px solid', borderColor: 'error.main', borderRadius: 2, p: 2, display: 'flex', alignItems: 'flex-start', gap: 2 }}>
                        <Avatar sx={{ bgcolor: 'error.50', color: 'error.main' }}>
                          <AlertTriangleIcon   sx={{ fontSize: 18 }} />
                        </Avatar>
                        <Box sx={{ flex: 1 }}>
                          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 0.5 }}>
                            <Typography variant="subtitle2" fontWeight={700}>{alert.equipment}</Typography>
                            <Chip size="small" color="error" label={`${alert.riskScore}% Risk`} sx={{ fontWeight: 700 }} />
                          </Box>
                          <Typography variant="body2" color="text.secondary">{alert.reason}</Typography>
                        </Box>
                      </Card>
                    </Grid>
                  ))}
                </Grid>
              ) : (
                <Typography variant="body2" color="text.secondary" textAlign="center" py={2}>
                  Click "Run Predictive Scan" to analyze active isolations for potential failure risks.
                </Typography>
              )}
            </Box>

            <Grid container spacing={3}>
              {lotoRecords.map((loto) => {
                const permit = permits.find(p => p.id === loto.permitId);
                return (
                  <Grid item xs={12} md={6} lg={4} key={loto.id}>
                    <Card elevation={1} sx={{ borderRadius: 2, ...(loto.status === 'Active' ? { bgcolor: 'error.50', borderColor: 'error.200', border: 1 } : {}) }}>
                      <CardContent>
                        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 3 }}>
                          <Box sx={{ display: 'flex', gap: 2 }}>
                            <Avatar sx={{ bgcolor: loto.status === 'Active' ? 'error.100' : 'background.default', color: loto.status === 'Active' ? 'error.main' : 'text.secondary', borderRadius: 2 }}>
                              <LockIcon   sx={{ fontSize: 24 }} />
                            </Avatar>
                            <Box>
                              <Typography variant="subtitle2" fontWeight={700}>{loto.equipmentName}</Typography>
                              <Typography variant="caption" color="text.secondary">Permit: {permit?.type || 'Unknown'}</Typography>
                            </Box>
                          </Box>
                          <Chip 
                            size="small" 
                            label={loto.status} 
                            color={loto.status === 'Active' ? 'error' : 'default'} 
                            variant="outlined" 
                            sx={{ fontWeight: 600 }}
                          />
                        </Box>

                        <Box sx={{ mb: 3 }}>
                          <Typography variant="overline" color="text.secondary" fontWeight={600} display="block" mb={1}>Isolation Points</Typography>
                          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                            {loto.isolationPoints.map((point, idx) => (
                              <Typography key={idx} variant="body2" color="text.primary" sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                <Box sx={{ width: 6, height: 6, borderRadius: '50%', bgcolor: 'error.main' }} /> {point}
                              </Typography>
                            ))}
                          </Box>
                        </Box>

                        <Box sx={{ mb: 3 }}>
                          <Typography variant="body2" color="text.secondary" mb={0.5}>Applied by: <Box component="span" fontWeight={600} color="text.primary">{loto.appliedByName}</Box></Typography>
                          <Typography variant="body2" color="text.secondary" mb={0.5}>Applied at: <Box component="span" color="text.primary">{new Date(loto.appliedAt).toLocaleString()}</Box></Typography>
                          {loto.removedAt && (
                            <Typography variant="body2" color="text.secondary">Removed at: <Box component="span" color="text.primary">{new Date(loto.removedAt).toLocaleString()}</Box></Typography>
                          )}
                        </Box>

                        {loto.photoEvidence && (
                          <Box sx={{ mb: 3 }}>
                            <Typography variant="overline" color="text.secondary" fontWeight={600} display="block" mb={1}>Visual Evidence</Typography>
                            <Box sx={{ height: 120, width: '100%', borderRadius: 2, overflow: 'hidden', border: '1px solid', borderColor: 'divider' }}>
                              <img src={loto.photoEvidence} alt="LOTO Evidence" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                            </Box>
                          </Box>
                        )}

                        {loto.status === 'Active' && (
                          <Button 
                            fullWidth 
                            variant="outlined" 
                            color="inherit" 
                            startIcon={<ShieldAlertIcon   sx={{ fontSize: 16 }} />}
                            onClick={() => removeLOTO(loto.id)}
                            sx={{ mt: 1 }}
                          >
                            Remove LOTO
                          </Button>
                        )}
                      </CardContent>
                    </Card>
                  </Grid>
                );
              })}
              {lotoRecords.length === 0 && (
                <Grid item xs={12}>
                  <Box sx={{ p: 6, textAlign: 'center', bgcolor: 'background.default', borderRadius: 2, border: '1px dashed', borderColor: 'divider' }}>
                    <Typography color="text.secondary">No LOTO records found.</Typography>
                  </Box>
                </Grid>
              )}
            </Grid>
          </Box>
        )}
      </Box>

      {/* Request Permit Dialog */}
      <Dialog open={isRequestingPermit} onClose={() => setIsRequestingPermit(false)} maxWidth="md" fullWidth>
        <form onSubmit={handleRequestPermit}>
          <DialogTitle sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <Typography variant="h6" fontWeight={700}>Request Permit to Work</Typography>
            <IconButton size="small" onClick={() => setIsRequestingPermit(false)}>
              <XCircleIcon   sx={{ fontSize: 20 }} />
            </IconButton>
          </DialogTitle>
          <DialogContent dividers>
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
              
              {/* AI Drafting Section */}
              <Box sx={{ bgcolor: '#eef2ff', p: 3, borderRadius: 2, border: '1px solid', borderColor: '#c7d2fe' }}>
                <Typography variant="subtitle2" fontWeight={700} color="#312e81" mb={2} sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <SparklesIcon    sx={{ fontSize: 16, color: '#4f46e5' }} />
                  Natural Language Permit Request
                </Typography>
                <Box sx={{ display: 'flex', gap: 2 }}>
                  <TextField 
                    fullWidth 
                    size="small"
                    value={aiPrompt}
                    onChange={(e) => setAiPrompt(e.target.value)}
                    placeholder="e.g., I need to weld the main boiler tomorrow at 2pm..."
                    onKeyDown={(e) => {
                      if (e.key === 'Enter') {
                        e.preventDefault();
                        handleDraftPermit();
                      }
                    }}
                    sx={{ bgcolor: 'white' }}
                  />
                  <Button 
                    variant="contained" 
                    color="primary"
                    onClick={handleDraftPermit}
                    disabled={isDrafting || !aiPrompt}
                    startIcon={isDrafting ? <CircularProgress size={16} color="inherit"   sx={{ fontSize: 16 }} /> : <SparklesIcon   sx={{ fontSize: 16 }} />}
                  >
                    Draft
                  </Button>
                </Box>
                <Typography variant="caption" color="#4f46e5" mt={1} display="block">
                  Describe the work, and AI will auto-fill the form below.
                </Typography>
              </Box>

              <Grid container spacing={3}>
                <Grid item xs={12} sm={6}>
                  <Typography variant="subtitle2" fontWeight={600} mb={1}>Permit Type</Typography>
                  <Select 
                    fullWidth
                    size="small"
                    required
                    value={permitType}
                    onChange={(e) => setPermitType(e.target.value as any)}
                  >
                    <MenuItem value="Hot Work">Hot Work</MenuItem>
                    <MenuItem value="Working at Heights">Working at Heights</MenuItem>
                    <MenuItem value="Confined Space">Confined Space</MenuItem>
                    <MenuItem value="Electrical">Electrical</MenuItem>
                    <MenuItem value="Excavation">Excavation</MenuItem>
                    <MenuItem value="Other">Other</MenuItem>
                  </Select>
                </Grid>
                <Grid item xs={12} sm={6}>
                  <Typography variant="subtitle2" fontWeight={600} mb={1}>Location</Typography>
                  <TextField 
                    fullWidth
                    size="small"
                    required
                    value={location}
                    onChange={(e) => setLocation(e.target.value)}
                    placeholder="e.g., Boiler Room A"
                  />
                </Grid>
              </Grid>

              <Box>
                <Typography variant="subtitle2" fontWeight={600} mb={1}>Contractor (Optional)</Typography>
                <Select 
                  fullWidth
                  size="small"
                  value={selectedContractorId}
                  onChange={(e) => {
                    setSelectedContractorId(e.target.value);
                    setSelectedWorkerIds([]);
                  }}
                  displayEmpty
                >
                  <MenuItem value=""><em>Internal / No Contractor</em></MenuItem>
                  {contractors.map(c => (
                    <MenuItem key={c.id} value={c.id}>
                      {c.companyName} ({c.complianceStatus})
                    </MenuItem>
                  ))}
                </Select>
              </Box>

              {selectedContractorId && (
                <Box>
                  <Typography variant="subtitle2" fontWeight={600} mb={1}>Assign Workers</Typography>
                  <Box sx={{ maxHeight: 150, overflowY: 'auto', border: '1px solid', borderColor: 'divider', borderRadius: 1, p: 1 }}>
                    {workers.filter(w => w.contractorId === selectedContractorId).map(worker => (
                      <FormControlLabel
                        key={worker.id}
                        control={
                          <Checkbox 
                            size="small"
                            checked={selectedWorkerIds.includes(worker.id)}
                            onChange={(e) => {
                              if (e.target.checked) {
                                setSelectedWorkerIds([...selectedWorkerIds, worker.id]);
                              } else {
                                setSelectedWorkerIds(selectedWorkerIds.filter(id => id !== worker.id));
                              }
                            }}
                          />
                        }
                        label={
                          <Typography variant="body2" color={worker.complianceStatus === 'Green' ? 'text.primary' : 'error.main'} fontWeight={worker.complianceStatus !== 'Green' ? 600 : 400}>
                            {worker.fullName} ({worker.complianceStatus})
                          </Typography>
                        }
                        sx={{ display: 'flex', width: '100%', m: 0, p: 0.5, '&:hover': { bgcolor: 'background.default' } }}
                      />
                    ))}
                    {workers.filter(w => w.contractorId === selectedContractorId).length === 0 && (
                      <Typography variant="caption" color="text.secondary" p={1} display="block" fontStyle="italic">
                        No workers registered for this contractor.
                      </Typography>
                    )}
                  </Box>
                </Box>
              )}

              <Grid container spacing={3}>
                <Grid item xs={12} sm={6}>
                  <Typography variant="subtitle2" fontWeight={600} mb={1}>Valid From</Typography>
                  <TextField 
                    fullWidth
                    size="small"
                    type="datetime-local" 
                    required
                    value={validFrom}
                    onChange={(e) => setValidFrom(e.target.value)}
                    InputLabelProps={{ shrink: true }}
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <Typography variant="subtitle2" fontWeight={600} mb={1}>Valid To</Typography>
                  <TextField 
                    fullWidth
                    size="small"
                    type="datetime-local" 
                    required
                    value={validTo}
                    onChange={(e) => setValidTo(e.target.value)}
                    InputLabelProps={{ shrink: true }}
                  />
                </Grid>
              </Grid>

              <Box>
                <FormControlLabel
                  control={
                    <Checkbox 
                      checked={lotoRequired}
                      onChange={(e) => setLotoRequired(e.target.checked)}
                      color="primary"
                    />
                  }
                  label={<Typography variant="body2" fontWeight={600}>Lockout/Tagout (LOTO) Required</Typography>}
                />
              </Box>

              {/* AI Risk Analysis Section */}
              <Box sx={{ bgcolor: 'info.50', border: '1px solid', borderColor: 'info.200', borderRadius: 2, p: 3 }}>
                <Box sx={{ display: 'flex', justifyItems: 'space-between', alignItems: 'center', mb: 2 }}>
                  <Typography variant="subtitle2" fontWeight={700} color="#1e3a8a" sx={{ display: 'flex', alignItems: 'center', gap: 1, flex: 1 }}>
                    <BrainIcon    sx={{ fontSize: 16, color: '#4f46e5' }} /> AI Risk & Clash Analysis
                  </Typography>
                  {!riskProfile && (
                    <Button 
                      size="small"
                      variant="contained"
                      color="primary"
                      onClick={handleAnalyzeRisk} 
                      disabled={isAnalyzingRisk || !location || !validFrom || !validTo}
                      startIcon={isAnalyzingRisk ? <CircularProgress size={16} color="inherit"  sx={{ fontSize: 14 }} /> : undefined}
                    >
                      {isAnalyzingRisk ? 'Analyzing...' : 'Analyze Risk'}
                    </Button>
                  )}
                </Box>
                
                {riskProfile && (
                  <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <Chip 
                        size="small" 
                        label={`${riskProfile.riskLevel} RISK`} 
                        sx={{ 
                          fontWeight: 700, 
                          color: 'white',
                          bgcolor: riskProfile.riskLevel === 'Critical' ? 'error.main' : 
                                   riskProfile.riskLevel === 'High' ? 'warning.dark' : 
                                   riskProfile.riskLevel === 'Medium' ? 'warning.main' : 'success.main' 
                        }} 
                      />
                      {riskProfile.clashDetected && (
                        <Chip 
                          size="small" 
                          icon={<AlertTriangleIcon   sx={{ fontSize: 12 }} />} 
                          label="CLASH DETECTED" 
                          color="error" 
                          variant="outlined" 
                          sx={{ fontWeight: 700, bgcolor: 'error.50' }}
                        />
                      )}
                    </Box>
                    
                    {riskProfile.clashDetected && (
                      <Typography variant="caption" sx={{ color: 'error.dark', bgcolor: 'error.50', p: 1.5, borderRadius: 1, border: '1px solid', borderColor: 'error.200' }}>
                        {riskProfile.clashDetails}
                      </Typography>
                    )}
                    
                    <Box>
                      <Typography variant="caption" fontWeight={700} color="#1e3a8a" mb={0.5} display="block">Required Precautions:</Typography>
                      <Box component="ul" sx={{ pl: 2, m: 0 }}>
                        {riskProfile.requiredPrecautions.map((p, i) => (
                          <Box component="li" key={i}>
                            <Typography variant="caption" color="#3730a3">{p}</Typography>
                          </Box>
                        ))}
                      </Box>
                    </Box>
                  </Box>
                )}
              </Box>

            </Box>
          </DialogContent>
          <DialogActions sx={{ p: 2, px: 3 }}>
            <Button onClick={() => setIsRequestingPermit(false)} color="inherit">Cancel</Button>
            <Button type="submit" variant="contained" color="primary">Submit Request</Button>
          </DialogActions>
        </form>
      </Dialog>

      {/* Apply LOTO Dialog */}
      <Dialog open={isApplyingLOTO} onClose={() => setIsApplyingLOTO(false)} maxWidth="sm" fullWidth>
        <form onSubmit={handleApplyLOTO}>
          <DialogTitle sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <Typography variant="h6" fontWeight={700}>Apply Lockout/Tagout</Typography>
            <IconButton size="small" onClick={() => setIsApplyingLOTO(false)}>
              <XCircleIcon   sx={{ fontSize: 20 }} />
            </IconButton>
          </DialogTitle>
          <DialogContent dividers>
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
              <Box>
                <Typography variant="subtitle2" fontWeight={600} mb={1}>Equipment Name</Typography>
                <TextField 
                  fullWidth
                  size="small"
                  required
                  value={equipmentName}
                  onChange={(e) => setEquipmentName(e.target.value)}
                  placeholder="e.g., Main Conveyor Belt"
                />
              </Box>
              <Box>
                <Typography variant="subtitle2" fontWeight={600} mb={1}>Isolation Points (comma separated)</Typography>
                <TextField 
                  fullWidth
                  size="small"
                  required
                  multiline
                  rows={3}
                  value={isolationPoints}
                  onChange={(e) => setIsolationPoints(e.target.value)}
                  placeholder="e.g., Main Breaker Panel A, Valve V-102"
                />
              </Box>
              
              <Box sx={{ bgcolor: 'error.50', border: '1px solid', borderColor: 'error.200', borderRadius: 2, p: 2, display: 'flex', alignItems: 'flex-start', gap: 2 }}>
                <AlertTriangleIcon   style={{ flexShrink: 0 }}  sx={{ fontSize: 20, color: '#dc2626' }} />
                <Typography variant="body2" color="error.dark">
                  By applying this LOTO, you confirm that all energy sources have been isolated, locked, and tagged according to safety procedures.
                </Typography>
              </Box>

              <Box sx={{ bgcolor: 'background.default', p: 2, borderRadius: 2, border: '1px solid', borderColor: 'divider', display: 'flex', flexDirection: 'column', gap: 2 }}>
                
                <Box sx={{ display: 'flex', alignItems: 'center', justifyItems: 'space-between', bgcolor: 'background.paper', p: 2, borderRadius: 1, border: '1px solid', borderColor: 'divider' }}>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, flex: 1 }}>
                    <QrCodeIcon sx={{ fontSize: 16, color: lotoQrVerified ? "#16a34a" : "#64748b" }} />
                    <Typography variant="body2" fontWeight={600}>Equipment QR Verification</Typography>
                  </Box>
                  {lotoQrVerified ? (
                    <Typography variant="caption" fontWeight={700} color="success.main" sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                      <ShieldCheckIcon  sx={{ fontSize: 14 }} /> Verified
                    </Typography>
                  ) : (
                    <Button size="small" variant="contained" color="secondary" onClick={() => setLotoQrVerified(true)}>
                      Simulate Scan
                    </Button>
                  )}
                </Box>

                <Box sx={{ bgcolor: 'background.paper', p: 2, borderRadius: 1, border: '1px solid', borderColor: 'divider' }}>
                  <Typography variant="caption" fontWeight={600} mb={2} sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <CameraIcon   sx={{ fontSize: 14 }} /> Visual Evidence (Zero-Energy State)
                  </Typography>
                  {!lotoPhoto ? (
                    <Box 
                      component="label" 
                      sx={{ 
                        display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', 
                        height: 100, border: '2px dashed', borderColor: 'divider', borderRadius: 2, 
                        cursor: 'pointer', '&:hover': { bgcolor: 'background.default' } 
                      }}
                    >
                      <ImageIcon   style={{ marginBottom: 4 }}  sx={{ fontSize: 20, color: '#94a3b8' }} />
                      <Typography variant="caption" color="text.secondary">Upload photo of locked isolation point</Typography>
                      <input type="file" accept="image/*" capture="environment" style={{ display: 'none' }} onChange={handleLotoPhotoUpload} />
                    </Box>
                  ) : (
                    <Box sx={{ position: 'relative', height: 120, width: '100%', borderRadius: 2, overflow: 'hidden', border: '1px solid', borderColor: 'divider' }}>
                      <img src={lotoPhoto} alt="LOTO Evidence" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                      <IconButton size="small" onClick={() => setLotoPhoto(null)} sx={{ position: 'absolute', top: 4, right: 4, bgcolor: 'rgba(0,0,0,0.5)', color: 'white', '&:hover': { bgcolor: 'rgba(0,0,0,0.7)' } }}>
                        <XCircleIcon   sx={{ fontSize: 14 }} />
                      </IconButton>
                    </Box>
                  )}
                </Box>

              </Box>

            </Box>
          </DialogContent>
          <DialogActions sx={{ p: 2, px: 3 }}>
            <Button onClick={() => setIsApplyingLOTO(false)} color="inherit">Cancel</Button>
            <Button 
              type="submit" 
              variant="contained" 
              color="error"
              disabled={!lotoQrVerified || !lotoPhoto}
              startIcon={<LockIcon   sx={{ fontSize: 16 }} />}
            >
              Apply Locks
            </Button>
          </DialogActions>
        </form>
      </Dialog>

    </Box>
  );
}
