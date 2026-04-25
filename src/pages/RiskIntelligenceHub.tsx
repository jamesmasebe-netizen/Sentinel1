import React, { useState } from 'react';
import { Box, Typography, Tabs, Tab, Paper } from '@mui/material';
import DashboardIcon from '@mui/icons-material/Dashboard';
import SecurityIcon from '@mui/icons-material/Security';
import FlashOnIcon from '@mui/icons-material/FlashOn';
import ReportProblemIcon from '@mui/icons-material/ReportProblem';

// Import existing components
import RiskDashboard from './RiskDashboard';
import RiskManagement from './RiskManagement';
import DynamicRiskAssessment from './DynamicRiskAssessment';
import IncidentsCAPA from './IncidentsCAPA';

export default function RiskIntelligenceHub() {
  const [activeTab, setActiveTab] = useState<'dashboard' | 'hira' | 'dra' | 'incidents'>('dashboard');

  const handleTabChange = (event: React.SyntheticEvent, newValue: 'dashboard' | 'hira' | 'dra' | 'incidents') => {
    setActiveTab(newValue);
  };

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
      <Box sx={{ display: 'flex', flexDirection: { xs: 'column', sm: 'row' }, justifyContent: 'space-between', alignItems: { xs: 'flex-start', sm: 'center' }, gap: 2 }}>
        <Box>
          <Typography variant="h5" sx={{ fontWeight: 900, color: 'text.primary', letterSpacing: '-0.02em' }}>
            Safety & Risk Intelligence Core
          </Typography>
          <Typography variant="subtitle2" sx={{ color: 'text.secondary', fontWeight: 500, mt: 0.5 }}>
            Unified command center for hazards, assessments, and incidents
          </Typography>
        </Box>
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
            icon={<DashboardIcon fontSize="small" />} 
            iconPosition="start" 
            label="Command Center" 
            value="dashboard" 
          />
          <Tab 
            icon={<SecurityIcon fontSize="small" />} 
            iconPosition="start" 
            label="Baseline Risk (HIRA)" 
            value="hira" 
          />
          <Tab 
            icon={<FlashOnIcon fontSize="small" />} 
            iconPosition="start" 
            label="Dynamic Risk (DRA)" 
            value="dra" 
          />
          <Tab 
            icon={<ReportProblemIcon fontSize="small" />} 
            iconPosition="start" 
            label="Incidents & CAPA" 
            value="incidents" 
          />
        </Tabs>
      </Paper>

      {/* Content Area */}
      <Box sx={{ mt: 1 }}>
        {activeTab === 'dashboard' && <RiskDashboard />}
        {activeTab === 'hira' && <RiskManagement />}
        {activeTab === 'dra' && <DynamicRiskAssessment />}
        {activeTab === 'incidents' && <IncidentsCAPA />}
      </Box>
    </Box>
  );
}
