import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy, doc, deleteDoc, updateDoc, where, limit } from 'firebase/firestore';
import { ref, uploadBytes, getDownloadURL } from 'firebase/storage';
import { db, storage, handleFirestoreError, OperationType } from '../lib/firebase';
import { getGeminiClient } from '../lib/gemini';
import { useAuth } from '../contexts/AuthContext';
import { NotificationService } from '../services/notificationService';
import { Box, Typography, Button, Paper, Tabs, Tab, IconButton, Grid, Card, CardContent, Chip , TextField, MenuItem, InputLabel, FormControl } from '@mui/material';

// Icons
import AlertOctagon from '@mui/icons-material/Warning';
import ClipboardList from '@mui/icons-material/Assignment';
import CheckSquare from '@mui/icons-material/CheckBox';
import Plus from '@mui/icons-material/Add';
import MapPin from '@mui/icons-material/LocationOn';
import Camera from '@mui/icons-material/CameraAlt';
import Trash2 from '@mui/icons-material/Delete';
import X from '@mui/icons-material/Close';
import Clock from '@mui/icons-material/AccessTime';
import User from '@mui/icons-material/Person';
import Sparkles from '@mui/icons-material/AutoAwesome';
import Loader2 from '@mui/icons-material/Sync';
import BarChart3 from '@mui/icons-material/BarChart';
import Mic from '@mui/icons-material/Mic';
import MicOff from '@mui/icons-material/MicOff';
import Smartphone from '@mui/icons-material/Smartphone';
import Target from '@mui/icons-material/Adjust';
import Unlock from '@mui/icons-material/NoEncryption';
import Eye from '@mui/icons-material/Visibility';


import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';

interface Incident {
  id: string;
  title: string;
  description: string;
  type: string;
  severity: string;
  location: string;
  status: string;
  siteId: string;
  reporterId: string;
  reporterName: string;
  contractorId?: string;
  contractorName?: string;
  dateOfIncident: string;
  createdAt: string;
  photoUrl?: string;
  
  // New Enhanced Fields
  directCosts?: number;
  indirectCosts?: number;
  totalCost?: number;
  linkedBowTieId?: string;
  linkedBarrier?: string;
  
  // Dynamic Fields
  injuryDetails?: {
    bodyPart: string;
    treatmentType: string;
  };
  environmentalDetails?: {
    substance: string;
    volume: string;
    unit: string;
  };
  propertyDamageDetails?: {
    assetId: string;
    estimatedDamage: number;
  };
}

interface BowTie {
  id: string;
  hazard: string;
  topEvent: string;
  preventative: string[];
  mitigative: string[];
}

interface Contractor {
  id: string;
  companyName: string;
}

interface CAPA {
  id: string;
  incidentId?: string;
  description: string;
  rca?: string;
  assignedToName: string;
  dueDate: string;
  status: string;
  createdById: string;
  createdAt: string;
}

