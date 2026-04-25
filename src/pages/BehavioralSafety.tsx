import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy, doc, updateDoc } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { 
  Box, 
  Typography, 
  Grid, 
  Card, 
  CardContent, 
  Button, 
  TextField, 
  Select, 
  MenuItem, 
  Dialog, 
  DialogTitle, 
  DialogContent, 
  DialogActions, 
  IconButton, 
  Chip, 
  Tabs,
  Tab,
  FormControlLabel,
  Checkbox,
  Avatar,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow
} from '@mui/material';

// Icons
import VisibilityIcon from '@mui/icons-material/Visibility';
import EmojiObjectsIcon from '@mui/icons-material/EmojiObjects';
import EmojiEventsIcon from '@mui/icons-material/EmojiEvents';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import CancelIcon from '@mui/icons-material/Cancel';
import WarningAmberIcon from '@mui/icons-material/WarningAmber';
import ChatIcon from '@mui/icons-material/Chat';
import ThumbUpIcon from '@mui/icons-material/ThumbUp';
import ThumbDownIcon from '@mui/icons-material/ThumbDown';
import RemoveIcon from '@mui/icons-material/Remove';
import CameraAltIcon from '@mui/icons-material/CameraAlt';
import CloudUploadIcon from '@mui/icons-material/CloudUpload';
import AddIcon from '@mui/icons-material/Add';
import CloseIcon from '@mui/icons-material/Close';

interface BBSObservation {
  id: string;
  observerName?: string;
  location: string;
  observationType: 'Safe Act' | 'Unsafe Act' | 'Unsafe Condition';
  description: string;
  interventionAction?: string;
  pointsAwarded: number;
  authorId: string;
  createdAt: string;
}

interface SafetySuggestion {
  id: string;
  suggestionText: string;
  category: 'Process Improvement' | 'Hazard Removal' | 'Welfare' | 'Other';
  isAnonymous: boolean;
  aiSentiment: 'Positive' | 'Neutral' | 'Negative' | 'Pending';
  authorId: string;
  createdAt: string;
}

