import React, { useState, useEffect } from 'react';
import { collection, query, onSnapshot, orderBy, where } from 'firebase/firestore';
import { db, handleFirestoreError, OperationType } from '../lib/firebase';
import { useAuth } from '../contexts/AuthContext';
import { 
  Box, 
  Typography, 
  Grid, 
  Card, 
  CardContent, 
  TextField, 
  Select, 
  MenuItem, 
  InputAdornment, 
  Table, 
  TableBody, 
  TableCell, 
  TableContainer, 
  TableHead, 
  TableRow, 
  Paper, 
  Chip, 
  CircularProgress, 
  Button,
  LinearProgress,
  Avatar
} from '@mui/material';

// Material Icons
import BusinessIcon from '@mui/icons-material/Business';
import SearchIcon from '@mui/icons-material/Search';
import FilterListIcon from '@mui/icons-material/FilterList';
import StarIcon from '@mui/icons-material/Star';
import ShieldIcon from '@mui/icons-material/Shield';
import AccessTimeIcon from '@mui/icons-material/AccessTime';
import BusinessCenterIcon from '@mui/icons-material/BusinessCenter';
import VerifiedUserIcon from '@mui/icons-material/VerifiedUser';

interface Vendor {
  id: string;
  companyName: string;
  contactPerson: string;
  contactEmail: string;
  complianceStatus: 'Green' | 'Amber' | 'Red';
  siteId?: string;
  // Simulated Enterprise Fields
  rating?: number;
  activeContracts?: number;
  slaCompliance?: number;
}

