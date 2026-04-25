import React from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  Box, 
  Typography, 
  Grid, 
  Card, 
  CardContent, 
  CardActionArea,
  Chip,
  Avatar,
  Stack
} from '@mui/material';

import BusinessIcon from '@mui/icons-material/Business';
import BuildIcon from '@mui/icons-material/Build';
import GroupsIcon from '@mui/icons-material/Groups';
import GppMaybeIcon from '@mui/icons-material/GppMaybe';
import ShowChartIcon from '@mui/icons-material/ShowChart';
import CallMadeIcon from '@mui/icons-material/CallMade';
import TrendingDownIcon from '@mui/icons-material/TrendingDown';
import AccessTimeIcon from '@mui/icons-material/AccessTime';
import NatureIcon from '@mui/icons-material/Nature';

export default function ExecutiveBentoDashboard() {
  const navigate = useNavigate();

  return (
    <Box sx={{ flexGrow: 1, p: 1 }}>
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" component="h1" sx={{ fontWeight: '500', color: 'text.primary', letterSpacing: '-0.5px' }}>
          Enterprise Command Center
        </Typography>
        <Typography variant="subtitle1" sx={{ color: 'text.secondary', mt: 0.5 }}>
          Real-time portfolio intelligence and strategic oversight.
        </Typography>
      </Box>

      <Grid container spacing={3}>
        {/* Metric 1: Financials */}
        <Grid item xs={12} md={6}>
          <Card elevation={2} sx={{ height: '100%', borderRadius: 2, bgcolor: '#1e293b', color: 'white' }}>
            <CardActionArea onClick={() => navigate('/financials')} sx={{ height: '100%', p: 2 }}>
              <Box sx={{ position: 'absolute', top: -20, right: -20, opacity: 0.15, transform: 'scale(1.5)' }}>
                <ShowChartIcon sx={{ fontSize: 140 }} />
              </Box>
              <CardContent sx={{ height: '100%', display: 'flex', flexDirection: 'column', justifyContent: 'space-between', position: 'relative', zIndex: 1, p: 1 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <Typography variant="overline" sx={{ fontWeight: 'bold', color: '#94a3b8', letterSpacing: 1.5 }}>
                    YTD OPEX & CAPEX
                  </Typography>
                  <CallMadeIcon sx={{ color: '#94a3b8' }} fontSize="small" />
                </Box>
                <Box sx={{ mt: 4 }}>
                  <Typography variant="h3" sx={{ fontWeight: 700, mb: 1, letterSpacing: '-1px' }}>
                    $14.2M
                  </Typography>
                  <Typography variant="body2" sx={{ color: '#34d399', display: 'flex', alignItems: 'center', gap: 0.5, fontWeight: 500 }}>
                    <TrendingDownIcon fontSize="small" /> 2.1% under budget
                  </Typography>
                </Box>
              </CardContent>
            </CardActionArea>
          </Card>
        </Grid>

        {/* Metric 2: Global Portfolio */}
        <Grid item xs={12} md={3}>
          <Card elevation={3} sx={{ height: '100%', borderRadius: 2, bgcolor: '#1976d2', color: 'white' }}>
            <CardActionArea onClick={() => navigate('/portfolio')} sx={{ height: '100%', p: 2 }}>
              <Box sx={{ position: 'absolute', top: 10, right: 10, opacity: 0.2 }}>
                <BusinessIcon sx={{ fontSize: 80 }} />
              </Box>
              <CardContent sx={{ height: '100%', display: 'flex', flexDirection: 'column', justifyContent: 'space-between', p: 1 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <Typography variant="overline" sx={{ fontWeight: 'bold', color: '#bbdefb', letterSpacing: 1.5 }}>
                    Active Sites
                  </Typography>
                  <CallMadeIcon sx={{ color: '#bbdefb' }} fontSize="small" />
                </Box>
                <Typography variant="h2" sx={{ fontWeight: 700, mt: 4 }}>
                  7
                </Typography>
              </CardContent>
            </CardActionArea>
          </Card>
        </Grid>

        {/* Metric 3: Critical Work Orders */}
        <Grid item xs={12} md={3}>
          <Card elevation={1} sx={{ height: '100%', borderRadius: 2 }}>
            <CardActionArea onClick={() => navigate('/work-orders')} sx={{ height: '100%', p: 2 }}>
              <CardContent sx={{ height: '100%', display: 'flex', flexDirection: 'column', justifyContent: 'space-between', p: 1 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <Avatar sx={{ bgcolor: '#ffebee', color: '#d32f2f' }} variant="rounded">
                    <BuildIcon />
                  </Avatar>
                  <CallMadeIcon sx={{ color: 'text.disabled' }} fontSize="small" />
                </Box>
                <Box sx={{ mt: 3 }}>
                  <Typography variant="h5" sx={{ fontWeight: 700, color: 'text.primary' }}>
                    3 Critical
                  </Typography>
                  <Typography variant="overline" sx={{ fontWeight: 'bold', color: 'text.secondary', display: 'block', lineHeight: 1 }}>
                    Work Orders
                  </Typography>
                </Box>
              </CardContent>
            </CardActionArea>
          </Card>
        </Grid>

        {/* Metric 4: Risk Event Feed */}
        <Grid item xs={12} md={6}>
          <Card elevation={1} sx={{ height: '100%', borderRadius: 2 }}>
            <CardActionArea onClick={() => navigate('/enterprise-risk-esg')} sx={{ height: '100%', p: 2, display: 'flex', flexDirection: 'column', alignItems: 'stretch' }}>
              <CardContent sx={{ p: 1, flex: 1 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
                  <Typography variant="h6" sx={{ fontWeight: 700, display: 'flex', alignItems: 'center', gap: 1 }}>
                    <GppMaybeIcon color="secondary" /> Enterprise Risk Radar
                  </Typography>
                  <CallMadeIcon sx={{ color: 'text.disabled' }} fontSize="small" />
                </Box>
                
                <Stack spacing={1.5}>
                  {[
                    { id: 'RSK-001', site: 'NYC-02', txt: 'Facade degradation on South wing', sev: 'High', color: 'warning' },
                    { id: 'RSK-002', site: 'FRA-04', txt: 'Cooling system redundancy failure', sev: 'Critical', color: 'error' },
                    { id: 'RSK-003', site: 'LDN-01', txt: 'Fire safety reg changes', sev: 'Medium', color: 'warning' },
                  ].map(r => (
                     <Box key={r.id} sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', p: 1.5, borderRadius: 1, border: '1px solid', borderColor: 'divider', '&:hover': { bgcolor: 'action.hover' } }}>
                       <Box>
                         <Typography variant="body2" sx={{ fontWeight: 600 }}>{r.txt}</Typography>
                         <Typography variant="caption" color="text.secondary">{r.site} • {r.id}</Typography>
                       </Box>
                       <Chip label={r.sev} color={r.color as any} size="small" sx={{ fontWeight: 'bold', fontSize: '0.7rem' }} />
                     </Box>
                  ))}
                </Stack>
              </CardContent>
            </CardActionArea>
          </Card>
        </Grid>

        {/* Metric 5: Vendors */}
        <Grid item xs={12} md={6}>
          <Grid container spacing={3}>
            <Grid item xs={12}>
              <Card elevation={1} sx={{ borderRadius: 2 }}>
                <CardActionArea onClick={() => navigate('/vendors')} sx={{ p: 2 }}>
                  <CardContent sx={{ p: 1 }}>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 3 }}>
                      <Typography variant="h6" sx={{ fontWeight: 700, display: 'flex', alignItems: 'center', gap: 1 }}>
                        <GroupsIcon color="primary" /> Vendor SLA Performance
                      </Typography>
                      <CallMadeIcon sx={{ color: 'text.disabled' }} fontSize="small" />
                    </Box>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 3 }}>
                      <Box sx={{ position: 'relative', width: 80, height: 80, borderRadius: '50%', background: 'conic-gradient(#4caf50 0% 88%, #f1f5f9 88% 100%)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        <Box sx={{ position: 'absolute', inset: 8, bgcolor: 'background.paper', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                          <Typography variant="h6" sx={{ fontWeight: 900 }}>88%</Typography>
                        </Box>
                      </Box>
                      <Box>
                        <Typography variant="body2" sx={{ fontWeight: 700 }}>Average compliance rate across 45 active enterprise vendors.</Typography>
                        <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mt: 1 }}>3 vendors require immediate review.</Typography>
                      </Box>
                    </Box>
                  </CardContent>
                </CardActionArea>
              </Card>
            </Grid>
            
            <Grid item xs={12} sm={6}>
              <Card elevation={1} sx={{ borderRadius: 2, bgcolor: '#e8f5e9' }}>
                <CardActionArea onClick={() => navigate('/enterprise-risk-esg')} sx={{ p: 2 }}>
                  <CardContent sx={{ p: 1 }}>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                      <Avatar sx={{ bgcolor: 'rgba(76, 175, 80, 0.2)', color: '#2e7d32' }} variant="rounded">
                        <NatureIcon />
                      </Avatar>
                      <CallMadeIcon sx={{ color: '#81c784' }} fontSize="small" />
                    </Box>
                    <Box sx={{ mt: 2 }}>
                      <Typography variant="h5" sx={{ fontWeight: 700, color: '#1b5e20' }}>
                        3,085 <Typography component="span" variant="body2">tCO2e</Typography>
                      </Typography>
                      <Typography variant="overline" sx={{ fontWeight: 'bold', color: '#2e7d32', lineHeight: 1 }}>
                        Scope 1+2 Emissions
                      </Typography>
                    </Box>
                  </CardContent>
                </CardActionArea>
              </Card>
            </Grid>

            <Grid item xs={12} sm={6}>
              <Card elevation={0} sx={{ borderRadius: 2, border: '2px dashed', borderColor: 'divider', height: '100%' }}>
                <CardActionArea onClick={() => navigate('/action-items')} sx={{ height: '100%', p: 2, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
                  <AccessTimeIcon color="action" sx={{ fontSize: 32, mb: 1 }} />
                  <Typography variant="subtitle2" sx={{ fontWeight: 700 }}>Action Tracker</Typography>
                  <Typography variant="caption" color="text.secondary">8 items pending review</Typography>
                </CardActionArea>
              </Card>
            </Grid>
          </Grid>
        </Grid>
      </Grid>
    </Box>
  );
}