export default function BehavioralSafety() {
  const [activeTab, setActiveTab] = useState<'observations' | 'suggestions' | 'leaderboard' | 'ai_spotter'>('observations');
  const [observations, setObservations] = useState<BBSObservation[]>([]);
  const [suggestions, setSuggestions] = useState<SafetySuggestion[]>([]);
  
  const [isAddingObservation, setIsAddingObservation] = useState(false);
  const [isAddingSuggestion, setIsAddingSuggestion] = useState(false);

  // Observation Form
  const [isAnonymousObs, setIsAnonymousObs] = useState(false);
  const [location, setLocation] = useState('');
  const [observationType, setObservationType] = useState<BBSObservation['observationType']>('Safe Act');
  const [description, setDescription] = useState('');
  const [interventionAction, setInterventionAction] = useState('');

  // Suggestion Form
  const [suggestionText, setSuggestionText] = useState('');
  const [category, setCategory] = useState<SafetySuggestion['category']>('Process Improvement');
  const [isAnonymousSugg, setIsAnonymousSugg] = useState(false);

  useEffect(() => {
    if (!auth.currentUser) return;

    const qObs = query(collection(db, 'bbs_observations'), orderBy('createdAt', 'desc'));
    const unsubscribeObs = onSnapshot(qObs, (snapshot) => {
      const obsRecords = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as BBSObservation[];
      setObservations(obsRecords);
    }, (error) => {
      handleFirestoreError(error, 'list' as any, 'bbs_observations');
    });

    const qSugg = query(collection(db, 'safety_suggestions'), orderBy('createdAt', 'desc'));
    const unsubscribeSugg = onSnapshot(qSugg, (snapshot) => {
      const suggRecords = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as SafetySuggestion[];
      setSuggestions(suggRecords);
    }, (error) => {
      handleFirestoreError(error, 'list' as any, 'safety_suggestions');
    });

    return () => {
      unsubscribeObs();
      unsubscribeSugg();
    };
  }, []);

  const handleAddObservation = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;

    try {
      // Gamification logic: 10 points for Safe Act, 5 for Unsafe Act/Condition (for reporting it)
      const points = observationType === 'Safe Act' ? 10 : 5;

      const newObs: Omit<BBSObservation, 'id'> = {
        location,
        observationType,
        description,
        pointsAwarded: points,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      };

      if (!isAnonymousObs) {
        newObs.observerName = auth.currentUser.displayName || 'Unknown User';
      }
      if (interventionAction) {
        newObs.interventionAction = interventionAction;
      }

      await addDoc(collection(db, 'bbs_observations'), newObs);
      setIsAddingObservation(false);
      // Reset form
      setIsAnonymousObs(false);
      setLocation('');
      setObservationType('Safe Act');
      setDescription('');
      setInterventionAction('');
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'bbs_observations');
    }
  };

  const handleAddSuggestion = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;

    try {
      // In a real app, you would call a Cloud Function here to analyze sentiment via Gemini API.
      // For this prototype, we'll simulate it or set it to Pending.
      const simulatedSentiment = 
        suggestionText.toLowerCase().includes('great') || suggestionText.toLowerCase().includes('good') ? 'Positive' :
        suggestionText.toLowerCase().includes('bad') || suggestionText.toLowerCase().includes('terrible') ? 'Negative' : 'Neutral';

      const newSugg = {
        suggestionText,
        category,
        isAnonymous: isAnonymousSugg,
        aiSentiment: simulatedSentiment,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      };

      await addDoc(collection(db, 'safety_suggestions'), newSugg);
      setIsAddingSuggestion(false);
      // Reset form
      setSuggestionText('');
      setCategory('Process Improvement');
      setIsAnonymousSugg(false);
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'safety_suggestions');
    }
  };

  // Calculate Leaderboard
  const calculateLeaderboard = () => {
    const userPoints: Record<string, { name: string, points: number, obsCount: number }> = {};
    
    observations.forEach(obs => {
      if (obs.observerName) { // Only count non-anonymous
        if (!userPoints[obs.observerName]) {
          userPoints[obs.observerName] = { name: obs.observerName, points: 0, obsCount: 0 };
        }
        userPoints[obs.observerName].points += obs.pointsAwarded;
        userPoints[obs.observerName].obsCount += 1;
      }
    });

    return Object.values(userPoints).sort((a, b) => b.points - a.points);
  };

  const leaderboard = calculateLeaderboard();

  return (
    <Box sx={{ spaceY: 3 }}>
      <Box sx={{ display: 'flex', flexDirection: { xs: 'column', md: 'row' }, alignItems: { md: 'center' }, justifyContent: 'space-between', gap: 2, mb: 4 }}>
        <Box>
          <Typography variant="h5" sx={{ fontWeight: 700, display: 'flex', alignItems: 'center', gap: 1 }}>
            Behavioral Based Safety <VisibilityIcon color="primary" />
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Peer observations, safety culture, and gamification.
          </Typography>
        </Box>
        <Box sx={{ display: 'flex', gap: 2 }}>
          {activeTab === 'observations' && (
            <Button 
              variant="contained" 
              color="primary" 
              startIcon={<AddIcon />}
              onClick={() => setIsAddingObservation(true)}
              sx={{ boxShadow: 1 }}
            >
              Log Observation
            </Button>
          )}
          {activeTab === 'suggestions' && (
            <Button 
              variant="contained" 
              color="primary" 
              startIcon={<AddIcon />}
              onClick={() => setIsAddingSuggestion(true)}
              sx={{ boxShadow: 1 }}
            >
              Submit Suggestion
            </Button>
          )}
        </Box>
      </Box>

      {/* Tabs */}
      <Box sx={{ borderBottom: 1, borderColor: 'divider', mb: 3 }}>
        <Tabs 
          value={activeTab} 
          onChange={(_, newValue) => setActiveTab(newValue)} 
          variant="scrollable"
          scrollButtons="auto"
        >
          <Tab icon={<VisibilityIcon fontSize="small" />} iconPosition="start" label="BBS Observations" value="observations" sx={{ fontWeight: 600 }} />
          <Tab icon={<EmojiObjectsIcon fontSize="small" />} iconPosition="start" label="Suggestion Box" value="suggestions" sx={{ fontWeight: 600 }} />
          <Tab icon={<EmojiEventsIcon fontSize="small" />} iconPosition="start" label="Safety Leaderboard" value="leaderboard" sx={{ fontWeight: 600 }} />
          <Tab icon={<CameraAltIcon fontSize="small" />} iconPosition="start" label="AI Hazard Spotter" value="ai_spotter" sx={{ fontWeight: 600 }} />
        </Tabs>
      </Box>

      {/* Content Area */}
      <Box>
        
        {/* Observations Tab */}
        {activeTab === 'observations' && (
          <Grid container spacing={3}>
            {observations.map((obs) => (
              <Grid item xs={12} md={6} lg={4} key={obs.id}>
                <Card elevation={1} sx={{ borderRadius: 2, height: '100%', display: 'flex', flexDirection: 'column' }}>
                  <CardContent sx={{ flex: 1, p: 3 }}>
                    <Box sx={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', mb: 2 }}>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        {obs.observationType === 'Safe Act' ? (
                          <Avatar sx={{ bgcolor: 'success.light', color: 'success.main', width: 32, height: 32 }}>
                            <CheckCircleIcon fontSize="small" />
                          </Avatar>
                        ) : obs.observationType === 'Unsafe Act' ? (
                          <Avatar sx={{ bgcolor: 'error.light', color: 'error.main', width: 32, height: 32 }}>
                            <CancelIcon fontSize="small" />
                          </Avatar>
                        ) : (
                          <Avatar sx={{ bgcolor: 'warning.light', color: 'warning.main', width: 32, height: 32 }}>
                            <WarningAmberIcon fontSize="small" />
                          </Avatar>
                        )}
                        <Typography variant="subtitle2" sx={{ fontWeight: 700 }}>{obs.observationType}</Typography>
                      </Box>
                      <Chip 
                        icon={<EmojiEventsIcon fontSize="small" />} 
                        label={`+${obs.pointsAwarded}`} 
                        size="small" 
                        color="primary" 
                        sx={{ fontWeight: 600, bgcolor: 'primary.light', color: 'primary.dark', border: 'none' }} 
                        variant="outlined" 
                      />
                    </Box>
                    
                    <Typography variant="body2" color="text.secondary" sx={{ mb: 2, display: '-webkit-box', WebkitLineClamp: 3, WebkitBoxOrient: 'vertical', overflow: 'hidden' }} title={obs.description}>
                      "{obs.description}"
                    </Typography>
                    
                    {obs.interventionAction && (
                      <Box sx={{ bgcolor: 'background.default', p: 1.5, borderRadius: 1, border: '1px solid', borderColor: 'divider', mb: 2 }}>
                        <Typography variant="caption" sx={{ fontWeight: 700 }} color="text.secondary" display="block" mb={0.5}>Action Taken:</Typography>
                        <Typography variant="body2">{obs.interventionAction}</Typography>
                      </Box>
                    )}
                  </CardContent>
                  <Box sx={{ p: 2, pt: 0, display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderTop: '1px solid', borderColor: 'divider', mt: 'auto' }}>
                    <Typography variant="caption" color="text.secondary" sx={{ fontWeight: 500 }}>{obs.observerName || 'Anonymous'}</Typography>
                    <Typography variant="caption" color="text.secondary">{new Date(obs.createdAt).toLocaleDateString()}</Typography>
                  </Box>
                </Card>
              </Grid>
            ))}
            {observations.length === 0 && (
              <Grid item xs={12}>
                <Box sx={{ p: 6, textAlign: 'center', bgcolor: 'background.default', borderRadius: 2, border: '1px dashed', borderColor: 'divider' }}>
                  <Typography color="text.secondary">No BBS observations logged yet.</Typography>
                </Box>
              </Grid>
            )}
          </Grid>
        )}

        {/* Suggestions Tab */}
        {activeTab === 'suggestions' && (
          <Grid container spacing={3}>
            {suggestions.map((sugg) => (
              <Grid item xs={12} md={6} key={sugg.id}>
                <Card elevation={1} sx={{ borderRadius: 2 }}>
                  <CardContent>
                    <Box sx={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', mb: 2 }}>
                      <Chip label={sugg.category} size="small" sx={{ fontWeight: 600 }} />
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        {sugg.aiSentiment === 'Positive' && <Chip icon={<ThumbUpIcon fontSize="small" />} label="Positive" size="small" color="success" variant="outlined" />}
                        {sugg.aiSentiment === 'Negative' && <Chip icon={<ThumbDownIcon fontSize="small" />} label="Negative" size="small" color="error" variant="outlined" />}
                        {sugg.aiSentiment === 'Neutral' && <Chip icon={<RemoveIcon fontSize="small" />} label="Neutral" size="small" variant="outlined" />}
                        {sugg.aiSentiment === 'Pending' && <Chip label="Analyzing..." size="small" color="warning" variant="outlined" />}
                      </Box>
                    </Box>
                    
                    <Box sx={{ bgcolor: 'background.default', p: 2, borderRadius: 2, border: '1px solid', borderColor: 'divider', mb: 3 }}>
                      <Typography variant="body2" fontStyle="italic" color="text.secondary">
                        "{sugg.suggestionText}"
                      </Typography>
                    </Box>

                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, color: 'text.secondary' }}>
                        <ChatIcon fontSize="small" />
                        <Typography variant="caption" sx={{ fontWeight: 600 }}>
                          {sugg.isAnonymous ? 'Anonymous Submission' : 'Named Submission'}
                        </Typography>
                      </Box>
                      <Typography variant="caption" color="text.secondary">
                        {new Date(sugg.createdAt).toLocaleDateString()}
                      </Typography>
                    </Box>
                  </CardContent>
                </Card>
              </Grid>
            ))}
            {suggestions.length === 0 && (
              <Grid item xs={12}>
                <Box sx={{ p: 6, textAlign: 'center', bgcolor: 'background.default', borderRadius: 2, border: '1px dashed', borderColor: 'divider' }}>
                  <Typography color="text.secondary">No safety suggestions submitted yet.</Typography>
                </Box>
              </Grid>
            )}
          </Grid>
        )}

        {/* Leaderboard Tab */}
        {activeTab === 'leaderboard' && (
          <Box sx={{ maxWidth: 800, mx: 'auto' }}>
            <Box sx={{ textAlign: 'center', mb: 4, py: 6, px: 3, bgcolor: 'primary.50', borderRadius: 3, border: '1px solid', borderColor: 'primary.100' }}>
              <EmojiEventsIcon sx={{ fontSize: 64, color: 'primary.main', mb: 2 }} />
              <Typography variant="h4" sx={{ fontWeight: 700 }} color="text.primary" gutterBottom>Safety Champions</Typography>
              <Typography variant="body1" color="text.secondary">
                Earn points by logging BBS observations. 10pts for Safe Acts, 5pts for identifying and correcting Unsafe Acts/Conditions.
              </Typography>
            </Box>

            <TableContainer component={Card} elevation={0} sx={{ border: '1px solid', borderColor: 'divider', borderRadius: 2 }}>
              <Table>
                <TableHead>
                  <TableRow sx={{ bgcolor: 'background.default' }}>
                    <TableCell align="center" sx={{ width: 80, fontWeight: 600 }}>Rank</TableCell>
                    <TableCell sx={{ fontWeight: 600 }}>Employee Name</TableCell>
                    <TableCell align="center" sx={{ fontWeight: 600 }}>Observations</TableCell>
                    <TableCell align="right" sx={{ fontWeight: 600 }}>Total Points</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {leaderboard.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={4} align="center" sx={{ py: 4 }}>
                        <Typography color="text.secondary">No points awarded yet. Start observing!</Typography>
                      </TableCell>
                    </TableRow>
                  ) : (
                    leaderboard.map((user, index) => (
                      <TableRow key={user.name} hover>
                        <TableCell align="center">
                          {index === 0 ? <EmojiEventsIcon sx={{ color: '#fbbf24' }} /> : 
                           index === 1 ? <EmojiEventsIcon sx={{ color: '#94a3b8' }} /> : 
                           index === 2 ? <EmojiEventsIcon sx={{ color: '#d97706' }} /> : 
                           <Typography variant="body2" sx={{ fontWeight: 600 }} color="text.secondary">{index + 1}</Typography>}
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2" sx={{ fontWeight: 600 }}>{user.name}</Typography>
                        </TableCell>
                        <TableCell align="center">
                          <Chip label={user.obsCount} size="small" variant="outlined" />
                        </TableCell>
                        <TableCell align="right">
                          <Typography variant="body2" sx={{ fontWeight: 700 }} color="primary.main">{user.points} pts</Typography>
                        </TableCell>
                      </TableRow>
                    ))
                  )}
                </TableBody>
              </Table>
            </TableContainer>
          </Box>
        )}

        {/* AI Hazard Spotter Tab */}
        {activeTab === 'ai_spotter' && (
          <Box sx={{ p: 4, textAlign: 'center', maxWidth: 800, mx: 'auto', bgcolor: 'background.default', borderRadius: 3, border: '1px solid', borderColor: 'divider' }}>
            <Avatar sx={{ width: 80, height: 80, bgcolor: 'primary.light', color: 'primary.main', mx: 'auto', mb: 3 }}>
              <CameraAltIcon sx={{ fontSize: 40 }} />
            </Avatar>
            <Typography variant="h4" sx={{ fontWeight: 700 }} gutterBottom>AI Computer Vision Hazard Spotter</Typography>
            <Typography variant="body1" color="text.secondary" mb={4}>
              Upload a photo of a worksite, scaffolding, or machinery. Our Gemini Vision AI will scan the image for OHS Act violations, missing PPE, and unsafe conditions instantly.
            </Typography>
            
            <Box sx={{ border: '2px dashed', borderColor: 'primary.300', borderRadius: 3, p: 6, bgcolor: 'background.paper', cursor: 'pointer', '&:hover': { bgcolor: 'primary.50' }, transition: 'all 0.2s', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
              <CloudUploadIcon sx={{ fontSize: 48, color: 'primary.main', mb: 2 }} />
              <Typography variant="h6" sx={{ fontWeight: 600 }} mb={1}>Click to upload or drag and drop</Typography>
              <Typography variant="body2" color="text.secondary">PNG, JPG up to 10MB</Typography>
            </Box>

            <Box sx={{ mt: 4, bgcolor: 'info.light', p: 3, borderRadius: 2, display: 'flex', gap: 2, alignItems: 'flex-start', textAlign: 'left' }}>
              <WarningAmberIcon sx={{ color: 'info.main', flexShrink: 0 }} />
              <Typography variant="body2" color="info.dark">
                <strong>Future Proofing:</strong> This module is designed to integrate with site CCTV via API hooks to automatically log "Unsafe Acts" (e.g., forklift speeding, missing hardhats) into the BBS module without human intervention.
              </Typography>
            </Box>
          </Box>
        )}
      </Box>

      {/* Add Observation Dialog */}
      <Dialog open={isAddingObservation} onClose={() => setIsAddingObservation(false)} maxWidth="sm" fullWidth>
        <form onSubmit={handleAddObservation}>
          <DialogTitle sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <Typography variant="h6" sx={{ fontWeight: 700 }}>Log BBS Observation</Typography>
            <IconButton size="small" onClick={() => setIsAddingObservation(false)}>
              <CloseIcon />
            </IconButton>
          </DialogTitle>
          <DialogContent dividers>
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
              <Box sx={{ p: 2, bgcolor: 'background.default', borderRadius: 2, border: '1px solid', borderColor: 'divider' }}>
                <FormControlLabel
                  control={<Checkbox checked={isAnonymousObs} onChange={(e) => setIsAnonymousObs(e.target.checked)} color="primary" />}
                  label={<Typography variant="body2" sx={{ fontWeight: 600 }}>Submit Anonymously (No points awarded)</Typography>}
                />
              </Box>

              <Grid container spacing={2}>
                <Grid item xs={12} sm={6}>
                  <Typography variant="subtitle2" sx={{ fontWeight: 600 }} mb={1}>Observation Type</Typography>
                  <Select 
                    fullWidth 
                    size="small" 
                    value={observationType} 
                    onChange={(e) => setObservationType(e.target.value as any)}
                  >
                    <MenuItem value="Safe Act">Safe Act</MenuItem>
                    <MenuItem value="Unsafe Act">Unsafe Act</MenuItem>
                    <MenuItem value="Unsafe Condition">Unsafe Condition</MenuItem>
                  </Select>
                </Grid>
                <Grid item xs={12} sm={6}>
                  <Typography variant="subtitle2" sx={{ fontWeight: 600 }} mb={1}>Location</Typography>
                  <TextField 
                    fullWidth 
                    size="small" 
                    required 
                    value={location} 
                    onChange={(e) => setLocation(e.target.value)} 
                  />
                </Grid>
              </Grid>
              
              <Box>
                <Typography variant="subtitle2" sx={{ fontWeight: 600 }} mb={1}>Description</Typography>
                <TextField 
                  fullWidth 
                  size="small" 
                  required 
                  multiline 
                  rows={3} 
                  value={description} 
                  onChange={(e) => setDescription(e.target.value)} 
                  placeholder="What did you observe?"
                />
              </Box>

              {observationType !== 'Safe Act' && (
                <Box>
                  <Typography variant="subtitle2" sx={{ fontWeight: 600 }} mb={1}>Intervention Action</Typography>
                  <TextField 
                    fullWidth 
                    size="small" 
                    multiline 
                    rows={2} 
                    value={interventionAction} 
                    onChange={(e) => setInterventionAction(e.target.value)} 
                    placeholder="What did you do to correct it?"
                  />
                </Box>
              )}
            </Box>
          </DialogContent>
          <DialogActions sx={{ p: 2, px: 3 }}>
            <Button onClick={() => setIsAddingObservation(false)} color="inherit">Cancel</Button>
            <Button type="submit" variant="contained" color="primary">Save Observation</Button>
          </DialogActions>
        </form>
      </Dialog>

      {/* Add Suggestion Dialog */}
      <Dialog open={isAddingSuggestion} onClose={() => setIsAddingSuggestion(false)} maxWidth="sm" fullWidth>
        <form onSubmit={handleAddSuggestion}>
          <DialogTitle sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <Typography variant="h6" sx={{ fontWeight: 700 }}>Safety Suggestion Box</Typography>
            <IconButton size="small" onClick={() => setIsAddingSuggestion(false)}>
              <CloseIcon />
            </IconButton>
          </DialogTitle>
          <DialogContent dividers>
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
              <Box sx={{ p: 2, bgcolor: 'background.default', borderRadius: 2, border: '1px solid', borderColor: 'divider' }}>
                <FormControlLabel
                  control={<Checkbox checked={isAnonymousSugg} onChange={(e) => setIsAnonymousSugg(e.target.checked)} color="primary" />}
                  label={<Typography variant="body2" sx={{ fontWeight: 600 }}>Submit Anonymously</Typography>}
                />
              </Box>

              <Box>
                <Typography variant="subtitle2" sx={{ fontWeight: 600 }} mb={1}>Category</Typography>
                <Select 
                  fullWidth 
                  size="small" 
                  required 
                  value={category} 
                  onChange={(e) => setCategory(e.target.value as any)}
                >
                  <MenuItem value="Process Improvement">Process Improvement</MenuItem>
                  <MenuItem value="Hazard Removal">Hazard Removal</MenuItem>
                  <MenuItem value="Welfare">Welfare</MenuItem>
                  <MenuItem value="Other">Other</MenuItem>
                </Select>
              </Box>
              
              <Box>
                <Typography variant="subtitle2" sx={{ fontWeight: 600 }} mb={1}>Your Suggestion</Typography>
                <TextField 
                  fullWidth 
                  size="small" 
                  required 
                  multiline 
                  rows={4} 
                  value={suggestionText} 
                  onChange={(e) => setSuggestionText(e.target.value)} 
                  placeholder="How can we improve safety on site?"
                />
              </Box>
            </Box>
          </DialogContent>
          <DialogActions sx={{ p: 2, px: 3 }}>
            <Button onClick={() => setIsAddingSuggestion(false)} color="inherit">Cancel</Button>
            <Button type="submit" variant="contained" color="primary">Submit Suggestion</Button>
          </DialogActions>
        </form>
      </Dialog>

    </Box>
  );
}
