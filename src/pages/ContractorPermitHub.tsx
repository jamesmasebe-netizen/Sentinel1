import React, { useState } from 'react';
import { Box, Typography, Tabs, Tab, Paper } from '@mui/material';
import EngineeringIcon from '@mui/icons-material/Engineering';
import AssignmentTurnedInIcon from '@mui/icons-material/AssignmentTurnedIn';

import ContractorManagement from './ContractorManagement';
import PermitToWorkModule from './PermitToWork';

export default function ContractorPermitHub() {
  const [activeTab, setActiveTab] = useState<'contractors' | 'permits'>('contractors');

  const handleTabChange = (event: React.SyntheticEvent, newValue: 'contractors' | 'permits') => {
    setActiveTab(newValue);
  };

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
      <Box sx={{ display: 'flex', flexDirection: { xs: 'column', sm: 'row' }, justifyContent: 'space-between', alignItems: { xs: 'flex-start', sm: 'center' }, gap: 2 }}>
        <Box>
          <Typography variant="h5" sx={{ fontWeight: 900, color: 'text.primary', letterSpacing: '-0.02em', display: 'flex', alignItems: 'center', gap: 1 }}>
             Contractor & Permit Control Tower <EngineeringIcon color="primary" />
          </Typography>
          <Typography variant="subtitle2" sx={{ color: 'text.secondary', fontWeight: 500, mt: 0.5 }}>
            Integrated contractor management and high-risk work permit control.
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
          textColor="primary"
          indicatorColor="primary"
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
            icon={<EngineeringIcon fontSize="small" />} 
            iconPosition="start" 
            label="Contractor Management" 
            value="contractors" 
          />
          <Tab 
            icon={<AssignmentTurnedInIcon fontSize="small" />} 
            iconPosition="start" 
            label="Permit to Work" 
            value="permits" 
          />
        </Tabs>
      </Paper>

      {/* Content Area */}
      <Box sx={{ mt: 1 }}>
        {activeTab === 'contractors' && <ContractorManagement />}
        {activeTab === 'permits' && <PermitToWorkModule />}
      </Box>
    </Box>
  );
}
