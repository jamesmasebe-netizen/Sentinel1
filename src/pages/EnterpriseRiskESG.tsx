import React, { useState } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { 
  Box, 
  Typography, 
  Grid, 
  Card, 
  CardContent, 
  Button, 
  Table, 
  TableBody, 
  TableCell, 
  TableContainer, 
  TableHead, 
  TableRow, 
  Paper, 
  Chip, 
  Tabs,
  Tab,
  LinearProgress,
  Avatar
} from '@mui/material';

// Icons
import NatureIcon from '@mui/icons-material/Nature';
import GppMaybeIcon from '@mui/icons-material/GppMaybe';
import FactCheckIcon from '@mui/icons-material/FactCheck';
import InsightsIcon from '@mui/icons-material/Insights';
import DownloadIcon from '@mui/icons-material/Download';
import BusinessIcon from '@mui/icons-material/Business';
import WarningAmberIcon from '@mui/icons-material/WarningAmber';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import TrendingDownIcon from '@mui/icons-material/TrendingDown';
import AirIcon from '@mui/icons-material/Air';
import BoltIcon from '@mui/icons-material/Bolt';

// Mock Data for Enterprise ESG
const esgData = [
  { siteId: 'LDN-01', siteName: 'London HQ', scope1: 120, scope2: 450, energyIntensity: 145, wasteDiversion: 85, status: 'On Track' },
  { siteId: 'NYC-02', siteName: 'New York Tower', scope1: 180, scope2: 620, energyIntensity: 160, wasteDiversion: 72, status: 'Lagging' },
  { siteId: 'SGP-03', siteName: 'Singapore Hub', scope1: 90, scope2: 380, energyIntensity: 130, wasteDiversion: 92, status: 'Leading' },
  { siteId: 'FRA-04', siteName: 'Frankfurt Data Center', scope1: 45, scope2: 1200, energyIntensity: 310, wasteDiversion: 98, status: 'On Track' },
];

// Mock Data for Enterprise Risk Register
const riskData = [
  { id: 'RSK-001', siteId: 'NYC-02', category: 'Structural', description: 'Facade degradation on South wing', severity: 'High', status: 'Mitigating', costExposure: '$1.2M' },
  { id: 'RSK-002', siteId: 'FRA-04', category: 'Operational', description: 'Cooling system redundancy failure risk', severity: 'Critical', status: 'Open', costExposure: '$4.5M' },
  { id: 'RSK-003', siteId: 'LDN-01', category: 'Compliance', description: 'Upcoming fire safety regulation changes', severity: 'Medium', status: 'Monitoring', costExposure: '$250K' },
  { id: 'RSK-004', siteId: 'TOK-05', category: 'Environmental', description: 'Seismic resilience upgrade required', severity: 'High', status: 'Planned', costExposure: '$2.8M' },
];

// Mock Data for Compliance & Audits
const complianceData = [
  { siteId: 'LDN-01', siteName: 'London HQ', iso14001: 'Certified', iso45001: 'Certified', iso9001: 'Certified', nextAudit: '2026-09-15', fireSafety: 'Compliant' },
  { siteId: 'NYC-02', siteName: 'New York Tower', iso14001: 'In Progress', iso45001: 'Certified', iso9001: 'Certified', nextAudit: '2026-06-10', fireSafety: 'Action Required' },
  { siteId: 'FRA-04', siteName: 'Frankfurt Data Center', iso14001: 'Certified', iso45001: 'Certified', iso9001: 'Certified', nextAudit: '2026-11-20', fireSafety: 'Compliant' },
  { siteId: 'JHB-07', siteName: 'Johannesburg Regional', iso14001: 'Not Started', iso45001: 'In Progress', iso9001: 'Not Started', nextAudit: '2026-08-05', fireSafety: 'Compliant' },
];

// Mock Data for Predictive Maintenance (IoT)
const iotData = [
  { id: 'CHLR-01', siteId: 'FRA-04', equipment: 'Primary Chiller Unit A', healthScore: 98, predictedFailure: 'None', status: 'Optimal' },
  { id: 'HVAC-42', siteId: 'NYC-02', equipment: 'Rooftop HVAC 4', healthScore: 65, predictedFailure: '14 Days (Bearing Wear)', status: 'Warning' },
  { id: 'ELEV-03', siteId: 'LDN-01', equipment: 'Passenger Elevator C', healthScore: 82, predictedFailure: '45 Days (Cable Tension)', status: 'Monitor' },
  { id: 'GEN-01', siteId: 'SGP-03', equipment: 'Backup Generator 1', healthScore: 95, predictedFailure: 'None', status: 'Optimal' },
];

