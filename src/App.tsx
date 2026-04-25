/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import { ThemeProvider, createTheme, CssBaseline } from '@mui/material';

import Layout from './components/Layout';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Chatbot from './pages/Chatbot';
import GeminiFeatures from './pages/GeminiFeatures';
import RiskIntelligenceHub from './pages/RiskIntelligenceHub';
import ComplianceDocs from './pages/ComplianceDocs';
import ContractorPermitHub from './pages/ContractorPermitHub';
import UnifiedActionItemTracker from './components/UnifiedActionItemTracker';
import TrainingCompetency from './pages/TrainingCompetency';
import OccupationalHealth from './pages/OccupationalHealth';
import EnvironmentESGHub from './pages/EnvironmentESGHub';
import EmergencyResponse from './pages/EmergencyResponse';
import BehavioralSafety from './pages/BehavioralSafety';
import WorkersComp from './pages/WorkersComp';
import PeopleManagement from './pages/PeopleManagement';
import EquipmentManagement from './pages/EquipmentManagement';
import QualityManagement from './pages/QualityManagement';
import ExecutiveDashboard from './pages/ExecutiveDashboard';
import PortfolioDashboard from './pages/PortfolioDashboard';
import VendorManagement from './pages/VendorManagement';
import WorkOrderManagement from './pages/WorkOrderManagement';
import EnterpriseFinancials from './pages/EnterpriseFinancials';
import EnterpriseRiskESG from './pages/EnterpriseRiskESG';
import ErrorBoundary from './components/ErrorBoundary';

import GovernanceStrategy from './pages/GovernanceStrategy';
import SafetyOperations from './pages/SafetyOperations';

// Create a custom MUI theme matching the app's sophisticated dark/slate aesthetic
const theme = createTheme({
  palette: {
    primary: {
      main: '#2563eb', // blue-600
    },
    secondary: {
      main: '#64748b', // slate-500
    },
    background: {
      default: '#f8fafc', // slate-50
      paper: '#ffffff',
    },
  },
  typography: {
    fontFamily: '"Roboto", "Inter", "Helvetica", "Arial", sans-serif',
  },
  shape: {
    borderRadius: 8,
  },
  components: {
    MuiButton: {
      styleOverrides: {
        root: {
          textTransform: 'none',
          fontWeight: 600,
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          boxShadow: '0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1)',
        },
      },
    },
  },
});

// Protected Route Wrapper
function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { user, loading } = useAuth();
  
  if (loading) return <div className="min-h-screen flex items-center justify-center">Loading...</div>;
  if (!user) return <Navigate to="/login" replace />;
  
  return <>{children}</>;
}

// Role-Based Protected Route Wrapper
function RoleProtectedRoute({ children, allowedRoles }: { children: React.ReactNode, allowedRoles: string[] }) {
  const { user, profile, loading } = useAuth();
  
  if (loading) return <div className="min-h-screen flex items-center justify-center">Loading...</div>;
  if (!user) return <Navigate to="/login" replace />;
  
  // If profile is loaded and the user's role is not in the allowed list, redirect to home
  if (profile && !allowedRoles.includes(profile.role)) {
    return <Navigate to="/" replace />;
  }
  
  return <>{children}</>;
}

function AppRoutes() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route path="/" element={<ProtectedRoute><Layout /></ProtectedRoute>}>
        <Route index element={<Dashboard />} />
        <Route path="portfolio" element={
          <RoleProtectedRoute allowedRoles={['admin', 'executive']}>
            <PortfolioDashboard />
          </RoleProtectedRoute>
        } />
        <Route path="vendors" element={
          <RoleProtectedRoute allowedRoles={['admin', 'executive']}>
            <VendorManagement />
          </RoleProtectedRoute>
        } />
        <Route path="work-orders" element={
          <RoleProtectedRoute allowedRoles={['admin', 'executive']}>
            <WorkOrderManagement />
          </RoleProtectedRoute>
        } />
        <Route path="financials" element={
          <RoleProtectedRoute allowedRoles={['admin', 'executive']}>
            <EnterpriseFinancials />
          </RoleProtectedRoute>
        } />
        <Route path="enterprise-risk-esg" element={
          <RoleProtectedRoute allowedRoles={['admin', 'executive']}>
            <EnterpriseRiskESG />
          </RoleProtectedRoute>
        } />
        <Route path="safety" element={<SafetyOperations />} />
        <Route path="health" element={<OccupationalHealth />} />
        <Route path="governance" element={<GovernanceStrategy />} />
        <Route path="people" element={<PeopleManagement />} />
        <Route path="risk" element={<RiskIntelligenceHub />} />
        <Route path="quality" element={<QualityManagement />} />
        <Route path="executive-dashboard" element={<ExecutiveDashboard />} />
        <Route path="training" element={<TrainingCompetency />} />
        <Route path="environment" element={<EnvironmentESGHub />} />
        <Route path="contractors-permits" element={<ContractorPermitHub />} />
        <Route path="action-items" element={<UnifiedActionItemTracker />} />
        <Route path="chat" element={<Chatbot />} />
        <Route path="ai-tools" element={<GeminiFeatures />} />
      </Route>
    </Routes>
  );
}

export default function App() {
  return (
    <ErrorBoundary>
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <AuthProvider>
          <BrowserRouter>
            <AppRoutes />
          </BrowserRouter>
        </AuthProvider>
      </ThemeProvider>
    </ErrorBoundary>
  );
}

