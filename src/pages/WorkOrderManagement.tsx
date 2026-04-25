import React, { useState, useEffect } from 'react';
import { collection, query, onSnapshot, orderBy, addDoc, serverTimestamp, doc, updateDoc, where } from 'firebase/firestore';
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
  Button,
  Chip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  CircularProgress,
  IconButton,
  Divider,
  CardActions
} from '@mui/material';

import BuildIcon from '@mui/icons-material/Build';
import AddIcon from '@mui/icons-material/Add';
import SearchIcon from '@mui/icons-material/Search';
import FilterListIcon from '@mui/icons-material/FilterList';
import AccessTimeIcon from '@mui/icons-material/AccessTime';
import BusinessIcon from '@mui/icons-material/Business';
import CloseIcon from '@mui/icons-material/Close';

interface WorkOrder {
  id: string;
  title: string;
  description: string;
  siteId: string;
  priority: 'Low' | 'Medium' | 'High' | 'Critical';
  status: 'Open' | 'In Progress' | 'Pending Vendor' | 'Resolved' | 'Closed';
  assignedTo?: string;
  contractorId?: string;
  equipmentId?: string;
  slaDeadline: string;
  createdAt: any;
  authorId: string;
}

export default function WorkOrderManagement() {
  const { profile } = useAuth();
  const [workOrders, setWorkOrders] = useState<WorkOrder[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('All');
  const [isModalOpen, setIsModalOpen] = useState(false);

  // Form State
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [priority, setPriority] = useState<'Low' | 'Medium' | 'High' | 'Critical'>('Medium');
  const [siteId, setSiteId] = useState(profile?.siteId || '');
  const [slaDays, setSlaDays] = useState(3);

  useEffect(() => {
    if (!profile) return;

    // If executive/admin, they can see all. Otherwise, only their site.
    const isGlobal = profile.role === 'admin' || profile.role === 'executive';
    
    let q = query(collection(db, 'work_orders'), orderBy('createdAt', 'desc'));
    
    if (!isGlobal && profile.siteId) {
      q = query(collection(db, 'work_orders'), where('siteId', '==', profile.siteId), orderBy('createdAt', 'desc'));
    }

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data: WorkOrder[] = [];
      snapshot.forEach((doc) => {
        data.push({ id: doc.id, ...doc.data() } as WorkOrder);
      });
      setWorkOrders(data);
      setLoading(false);
    }, (error) => {
      handleFirestoreError(error, OperationType.LIST, 'work_orders');
      setLoading(false);
    });

    return () => unsubscribe();
  }, [profile]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!profile) return;

    const deadline = new Date();
    deadline.setDate(deadline.getDate() + slaDays);

    try {
      await addDoc(collection(db, 'work_orders'), {
        title,
        description,
        siteId: siteId || profile.siteId || 'Global',
        priority,
        status: 'Open',
        slaDeadline: deadline.toISOString(),
        authorId: profile.uid,
        createdAt: serverTimestamp()
      });
      setIsModalOpen(false);
      // Reset form
      setTitle('');
      setDescription('');
      setPriority('Medium');
      setSlaDays(3);
    } catch (error) {
      handleFirestoreError(error, OperationType.CREATE, 'work_orders');
    }
  };

  const updateStatus = async (id: string, newStatus: WorkOrder['status']) => {
    try {
      await updateDoc(doc(db, 'work_orders', id), { status: newStatus });
    } catch (error) {
      handleFirestoreError(error, OperationType.UPDATE, `work_orders/${id}`);
    }
  };

  const filteredOrders = workOrders.filter(wo => {
    const matchesSearch = wo.title.toLowerCase().includes(searchTerm.toLowerCase()) || 
                          wo.description.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = statusFilter === 'All' || wo.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'Critical': return 'error';
      case 'High': return 'warning';
      case 'Medium': return 'info';
      case 'Low': return 'default';
      default: return 'default';
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'Open': return 'default';
      case 'In Progress': return 'info';
      case 'Pending Vendor': return 'warning';
      case 'Resolved': return 'success';
      case 'Closed': return 'default';
      default: return 'default';
    }
  };

  return (
    <Box sx={{ p: { xs: 2, md: 4 }, maxWidth: 1400, mx: 'auto', flexGrow: 1 }}>
      <Box sx={{ display: 'flex', flexDirection: { xs: 'column', md: 'row' }, justifyContent: 'space-between', alignItems: { xs: 'flex-start', md: 'center' }, gap: 2, mb: 4 }}>
        <Box>
          <Typography variant="h4" component="h1" sx={{ fontWeight: '700', color: 'text.primary', letterSpacing: '-0.5px' }}>
            Centralized Work Orders
          </Typography>
          <Typography variant="subtitle1" sx={{ color: 'text.secondary', mt: 0.5 }}>
            Manage facility maintenance and vendor SLAs across the portfolio.
          </Typography>
        </Box>
        <Button 
          variant="contained" 
          color="primary" 
          startIcon={<AddIcon />} 
          onClick={() => setIsModalOpen(true)}
          sx={{ boxShadow: 1 }}
        >
          New Work Order
        </Button>
      </Box>

      {/* Filters */}
      <Card elevation={0} sx={{ p: 2, mb: 4, borderRadius: 2, border: '1px solid', borderColor: 'divider' }}>
        <Grid container spacing={2} alignItems="center">
          <Grid item xs={12} md={8}>
            <TextField 
              fullWidth 
              size="small" 
              placeholder="Search work orders..." 
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
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value as string)}
              >
                <MenuItem value="All">All Statuses</MenuItem>
                <MenuItem value="Open">Open</MenuItem>
                <MenuItem value="In Progress">In Progress</MenuItem>
                <MenuItem value="Pending Vendor">Pending Vendor</MenuItem>
                <MenuItem value="Resolved">Resolved</MenuItem>
                <MenuItem value="Closed">Closed</MenuItem>
              </Select>
            </Box>
          </Grid>
        </Grid>
      </Card>

      {/* Work Order Grid */}
      {loading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}>
          <CircularProgress />
        </Box>
      ) : (
        <Grid container spacing={3}>
          {filteredOrders.map(wo => {
            const isOverdue = new Date(wo.slaDeadline) < new Date() && wo.status !== 'Closed' && wo.status !== 'Resolved';
            return (
              <Grid item xs={12} md={6} lg={4} key={wo.id}>
                <Card elevation={1} sx={{ display: 'flex', flexDirection: 'column', height: '100%', borderRadius: 2, '&:hover': { boxShadow: 4 }, transition: 'box-shadow 0.2s' }}>
                  <CardContent sx={{ flex: 1, p: 3 }}>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2 }}>
                      <Chip label={`${wo.priority} Priority`} color={getPriorityColor(wo.priority) as any} size="small" sx={{ fontWeight: 600, fontSize: '0.7rem' }} />
                      <Chip label={wo.status} color={getStatusColor(wo.status) as any} size="small" variant={wo.status === 'Closed' ? 'outlined' : 'filled'} sx={{ fontWeight: 600, fontSize: '0.7rem' }} />
                    </Box>
                    <Typography variant="h6" component="h3" sx={{ fontWeight: 700, mb: 1, display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>
                      {wo.title}
                    </Typography>
                    <Typography variant="body2" color="text.secondary" sx={{ mb: 3, display: '-webkit-box', WebkitLineClamp: 3, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>
                      {wo.description}
                    </Typography>
                    
                    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1.5 }}>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, color: 'text.secondary' }}>
                        <BusinessIcon fontSize="small" />
                        <Typography variant="body2" fontWeight={500}>{wo.siteId}</Typography>
                      </Box>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, color: isOverdue ? 'error.main' : 'text.secondary' }}>
                        <AccessTimeIcon fontSize="small" />
                        <Typography variant="body2" fontWeight={isOverdue ? 700 : 500}>
                          SLA: {new Date(wo.slaDeadline).toLocaleDateString()}
                        </Typography>
                      </Box>
                    </Box>
                  </CardContent>
                  <Divider />
                  <CardActions sx={{ px: 3, py: 2, bgcolor: 'background.default', justifyContent: 'space-between' }}>
                    <Select
                      size="small"
                      value={wo.status}
                      onChange={(e) => updateStatus(wo.id, e.target.value as WorkOrder['status'])}
                      sx={{ bgcolor: 'background.paper', minWidth: 140, fontSize: '0.875rem' }}
                    >
                      <MenuItem value="Open">Open</MenuItem>
                      <MenuItem value="In Progress">In Progress</MenuItem>
                      <MenuItem value="Pending Vendor">Pending Vendor</MenuItem>
                      <MenuItem value="Resolved">Resolved</MenuItem>
                      <MenuItem value="Closed">Closed</MenuItem>
                    </Select>
                    <Button size="small" variant="text" sx={{ fontWeight: 700 }}>
                      View Details
                    </Button>
                  </CardActions>
                </Card>
              </Grid>
            )
          })}
          {filteredOrders.length === 0 && (
            <Grid item xs={12}>
              <Box sx={{ py: 8, textAlign: 'center', border: '1px dashed', borderColor: 'divider', borderRadius: 2, bgcolor: 'background.paper' }}>
                <BuildIcon sx={{ fontSize: 48, color: 'text.disabled', mb: 2 }} />
                <Typography color="text.secondary">No work orders found.</Typography>
              </Box>
            </Grid>
          )}
        </Grid>
      )}

      {/* New Work Order Modal */}
      <Dialog 
        open={isModalOpen} 
        onClose={() => setIsModalOpen(false)}
        maxWidth="sm"
        fullWidth
        PaperProps={{ sx: { borderRadius: 3 } }}
      >
        <DialogTitle sx={{ m: 0, p: 3, pb: 2, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Typography variant="h6" fontWeight={700}>Create Work Order</Typography>
          <IconButton onClick={() => setIsModalOpen(false)} size="small" sx={{ color: 'text.secondary' }}>
            <CloseIcon />
          </IconButton>
        </DialogTitle>
        <Divider />
        <form onSubmit={handleSubmit}>
          <DialogContent sx={{ p: 3, display: 'flex', flexDirection: 'column', gap: 3 }}>
            <Box>
              <Typography variant="subtitle2" fontWeight={600} mb={1}>Title</Typography>
              <TextField 
                required
                fullWidth
                size="small"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="e.g., HVAC Repair - Floor 3"
              />
            </Box>
            <Box>
              <Typography variant="subtitle2" fontWeight={600} mb={1}>Description</Typography>
              <TextField 
                required
                fullWidth
                multiline
                rows={4}
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="Detailed description of the issue..."
              />
            </Box>
            <Grid container spacing={2}>
              <Grid item xs={6}>
                <Typography variant="subtitle2" fontWeight={600} mb={1}>Priority</Typography>
                <Select 
                  fullWidth
                  size="small"
                  value={priority}
                  onChange={(e) => setPriority(e.target.value as any)}
                >
                  <MenuItem value="Low">Low</MenuItem>
                  <MenuItem value="Medium">Medium</MenuItem>
                  <MenuItem value="High">High</MenuItem>
                  <MenuItem value="Critical">Critical</MenuItem>
                </Select>
              </Grid>
              <Grid item xs={6}>
                <Typography variant="subtitle2" fontWeight={600} mb={1}>SLA (Days to Resolve)</Typography>
                <TextField 
                  fullWidth
                  size="small"
                  type="number"
                  inputProps={{ min: 1 }}
                  required
                  value={slaDays}
                  onChange={(e) => setSlaDays(parseInt(e.target.value))}
                />
              </Grid>
            </Grid>
            {(profile?.role === 'admin' || profile?.role === 'executive') && (
              <Box>
                <Typography variant="subtitle2" fontWeight={600} mb={1}>Site ID</Typography>
                <TextField 
                  fullWidth
                  size="small"
                  value={siteId}
                  onChange={(e) => setSiteId(e.target.value)}
                  placeholder="e.g., LDN-01"
                />
              </Box>
            )}
          </DialogContent>
          <Divider />
          <DialogActions sx={{ p: 3 }}>
            <Button onClick={() => setIsModalOpen(false)} color="inherit" sx={{ fontWeight: 600 }}>
              Cancel
            </Button>
            <Button type="submit" variant="contained" color="primary" sx={{ fontWeight: 600 }}>
              Create Work Order
            </Button>
          </DialogActions>
        </form>
      </Dialog>
    </Box>
  );
}