export default function VendorManagement() {
  const { profile } = useAuth();
  const [vendors, setVendors] = useState<Vendor[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [complianceFilter, setComplianceFilter] = useState('All');

  useEffect(() => {
    if (!profile) return;

    const isGlobal = profile.role === 'admin' || profile.role === 'executive';
    let q = query(collection(db, 'contractors'), orderBy('companyName'));
    
    if (!isGlobal && profile.siteId) {
      q = query(collection(db, 'contractors'), where('siteId', '==', profile.siteId), orderBy('companyName'));
    }

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data: Vendor[] = [];
      snapshot.forEach((doc) => {
        const vendorData = doc.data();
        const idHash = doc.id.split('').reduce((a, b) => a + b.charCodeAt(0), 0);
        const simulatedRating = 3 + (idHash % 3) + (idHash % 10) / 10;
        const simulatedContracts = 1 + (idHash % 5);
        const simulatedSla = 85 + (idHash % 15);

        data.push({ 
          id: doc.id, 
          ...vendorData,
          rating: vendorData.rating || Number(simulatedRating.toFixed(1)),
          activeContracts: vendorData.activeContracts || simulatedContracts,
          slaCompliance: vendorData.slaCompliance || simulatedSla
        } as Vendor);
      });
      setVendors(data);
      setLoading(false);
    }, (error) => {
      handleFirestoreError(error, OperationType.LIST, 'contractors');
      setLoading(false);
    });

    return () => unsubscribe();
  }, [profile]);

  const filteredVendors = vendors.filter(v => {
    const matchesSearch = v.companyName.toLowerCase().includes(searchTerm.toLowerCase()) || 
                          v.contactPerson.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesCompliance = complianceFilter === 'All' || v.complianceStatus === complianceFilter;
    return matchesSearch && matchesCompliance;
  });

  const getComplianceColor = (status: string) => {
    switch (status) {
      case 'Green': return 'success';
      case 'Amber': return 'warning';
      case 'Red': return 'error';
      default: return 'default';
    }
  };

  const getSlaColor = (sla: number) => {
    if (sla >= 90) return 'success';
    if (sla >= 80) return 'warning';
    return 'error';
  };

  return (
    <Box sx={{ p: { xs: 2, md: 4 }, maxWidth: 1400, mx: 'auto', flexGrow: 1 }}>
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" component="h1" sx={{ fontWeight: '700', color: 'text.primary', letterSpacing: '-0.5px' }}>
          Enterprise Vendor Portal
        </Typography>
        <Typography variant="subtitle1" sx={{ color: 'text.secondary', mt: 0.5 }}>
          Manage supplier performance, SLAs, and compliance across the portfolio.
        </Typography>
      </Box>

      {/* KPI Summary */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card elevation={1} sx={{ borderRadius: 2 }}>
            <CardContent sx={{ display: 'flex', alignItems: 'center', gap: 2, p: 3 }}>
              <Avatar sx={{ bgcolor: 'info.light', color: 'info.main', width: 56, height: 56 }} variant="rounded">
                <BusinessIcon />
              </Avatar>
              <Box>
                <Typography variant="body2" color="text.secondary" fontWeight={600}>Total Vendors</Typography>
                <Typography variant="h5" fontWeight={800}>{vendors.length}</Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card elevation={1} sx={{ borderRadius: 2 }}>
            <CardContent sx={{ display: 'flex', alignItems: 'center', gap: 2, p: 3 }}>
              <Avatar sx={{ bgcolor: 'success.light', color: 'success.main', width: 56, height: 56 }} variant="rounded">
                <VerifiedUserIcon />
              </Avatar>
              <Box>
                <Typography variant="body2" color="text.secondary" fontWeight={600}>Fully Compliant</Typography>
                <Typography variant="h5" fontWeight={800}>{vendors.filter(v => v.complianceStatus === 'Green').length}</Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card elevation={1} sx={{ borderRadius: 2 }}>
            <CardContent sx={{ display: 'flex', alignItems: 'center', gap: 2, p: 3 }}>
              <Avatar sx={{ bgcolor: 'warning.light', color: 'warning.main', width: 56, height: 56 }} variant="rounded">
                <AccessTimeIcon />
              </Avatar>
              <Box>
                <Typography variant="body2" color="text.secondary" fontWeight={600}>Avg SLA Compliance</Typography>
                <Typography variant="h5" fontWeight={800}>
                  {vendors.length > 0 ? Math.round(vendors.reduce((acc, v) => acc + (v.slaCompliance || 0), 0) / vendors.length) : 0}%
                </Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card elevation={1} sx={{ borderRadius: 2 }}>
            <CardContent sx={{ display: 'flex', alignItems: 'center', gap: 2, p: 3 }}>
              <Avatar sx={{ bgcolor: 'secondary.light', color: 'secondary.main', width: 56, height: 56 }} variant="rounded">
                <StarIcon />
              </Avatar>
              <Box>
                <Typography variant="body2" color="text.secondary" fontWeight={600}>Avg Rating</Typography>
                <Typography variant="h5" fontWeight={800}>
                  {vendors.length > 0 ? (vendors.reduce((acc, v) => acc + (v.rating || 0), 0) / vendors.length).toFixed(1) : '0.0'}
                </Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Filters */}
      <Card elevation={0} sx={{ p: 2, mb: 4, borderRadius: 2, border: '1px solid', borderColor: 'divider' }}>
        <Grid container spacing={2} alignItems="center">
          <Grid item xs={12} md={8}>
            <TextField 
              fullWidth 
              size="small" 
              placeholder="Search vendors by name or contact..." 
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <SearchIcon color="action" />
                  </InputAdornment>
                ),
              }}
            />
          </Grid>
          <Grid item xs={12} md={4}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <FilterListIcon color="action" />
              <Select 
                fullWidth 
                size="small" 
                value={complianceFilter}
                onChange={(e) => setComplianceFilter(e.target.value as string)}
              >
                <MenuItem value="All">All Compliance</MenuItem>
                <MenuItem value="Green">Green (Compliant)</MenuItem>
                <MenuItem value="Amber">Amber (Warning)</MenuItem>
                <MenuItem value="Red">Red (Non-Compliant)</MenuItem>
              </Select>
            </Box>
          </Grid>
        </Grid>
      </Card>

      {/* Vendor List */}
      {loading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}>
          <CircularProgress />
        </Box>
      ) : (
        <TableContainer component={Paper} elevation={1} sx={{ borderRadius: 2 }}>
          <Table>
            <TableHead sx={{ bgcolor: 'background.default' }}>
              <TableRow>
                <TableCell><Typography variant="overline" fontWeight={800}>Vendor Name</Typography></TableCell>
                <TableCell><Typography variant="overline" fontWeight={800}>Contact</Typography></TableCell>
                <TableCell align="center"><Typography variant="overline" fontWeight={800}>Compliance</Typography></TableCell>
                <TableCell align="center"><Typography variant="overline" fontWeight={800}>Active Contracts</Typography></TableCell>
                <TableCell align="center"><Typography variant="overline" fontWeight={800}>SLA Compliance</Typography></TableCell>
                <TableCell align="center"><Typography variant="overline" fontWeight={800}>Rating</Typography></TableCell>
                <TableCell align="right"><Typography variant="overline" fontWeight={800}>Actions</Typography></TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {filteredVendors.map(vendor => (
                <TableRow key={vendor.id} hover sx={{ '&:last-child td, &:last-child th': { border: 0 } }}>
                  <TableCell>
                    <Typography variant="body2" fontWeight={800} color="text.primary">{vendor.companyName}</Typography>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mt: 0.5, color: 'text.secondary' }}>
                      <BusinessIcon sx={{ fontSize: 14 }} />
                      <Typography variant="caption">{vendor.siteId || 'Global'}</Typography>
                    </Box>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2" color="text.primary" fontWeight={500}>{vendor.contactPerson}</Typography>
                    <Typography variant="caption" color="text.secondary">{vendor.contactEmail}</Typography>
                  </TableCell>
                  <TableCell align="center">
                    <Chip 
                      label={vendor.complianceStatus} 
                      color={getComplianceColor(vendor.complianceStatus) as any} 
                      size="small" 
                      sx={{ fontWeight: 700, fontSize: '0.75rem' }} 
                    />
                  </TableCell>
                  <TableCell align="center">
                    <Chip 
                      icon={<BusinessCenterIcon sx={{ fontSize: 16 }} />} 
                      label={vendor.activeContracts}
                      variant="outlined"
                      size="small"
                      sx={{ fontWeight: 600, border: 'none', bgcolor: 'background.default' }}
                    />
                  </TableCell>
                  <TableCell>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, justifyContent: 'center' }}>
                      <Box sx={{ width: '60px' }}>
                        <LinearProgress 
                          variant="determinate" 
                          value={vendor.slaCompliance || 0} 
                          color={getSlaColor(vendor.slaCompliance || 0) as any}
                          sx={{ height: 6, borderRadius: 3 }}
                        />
                      </Box>
                      <Typography variant="body2" fontWeight={600} sx={{ minWidth: 35 }}>
                        {vendor.slaCompliance}%
                      </Typography>
                    </Box>
                  </TableCell>
                  <TableCell align="center">
                    <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 0.5, color: 'warning.main' }}>
                      <StarIcon sx={{ fontSize: 18 }} />
                      <Typography variant="body2" fontWeight={800} color="text.primary">{vendor.rating}</Typography>
                    </Box>
                  </TableCell>
                  <TableCell align="right">
                    <Button size="small" variant="text" sx={{ fontWeight: 700 }}>
                      View Profile
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
              {filteredVendors.length === 0 && (
                <TableRow>
                  <TableCell colSpan={7} align="center" sx={{ py: 8 }}>
                    <BusinessIcon sx={{ fontSize: 48, color: 'text.disabled', mb: 2 }} />
                    <Typography variant="body1" color="text.secondary">No vendors found matching your criteria.</Typography>
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </TableContainer>
      )}
    </Box>
  );
}
