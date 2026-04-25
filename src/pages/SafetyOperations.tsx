import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy, doc, updateDoc, where } from 'firebase/firestore';
import { db, auth, handleFirestoreError } from '../lib/firebase';
import { useAuth } from '../contexts/AuthContext';
import { 
  Box, 
  Typography, 
  Button, 
  Tabs, 
  Tab, 
  Card,
  LinearProgress
} from '@mui/material';

// Icons
import ShieldIcon from '@mui/icons-material/Shield';
import AlertOctagonIcon from '@mui/icons-material/ReportProblem';
import VisibilityIcon from '@mui/icons-material/Visibility';
import AssignmentTurnedInIcon from '@mui/icons-material/AssignmentTurnedIn';
import PhoneInTalkIcon from '@mui/icons-material/PhoneInTalk';
import ChatIcon from '@mui/icons-material/Chat';
import BuildIcon from '@mui/icons-material/Build';
import WarningAmberIcon from '@mui/icons-material/WarningAmber';
import EngineeringIcon from '@mui/icons-material/Engineering';
import SecurityIcon from '@mui/icons-material/Security';
import TrackChangesIcon from '@mui/icons-material/TrackChanges';
import EmojiEventsIcon from '@mui/icons-material/EmojiEvents';
import AssessmentIcon from '@mui/icons-material/Assessment';

import BehavioralSafety from './BehavioralSafety';
import PermitToWork from './PermitToWork';
import EmergencyResponse from './EmergencyResponse';
import EquipmentManagement from './EquipmentManagement';
import ContractorManagement from './ContractorManagement';
import ObservationLog from '../components/ObservationLog';
import HazardRegister from '../components/HazardRegister';
import PPEComplianceTracker from '../components/PPEComplianceTracker';
import SafetyCultureSurvey from '../components/SafetyCultureSurvey';
import SafetyRewards from '../components/SafetyRewards';
import SafetyAnalytics from '../components/SafetyAnalytics';

export default function SafetyOperations() {
  const { profile } = useAuth();
  const [activeTab, setActiveTab] = useState('behavioral');
  const [incidents, setIncidents] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!profile?.siteId) return;
    
    const qIncidents = query(collection(db, 'incidents'), where('siteId', '==', profile.siteId), orderBy('createdAt', 'desc'));
    const unsubIncidents = onSnapshot(qIncidents, (snapshot) => {
      setIncidents(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
      setLoading(false);
    }, (error) => handleFirestoreError(error, 'list' as any, 'incidents'));

    return () => unsubIncidents();
  }, [profile?.siteId]);

  const tabs = [
    { id: 'behavioral', label: 'Behavioral Safety', icon: VisibilityIcon },
    { id: 'permits', label: 'Permit to Work', icon: AssignmentTurnedInIcon },
    { id: 'emergency', label: 'Emergency Response', icon: PhoneInTalkIcon },
    { id: 'observations', label: 'Observations', icon: ChatIcon },
    { id: 'equipment', label: 'Plant & Equipment', icon: BuildIcon },
    { id: 'hazards', label: 'Hazard Register', icon: WarningAmberIcon },
    { id: 'contractors', label: 'Contractor Safety', icon: EngineeringIcon },
    { id: 'ppe', label: 'PPE Compliance', icon: SecurityIcon },
    { id: 'culture', label: 'Safety Culture', icon: TrackChangesIcon },
    { id: 'gamification', label: 'Safety Rewards', icon: EmojiEventsIcon },
    { id: 'analytics', label: 'Safety Analytics', icon: AssessmentIcon },
  ];

  return (
    <Box sx={{ maxWidth: 'xl', mx: 'auto', p: { xs: 2, md: 3 } }}>
      <Box sx={{ display: 'flex', flexDirection: { xs: 'column', md: 'row' }, alignItems: { md: 'center' }, justifyContent: 'space-between', gap: 2, mb: 4 }}>
        <Box>
          <Typography variant="h5" fontWeight={700} sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            Safety & Operations <ShieldIcon color="error" />
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Unified safety management, behavioral observations, and operational controls.
          </Typography>
        </Box>
        <Button 
          variant="contained" 
          color="error" 
          startIcon={<AlertOctagonIcon />}
          sx={{ boxShadow: 1 }}
        >
          Quick Report
        </Button>
      </Box>

      {/* Tabs */}
      <Box sx={{ borderBottom: 1, borderColor: 'divider', mb: 3 }}>
        <Tabs 
          value={activeTab} 
          onChange={(_, newValue) => setActiveTab(newValue)} 
          variant="scrollable"
          scrollButtons="auto"
          sx={{
            '& .MuiTabs-indicator': { backgroundColor: 'error.main' },
            '& .MuiTab-root.Mui-selected': { color: 'error.main' }
          }}
        >
          {tabs.map(tab => (
            <Tab 
              key={tab.id}
              icon={<tab.icon fontSize="small" />} 
              iconPosition="start" 
              label={tab.label} 
              value={tab.id} 
              sx={{ fontWeight: 600, minHeight: 64 }} 
            />
          ))}
        </Tabs>
      </Box>

      <Card elevation={0} sx={{ border: '1px solid', borderColor: 'divider', borderRadius: 2, minHeight: 600 }}>
        {activeTab === 'behavioral' && <Box sx={{ p: 3 }}><BehavioralSafety /></Box>}
        {activeTab === 'permits' && <Box sx={{ p: 3 }}><PermitToWork /></Box>}
        {activeTab === 'emergency' && <Box sx={{ p: 3 }}><EmergencyResponse /></Box>}
        {activeTab === 'observations' && <Box sx={{ p: 3 }}><ObservationLog /></Box>}
        {activeTab === 'equipment' && <Box sx={{ p: 3 }}><EquipmentManagement /></Box>}
        {activeTab === 'hazards' && <Box sx={{ p: 3 }}><HazardRegister /></Box>}
        {activeTab === 'contractors' && <Box sx={{ p: 3 }}><ContractorManagement /></Box>}
        {activeTab === 'ppe' && <Box sx={{ p: 3 }}><PPEComplianceTracker /></Box>}
        {activeTab === 'culture' && <Box sx={{ p: 3 }}><SafetyCultureSurvey /></Box>}
        {activeTab === 'gamification' && <Box sx={{ p: 3 }}><SafetyRewards /></Box>}
        {activeTab === 'analytics' && <Box sx={{ p: 3 }}><SafetyAnalytics /></Box>}
      </Card>
    </Box>
  );
}
