import React from 'react';
import { NavLink, Outlet, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { 
  Box,
  Drawer,
  AppBar,
  Toolbar,
  List,
  Typography,
  Divider,
  IconButton,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Badge,
  Avatar,
  Menu,
  MenuItem,
  ListSubheader,
  Tooltip,
  Fab
} from '@mui/material';

// Material Icons
import DashboardIcon from '@mui/icons-material/Dashboard';
import LanguageIcon from '@mui/icons-material/Language';
import ShowChartIcon from '@mui/icons-material/ShowChart';
import GppMaybeIcon from '@mui/icons-material/GppMaybe';
import BuildIcon from '@mui/icons-material/Build';
import GroupsIcon from '@mui/icons-material/Groups';
import SecurityIcon from '@mui/icons-material/Security';
import AssignmentIcon from '@mui/icons-material/Assignment';
import WarningAmberIcon from '@mui/icons-material/WarningAmber';
import HealthAndSafetyIcon from '@mui/icons-material/HealthAndSafety';
import VerifiedUserIcon from '@mui/icons-material/VerifiedUser';
import NatureIcon from '@mui/icons-material/Nature';
import ContentPasteGoIcon from '@mui/icons-material/ContentPasteGo';
import AccountBalanceIcon from '@mui/icons-material/AccountBalance';
import CastForEducationIcon from '@mui/icons-material/CastForEducation';
import MenuIcon from '@mui/icons-material/Menu';
import LogoutIcon from '@mui/icons-material/Logout';
import AddIcon from '@mui/icons-material/Add';
import ReportProblemIcon from '@mui/icons-material/ReportProblem';

import NotificationCenter from './NotificationCenter';
import GlobalSearch from './GlobalSearch';

const DRAWER_WIDTH = 280;

export default function Layout() {
  const { user, profile, signOut } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();
  
  const [mobileOpen, setMobileOpen] = React.useState(false);
  const [quickActionAnchorEl, setQuickActionAnchorEl] = React.useState<null | HTMLElement>(null);

  const isExec = profile?.role === 'admin' || profile?.role === 'executive';

  const handleDrawerToggle = () => {
    setMobileOpen(!mobileOpen);
  };

  const navGroups = [
    {
      title: 'Command Center',
      items: [
        { to: '/', icon: DashboardIcon, label: 'Overview Dashboard' },
        ...(isExec ? [
          { to: '/portfolio', icon: LanguageIcon, label: 'Global Portfolio' },
          { to: '/financials', icon: ShowChartIcon, label: 'Asset Financials' },
          { to: '/enterprise-risk-esg', icon: GppMaybeIcon, label: 'Enterprise Risk & ESG' },
        ] : []),
      ]
    },
    {
      title: 'Asset Operations',
      items: [
        ...(isExec ? [
          { to: '/work-orders', icon: BuildIcon, label: 'Enterprise Work Orders' },
          { to: '/vendors', icon: GroupsIcon, label: 'Enterprise Vendors' },
        ] : []),
        { to: '/safety', icon: SecurityIcon, label: 'Safety Operations' },
        { to: '/action-items', icon: AssignmentIcon, label: 'Unified Action Tracker' },
      ]
    },
    {
      title: 'HSE & Compliance',
      items: [
        { to: '/risk', icon: WarningAmberIcon, label: 'Risk Intelligence' },
        { to: '/health', icon: HealthAndSafetyIcon, label: 'Occupational Health' },
        { to: '/contractors-permits', icon: VerifiedUserIcon, label: 'Contractors & Permits' },
        { to: '/environment', icon: NatureIcon, label: 'Environment & ESG' },
        { to: '/quality', icon: ContentPasteGoIcon, label: 'Quality (ISO 9001)' },
      ]
    },
    {
      title: 'Strategy & People',
      items: [
        { to: '/governance', icon: AccountBalanceIcon, label: 'Governance & Strategy' },
        { to: '/people', icon: CastForEducationIcon, label: 'Training & Competency' },
      ]
    }
  ];

  const quickActions = [
    { name: 'Report Incident', icon: ReportProblemIcon, color: '#dc2626', path: '/safety?tab=incidents' },
    { name: 'Log Hazard', icon: WarningAmberIcon, color: '#d97706', path: '/safety?tab=hazards' },
    { name: 'New Permit', icon: VerifiedUserIcon, color: '#059669', path: '/safety?tab=permits' },
    { name: 'Create Work Order', icon: BuildIcon, color: '#2563eb', path: '/work-orders' },
    { name: 'Log Risk Event', icon: GppMaybeIcon, color: '#9333ea', path: '/risk' },
  ];

  const drawerContent = (
    <Box sx={{ display: 'flex', flexDirection: 'column', height: '100%', bgcolor: '#0f172a', color: '#f8fafc' }}>
      <Box sx={{ p: 3, display: 'flex', alignItems: 'center', gap: 2, borderBottom: '1px solid rgba(255,255,255,0.05)' }}>
        <Avatar variant="rounded" sx={{ bgcolor: 'info.main', width: 40, height: 40, boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)' }}>
          <SecurityIcon />
        </Avatar>
        <Box>
          <Typography variant="h6" sx={{ fontWeight: 900, letterSpacing: '-0.5px', lineHeight: 1 }}>SHEQ</Typography>
          <Typography variant="caption" sx={{ color: '#94a3b8', fontWeight: 700, letterSpacing: 1 }}>ENTERPRISE</Typography>
        </Box>
      </Box>

      <Box sx={{ flex: 1, overflowY: 'auto', p: 2, '&::-webkit-scrollbar': { display: 'none' } }}>
        {navGroups.map((group, idx) => (
          <List 
            key={idx}
            subheader={
              <ListSubheader 
                sx={{ 
                  bgcolor: 'transparent', 
                  color: '#64748b', 
                  fontWeight: 800, 
                  fontSize: '0.65rem', 
                  letterSpacing: 1.5,
                  textTransform: 'uppercase',
                  lineHeight: 1,
                  mb: 1,
                  mt: idx > 0 ? 2 : 0
                }}
              >
                {group.title}
              </ListSubheader>
            }
          >
            {group.items.map((item) => {
              const isActive = location.pathname === item.to || (item.to !== '/' && location.pathname.startsWith(item.to));
              return (
                <ListItem key={item.to} disablePadding sx={{ mb: 0.5 }}>
                  <ListItemButton 
                    component={NavLink} 
                    to={item.to}
                    sx={{ 
                      borderRadius: 1.5, 
                      bgcolor: isActive ? 'rgba(37, 99, 235, 0.15)' : 'transparent',
                      color: isActive ? '#60a5fa' : '#94a3b8',
                      '&:hover': {
                        bgcolor: isActive ? 'rgba(37, 99, 235, 0.25)' : 'rgba(255,255,255,0.05)',
                        color: isActive ? '#60a5fa' : '#f8fafc'
                      }
                    }}
                  >
                    <ListItemIcon sx={{ minWidth: 40, color: 'inherit' }}>
                      <item.icon fontSize="small" />
                    </ListItemIcon>
                    <ListItemText 
                      primary={
                        <Typography sx={{ fontSize: '0.875rem', fontWeight: isActive ? 700 : 600 }}>
                          {item.label}
                        </Typography>
                      }
                    />
                  </ListItemButton>
                </ListItem>
              );
            })}
          </List>
        ))}
      </Box>

      <Box sx={{ p: 2, borderTop: '1px solid rgba(255,255,255,0.05)' }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, p: 1.5, bgcolor: 'rgba(255,255,255,0.03)', borderRadius: 2, border: '1px solid rgba(255,255,255,0.05)' }}>
          <Avatar 
            src={user?.photoURL || `https://ui-avatars.com/api/?name=${user?.displayName || 'User'}`} 
            alt="Profile"
            variant="rounded"
            sx={{ width: 40, height: 40, border: '1px solid rgba(255,255,255,0.1)' }}
          />
          <Box sx={{ flex: 1, overflow: 'hidden' }}>
            <Typography variant="body2" sx={{ fontWeight: 700, minWidth: 0, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
              {user?.displayName || 'User'}
            </Typography>
            <Typography variant="caption" sx={{ color: '#94a3b8', display: 'block', textTransform: 'capitalize' }}>
              {profile?.role || 'Guest'}
            </Typography>
          </Box>
          <IconButton onClick={() => signOut()} size="small" sx={{ color: '#94a3b8', '&:hover': { color: '#ef4444', bgcolor: 'rgba(239, 68, 68, 0.1)' } }}>
            <LogoutIcon fontSize="small" />
          </IconButton>
        </Box>
      </Box>
    </Box>
  );

  return (
    <Box sx={{ display: 'flex', minHeight: '100vh', bgcolor: 'background.default' }}>
      {/* Mobile Drawer */}
      <Drawer
        variant="temporary"
        open={mobileOpen}
        onClose={handleDrawerToggle}
        ModalProps={{ keepMounted: true }}
        sx={{
          display: { xs: 'block', md: 'none' },
          '& .MuiDrawer-paper': { boxSizing: 'border-box', width: DRAWER_WIDTH, borderRight: 'none' },
        }}
      >
        {drawerContent}
      </Drawer>

      {/* Desktop Drawer */}
      <Drawer
        variant="permanent"
        sx={{
          display: { xs: 'none', md: 'block' },
          '& .MuiDrawer-paper': { boxSizing: 'border-box', width: DRAWER_WIDTH, borderRight: 'none' },
        }}
        open
      >
        {drawerContent}
      </Drawer>

      <Box component="main" sx={{ flexGrow: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
        <AppBar position="sticky" elevation={0} sx={{ bgcolor: 'white', borderBottom: '1px solid', borderColor: 'divider', color: 'text.primary', zIndex: (theme) => theme.zIndex.drawer - 1 }}>
          <Toolbar sx={{ justifyContent: 'space-between', minHeight: '64px !important', px: { xs: 2, lg: 4 } }}>
            <Box sx={{ display: 'flex', alignItems: 'center', flex: 1 }}>
              <IconButton
                color="inherit"
                edge="start"
                onClick={handleDrawerToggle}
                sx={{ mr: 2, display: { md: 'none' } }}
              >
                <MenuIcon />
              </IconButton>
              
              <Box sx={{ display: { xs: 'none', md: 'block' }, maxWidth: 400, width: '100%' }}>
                <GlobalSearch />
              </Box>
            </Box>

            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
              <NotificationCenter />
              
              <Box sx={{ position: 'relative' }}>
                <Fab 
                  size="small" 
                  onClick={(e) => setQuickActionAnchorEl(e.currentTarget)}
                  sx={{ 
                    bgcolor: '#0f172a', 
                    color: 'white', 
                    '&:hover': { bgcolor: '#1e293b' },
                    boxShadow: '0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1)',
                    width: 36, height: 36, minHeight: 36
                  }}
                >
                  <AddIcon fontSize="small" sx={{ transition: 'transform 0.2s', transform: Boolean(quickActionAnchorEl) ? 'rotate(45deg)' : 'none' }} />
                </Fab>

                <Menu
                  anchorEl={quickActionAnchorEl}
                  open={Boolean(quickActionAnchorEl)}
                  onClose={() => setQuickActionAnchorEl(null)}
                  slotProps={{
                    paper: {
                      elevation: 3,
                      sx: { width: 220, mt: 1, borderRadius: 2 }
                    }
                  }}
                  transformOrigin={{ horizontal: 'right', vertical: 'top' }}
                  anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
                >
                  <Box sx={{ px: 2, py: 1.5, borderBottom: '1px solid', borderColor: 'divider', bgcolor: 'rgba(0,0,0,0.02)' }}>
                    <Typography variant="overline" sx={{ fontWeight: 800, color: 'text.secondary' }}>Quick Actions</Typography>
                  </Box>
                  {quickActions.map((action, idx) => (
                    <MenuItem 
                      key={idx} 
                      onClick={() => {
                        setQuickActionAnchorEl(null);
                        navigate(action.path);
                      }}
                      sx={{ py: 1.5, gap: 1.5 }}
                    >
                      <Box sx={{ p: 0.5, borderRadius: 1, bgcolor: `${action.color}15`, display: 'flex' }}>
                        <action.icon sx={{ color: action.color, fontSize: 18 }} />
                      </Box>
                      <Typography variant="body2" sx={{ fontWeight: 600 }}>{action.name}</Typography>
                    </MenuItem>
                  ))}
                </Menu>
              </Box>
            </Box>
          </Toolbar>
        </AppBar>

        <Box sx={{ flex: 1, overflow: 'auto' }}>
          <Outlet />
        </Box>
      </Box>
    </Box>
  );
}
