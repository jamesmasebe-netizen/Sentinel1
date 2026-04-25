import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy, deleteDoc, doc } from 'firebase/firestore';
import { db, handleFirestoreError, OperationType } from '../lib/firebase';
import { useAuth } from '../contexts/AuthContext';
import { 
  Box, Typography, Button, TextField, Grid, Checkbox, 
  FormControlLabel, Paper, Card, CardContent, CardActions, 
  IconButton, Chip, Divider, CircularProgress
} from '@mui/material';
import AddIcon from '@mui/icons-material/Add';
import DeleteIcon from '@mui/icons-material/Delete';
import LocationOnIcon from '@mui/icons-material/LocationOn';
import AssignmentIcon from '@mui/icons-material/Assignment';
import WarningAmberIcon from '@mui/icons-material/WarningAmber';

export interface DRA {
  id: string;
  taskDescription: string;
  location: string;
  hazardsIdentified: string[];
  controlsApplied: string[];
  isSafeToProceed: boolean;
  authorId: string;
  authorName: string;
  createdAt: string;
}

export default function DynamicRiskAssessment() {
  const { user } = useAuth();
  const [dras, setDras] = useState<DRA[]>([]);
  const [isCreating, setIsCreating] = useState(false);
  const [loading, setLoading] = useState(true);

  // Form state
  const [taskDescription, setTaskDescription] = useState('');
  const [location, setLocation] = useState('');
  const [hazards, setHazards] = useState<string[]>([]);
  const [controls, setControls] = useState<string[]>([]);
  const [isSafe, setIsSafe] = useState(false);
  
  const [currentHazard, setCurrentHazard] = useState('');
  const [currentControl, setCurrentControl] = useState('');

  useEffect(() => {
    if (!user) return;
    const q = query(collection(db, 'dynamic_risk_assessments'), orderBy('createdAt', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data: DRA[] = [];
      snapshot.forEach((doc) => {
        data.push({ id: doc.id, ...doc.data() } as DRA);
      });
      setDras(data);
      setLoading(false);
    }, (error) => {
      handleFirestoreError(error, OperationType.LIST, 'dynamic_risk_assessments');
      setLoading(false);
    });
    return () => unsubscribe();
  }, [user]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user) return;
    if (hazards.length === 0 || controls.length === 0) {
      alert("Please identify at least one hazard and one control.");
      return;
    }
    try {
      await addDoc(collection(db, 'dynamic_risk_assessments'), {
        taskDescription,
        location,
        hazardsIdentified: hazards,
        controlsApplied: controls,
        isSafeToProceed: isSafe,
        authorId: user.uid,
        authorName: user.displayName || 'Unknown User',
        createdAt: new Date().toISOString()
      });
      setIsCreating(false);
      setTaskDescription('');
      setLocation('');
      setHazards([]);
      setControls([]);
      setIsSafe(false);
    } catch (error) {
      handleFirestoreError(error, OperationType.CREATE, 'dynamic_risk_assessments');
    }
  };

  const handleDelete = async (id: string) => {
    if (!window.confirm('Delete this DRA?')) return;
    try {
      await deleteDoc(doc(db, 'dynamic_risk_assessments', id));
    } catch (error) {
      handleFirestoreError(error, OperationType.DELETE, `dynamic_risk_assessments/${id}`);
    }
  };

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
      <Box sx={{ display: 'flex', justifyContent: 'flex-end' }}>
        <Button
          variant="contained"
          onClick={() => setIsCreating(!isCreating)}
          startIcon={<AddIcon />}
          sx={{
            bgcolor: 'warning.main',
            '&:hover': { bgcolor: 'warning.dark' }
          }}
        >
          {isCreating ? 'Cancel' : 'New DRA'}
        </Button>
      </Box>

      {isCreating && (
        <Paper 
          elevation={0}
          component="form" 
          onSubmit={handleSubmit}
          sx={{ 
            p: 3, 
            border: 1, 
            borderColor: 'warning.light', 
            borderRadius: 2,
            bgcolor: 'background.paper'
          }}
        >
          <Typography variant="h6" sx={{ mb: 3, borderBottom: 1, pb: 1, borderColor: 'divider', color: 'warning.main', fontWeight: 600 }}>
            New On-the-Spot Assessment
          </Typography>
          
          <Grid container spacing={3} sx={{ mb: 3 }}>
            <Grid item xs={12}>
              <TextField
                fullWidth
                required
                label="Task Description"
                variant="outlined"
                value={taskDescription}
                onChange={(e) => setTaskDescription(e.target.value)}
                placeholder="What task are you about to perform?"
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                required
                label="Location"
                variant="outlined"
                value={location}
                onChange={(e) => setLocation(e.target.value)}
                placeholder="Specific area"
              />
            </Grid>
          </Grid>

          <Grid container spacing={3} sx={{ mb: 3 }}>
            <Grid item xs={12} md={6}>
              <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 600 }}>Hazards Identified</Typography>
              <Box sx={{ display: 'flex', gap: 1, mb: 1 }}>
                <TextField
                  fullWidth
                  size="small"
                  value={currentHazard}
                  onChange={(e) => setCurrentHazard(e.target.value)}
                  placeholder="Add hazard..."
                />
                <Button 
                  variant="contained" 
                  color="inherit"
                  sx={{ bgcolor: 'grey.800', color: 'white', '&:hover': { bgcolor: 'grey.900' } }}
                  onClick={() => { if(currentHazard) { setHazards([...hazards, currentHazard]); setCurrentHazard(''); } }}
                >
                  Add
                </Button>
              </Box>
              <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1 }}>
                {hazards.map((h, i) => (
                  <Chip 
                    key={i} 
                    label={h} 
                    onDelete={() => setHazards(hazards.filter((_, idx) => idx !== i))}
                    color="error"
                    variant="outlined"
                    size="small"
                    sx={{ bgcolor: 'error.50' }}
                  />
                ))}
              </Box>
            </Grid>

            <Grid item xs={12} md={6}>
              <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 600 }}>Controls Applied</Typography>
              <Box sx={{ display: 'flex', gap: 1, mb: 1 }}>
                <TextField
                  fullWidth
                  size="small"
                  value={currentControl}
                  onChange={(e) => setCurrentControl(e.target.value)}
                  placeholder="Add control..."
                />
                <Button 
                  variant="contained" 
                  color="inherit"
                  sx={{ bgcolor: 'grey.800', color: 'white', '&:hover': { bgcolor: 'grey.900' } }}
                  onClick={() => { if(currentControl) { setControls([...controls, currentControl]); setCurrentControl(''); } }}
                >
                  Add
                </Button>
              </Box>
              <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1 }}>
                {controls.map((c, i) => (
                  <Chip 
                    key={i} 
                    label={c} 
                    onDelete={() => setControls(controls.filter((_, idx) => idx !== i))}
                    color="success"
                    variant="outlined"
                    size="small"
                    sx={{ bgcolor: 'success.50' }}
                  />
                ))}
              </Box>
            </Grid>
          </Grid>

          <Box sx={{ p: 2, bgcolor: 'warning.50', border: 1, borderColor: 'warning.100', borderRadius: 1, mb: 3 }}>
            <FormControlLabel
              control={
                <Checkbox
                  checked={isSafe}
                  onChange={(e) => setIsSafe(e.target.checked)}
                  color="warning"
                />
              }
              label={
                <Typography variant="body2" sx={{ fontWeight: 700, textTransform: 'uppercase', color: 'warning.900' }}>
                  I confirm that it is safe to proceed with the task
                </Typography>
              }
            />
          </Box>

          <Box sx={{ display: 'flex', justifyContent: 'flex-end' }}>
            <Button
              type="submit"
              variant="contained"
              disabled={!isSafe}
              sx={{ 
                bgcolor: 'warning.main', 
                color: 'white', 
                px: 4,
                '&:hover': { bgcolor: 'warning.dark' }
              }}
            >
              Submit DRA
            </Button>
          </Box>
        </Paper>
      )}

      <Paper elevation={0} sx={{ border: 1, borderColor: 'divider', borderRadius: 2, overflow: 'hidden' }}>
        <Box sx={{ p: 2, borderBottom: 1, borderColor: 'divider', bgcolor: 'grey.50' }}>
          <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>DRA History</Typography>
        </Box>

        {loading ? (
          <Box sx={{ p: 6, display: 'flex', justifyContent: 'center' }}>
            <CircularProgress size={24} />
          </Box>
        ) : dras.length === 0 ? (
          <Box sx={{ p: 6, display: 'flex', flexDirection: 'column', alignItems: 'center', color: 'text.secondary' }}>
            <AssignmentIcon sx={{ fontSize: 48, color: 'text.disabled', mb: 2 }} />
            <Typography>No dynamic risk assessments found.</Typography>
          </Box>
        ) : (
          <Grid container spacing={3} sx={{ p: 3 }}>
            {dras.map((dra) => (
              <Grid item xs={12} md={6} lg={4} key={dra.id}>
                <Card elevation={0} sx={{ border: 1, borderColor: 'divider', display: 'flex', flexDirection: 'column', height: '100%' }}>
                  <Box sx={{ p: 2, borderBottom: 1, borderColor: 'divider', bgcolor: 'grey.50', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <WarningAmberIcon sx={{ color: 'warning.main', fontSize: 16 }} />
                      <Typography variant="caption" sx={{ fontWeight: 700, color: 'text.secondary', textTransform: 'uppercase', letterSpacing: 1 }}>
                        DRA
                      </Typography>
                    </Box>
                    <IconButton size="small" onClick={() => handleDelete(dra.id)} color="error" sx={{ opacity: 0.7, '&:hover': { opacity: 1 } }}>
                      <DeleteIcon fontSize="small" />
                    </IconButton>
                  </Box>

                  <CardContent sx={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 2 }}>
                    <Box>
                      <Typography variant="subtitle1" sx={{ fontWeight: 700, mb: 0.5 }}>
                        {dra.taskDescription}
                      </Typography>
                      <Typography variant="caption" color="text.secondary" sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                        <LocationOnIcon sx={{ fontSize: 14 }} /> {dra.location}
                      </Typography>
                    </Box>

                    <Box>
                      <Typography variant="overline" sx={{ display: 'block', mb: 0.5, lineHeight: 1, color: 'text.disabled', fontWeight: 700 }}>
                        Hazards
                      </Typography>
                      <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                        {dra.hazardsIdentified.map((h, i) => (
                          <Chip key={i} label={h} size="small" variant="outlined" color="error" sx={{ height: 20, fontSize: '0.65rem' }} />
                        ))}
                      </Box>
                    </Box>

                    <Box>
                      <Typography variant="overline" sx={{ display: 'block', mb: 0.5, lineHeight: 1, color: 'text.disabled', fontWeight: 700 }}>
                        Controls
                      </Typography>
                      <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                        {dra.controlsApplied.map((c, i) => (
                          <Chip key={i} label={c} size="small" variant="outlined" color="success" sx={{ height: 20, fontSize: '0.65rem' }} />
                        ))}
                      </Box>
                    </Box>
                  </CardContent>

                  <Box sx={{ p: 2, bgcolor: 'grey.50', borderTop: 1, borderColor: 'divider', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <Box sx={{ width: 8, height: 8, borderRadius: '50%', bgcolor: dra.isSafeToProceed ? 'success.main' : 'error.main' }} />
                      <Typography variant="caption" sx={{ fontWeight: 700, color: 'text.secondary', textTransform: 'uppercase' }}>
                        {dra.isSafeToProceed ? 'Safe to Proceed' : 'Unsafe'}
                      </Typography>
                    </Box>
                    <Box sx={{ textAlign: 'right' }}>
                      <Typography variant="caption" sx={{ display: 'block', fontWeight: 600 }}>{dra.authorName}</Typography>
                      <Typography variant="caption" color="text.secondary">{new Date(dra.createdAt).toLocaleDateString()}</Typography>
                    </Box>
                  </Box>
                </Card>
              </Grid>
            ))}
          </Grid>
        )}
      </Paper>
    </Box>
  );
}
