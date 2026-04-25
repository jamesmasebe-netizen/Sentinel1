import React, { useState } from 'react';
import { 
  Box, 
  Typography, 
  Select, 
  MenuItem, 
  Button, 
  Grid, 
  Card, 
  CardContent, 
  Table, 
  TableBody, 
  TableCell, 
  TableContainer, 
  TableHead, 
  TableRow,
  Paper,
  Chip
} from '@mui/material';

// Material Icons
import BusinessIcon from '@mui/icons-material/Business';
import TrendingUpIcon from '@mui/icons-material/TrendingUp';
import WarningAmberIcon from '@mui/icons-material/WarningAmber';
import NatureIcon from '@mui/icons-material/Nature';
import ArrowUpwardIcon from '@mui/icons-material/ArrowUpward';
import FilterListIcon from '@mui/icons-material/FilterList';
import DownloadIcon from '@mui/icons-material/Download';
import MapIcon from '@mui/icons-material/Map';

import SiteMap from '../components/SiteMap';

// Mock Data for Portfolio
const portfolioData = [
  { id: 'LDN-01', site: 'London HQ', region: 'EMEA', occupancy: '92%', costSqFt: '£120', esgScore: 'A-', status: 'Green' as const, incidents: 0, lat: 51.5074, lng: -0.1278 },
  { id: 'NYC-02', site: 'New York Tower', region: 'AMER', occupancy: '85%', costSqFt: '$145', esgScore: 'B+', status: 'Amber' as const, incidents: 2, lat: 40.7128, lng: -74.0060 },
  { id: 'SGP-03', site: 'Singapore Hub', region: 'APAC', occupancy: '98%', costSqFt: '$110', esgScore: 'A', status: 'Green' as const, incidents: 0, lat: 1.3521, lng: 103.8198 },
  { id: 'FRA-04', site: 'Frankfurt Data Center', region: 'EMEA', occupancy: '100%', costSqFt: '€180', esgScore: 'A+', status: 'Green' as const, incidents: 0, lat: 50.1109, lng: 8.6821 },
  { id: 'TOK-05', site: 'Tokyo Office', region: 'APAC', occupancy: '75%', costSqFt: '¥15,000', esgScore: 'B', status: 'Amber' as const, incidents: 1, lat: 35.6762, lng: 139.6503 },
  { id: 'SYD-06', site: 'Sydney Branch', region: 'APAC', occupancy: '88%', costSqFt: '$95', esgScore: 'A-', status: 'Green' as const, incidents: 0, lat: -33.8688, lng: 151.2093 },
  { id: 'JHB-07', site: 'Johannesburg Regional', region: 'EMEA', occupancy: '65%', costSqFt: 'R450', esgScore: 'C+', status: 'Red' as const, incidents: 4, lat: -26.2041, lng: 28.0473 },
];