export default function EnterpriseRiskESG() {
  const { profile } = useAuth();
  const [activeTab, setActiveTab] = useState<'esg' | 'risk' | 'compliance' | 'iot'>('esg');

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'Critical': return 'error';
      case 'High': return 'warning';
      case 'Medium': return 'info';
      case 'Low': return 'success';
      default: return 'default';
    }
  };

  const getCertColor = (status: string) => {
    switch (status) {
      case 'Certified': return 'success';
      case 'In Progress': return 'warning';
      case 'Not Started': return 'default';
      case 'Action Required': return 'error';
      case 'Compliant': return 'success';
      default: return 'default';
    }
  };

  return (
    <Box sx={{ p: { xs: 2, md: 4 }, maxWidth: 1400, mx: 'auto', flexGrow: 1 }}>
      
      {/* Header */}
      <Box sx={{ display: 'flex', flexDirection: { xs: 'column', md: 'row' }, justifyContent: 'space-between', alignItems: { xs: 'flex-start', md: 'center' }, gap: 2, mb: 4 }}>
        <Box>
          <Typography variant="h4" component="h1" sx={{ fontWeight: '700', color: 'text.primary', letterSpacing: '-0.5px' }}>
            Risk, Compliance & ESG
          </Typography>
          <Typography variant="subtitle1" sx={{ color: 'text.secondary', mt: 0.5 }}>
            Enterprise portfolio sustainability, automated audits, and predictive risk.
          </Typography>
        </Box>
        <Button 
          variant="outlined" 
          startIcon={<DownloadIcon />} 
          sx={{ bgcolor: 'background.paper' }}
        >
          Export Board Report
        </Button>
      </Box>

      {/* KPI Grid */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} lg={3}>
          <Card elevation={1} sx={{ borderRadius: 2 }}>
            <CardContent>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2 }}>
                <Typography variant="overline" color="text.secondary" fontWeight={600}>
                  Portfolio Carbon (Scope 1+2)
                </Typography>
                <Avatar sx={{ bgcolor: 'success.light', color: 'success.main', width: 32, height: 32 }}>
                  <AirIcon fontSize="small" />
                </Avatar>
              </Box>
              <Typography variant="h4" fontWeight={300} sx={{ letterSpacing: '-0.5px' }}>
                3,085 <Typography component="span" variant="h6" color="text.secondary" fontWeight={400}>tCO2e</Typography>
              </Typography>
              <Box sx={{ display: 'flex', alignItems: 'center', color: 'success.main', mt: 1 }}>
                <TrendingDownIcon fontSize="small" sx={{ mr: 0.5 }} />
                <Typography variant="body2" fontWeight={600}>4.2% reduction YoY</Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} lg={3}>
          <Card elevation={1} sx={{ borderRadius: 2 }}>
            <CardContent>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2 }}>
                <Typography variant="overline" color="text.secondary" fontWeight={600}>
                  Critical Enterprise Risks
                </Typography>
                <Avatar sx={{ bgcolor: 'error.light', color: 'error.main', width: 32, height: 32 }}>
                  <GppMaybeIcon fontSize="small" />
                </Avatar>
              </Box>
              <Typography variant="h4" fontWeight={300} sx={{ letterSpacing: '-0.5px' }}>
                1
              </Typography>
              <Box sx={{ display: 'flex', alignItems: 'center', color: 'error.main', mt: 1 }}>
                <WarningAmberIcon fontSize="small" sx={{ mr: 0.5 }} />
                <Typography variant="body2" fontWeight={600}>$4.5M Value at Risk</Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} lg={3}>
          <Card elevation={1} sx={{ borderRadius: 2 }}>
            <CardContent>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2 }}>
                <Typography variant="overline" color="text.secondary" fontWeight={600}>
                  Global Compliance Rate
                </Typography>
                <Avatar sx={{ bgcolor: 'info.light', color: 'info.main', width: 32, height: 32 }}>
                  <FactCheckIcon fontSize="small" />
                </Avatar>
              </Box>
              <Typography variant="h4" fontWeight={300} sx={{ letterSpacing: '-0.5px' }}>
                88%
              </Typography>
              <LinearProgress variant="determinate" value={88} sx={{ mt: 2, mb: 1, borderRadius: 1 }} />
              <Typography variant="caption" color="text.secondary">Target: 95% by Q4</Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} lg={3}>
          <Card elevation={1} sx={{ borderRadius: 2 }}>
            <CardContent>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2 }}>
                <Typography variant="overline" color="text.secondary" fontWeight={600}>
                  IoT Predictive Alerts
                </Typography>
                <Avatar sx={{ bgcolor: 'secondary.light', color: 'secondary.main', width: 32, height: 32 }}>
                  <InsightsIcon fontSize="small" />
                </Avatar>
              </Box>
              <Typography variant="h4" fontWeight={300} sx={{ letterSpacing: '-0.5px' }}>
                3
              </Typography>
              <Box sx={{ display: 'flex', alignItems: 'center', color: 'secondary.main', mt: 1 }}>
                <BoltIcon fontSize="small" sx={{ mr: 0.5 }} />
                <Typography variant="body2" fontWeight={600}>1 Critical Warning</Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Tabs */}
      <Box sx={{ borderBottom: 1, borderColor: 'divider', mb: 3 }}>
        <Tabs 
          value={activeTab} 
          onChange={(_, newValue) => setActiveTab(newValue)} 
          variant="scrollable"
          scrollButtons="auto"
        >
          <Tab icon={<NatureIcon fontSize="small" />} iconPosition="start" label="ESG & Sustainability" value="esg" sx={{ fontWeight: 600 }} />
          <Tab icon={<GppMaybeIcon fontSize="small" />} iconPosition="start" label="Enterprise Risk Register" value="risk" sx={{ fontWeight: 600 }} />
          <Tab icon={<FactCheckIcon fontSize="small" />} iconPosition="start" label="Compliance & Audits" value="compliance" sx={{ fontWeight: 600 }} />
          <Tab icon={<InsightsIcon fontSize="small" />} iconPosition="start" label="Predictive Maintenance (IoT)" value="iot" sx={{ fontWeight: 600 }} />
        </Tabs>
      </Box>

      {/* Tab Content */}
      <Card elevation={0} sx={{ border: '1px solid', borderColor: 'divider', borderRadius: 2 }}>
        
        {/* ESG Tab */}
        {activeTab === 'esg' && (
          <Box sx={{ p: 3 }}>
            <Box sx={{ mb: 3 }}>
              <Typography variant="h6" fontWeight={700}>Portfolio Sustainability Metrics</Typography>
              <Typography variant="body2" color="text.secondary">Aggregated environmental data for corporate ESG reporting.</Typography>
            </Box>
            <TableContainer>
              <Table size="small">
                <TableHead>
                  <TableRow sx={{ bgcolor: 'background.default' }}>
                    <TableCell sx={{ fontWeight: 600 }}>Site</TableCell>
                    <TableCell align="right" sx={{ fontWeight: 600 }}>Scope 1 (tCO2e)</TableCell>
                    <TableCell align="right" sx={{ fontWeight: 600 }}>Scope 2 (tCO2e)</TableCell>
                    <TableCell align="right" sx={{ fontWeight: 600 }}>Energy Intensity (kWh/m²)</TableCell>
                    <TableCell align="center" sx={{ fontWeight: 600 }}>Waste Diversion</TableCell>
                    <TableCell align="center" sx={{ fontWeight: 600 }}>Status</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {esgData.map(data => (
                     <TableRow key={data.siteId} hover>
                      <TableCell>
                        <Typography variant="body2" fontWeight={600}>{data.siteName}</Typography>
                        <Typography variant="caption" color="text.secondary">{data.siteId}</Typography>
                      </TableCell>
                      <TableCell align="right" sx={{ fontFamily: 'monospace' }}>{data.scope1}</TableCell>
                      <TableCell align="right" sx={{ fontFamily: 'monospace' }}>{data.scope2}</TableCell>
                      <TableCell align="right" sx={{ fontFamily: 'monospace' }}>{data.energyIntensity}</TableCell>
                      <TableCell align="center">
                        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 1 }}>
                          <LinearProgress 
                            variant="determinate" 
                            value={data.wasteDiversion} 
                            color={data.wasteDiversion >= 90 ? 'success' : data.wasteDiversion >= 75 ? 'warning' : 'error'}
                            sx={{ width: 60, height: 6, borderRadius: 1 }} 
                          />
                          <Typography variant="body2" fontWeight={600}>{data.wasteDiversion}%</Typography>
                        </Box>
                      </TableCell>
                      <TableCell align="center">
                        <Chip 
                          label={data.status} 
                          color={data.status === 'Leading' ? 'success' : data.status === 'On Track' ? 'info' : 'warning'} 
                          size="small" 
                          sx={{ fontWeight: 600 }} 
                        />
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
          </Box>
        )}

        {/* Risk Tab */}
        {activeTab === 'risk' && (
          <Box sx={{ p: 3 }}>
            <Box sx={{ mb: 3 }}>
              <Typography variant="h6" fontWeight={700}>Enterprise Risk Register</Typography>
              <Typography variant="body2" color="text.secondary">Aggregated high-level risks escalated from site-level assessments.</Typography>
            </Box>
            <Grid container spacing={2}>
              {riskData.map(risk => (
                <Grid item xs={12} sm={6} lg={3} key={risk.id}>
                  <Card elevation={0} sx={{ border: '1px solid', borderColor: 'divider', bgcolor: 'background.default', height: '100%', display: 'flex', flexDirection: 'column' }}>
                    <CardContent sx={{ flex: 1, p: 2 }}>
                      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 1.5 }}>
                        <Chip label={risk.severity} color={getSeverityColor(risk.severity) as any} size="small" sx={{ fontWeight: 600, fontSize: '0.7rem' }} />
                        <Typography variant="caption" sx={{ fontFamily: 'monospace', color: 'text.disabled' }}>{risk.id}</Typography>
                      </Box>
                      <Typography variant="subtitle2" fontWeight={700} mb={0.5}>{risk.category}</Typography>
                      <Typography variant="body2" color="text.secondary" sx={{ display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden', mb: 2 }}>
                        {risk.description}
                      </Typography>
                    </CardContent>
                    <Box sx={{ p: 2, pt: 0, display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderTop: '1px solid', borderColor: 'divider', mt: 'auto' }}>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, color: 'text.secondary', mt: 1 }}>
                        <BusinessIcon fontSize="small" sx={{ fontSize: 14 }} />
                        <Typography variant="caption" fontWeight={500}>{risk.siteId}</Typography>
                      </Box>
                      <Typography variant="body2" fontWeight={600} fontFamily="monospace" sx={{ mt: 1 }}>{risk.costExposure}</Typography>
                    </Box>
                  </Card>
                </Grid>
              ))}
            </Grid>
          </Box>
        )}

        {/* Compliance Tab */}
        {activeTab === 'compliance' && (
          <Box sx={{ p: 3 }}>
            <Box sx={{ mb: 3 }}>
              <Typography variant="h6" fontWeight={700}>Automated Compliance & Audits</Typography>
              <Typography variant="body2" color="text.secondary">Centralized tracking of ISO certifications and statutory compliance.</Typography>
            </Box>
            <TableContainer>
              <Table size="small">
                <TableHead>
                  <TableRow sx={{ bgcolor: 'background.default' }}>
                    <TableCell sx={{ fontWeight: 600 }}>Site</TableCell>
                    <TableCell align="center" sx={{ fontWeight: 600 }}>ISO 9001 (Quality)</TableCell>
                    <TableCell align="center" sx={{ fontWeight: 600 }}>ISO 14001 (Environment)</TableCell>
                    <TableCell align="center" sx={{ fontWeight: 600 }}>ISO 45001 (Safety)</TableCell>
                    <TableCell align="center" sx={{ fontWeight: 600 }}>Fire Safety Statutory</TableCell>
                    <TableCell align="right" sx={{ fontWeight: 600 }}>Next Major Audit</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {complianceData.map(data => (
                    <TableRow key={data.siteId} hover>
                      <TableCell>
                        <Typography variant="body2" fontWeight={600}>{data.siteName}</Typography>
                        <Typography variant="caption" color="text.secondary">{data.siteId}</Typography>
                      </TableCell>
                      <TableCell align="center">
                        <Chip label={data.iso9001} color={getCertColor(data.iso9001) as any} size="small" variant={data.iso9001 === 'Not Started' ? 'outlined' : 'filled'} sx={{ fontWeight: 600 }} />
                      </TableCell>
                      <TableCell align="center">
                        <Chip label={data.iso14001} color={getCertColor(data.iso14001) as any} size="small" variant={data.iso14001 === 'Not Started' ? 'outlined' : 'filled'} sx={{ fontWeight: 600 }} />
                      </TableCell>
                      <TableCell align="center">
                        <Chip label={data.iso45001} color={getCertColor(data.iso45001) as any} size="small" variant={data.iso45001 === 'Not Started' ? 'outlined' : 'filled'} sx={{ fontWeight: 600 }} />
                      </TableCell>
                      <TableCell align="center">
                        <Chip label={data.fireSafety} color={getCertColor(data.fireSafety) as any} size="small" variant={data.fireSafety === 'Compliant' ? 'filled' : 'outlined'} sx={{ fontWeight: 600 }} />
                      </TableCell>
                      <TableCell align="right">
                        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'flex-end', gap: 1, color: 'text.secondary' }}>
                          <CheckCircleIcon fontSize="small" />
                          <Typography variant="body2" fontWeight={500}>{data.nextAudit}</Typography>
                        </Box>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
          </Box>
        )}

        {/* IoT Tab */}
        {activeTab === 'iot' && (
          <Box sx={{ p: 3 }}>
            <Box sx={{ mb: 3, display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end' }}>
              <Box>
                <Typography variant="h6" fontWeight={700}>Predictive Maintenance (IoT)</Typography>
                <Typography variant="body2" color="text.secondary">Real-time equipment health monitoring integrated with BMS.</Typography>
              </Box>
              <Chip 
                icon={<Box sx={{ width: 8, height: 8, borderRadius: '50%', bgcolor: 'success.main', ml: 1, mr: -0.5, animation: 'pulse 2s infinite' }} />} 
                label="Live Connection Active" 
                color="success" 
                variant="outlined" 
                size="small"
                sx={{ fontWeight: 600, bgcolor: 'success.light', color: 'success.dark', border: 'none' }} 
              />
            </Box>
            <Grid container spacing={2}>
              {iotData.map(item => (
                <Grid item xs={12} md={6} key={item.id}>
                  <Card elevation={0} sx={{ border: '1px solid', borderColor: 'divider', bgcolor: 'background.default', display: 'flex', alignItems: 'center', justifyContent: 'space-between', p: 2 }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                      <Avatar sx={{ 
                        bgcolor: item.healthScore >= 90 ? 'success.light' : item.healthScore >= 70 ? 'warning.light' : 'error.light', 
                        color: item.healthScore >= 90 ? 'success.main' : item.healthScore >= 70 ? 'warning.main' : 'error.main', 
                        border: '2px solid',
                        borderColor: 'background.paper',
                        width: 48,
                        height: 48 
                      }}>
                        <InsightsIcon />
                      </Avatar>
                      <Box>
                        <Typography variant="subtitle2" fontWeight={700}>{item.equipment}</Typography>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, color: 'text.secondary', mt: 0.5 }}>
                          <Typography variant="caption" fontFamily="monospace">{item.id}</Typography>
                          <Typography variant="caption">•</Typography>
                          <Typography variant="caption">{item.siteId}</Typography>
                        </Box>
                      </Box>
                    </Box>
                    <Box sx={{ textAlign: 'right' }}>
                      <Typography variant="h5" fontWeight={300} sx={{ letterSpacing: '-0.5px' }}>
                        {item.healthScore}<Typography component="span" variant="body2" color="text.secondary">%</Typography>
                      </Typography>
                      <Typography variant="caption" fontWeight={600} color={item.predictedFailure !== 'None' ? 'error.main' : 'success.main'} sx={{ mt: 0.5, display: 'block' }}>
                        {item.predictedFailure !== 'None' ? `Warning: ${item.predictedFailure}` : 'Status: Optimal'}
                      </Typography>
                    </Box>
                  </Card>
                </Grid>
              ))}
            </Grid>
          </Box>
        )}

      </Card>
    </Box>
  );
}