export default function IncidentsCAPA() {
  const { profile } = useAuth();
  const [incidents, setIncidents] = useState<Incident[]>([]);
  const [capas, setCapas] = useState<CAPA[]>([]);
  const [contractors, setContractors] = useState<Contractor[]>([]);
  const [bowties, setBowties] = useState<BowTie[]>([]);
  const [loading, setLoading] = useState(true);
  
  // UI State
  const [activeTab, setActiveTab] = useState<'register' | 'report' | 'capa' | 'analytics'>('register');
  const [isCreatingCAPA, setIsCreatingCAPA] = useState(false);
  const [selectedIncidentId, setSelectedIncidentId] = useState<string | undefined>(undefined);
  const [viewingIncident, setViewingIncident] = useState<Incident | null>(null);

  // Incident Form State
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [type, setType] = useState('Injury');
  const [severity, setSeverity] = useState('Minor');
  const [location, setLocation] = useState('');
  const [selectedContractorId, setSelectedContractorId] = useState('');
  const [dateOfIncident, setDateOfIncident] = useState(new Date().toISOString().slice(0, 16)); // YYYY-MM-DDTHH:mm
  const [photoFile, setPhotoFile] = useState<File | null>(null);
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [isListening, setIsListening] = useState(false);
  const [isGeneratingRCA, setIsGeneratingRCA] = useState(false);
  const [isAnalyzingPhoto, setIsAnalyzingPhoto] = useState(false);
  const [isGeneratingLessons, setIsGeneratingLessons] = useState(false);
  const [isAnonymous, setIsAnonymous] = useState(false);
  const [showQRCode, setShowQRCode] = useState(false);
  const [notifications, setNotifications] = useState<{id: string, message: string, type: 'error' | 'success' | 'alert'}[]>([]);

  // Enhanced Form State
  const [directCosts, setDirectCosts] = useState<string>('0');
  const [indirectCosts, setIndirectCosts] = useState<string>('0');
  const [linkedBowTieId, setLinkedBowTieId] = useState('');
  const [linkedBarrier, setLinkedBarrier] = useState('');
  
  // Dynamic Fields State
  const [injuryBodyPart, setInjuryBodyPart] = useState('');
  const [injuryTreatment, setInjuryTreatment] = useState('');
  const [envSubstance, setEnvSubstance] = useState('');
  const [envVolume, setEnvVolume] = useState('');
  const [envUnit, setEnvUnit] = useState('Liters');
  const [damageAssetId, setDamageAssetId] = useState('');
  const [damageEstimate, setDamageEstimate] = useState('0');

  // CAPA Form State
  const [capaDescription, setCapaDescription] = useState('');
  const [rca, setRca] = useState('');
  const [assignedToName, setAssignedToName] = useState('');
  const [dueDate, setDueDate] = useState('');

  useEffect(() => {
    if (!profile?.siteId) return;
    
    const qIncidents = query(collection(db, 'incidents'), where('siteId', '==', profile.siteId), orderBy('createdAt', 'desc'), limit(100));
    const unsubIncidents = onSnapshot(qIncidents, (snapshot) => {
      const data: Incident[] = [];
      snapshot.forEach((doc) => {
        data.push({ id: doc.id, ...doc.data() } as Incident);
      });
      setIncidents(data);
      setLoading(false);
    }, (error) => handleFirestoreError(error, OperationType.LIST, 'incidents'));

    const qCapas = query(collection(db, 'capas'), where('siteId', '==', profile.siteId), orderBy('createdAt', 'desc'), limit(100));
    const unsubCapas = onSnapshot(qCapas, (snapshot) => {
      const data: CAPA[] = [];
      snapshot.forEach((doc) => {
        data.push({ id: doc.id, ...doc.data() } as CAPA);
      });
      setCapas(data);
    }, (error) => handleFirestoreError(error, OperationType.LIST, 'capas'));

    const qContractors = query(collection(db, 'contractors'), where('siteId', '==', profile.siteId), orderBy('companyName', 'asc'));
    const unsubContractors = onSnapshot(qContractors, (snapshot) => {
      const data: Contractor[] = [];
      snapshot.forEach((doc) => {
        data.push({ id: doc.id, companyName: doc.data().companyName } as Contractor);
      });
      setContractors(data);
    }, (error) => handleFirestoreError(error, OperationType.LIST, 'contractors'));

    const qBowties = query(collection(db, 'bowtie_analyses'), where('siteId', '==', profile.siteId), orderBy('hazard', 'asc'));
    const unsubBowties = onSnapshot(qBowties, (snapshot) => {
      setBowties(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as BowTie[]);
    }, (error) => handleFirestoreError(error, OperationType.LIST, 'bowtie_analyses'));

    return () => {
      unsubIncidents();
      unsubCapas();
      unsubContractors();
      unsubBowties();
    };
  }, [profile]);

  const handleGetLocation = () => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          setLocation(`${position.coords.latitude.toFixed(4)}, ${position.coords.longitude.toFixed(4)}`);
        },
        (error) => {
          console.error("Error getting location", error);
          alert("Unable to retrieve your location. Please enter it manually.");
        }
      );
    } else {
      alert("Geolocation is not supported by this browser.");
    }
  };

  const analyzeWithAI = async () => {
    if (!description) return;
    setIsAnalyzing(true);
    try {
      const ai = getGeminiClient();
      const response = await ai.models.generateContent({
        model: "gemini-3-flash-preview",
        contents: `Analyze this incident description and suggest the most appropriate Incident Type (Injury, Near Miss, Property Damage, Environmental, Hazard Observation) and Severity (Minor, Major, Critical). Return JSON: {"type": "...", "severity": "..."}. Description: ${description}`,
        config: { responseMimeType: "application/json" }
      });
      const result = JSON.parse(response.text!);
      setType(result.type);
      setSeverity(result.severity);
    } catch (e) {
      console.error("AI Analysis failed", e);
    } finally {
      setIsAnalyzing(false);
    }
  };

  const toggleListening = () => {
    const SpeechRecognition = (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition;
    if (!SpeechRecognition) {
      alert("Speech recognition is not supported in this browser.");
      return;
    }

    if (isListening) {
      setIsListening(false);
      return;
    }

    const recognition = new SpeechRecognition();
    recognition.continuous = true;
    recognition.interimResults = true;
    recognition.lang = 'en-US';

    recognition.onstart = () => setIsListening(true);
    recognition.onend = () => setIsListening(false);
    recognition.onerror = (event: any) => {
      console.error("Speech recognition error", event.error);
      setIsListening(false);
    };

    recognition.onresult = (event: any) => {
      let interimTranscript = '';
      let finalTranscript = '';

      for (let i = event.resultIndex; i < event.results.length; ++i) {
        if (event.results[i].isFinal) {
          finalTranscript += event.results[i][0].transcript;
        } else {
          interimTranscript += event.results[i][0].transcript;
        }
      }

      if (finalTranscript) {
        setDescription(prev => prev + (prev ? ' ' : '') + finalTranscript);
      }
    };

    recognition.start();
  };

  const analyzePhotoWithAI = async (file: File) => {
    setIsAnalyzingPhoto(true);
    try {
      const reader = new FileReader();
      reader.readAsDataURL(file);
      reader.onload = async () => {
        const base64Data = (reader.result as string).split(',')[1];
        
        const ai = getGeminiClient();
        const response = await ai.models.generateContent({
          model: "gemini-3-flash-preview",
          contents: [
            {
              role: "user",
              parts: [
                { text: "Analyze this incident photo. Identify potential hazards, missing PPE, or equipment involved. Provide a concise summary for an incident report." },
                { inlineData: { mimeType: file.type, data: base64Data } }
              ]
            }
          ]
        });
        
        const analysis = response.text;
        setDescription(prev => prev + (prev ? '\n\n' : '') + "AI Photo Analysis:\n" + analysis);
        setIsAnalyzingPhoto(false);
      };
    } catch (e) {
      console.error("Photo analysis failed", e);
      setIsAnalyzingPhoto(false);
    }
  };

  const handlePhotoChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0] || null;
    setPhotoFile(file);
    if (file) {
      analyzePhotoWithAI(file);
    }
  };

  const generateAIRCA = async () => {
    let incidentToAnalyze = incidents.find(i => i.id === selectedIncidentId);
    const textToAnalyze = incidentToAnalyze ? incidentToAnalyze.description : capaDescription;
    
    if (!textToAnalyze) return;
    
    setIsGeneratingRCA(true);
    try {
      const prompt = `As a Senior SHEQ Auditor, perform a "5 Whys" Root Cause Analysis for the following incident:
      
      Incident Title: ${incidentToAnalyze?.title || 'Unknown'}
      Description: ${textToAnalyze}
      
      Format the response as a structured "5 Whys" analysis followed by a concise "Root Cause" statement.`;

      const ai = getGeminiClient();
      const result = await ai.models.generateContent({
        model: "gemini-3-flash-preview",
        contents: prompt
      });
      
      setRca(result.text || "Failed to generate RCA.");
    } catch (e) {
      console.error("AI RCA generation failed", e);
      setNotifications(prev => [...prev, {
        id: Date.now().toString(),
        message: "Failed to generate AI RCA. Please try again.",
        type: 'error'
      }]);
    } finally {
      setIsGeneratingRCA(false);
    }
  };

  const generateLessonsLearned = async (incident: Incident) => {
    setIsGeneratingLessons(true);
    try {
      const prompt = `As a Senior SHEQ Manager, generate a "Lessons Learned" summary for the following incident to be shared in a safety toolbox talk.
      
      Title: ${incident.title}
      Description: ${incident.description}
      Type: ${incident.type}
      
      Provide 3 key takeaways and 2 preventative actions.`;

      const ai = getGeminiClient();
      const result = await ai.models.generateContent({
        model: "gemini-3-flash-preview",
        contents: prompt
      });
      
      alert(`Lessons Learned for ${incident.title}:\n\n${result.text}`);
    } catch (e) {
      console.error("Lessons Learned generation failed", e);
    } finally {
      setIsGeneratingLessons(false);
    }
  };

  const handleSubmitIncident = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!profile) return;

    try {
      let photoUrl = null;
      if (photoFile) {
        const storageRef = ref(storage, `incidents/${Date.now()}_${photoFile.name}`);
        await uploadBytes(storageRef, photoFile);
        photoUrl = await getDownloadURL(storageRef);
      }

      const contractor = contractors.find(c => c.id === selectedContractorId);
      const newIncident: any = {
        title,
        description,
        type,
        severity,
        location,
        status: 'Open',
        reporterId: isAnonymous ? 'anonymous' : profile.uid,
        reporterName: isAnonymous ? 'Anonymous Whistleblower' : (profile.fullName || 'Unknown User'),
        siteId: profile.siteId,
        contractorId: selectedContractorId || null,
        contractorName: contractor?.companyName || null,
        dateOfIncident: new Date(dateOfIncident).toISOString(),
        createdAt: new Date().toISOString(),
        photoUrl,
        isAnonymous,
        
        // Enhanced Fields
        directCosts: Number(directCosts),
        indirectCosts: Number(indirectCosts),
        totalCost: Number(directCosts) + Number(indirectCosts),
        linkedBowTieId: linkedBowTieId || null,
        linkedBarrier: linkedBarrier || null
      };

      // Dynamic Fields
      if (type === 'Injury') {
        newIncident.injuryDetails = { bodyPart: injuryBodyPart, treatmentType: injuryTreatment };
      } else if (type === 'Environmental') {
        newIncident.environmentalDetails = { substance: envSubstance, volume: envVolume, unit: envUnit };
      } else if (type === 'Property Damage') {
        newIncident.propertyDamageDetails = { assetId: damageAssetId, estimatedDamage: Number(damageEstimate) };
      }

      const docRef = await addDoc(collection(db, 'incidents'), newIncident);
      
      // Trigger Notifications
      await NotificationService.notifyIncidentCreated(newIncident, 'safety-manager@example.com'); // In real app, fetch manager email

      // Escalation logic
      if (severity === 'Major' || severity === 'Critical') {
        // Automatically create CAPA
        await addDoc(collection(db, 'capas'), {
          incidentId: docRef.id,
          description: `Automatic CAPA for ${severity} incident: ${title}`,
          status: 'Open',
          createdById: profile.uid,
          siteId: profile.siteId,
          createdAt: new Date().toISOString(),
          assignedToName: 'Safety Manager', // Default assignment
          dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString() // 1 week deadline
        });

        setNotifications(prev => [...prev, {
          id: Date.now().toString(),
          message: `CRITICAL ALERT: ${severity} incident "${title}" reported at ${location}. Escalating to safety management and creating CAPA.`,
          type: 'alert'
        }]);
        // Simulate email/SMS
        console.log(`Sending SMS/Email to safety management for ${severity} incident: ${title}`);
      }

      // Reset form and switch tab
      setTitle('');
      setDescription('');
      setType('Injury');
      setSeverity('Minor');
      setLocation('');
      setSelectedContractorId('');
      setDateOfIncident(new Date().toISOString().slice(0, 16));
      setPhotoFile(null);
      setIsAnonymous(false);
      setActiveTab('register');
    } catch (error) {
      handleFirestoreError(error, OperationType.CREATE, 'incidents');
    }
  };

  const handleSubmitCAPA = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!profile) return;

    try {
      const newCapa: any = {
        description: capaDescription,
        rca,
        assignedToName,
        dueDate: new Date(dueDate).toISOString(),
        status: 'Open',
        createdById: profile.uid,
        siteId: profile.siteId,
        createdAt: new Date().toISOString()
      };

      if (selectedIncidentId) {
        newCapa.incidentId = selectedIncidentId;
      }

      const docRef = await addDoc(collection(db, 'capas'), newCapa);
      
      // Trigger Notifications
      await NotificationService.notifyCAPAAssigned(newCapa, 'assigned-user@example.com'); // In real app, fetch assigned user email
      
      setIsCreatingCAPA(false);
      setCapaDescription('');
      setAssignedToName('');
      setDueDate('');
      setSelectedIncidentId(undefined);
    } catch (error) {
      handleFirestoreError(error, OperationType.CREATE, 'capas');
    }
  };

  const downloadICal = (capa: CAPA) => {
    const startDate = new Date(capa.dueDate).toISOString().replace(/-|:|\.\d+/g, "");
    const endDate = new Date(new Date(capa.dueDate).getTime() + 3600000).toISOString().replace(/-|:|\.\d+/g, ""); // +1 hour
    
    const icalContent = [
      "BEGIN:VCALENDAR",
      "VERSION:2.0",
      "PRODID:-//SHEQ App//CAPA Tracker//EN",
      "BEGIN:VEVENT",
      `UID:${capa.id}@sheqapp.com`,
      `DTSTAMP:${new Date().toISOString().replace(/-|:|\.\d+/g, "")}`,
      `DTSTART:${startDate}`,
      `DTEND:${endDate}`,
      `SUMMARY:CAPA DUE: ${capa.description.slice(0, 50)}...`,
      `DESCRIPTION:CAPA Description: ${capa.description}\\n\\nRoot Cause: ${capa.rca || 'N/A'}\\n\\nAssigned To: ${capa.assignedToName}`,
      "STATUS:CONFIRMED",
      "END:VEVENT",
      "END:VCALENDAR"
    ].join("\r\n");

    const blob = new Blob([icalContent], { type: "text/calendar;charset=utf-8" });
    const link = document.createElement("a");
    link.href = window.URL.createObjectURL(blob);
    link.setAttribute("download", `CAPA_${capa.id.slice(0, 8)}.ics`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const updateCapaStatus = async (id: string, newStatus: string) => {
    try {
      await updateDoc(doc(db, 'capas', id), { status: newStatus });
    } catch (error) {
      handleFirestoreError(error, OperationType.UPDATE, `capas/${id}`);
    }
  };

  const updateIncidentStatus = async (id: string, newStatus: string) => {
    try {
      await updateDoc(doc(db, 'incidents', id), { status: newStatus });
      if (newStatus === 'Escalated') {
        setNotifications(prev => [...prev, {
          id: Date.now().toString(),
          message: `Incident ${id.slice(0, 8)} has been escalated to management.`,
          type: 'alert'
        }]);
      }
    } catch (error) {
      handleFirestoreError(error, OperationType.UPDATE, `incidents/${id}`);
    }
  };

  const getSeverityColor = (s: string) => {
    switch (s) {
      case 'Critical': return 'bg-red-100 text-red-800 border-red-200';
      case 'Major': return 'bg-orange-100 text-orange-800 border-orange-200';
      case 'Minor': return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      default: return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  const handleTabChange = (event: React.SyntheticEvent, newValue: string) => {
    setActiveTab(newValue as 'register' | 'capa' | 'analytics' | 'report');
  };

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
      <Box sx={{ display: 'flex', flexDirection: { xs: 'column', sm: 'row' }, justifyContent: 'flex-end', alignItems: { xs: 'flex-start', sm: 'center' }, gap: 2 }}>
        <Box sx={{ display: 'flex', gap: 1, width: { xs: '100%', sm: 'auto' } }}>
          <Button
            variant="outlined"
            color="inherit"
            onClick={() => setShowQRCode(!showQRCode)}
            startIcon={<Smartphone   sx={{ fontSize: 20 }} />}
            sx={{ flex: { xs: 1, sm: 'none' }, bgcolor: 'grey.100', '&:hover': { bgcolor: 'grey.200' } }}
          >
            {showQRCode ? 'Hide QR' : 'Quick Log QR'}
          </Button>
          <Button
            variant="contained"
            color="error"
            onClick={() => setActiveTab('report')}
            startIcon={<AlertOctagon   sx={{ fontSize: 20 }} />}
            sx={{ flex: { xs: 1, sm: 'none' } }}
          >
            Quick Report
          </Button>
        </Box>
      </Box>

      {showQRCode && (
        <Paper elevation={0} sx={{ p: 3, borderRadius: 2, border: 1, borderColor: 'divider', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
          <Box sx={{ bgcolor: 'grey.100', p: 2, borderRadius: 2, mb: 2 }}>
            <Box sx={{ width: 192, height: 192, bgcolor: 'background.paper', border: 8, borderColor: 'background.paper', boxShadow: 1, display: 'flex', flexWrap: 'wrap', p: 1 }}>
              {Array.from({ length: 256 }).map((_, i) => (
                <Box key={i} sx={{ width: '12.5%', height: '12.5%', bgcolor: Math.random() > 0.7 ? 'common.black' : 'common.white' }} />
              ))}
            </Box>
          </Box>
          <Typography variant="subtitle1" fontWeight="bold">Scan to Report Incident</Typography>
          <Typography variant="body2" color="text.secondary" align="center" sx={{ maxWidth: 250, mt: 0.5 }}>
            Display this QR code in common areas for frictionless reporting by any worker.
          </Typography>
        </Paper>
      )}

      {/* Notifications */}
      <Box sx={{ position: 'fixed', top: 80, right: 24, zIndex: 1300, display: 'flex', flexDirection: 'column', gap: 1 }}>
        {notifications.map(n => (
          <Paper key={n.id} elevation={3} sx={{ p: 2, borderRadius: 2, border: 1, display: 'flex', alignItems: 'center', gap: 1.5, ...(n.type === 'alert' ? { bgcolor: 'error.50', borderColor: 'error.200', color: 'error.dark' } : { bgcolor: 'success.50', borderColor: 'success.200', color: 'success.dark' }) }}>
            <AlertOctagon   sx={{ fontSize: 20 }} />
            <Typography variant="body2" fontWeight="medium">{n.message}</Typography>
            <IconButton size="small" onClick={() => setNotifications(prev => prev.filter(p => p.id !== n.id))} sx={{ ml: 1, color: n.type === 'alert' ? 'error.light' : 'success.light', '&:hover': { color: n.type === 'alert' ? 'error.main' : 'success.main' } }}>
              <X   sx={{ fontSize: 16 }} />
            </IconButton>
          </Paper>
        ))}
      </Box>

      {/* Tabs */}
      <Paper elevation={0} sx={{ borderBottom: 1, borderColor: 'divider', bgcolor: 'transparent' }}>
        <Tabs 
          value={activeTab} 
          onChange={handleTabChange}
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
            icon={<ClipboardList   sx={{ fontSize: 16 }} />} 
            iconPosition="start" 
            label="Incident Register" 
            value="register" 
          />
          <Tab 
            icon={<CheckSquare   sx={{ fontSize: 16 }} />} 
            iconPosition="start" 
            label="CAPA Tracker" 
            value="capa" 
          />
          <Tab 
            icon={<ClipboardList   sx={{ fontSize: 16 }} />} 
            iconPosition="start" 
            label="Analytics" 
            value="analytics" 
          />
          <Tab 
            icon={<AlertOctagon   sx={{ fontSize: 16 }} />} 
            iconPosition="start" 
            label="Report Incident" 
            value="report" 
            sx={{ '&.Mui-selected': { color: 'error.main' } }}
          />
        </Tabs>
      </Paper>

      {activeTab === 'analytics' && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-200">
            <h3 className="font-bold text-gray-900 mb-4">Incidents by Type</h3>
            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={Object.entries(incidents.reduce((acc, i) => ({ ...acc, [i.type]: (acc[i.type] || 0) + 1 }), {} as Record<string, number>)).map(([name, value]) => ({ name, value }))}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="name"  />
                <YAxis />
                <Tooltip />
                <Bar dataKey="value" fill="#3b82f6" />
              </BarChart>
            </ResponsiveContainer>
          </div>
          <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-200">
            <h3 className="font-bold text-gray-900 mb-4">Severity Distribution</h3>
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie data={Object.entries(incidents.reduce((acc, i) => ({ ...acc, [i.severity]: (acc[i.severity] || 0) + 1 }), {} as Record<string, number>)).map(([name, value]) => ({ name, value }))} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={80} label>
                  {Object.entries(incidents.reduce((acc, i) => ({ ...acc, [i.severity]: (acc[i.severity] || 0) + 1 }), {} as Record<string, number>)).map((_, index) => (
                    <Cell key={`cell-${index}`} fill={['#ef4444', '#f97316', '#eab308'][index % 3]} />
                  ))}
                </Pie>
                <Tooltip />
                <Legend />
              </PieChart>
            </ResponsiveContainer>
          </div>
          <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-200 md:col-span-2">
            <h3 className="font-bold text-gray-900 mb-4 flex items-center gap-2">
              <MapPin  className="text-red-600"  sx={{ fontSize: 18 }} /> Predictive Incident Heatmap (Location Analysis)
            </h3>
            <div className="h-64 bg-slate-50 rounded-lg border border-slate-200 flex items-center justify-center relative overflow-hidden">
              <div className="absolute inset-0 opacity-20">
                <div className="w-full h-full grid grid-cols-10 grid-rows-6">
                  {Array.from({ length: 60 }).map((_, i) => (
                    <div key={i} className="border border-slate-200"></div>
                  ))}
                </div>
              </div>
              <div className="relative z-10 flex flex-wrap justify-center gap-8 p-8">
                {Object.entries(incidents.reduce((acc, i) => ({ ...acc, [i.location]: (acc[i.location] || 0) + 1 }), {} as Record<string, number>))
                  .sort((a, b) => b[1] - a[1])
                  .slice(0, 5)
                  .map(([loc, count]) => (
                    <div key={loc} className="flex flex-col items-center">
                      <div 
                        className="rounded-full flex items-center justify-center text-white font-bold shadow-lg transition-transform hover:scale-110 cursor-default"
                        style={{ 
                          width: `${40 + count * 15}px`, 
                          height: `${40 + count * 15}px`,
                          backgroundColor: count > 5 ? '#ef4444' : count > 2 ? '#f97316' : '#3b82f6',
                          opacity: 0.8
                        }}
                      >
                        {count}
                      </div>
                      <span className="mt-2 text-xs font-bold text-slate-600 uppercase tracking-wider">{loc}</span>
                    </div>
                  ))}
              </div>
            </div>
            <p className="mt-4 text-xs text-slate-500 italic">
              * AI Analysis: Hotspots detected in {Object.entries(incidents.reduce((acc, i) => ({ ...acc, [i.location]: (acc[i.location] || 0) + 1 }), {} as Record<string, number>)).sort((a,b) => b[1]-a[1])[0]?.[0] || 'N/A'}. Recommend increased safety walks in these areas.
            </p>
          </div>
        </div>
      )}
      {activeTab === 'report' && (
        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-200 max-w-3xl mx-auto">
          <h2 className="text-xl font-bold text-gray-900 mb-6 border-b pb-4">New Incident Report</h2>
          <form onSubmit={handleSubmitIncident} className="space-y-6">
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Incident Title</label>
                <TextField type="text" required value={title} onChange={(e) => setTitle(e.target.value)} className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:ring-2 focus:ring-blue-500" placeholder="Brief summary of what happened" />
              </div>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Type</label>
                  <TextField select value={type} onChange={(e) => setType(e.target.value)} className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:ring-2 focus:ring-blue-500">
                    <MenuItem value="Injury">Injury</MenuItem>
                    <MenuItem value="Near Miss">Near Miss</MenuItem>
                    <MenuItem value="Property Damage">Property Damage</MenuItem>
                    <MenuItem value="Environmental">Environmental</MenuItem>
                    <MenuItem value="Hazard Observation">Hazard Observation</MenuItem>
                  </TextField>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Severity</label>
                  <TextField select value={severity} onChange={(e) => setSeverity(e.target.value)} className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:ring-2 focus:ring-blue-500">
                    <MenuItem value="Minor">Minor (First aid, minor damage)</MenuItem>
                    <MenuItem value="Major">Major (Medical treatment, significant damage)</MenuItem>
                    <MenuItem value="Critical">Critical (Fatality, severe environmental impact)</MenuItem>
                  </TextField>
                </div>
              </div>

              {/* Dynamic Smart Forms */}
              {type === 'Injury' && (
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 p-4 bg-red-50 rounded-lg border border-red-100">
                  <div>
                    <label className="block text-sm font-medium text-red-900 mb-1">Body Part Involved</label>
                    <TextField type="text" value={injuryBodyPart} onChange={e => setInjuryBodyPart(e.target.value)} className="w-full rounded-lg border border-red-200 px-4 py-2" placeholder="e.g., Left Hand" />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-red-900 mb-1">Treatment Type</label>
                    <TextField select value={injuryTreatment} onChange={e => setInjuryTreatment(e.target.value)} className="w-full rounded-lg border border-red-200 px-4 py-2">
                      <MenuItem value="">-- Select Treatment --</MenuItem>
                      <MenuItem value="First Aid">First Aid</MenuItem>
                      <MenuItem value="Medical Treatment">Medical Treatment</MenuItem>
                      <MenuItem value="Hospitalization">Hospitalization</MenuItem>
                    </TextField>
                  </div>
                </div>
              )}

              {type === 'Environmental' && (
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4 p-4 bg-emerald-50 rounded-lg border border-emerald-100">
                  <div>
                    <label className="block text-sm font-medium text-emerald-900 mb-1">Substance Spilled</label>
                    <TextField type="text" value={envSubstance} onChange={e => setEnvSubstance(e.target.value)} className="w-full rounded-lg border border-emerald-200 px-4 py-2" placeholder="e.g., Diesel" />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-emerald-900 mb-1">Volume</label>
                    <TextField type="text" value={envVolume} onChange={e => setEnvVolume(e.target.value)} className="w-full rounded-lg border border-emerald-200 px-4 py-2" placeholder="e.g., 50" />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-emerald-900 mb-1">Unit</label>
                    <TextField select value={envUnit} onChange={e => setEnvUnit(e.target.value)} className="w-full rounded-lg border border-emerald-200 px-4 py-2">
                      <MenuItem value="Liters">Liters</MenuItem>
                      <MenuItem value="Kilograms">Kilograms</MenuItem>
                      <MenuItem value="Cubic Meters">Cubic Meters</MenuItem>
                    </TextField>
                  </div>
                </div>
              )}

              {type === 'Property Damage' && (
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 p-4 bg-amber-50 rounded-lg border border-amber-100">
                  <div>
                    <label className="block text-sm font-medium text-amber-900 mb-1">Asset Involved</label>
                    <TextField type="text" value={damageAssetId} onChange={e => setDamageAssetId(e.target.value)} className="w-full rounded-lg border border-amber-200 px-4 py-2" placeholder="e.g., Forklift #12" />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-amber-900 mb-1">Estimated Damage (ZAR)</label>
                    <TextField type="number" value={damageEstimate} onChange={e => setDamageEstimate(e.target.value)} className="w-full rounded-lg border border-amber-200 px-4 py-2" />
                  </div>
                </div>
              )}

              {/* Cost Calculator */}
              <div className="bg-slate-50 p-4 rounded-lg border border-slate-200">
                <h3 className="text-sm font-bold text-slate-900 mb-3 flex items-center gap-2">
                  <BarChart3   sx={{ fontSize: 16 }} /> Cost of Incident Calculator
                </h3>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div>
                    <label className="block text-xs font-medium text-slate-500 mb-1">Direct Costs (ZAR)</label>
                    <TextField type="number" value={directCosts} onChange={e => setDirectCosts(e.target.value)} className="w-full rounded-lg border border-slate-300 px-3 py-1.5 text-sm" />
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-slate-500 mb-1">Indirect Costs (ZAR)</label>
                    <TextField type="number" value={indirectCosts} onChange={e => setIndirectCosts(e.target.value)} className="w-full rounded-lg border border-slate-300 px-3 py-1.5 text-sm" />
                  </div>
                  <div className="flex flex-col justify-end">
                    <div className="bg-white px-3 py-1.5 rounded-lg border border-slate-300 text-sm font-bold text-blue-600">
                      Total: R {(Number(directCosts) + Number(indirectCosts)).toLocaleString()}
                    </div>
                  </div>
                </div>
              </div>

              {/* BowTie Linkage */}
              <div className="bg-blue-50 p-4 rounded-lg border border-blue-100">
                <h3 className="text-sm font-bold text-blue-900 mb-3 flex items-center gap-2">
                  <Target   sx={{ fontSize: 16 }} /> BowTie Barrier Linkage
                </h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-xs font-medium text-blue-700 mb-1">Linked Hazard (BowTie)</label>
                    <TextField select value={linkedBowTieId} onChange={e => setLinkedBowTieId(e.target.value)} className="w-full rounded-lg border border-blue-200 px-3 py-1.5 text-sm">
                      <MenuItem value="">-- Select Hazard --</MenuItem>
                      {bowties.map(bt => (
                        <MenuItem key={bt.id} value={bt.id}>{bt.hazard}</MenuItem>
                      ))}
                    </TextField>
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-blue-700 mb-1">Failed Barrier</label>
                    <TextField select value={linkedBarrier} onChange={e => setLinkedBarrier(e.target.value)} className="w-full rounded-lg border border-blue-200 px-3 py-1.5 text-sm" disabled={!linkedBowTieId}>
                      <MenuItem value="">-- Select Barrier --</MenuItem>
                      {linkedBowTieId && bowties.find(b => b.id === linkedBowTieId)?.preventative.map(p => (
                        <MenuItem key={p} value={p}>{p} (Preventative)</MenuItem>
                      ))}
                      {linkedBowTieId && bowties.find(b => b.id === linkedBowTieId)?.mitigative.map(m => (
                        <MenuItem key={m} value={m}>{m} (Mitigative)</MenuItem>
                      ))}
                    </TextField>
                  </div>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Date & Time of Incident</label>
                  <TextField InputLabelProps={{ shrink: true }} type="datetime-local" required value={dateOfIncident} onChange={(e) => setDateOfIncident(e.target.value)} className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:ring-2 focus:ring-blue-500" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Involved Contractor (Optional)</label>
                  <TextField select 
                    value={selectedContractorId} 
                    onChange={(e) => setSelectedContractorId(e.target.value)} 
                    className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:ring-2 focus:ring-blue-500"
                  >
                    <MenuItem value="">-- No Contractor Involved --</MenuItem>
                    {contractors.map(c => (
                      <MenuItem key={c.id} value={c.id}>{c.companyName}</MenuItem>
                    ))}
                  </TextField>
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Location</label>
                <div className="flex gap-2">
                  <TextField type="text" required value={location} onChange={(e) => setLocation(e.target.value)} className="flex-1 rounded-lg border border-gray-300 px-4 py-2 focus:ring-2 focus:ring-blue-500" placeholder="Where did this happen?" />
                  <button type="button" onClick={handleGetLocation} className="bg-slate-100 text-slate-600 px-3 py-2 rounded-lg hover:bg-slate-200 border border-slate-200" title="Get current location">
                    <MapPin   sx={{ fontSize: 20 }} />
                  </button>
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Detailed Description</label>
                <div className="relative">
                  <textarea required value={description} onChange={(e) => setDescription(e.target.value)} className="w-full rounded-lg border border-gray-300 px-4 py-2 h-32 focus:ring-2 focus:ring-blue-500" placeholder="Describe the sequence of events, people involved, and immediate actions taken..." />
                  <div className="absolute top-2 right-2 flex gap-2">
                    <button 
                      type="button" 
                      onClick={toggleListening}
                      className={`px-3 py-1 rounded-md text-xs flex items-center gap-1 transition-colors ${isListening ? 'bg-red-600 text-white animate-pulse' : 'bg-slate-100 text-slate-600 hover:bg-slate-200'}`}
                      title={isListening ? "Stop Listening" : "Start Voice-to-Text"}
                    >
                      {isListening ? <MicOff  sx={{ fontSize: 12 }}  /> : <Mic  sx={{ fontSize: 12 }} />} {isListening ? 'Listening...' : 'Dictate'}
                    </button>
                    <button 
                      type="button" 
                      onClick={analyzeWithAI}
                      disabled={isAnalyzing || !description}
                      className="bg-blue-600 text-white px-3 py-1 rounded-md text-xs hover:bg-blue-700 disabled:bg-gray-400 flex items-center gap-1"
                    >
                      {isAnalyzing ? <Loader2 className="animate-spin"  sx={{ fontSize: 12 }} /> : <Sparkles  sx={{ fontSize: 12 }} />} AI Analyze
                    </button>
                  </div>
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Attach Photo (Optional)</label>
                <div className="border-2 border-dashed border-gray-300 rounded-lg p-6 flex flex-col items-center justify-center text-gray-500 bg-gray-50 relative">
                  {isAnalyzingPhoto && (
                    <div className="absolute inset-0 bg-white/80 backdrop-blur-sm flex flex-col items-center justify-center z-10">
                      <Loader2 className="animate-spin text-blue-600 mb-2"   sx={{ fontSize: 32 }} />
                      <p className="text-sm font-bold text-blue-600">AI Analyzing Photo...</p>
                    </div>
                  )}
                  <Camera  className="mb-2 text-gray-400"  sx={{ fontSize: 32 }} />
                  <p className="text-sm">{photoFile ? photoFile.name : "Click to upload or drag and drop"}</p>
                  <input type="file" accept="image/*" onChange={handlePhotoChange} className="mt-2 text-sm" />
                </div>
              </div>
            </div>

            <div className="flex items-center gap-2 p-4 bg-slate-50 rounded-lg border border-slate-200">
              <input 
                type="checkbox" 
                id="anonymous" 
                checked={isAnonymous} 
                onChange={e => setIsAnonymous(e.target.checked)}
                className="w-4 h-4 text-blue-600 rounded border-gray-300 focus:ring-blue-500"
              />
              <label htmlFor="anonymous" className="text-sm font-medium text-gray-700 flex items-center gap-2">
                <Unlock  className="text-amber-600"  sx={{ fontSize: 16 }} /> Report Anonymously (Whistleblower Portal)
              </label>
            </div>

            <div className="flex justify-end pt-4 border-t border-gray-100">
              <button type="submit" className="bg-red-600 text-white px-8 py-3 rounded-lg hover:bg-red-700 font-bold text-lg shadow-sm transition-colors">
                Submit Report
              </button>
            </div>
          </form>
        </div>
      )}

      {activeTab === 'register' && (
        <div className="bg-white shadow-sm rounded-xl border border-gray-200 overflow-hidden">
          {loading ? (
            <div className="p-8 text-center text-gray-500">Loading incidents...</div>
          ) : incidents.length === 0 ? (
            <div className="p-8 text-center text-gray-500">No incidents reported.</div>
          ) : (
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Incident</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Type & Severity</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date</th>
                    <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {incidents.map((incident) => (
                    <tr key={incident.id} className="hover:bg-gray-50">
                      <td className="px-6 py-4">
                        <div className="font-medium text-gray-900">{incident.title}</div>
                        <div className="text-xs text-gray-500 flex items-center gap-1 mt-1"><MapPin  sx={{ fontSize: 12 }} /> {incident.location}</div>
                        {incident.contractorName && (
                          <div className="text-xs text-blue-600 font-medium mt-1 flex items-center gap-1">
                            <ClipboardList   sx={{ fontSize: 12 }} /> Contractor: {incident.contractorName}
                          </div>
                        )}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-gray-900">{incident.type}</div>
                        <span className={`mt-1 px-2 py-0.5 inline-flex text-xs leading-5 font-semibold rounded border ${getSeverityColor(incident.severity)}`}>
                          {incident.severity}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <TextField select 
                          value={incident.status}
                          onChange={(e) => updateIncidentStatus(incident.id, e.target.value)}
                          className={`text-sm rounded border-gray-300 focus:ring-blue-500 ${
                            incident.status === 'Open' ? 'text-red-600 font-medium' : 
                            incident.status === 'Investigating' ? 'text-amber-600 font-medium' : 
                            incident.status === 'Escalated' ? 'text-purple-600 font-bold' : 'text-green-600 font-medium'
                          }`}
                        >
                          <MenuItem value="Open">Open</MenuItem>
                          <MenuItem value="Investigating">Investigating</MenuItem>
                          <MenuItem value="Escalated">Escalated</MenuItem>
                          <MenuItem value="Closed">Closed</MenuItem>
                        </TextField>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {new Date(incident.dateOfIncident).toLocaleDateString()}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                        <div className="flex justify-end gap-2">
                          <button 
                            onClick={() => setViewingIncident(incident)}
                            className="text-slate-600 hover:text-slate-900 bg-slate-100 px-3 py-1 rounded flex items-center gap-1"
                            title="360° View"
                          >
                            <Eye  sx={{ fontSize: 14 }} /> 360° View
                          </button>
                          <button 
                            onClick={() => generateLessonsLearned(incident)}
                            disabled={isGeneratingLessons}
                            className="text-slate-600 hover:text-slate-900 bg-slate-100 px-3 py-1 rounded flex items-center gap-1"
                            title="Generate Lessons Learned toolbox talk"
                          >
                            {isGeneratingLessons ? <Loader2 className="animate-spin"  sx={{ fontSize: 14 }} /> : <Sparkles  sx={{ fontSize: 14 }} />} Lessons
                          </button>
                          <button 
                            onClick={() => {
                              setSelectedIncidentId(incident.id);
                              setIsCreatingCAPA(true);
                              setActiveTab('capa');
                            }}
                            className="text-blue-600 hover:text-blue-900 bg-blue-50 px-3 py-1 rounded"
                          >
                            + CAPA
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {activeTab === 'capa' && (
        <div className="space-y-6">
          <div className="flex justify-end">
            <button
              onClick={() => { setSelectedIncidentId(undefined); setIsCreatingCAPA(true); }}
              className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 flex items-center gap-2"
            >
              <Plus   sx={{ fontSize: 20 }} /> New CAPA
            </button>
          </div>

          {isCreatingCAPA && (
            <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-200 mb-6">
              <div className="flex justify-between items-center mb-4">
                <h2 className="text-lg font-bold">Create Corrective/Preventative Action</h2>
                <button onClick={() => setIsCreatingCAPA(false)} className="text-gray-400 hover:text-gray-600"><X   sx={{ fontSize: 24 }} /></button>
              </div>
              <form onSubmit={handleSubmitCAPA} className="space-y-4">
                {selectedIncidentId && (
                  <div className="p-3 bg-blue-50 text-blue-800 rounded-lg text-sm border border-blue-100 flex items-center gap-2">
                    <AlertOctagon   sx={{ fontSize: 16 }} /> Linking CAPA to Incident ID: {selectedIncidentId.slice(0, 8)}...
                  </div>
                )}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Action Description</label>
                  <textarea required value={capaDescription} onChange={(e) => setCapaDescription(e.target.value)} className="w-full rounded-lg border border-gray-300 px-4 py-2 h-24 focus:ring-2 focus:ring-blue-500" placeholder="What specific action needs to be taken?" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Root Cause Analysis (RCA)</label>
                  <div className="relative">
                    <textarea value={rca} onChange={(e) => setRca(e.target.value)} className="w-full rounded-lg border border-gray-300 px-4 py-2 h-32 focus:ring-2 focus:ring-blue-500" placeholder="Describe the root cause (e.g., 5 Whys)..." />
                    <button 
                      type="button" 
                      onClick={generateAIRCA}
                      disabled={isGeneratingRCA || (!selectedIncidentId && !capaDescription)}
                      className="absolute top-2 right-2 bg-purple-600 text-white px-3 py-1 rounded-md text-xs hover:bg-purple-700 disabled:bg-gray-400 flex items-center gap-1"
                    >
                      {isGeneratingRCA ? <Loader2 className="animate-spin"  sx={{ fontSize: 12 }} /> : <Sparkles  sx={{ fontSize: 12 }} />} AI RCA (5 Whys)
                    </button>
                  </div>
                </div>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Assign To (Name)</label>
                    <div className="relative">
                      <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                        <User  className="text-gray-400"  sx={{ fontSize: 16 }} />
                      </div>
                      <TextField type="text" required value={assignedToName} onChange={(e) => setAssignedToName(e.target.value)} className="w-full rounded-lg border border-gray-300 pl-10 pr-4 py-2 focus:ring-2 focus:ring-blue-500" placeholder="e.g. John Doe" />
                    </div>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Due Date</label>
                    <TextField InputLabelProps={{ shrink: true }} type="date" required value={dueDate} onChange={(e) => setDueDate(e.target.value)} className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:ring-2 focus:ring-blue-500" />
                  </div>
                </div>
                <div className="flex justify-end pt-4">
                  <button type="submit" className="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700 font-medium">Save Action</button>
                </div>
              </form>
            </div>
          )}

          {/* Kanban Board for CAPAs */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {['Open', 'In Progress', 'Closed'].map((statusCol) => (
              <div key={statusCol} className="bg-gray-50 rounded-xl p-4 border border-gray-200 flex flex-col h-full min-h-[400px]">
                <div className="flex justify-between items-center mb-4">
                  <h3 className="font-bold text-gray-700">{statusCol}</h3>
                  <span className="bg-gray-200 text-gray-700 text-xs font-bold px-2 py-1 rounded-full">
                    {capas.filter(c => c.status === statusCol).length}
                  </span>
                </div>
                
                <div className="space-y-3 flex-1">
                  {capas.filter(c => c.status === statusCol).map(capa => (
                    <div key={capa.id} className="bg-white p-4 rounded-lg shadow-sm border border-gray-200 hover:shadow-md transition-shadow">
                      <p className="text-sm font-medium text-gray-900 mb-3">{capa.description}</p>
                      {capa.rca && (
                        <div className="bg-amber-50 p-2 rounded text-xs text-amber-800 mb-3">
                          <span className="font-bold">RCA:</span> {capa.rca}
                        </div>
                      )}
                      <div className="flex items-center justify-between text-xs text-gray-500 mb-3">
                        <div className="flex items-center gap-1"><User  sx={{ fontSize: 14 }} /> {capa.assignedToName}</div>
                        <button 
                          onClick={() => downloadICal(capa)}
                          className={`flex items-center gap-1 hover:text-blue-600 transition-colors ${new Date(capa.dueDate) < new Date() && capa.status !== 'Closed' ? 'text-red-600 font-bold' : ''}`}
                          title="Download to Calendar"
                        >
                          <Clock  sx={{ fontSize: 14 }} /> {new Date(capa.dueDate).toLocaleDateString()}
                        </button>
                      </div>
                      
                      <div className="flex gap-2 mt-2 pt-3 border-t border-gray-100">
                        {statusCol !== 'Open' && (
                          <button onClick={() => updateCapaStatus(capa.id, 'Open')} className="flex-1 text-xs bg-gray-100 hover:bg-gray-200 text-gray-700 py-1.5 rounded">To Open</button>
                        )}
                        {statusCol !== 'In Progress' && (
                          <button onClick={() => updateCapaStatus(capa.id, 'In Progress')} className="flex-1 text-xs bg-blue-50 hover:bg-blue-100 text-blue-700 py-1.5 rounded">To Progress</button>
                        )}
                        {statusCol !== 'Closed' && (
                          <button onClick={() => updateCapaStatus(capa.id, 'Closed')} className="flex-1 text-xs bg-green-50 hover:bg-green-100 text-green-700 py-1.5 rounded">To Closed</button>
                        )}
                      </div>
                    </div>
                  ))}
                  {capas.filter(c => c.status === statusCol).length === 0 && (
                    <div className="h-24 border-2 border-dashed border-gray-200 rounded-lg flex items-center justify-center text-gray-400 text-sm">
                      No actions
                    </div>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
      {/* Deep View Modal */}
      {viewingIncident && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-slate-50 rounded-2xl shadow-2xl w-full max-w-5xl max-h-[90vh] overflow-hidden flex flex-col border border-slate-200">
            {/* Header */}
            <div className="bg-white p-6 border-b border-slate-200 flex justify-between items-start shrink-0">
              <div className="flex items-center gap-4">
                <div className={`w-16 h-16 rounded-2xl flex items-center justify-center ${
                  viewingIncident.severity === 'Critical' ? 'bg-red-100 text-red-600' :
                  viewingIncident.severity === 'Major' ? 'bg-orange-100 text-orange-600' :
                  'bg-yellow-100 text-yellow-600'
                }`}>
                  <AlertOctagon   sx={{ fontSize: 32 }} />
                </div>
                <div>
                  <h2 className="text-2xl font-black text-slate-900 tracking-tight">{viewingIncident.title}</h2>
                  <div className="flex items-center gap-3 mt-1 text-sm text-slate-500 font-medium">
                    <span className="font-mono bg-slate-100 px-2 py-0.5 rounded">{viewingIncident.id.slice(0, 8).toUpperCase()}</span>
                    <span>•</span>
                    <span className="flex items-center gap-1">
                      <Clock   sx={{ fontSize: 14 }} /> {new Date(viewingIncident.dateOfIncident).toLocaleString()}
                    </span>
                  </div>
                </div>
              </div>
              <button 
                onClick={() => setViewingIncident(null)}
                className="p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded-xl transition-colors"
              >
                <X   sx={{ fontSize: 24 }} />
              </button>
            </div>

            {/* Content */}
            <div className="flex-1 overflow-y-auto p-6">
              <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                
                {/* Left Column: Quick Stats & Status */}
                <div className="space-y-6">
                  <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-sm">
                    <h3 className="text-sm font-bold text-slate-900 uppercase tracking-wider mb-4">Incident Details</h3>
                    <div className="space-y-4">
                      <div>
                        <p className="text-xs text-slate-500 font-medium uppercase tracking-wider mb-1">Type & Severity</p>
                        <div className="flex items-center gap-2">
                          <span className="font-bold text-slate-900">{viewingIncident.type}</span>
                          <span className={`px-2 py-0.5 rounded text-xs font-bold border ${getSeverityColor(viewingIncident.severity)}`}>
                            {viewingIncident.severity}
                          </span>
                        </div>
                      </div>
                      <div>
                        <p className="text-xs text-slate-500 font-medium uppercase tracking-wider mb-1">Status</p>
                        <span className={`px-2 py-0.5 rounded text-xs font-bold border ${
                          viewingIncident.status === 'Open' ? 'bg-red-50 text-red-700 border-red-200' :
                          viewingIncident.status === 'Investigating' ? 'bg-amber-50 text-amber-700 border-amber-200' :
                          viewingIncident.status === 'Escalated' ? 'bg-purple-50 text-purple-700 border-purple-200' :
                          'bg-green-50 text-green-700 border-green-200'
                        }`}>
                          {viewingIncident.status}
                        </span>
                      </div>
                      <div>
                        <p className="text-xs text-slate-500 font-medium uppercase tracking-wider mb-1">Location</p>
                        <p className="text-sm font-medium text-slate-900 flex items-center gap-1">
                          <MapPin  className="text-slate-400"  sx={{ fontSize: 14 }} /> {viewingIncident.location}
                        </p>
                      </div>
                      <div>
                        <p className="text-xs text-slate-500 font-medium uppercase tracking-wider mb-1">Reporter</p>
                        <p className="text-sm font-medium text-slate-900 flex items-center gap-1">
                          <User  className="text-slate-400"  sx={{ fontSize: 14 }} /> {viewingIncident.reporterName}
                        </p>
                      </div>
                      {viewingIncident.contractorName && (
                        <div>
                          <p className="text-xs text-slate-500 font-medium uppercase tracking-wider mb-1">Contractor</p>
                          <p className="text-sm font-medium text-blue-600 flex items-center gap-1">
                            <ClipboardList   sx={{ fontSize: 14 }} /> {viewingIncident.contractorName}
                          </p>
                        </div>
                      )}
                    </div>
                  </div>

                  <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-sm">
                    <h3 className="text-sm font-bold text-slate-900 uppercase tracking-wider mb-4 flex items-center gap-2">
                      <BarChart3  className="text-blue-600"  sx={{ fontSize: 16 }} /> Cost Impact
                    </h3>
                    <div className="space-y-3">
                      <div className="flex justify-between items-center text-sm">
                        <span className="text-slate-500">Direct Costs</span>
                        <span className="font-medium text-slate-900">R {viewingIncident.directCosts?.toLocaleString() || 0}</span>
                      </div>
                      <div className="flex justify-between items-center text-sm">
                        <span className="text-slate-500">Indirect Costs</span>
                        <span className="font-medium text-slate-900">R {viewingIncident.indirectCosts?.toLocaleString() || 0}</span>
                      </div>
                      <div className="pt-3 border-t border-slate-100 flex justify-between items-center">
                        <span className="text-sm font-bold text-slate-900">Total Impact</span>
                        <span className="font-black text-blue-600">R {viewingIncident.totalCost?.toLocaleString() || 0}</span>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Right Column: Description & Dynamic Fields */}
                <div className="lg:col-span-2 space-y-6">
                  <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-sm">
                    <h3 className="text-sm font-bold text-slate-900 uppercase tracking-wider mb-4">Incident Description</h3>
                    <div className="prose prose-sm max-w-none text-slate-700 whitespace-pre-wrap">
                      {viewingIncident.description}
                    </div>
                    {viewingIncident.photoUrl && (
                      <div className="mt-4">
                        <h4 className="text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">Attached Evidence</h4>
                        <img src={viewingIncident.photoUrl} alt="Incident Evidence" className="rounded-lg border border-slate-200 max-h-64 object-cover" />
                      </div>
                    )}
                  </div>

                  {/* Dynamic Fields Section */}
                  {(viewingIncident.injuryDetails || viewingIncident.environmentalDetails || viewingIncident.propertyDamageDetails) && (
                    <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-sm">
                      <h3 className="text-sm font-bold text-slate-900 uppercase tracking-wider mb-4">Specific Details</h3>
                      
                      {viewingIncident.injuryDetails && (
                        <div className="grid grid-cols-2 gap-4 p-4 bg-red-50 rounded-lg border border-red-100">
                          <div>
                            <p className="text-xs font-bold text-red-800 uppercase tracking-wider mb-1">Body Part</p>
                            <p className="font-medium text-red-900">{viewingIncident.injuryDetails.bodyPart}</p>
                          </div>
                          <div>
                            <p className="text-xs font-bold text-red-800 uppercase tracking-wider mb-1">Treatment</p>
                            <p className="font-medium text-red-900">{viewingIncident.injuryDetails.treatmentType}</p>
                          </div>
                        </div>
                      )}

                      {viewingIncident.environmentalDetails && (
                        <div className="grid grid-cols-3 gap-4 p-4 bg-emerald-50 rounded-lg border border-emerald-100">
                          <div>
                            <p className="text-xs font-bold text-emerald-800 uppercase tracking-wider mb-1">Substance</p>
                            <p className="font-medium text-emerald-900">{viewingIncident.environmentalDetails.substance}</p>
                          </div>
                          <div>
                            <p className="text-xs font-bold text-emerald-800 uppercase tracking-wider mb-1">Volume</p>
                            <p className="font-medium text-emerald-900">{viewingIncident.environmentalDetails.volume}</p>
                          </div>
                          <div>
                            <p className="text-xs font-bold text-emerald-800 uppercase tracking-wider mb-1">Unit</p>
                            <p className="font-medium text-emerald-900">{viewingIncident.environmentalDetails.unit}</p>
                          </div>
                        </div>
                      )}

                      {viewingIncident.propertyDamageDetails && (
                        <div className="grid grid-cols-2 gap-4 p-4 bg-amber-50 rounded-lg border border-amber-100">
                          <div>
                            <p className="text-xs font-bold text-amber-800 uppercase tracking-wider mb-1">Asset ID</p>
                            <p className="font-medium text-amber-900">{viewingIncident.propertyDamageDetails.assetId}</p>
                          </div>
                          <div>
                            <p className="text-xs font-bold text-amber-800 uppercase tracking-wider mb-1">Est. Damage</p>
                            <p className="font-medium text-amber-900">R {viewingIncident.propertyDamageDetails.estimatedDamage.toLocaleString()}</p>
                          </div>
                        </div>
                      )}
                    </div>
                  )}

                  {/* BowTie Linkage */}
                  {(viewingIncident.linkedBowTieId || viewingIncident.linkedBarrier) && (
                    <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-sm">
                      <h3 className="text-sm font-bold text-slate-900 uppercase tracking-wider mb-4 flex items-center gap-2">
                        <Target  className="text-blue-600"  sx={{ fontSize: 16 }} /> BowTie Analysis Linkage
                      </h3>
                      <div className="p-4 bg-blue-50 rounded-lg border border-blue-100 space-y-3">
                        {viewingIncident.linkedBowTieId && (
                          <div>
                            <p className="text-xs font-bold text-blue-800 uppercase tracking-wider mb-1">Linked Hazard</p>
                            <p className="font-medium text-blue-900">{bowties.find(b => b.id === viewingIncident.linkedBowTieId)?.hazard || 'Unknown Hazard'}</p>
                          </div>
                        )}
                        {viewingIncident.linkedBarrier && (
                          <div>
                            <p className="text-xs font-bold text-blue-800 uppercase tracking-wider mb-1">Failed Barrier</p>
                            <p className="font-medium text-blue-900">{viewingIncident.linkedBarrier}</p>
                          </div>
                        )}
                      </div>
                    </div>
                  )}

                </div>
              </div>
            </div>
          </div>
        </div>
      )}

    </Box>
  );
}