export default function PortfolioDashboard() {
  const [regionFilter, setRegionFilter] = useState('All');

  const filteredData = regionFilter === 'All' 
    ? portfolioData 
    : portfolioData.filter(d => d.region === regionFilter);

  // Prepare map locations
  const mapLocations = filteredData.map(site => ({
    lat: site.lat,
    lng: site.lng,
    name: site.site,
    status: site.status
  }));

  // Calculate center based on filtered data, default to global view (0,0) if all regions
  const mapCenter = regionFilter === 'All' || filteredData.length === 0
    ? { lat: 20, lng: 0 }
    : { lat: filteredData[0].lat, lng: filteredData[0].lng };
  
  const mapZoom = regionFilter === 'All' ? 2 : 4;

  const getStatusColor = (status: 'Green' | 'Amber' | 'Red') => {
    switch(status) {
      case 'Green': return 'success';
      case 'Amber': return 'warning';
      case 'Red': return 'error';
      default: return 'default';
    }
  };

  return (
    <Box sx={{ flexGrow: 1, p: 1 }}>
      
      {/* Header */}
      <Box sx={{ mb: 4, display: 'flex', flexDirection: { xs: 'column', md: 'row' }, justifyContent: 'space-between', alignItems: { xs: 'flex-start', md: 'flex-end' }, gap: 2 }}>
        <Box>
          <Typography variant="h4" component="h1" sx={{ fontWeight: '700', color: 'text.primary', letterSpacing: '-0.5px' }}>
            Global Portfolio
          </Typography>
          <Typography variant="subtitle1" sx={{ color: 'text.secondary', mt: 0.5 }}>
            Corporate Real Estate Overview
          </Typography>
        </Box>
        <Box sx={{ display: 'flex', gap: 1.5 }}>
          <Select 
            value={regionFilter}
            onChange={(e) => setRegionFilter(e.target.value as string)}
            size="small"
            sx={{ minWidth: 140, bgcolor: 'background.paper' }}
          >
            <MenuItem value="All">All Regions</MenuItem>
            <MenuItem value="EMEA">EMEA</MenuItem>
            <MenuItem value="AMER">AMER</MenuItem>
            <MenuItem value="APAC">APAC</MenuItem>
          </Select>
          <Button variant="outlined" color="secondary" startIcon={<FilterListIcon />} sx={{ bgcolor: 'background.paper' }}>
            Filter
          </Button>
          <Button variant="contained" color="secondary" startIcon={<DownloadIcon />}>
            Export
          </Button>
        </Box>
      </Box>

      {/* KPI Grid */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        
        {/* KPI 1 */}
        <Grid item xs={12} sm={6} md={3}>
          <Card elevation={1} sx={{ borderRadius: 2, height: '100%' }}>
            <CardContent sx={{ p: 2.5, display: 'flex', flexDirection: 'column', height: '100%', justifyContent: 'space-between' }}>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2 }}>
                <Typography variant="overline" sx={{ fontWeight: 'bold', color: 'text.secondary', lineHeight: 1.2 }}>Total Occupancy</Typography>
                <BusinessIcon color="disabled" />
              </Box>
              <Box sx={{ display: 'flex', alignItems: 'flex-end', gap: 1.5 }}>
                <Typography variant="h4" sx={{ fontWeight: 700, letterSpacing: '-0.5px' }}>86.2%</Typography>
                <Typography variant="body2" sx={{ display: 'flex', alignItems: 'center', color: 'success.main', fontWeight: 600, mb: 0.5 }}>
                  <ArrowUpwardIcon fontSize="small" sx={{ mr: 0.5 }} /> 2.4%
                </Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* KPI 2 */}
        <Grid item xs={12} sm={6} md={3}>
          <Card elevation={1} sx={{ borderRadius: 2, height: '100%' }}>
            <CardContent sx={{ p: 2.5, display: 'flex', flexDirection: 'column', height: '100%', justifyContent: 'space-between' }}>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2 }}>
                <Typography variant="overline" sx={{ fontWeight: 'bold', color: 'text.secondary', lineHeight: 1.2 }}>Avg Cost / SqFt</Typography>
                <TrendingUpIcon color="disabled" />
              </Box>
              <Box sx={{ display: 'flex', alignItems: 'flex-end', gap: 1.5 }}>
                <Typography variant="h4" sx={{ fontWeight: 700, letterSpacing: '-0.5px' }}>$118</Typography>
                <Typography variant="body2" sx={{ display: 'flex', alignItems: 'center', color: 'error.main', fontWeight: 600, mb: 0.5 }}>
                  <ArrowUpwardIcon fontSize="small" sx={{ mr: 0.5 }} /> 1.2%
                </Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* KPI 3 */}
        <Grid item xs={12} sm={6} md={3}>
          <Card elevation={1} sx={{ borderRadius: 2, height: '100%' }}>
            <CardContent sx={{ p: 2.5, display: 'flex', flexDirection: 'column', height: '100%', justifyContent: 'space-between' }}>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2 }}>
                <Typography variant="overline" sx={{ fontWeight: 'bold', color: 'text.secondary', lineHeight: 1.2 }}>Aggregate ESG</Typography>
                <NatureIcon color="disabled" />
              </Box>
              <Box sx={{ display: 'flex', alignItems: 'flex-end', gap: 1.5 }}>
                <Typography variant="h4" sx={{ fontWeight: 700, letterSpacing: '-0.5px' }}>A-</Typography>
                <Typography variant="body2" sx={{ display: 'flex', alignItems: 'center', color: 'success.main', fontWeight: 600, mb: 0.5 }}>
                  <ArrowUpwardIcon fontSize="small" sx={{ mr: 0.5 }} /> Stable
                </Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* KPI 4 */}
        <Grid item xs={12} sm={6} md={3}>
          <Card elevation={1} sx={{ borderRadius: 2, height: '100%' }}>
            <CardContent sx={{ p: 2.5, display: 'flex', flexDirection: 'column', height: '100%', justifyContent: 'space-between' }}>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2 }}>
                <Typography variant="overline" sx={{ fontWeight: 'bold', color: 'text.secondary', lineHeight: 1.2 }}>Active Incidents</Typography>
                <WarningAmberIcon color="disabled" />
              </Box>
              <Box sx={{ display: 'flex', alignItems: 'flex-end', gap: 1.5 }}>
                <Typography variant="h4" sx={{ fontWeight: 700, letterSpacing: '-0.5px' }}>7</Typography>
                <Typography variant="body2" sx={{ display: 'flex', alignItems: 'center', color: 'error.main', fontWeight: 600, mb: 0.5 }}>
                  <ArrowUpwardIcon fontSize="small" sx={{ mr: 0.5 }} /> +3
                </Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>

      </Grid>

      {/* Main Content Area */}
      <Grid container spacing={3}>
        
        {/* Map */}
        <Grid item xs={12} lg={4}>
          <Card elevation={1} sx={{ borderRadius: 2, height: '100%', minHeight: 400, display: 'flex', flexDirection: 'column' }}>
            <Box sx={{ p: 2, borderBottom: '1px solid', borderColor: 'divider', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <Typography variant="subtitle2" sx={{ fontWeight: 700 }}>Geospatial View</Typography>
              <MapIcon color="action" fontSize="small" />
            </Box>
            <Box sx={{ flex: 1, position: 'relative' }}>
              <SiteMap locations={mapLocations} center={mapCenter} zoom={mapZoom} />
            </Box>
          </Card>
        </Grid>

        {/* Data Grid */}
        <Grid item xs={12} lg={8}>
          <TableContainer component={Paper} elevation={1} sx={{ borderRadius: 2, height: '100%' }}>
            <Table>
              <TableHead sx={{ bgcolor: 'background.default' }}>
                <TableRow>
                  <TableCell><Typography variant="overline" sx={{ fontWeight: 800 }}>ID</Typography></TableCell>
                  <TableCell><Typography variant="overline" sx={{ fontWeight: 800 }}>Site Location</Typography></TableCell>
                  <TableCell><Typography variant="overline" sx={{ fontWeight: 800 }}>Occupancy</Typography></TableCell>
                  <TableCell><Typography variant="overline" sx={{ fontWeight: 800 }}>Cost/SqFt</Typography></TableCell>
                  <TableCell><Typography variant="overline" sx={{ fontWeight: 800 }}>ESG</Typography></TableCell>
                  <TableCell><Typography variant="overline" sx={{ fontWeight: 800 }}>Status</Typography></TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {filteredData.map((row) => (
                  <TableRow key={row.id} hover sx={{ cursor: 'pointer', '&:last-child td, &:last-child th': { border: 0 } }}>
                    <TableCell><Typography variant="body2" sx={{ color: 'text.secondary', fontWeight: 500, fontFamily: 'monospace' }}>{row.id}</Typography></TableCell>
                    <TableCell><Typography variant="body2" sx={{ fontWeight: 600 }}>{row.site}</Typography></TableCell>
                    <TableCell>{row.occupancy}</TableCell>
                    <TableCell>{row.costSqFt}</TableCell>
                    <TableCell>{row.esgScore}</TableCell>
                    <TableCell>
                      <Chip 
                        label={row.status} 
                        color={getStatusColor(row.status)} 
                        size="small" 
                        sx={{ fontWeight: 600, fontSize: '0.75rem' }} 
                      />
                    </TableCell>
                  </TableRow>
                ))}
                {filteredData.length === 0 && (
                  <TableRow>
                    <TableCell colSpan={6} align="center" sx={{ py: 4 }}>
                      <Typography variant="body2" color="text.secondary">No sites found for the selected region.</Typography>
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </TableContainer>
        </Grid>

      </Grid>
    </Box>
  );
}
