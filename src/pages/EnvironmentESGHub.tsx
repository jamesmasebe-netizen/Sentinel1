import React, { useState } from 'react';
import { Box, Typography, Tabs, Tab, Paper } from '@mui/material';
import NaturePeopleIcon from '@mui/icons-material/NaturePeople';
import AssessmentIcon from '@mui/icons-material/Assessment';

import EnvironmentalManagement from './EnvironmentalManagement';
import ESGReporting from './ESGReporting';

export default function EnvironmentESGHub() {
  const [activeTab, setActiveTab] = useState<'management' | 'esg'>('management');

  const handleTabChange = (event: React.SyntheticEvent, newValue: 'management' | 'esg') => {
    setActiveTab(newValue);
  };

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
      <Box sx={{ display: 'flex', flexDirection: { xs: 'column', sm: 'row' }, justifyContent: 'space-between', alignItems: { xs: 'flex-start', sm: 'center' }, gap: 2 }}>
        <Box>
          <Typography variant="h5" sx={{ fontWeight: 900, color: 'text.primary', letterSpacing: '-0.02em', display: 'flex', alignItems: 'center', gap: 1 }}>
            <NaturePeopleIcon color="success" /> Environment & ESG Hub
          </Typography>
          <Typography variant="subtitle2" sx={{ color: 'text.secondary', fontWeight: 500, mt: 0.5 }}>
            Integrated environmental management and ESG performance tracking.
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
          textColor="secondary"
          indicatorColor="secondary"
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
            icon={<NaturePeopleIcon fontSize="small" />} 
            iconPosition="start" 
            label="Environmental Management" 
            value="management" 
          />
          <Tab 
            icon={<AssessmentIcon fontSize="small" />} 
            iconPosition="start" 
            label="ESG Reporting" 
            value="esg" 
          />
        </Tabs>
      </Paper>

      {/* Content Area */}
      <Box sx={{ mt: 1 }}>
        {activeTab === 'management' && <EnvironmentalManagement />}
        {activeTab === 'esg' && <ESGReporting />}
      </Box>
    </Box>
  );
}
