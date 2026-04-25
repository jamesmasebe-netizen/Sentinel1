import React, { useState } from 'react';
import { 
  CheckCircle, 
  ClipboardList, 
  Target, 
  MapPin, 
  Wrench,
  Search,
  Plus,
  FileText,
  Clock,
  AlertCircle,
  CheckSquare
} from 'lucide-react';
import {
  Container,
  Paper,
  Box,
  Typography,
  Tabs,
  Tab,
  Divider,
} from '@mui/material';
import CalibrationRegister from '../components/CalibrationRegister';

interface ITPRecord {
  id: string;
  reference: string;
  projectPhase: string;
  taskDescription: string;
  inspectionType: 'Hold Point' | 'Witness Point' | 'Surveillance' | 'Review';
  inspector: string;
  status: 'Pending' | 'In Progress' | 'Approved' | 'Rejected';
}

export default function QualityManagement() {
  const [activeTab, setActiveTab] = useState<'itp' | 'snags' | 'calibration'>('snags');
  const [searchQuery, setSearchQuery] = useState('');

  // Mock data for ITPs
  const [itpRecords] = useState<ITPRecord[]>([
    {
      id: 'ITP-001',
      reference: 'ITP-CIV-045',
      projectPhase: 'Earthworks',
      taskDescription: 'Compaction testing of sub-base layer',
      inspectionType: 'Hold Point',
      inspector: 'John Engineer',
      status: 'Pending'
    },
    {
      id: 'ITP-002',
      reference: 'ITP-STR-012',
      projectPhase: 'Structural Steel',
      taskDescription: 'Torque verification of primary connections',
      inspectionType: 'Witness Point',
      inspector: 'Sarah Quality',
      status: 'In Progress'
    },
    {
      id: 'ITP-003',
      reference: 'ITP-ELE-089',
      projectPhase: 'Electrical',
      taskDescription: 'Megger testing of main feeder cables',
      inspectionType: 'Review',
      inspector: 'Mike Spark',
      status: 'Approved'
    }
  ]);

  const getITPStatusColor = (status: string) => {
    switch (status) {
      case 'Approved': return 'bg-green-50 text-green-700 border-green-200';
      case 'In Progress': return 'bg-blue-50 text-blue-700 border-blue-200';
      case 'Pending': return 'bg-amber-50 text-amber-700 border-amber-200';
      case 'Rejected': return 'bg-red-50 text-red-700 border-red-200';
      default: return 'bg-slate-50 text-slate-700 border-slate-200';
    }
  };

  const getInspectionTypeColor = (type: string) => {
    switch (type) {
      case 'Hold Point': return 'text-red-700 bg-red-50 border-red-200';
      case 'Witness Point': return 'text-orange-700 bg-orange-50 border-orange-200';
      case 'Surveillance': return 'text-blue-700 bg-blue-50 border-blue-200';
      case 'Review': return 'text-slate-700 bg-slate-100 border-slate-300';
      default: return 'text-slate-700 bg-slate-50 border-slate-200';
    }
  };

  return (
    <Container maxWidth="xl" sx={{ mt: 4, mb: 4 }}>
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" component="h1" sx={{ fontWeight: 800, tracking: -0.5 }}>Quality Management</Typography>
        <Typography variant="body1" color="text.secondary" sx={{ mt: 1 }}>Manage defects, ITPs, and equipment calibration (ISO 9001).</Typography>
      </Box>

      <Paper elevation={3} sx={{ overflow: 'hidden' }}>
        <Tabs 
          value={activeTab} 
          onChange={(_, newValue) => setActiveTab(newValue)} 
          variant="scrollable"
          scrollButtons="auto"
          sx={{ borderBottom: 1, borderColor: 'divider' }}
        >
          <Tab icon={<MapPin size={18} />} iconPosition="start" label="Defect / Snag List" value="snags" />
          <Tab icon={<ClipboardList size={18} />} iconPosition="start" label="Inspection & Test Plans (ITP)" value="itp" />
          <Tab icon={<Target size={18} />} iconPosition="start" label="Calibration Register" value="calibration" />
        </Tabs>
        
        <Box sx={{ p: 3 }}>
          {activeTab === 'snags' && (
            <div>
              <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6">
                <div className="relative flex-1 max-w-md">
                  <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={20} />
                  <input 
                    type="text" 
                    placeholder="Search defects..." 
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="w-full pl-10 pr-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  />
                </div>
                <button className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors font-medium">
                  <Plus size={20} />
                  Log Defect
                </button>
              </div>

              <div className="overflow-x-auto">
                <table className="w-full text-left border-collapse">
                  <thead>
                    <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 text-sm">
                      <th className="p-4 font-medium">ID</th>
                      <th className="p-4 font-medium">Description</th>
                      <th className="p-4 font-medium">Location</th>
                      <th className="p-4 font-medium">Assigned To</th>
                      <th className="p-4 font-medium">Status</th>
                      <th className="p-4 font-medium text-right">Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr className="border-b border-slate-100 hover:bg-slate-50 transition-colors">
                      <td className="p-4 font-medium text-slate-900">DEF-001</td>
                      <td className="p-4 text-slate-600">Concrete spalling on column C4</td>
                      <td className="p-4 text-slate-600">Basement Level 2</td>
                      <td className="p-4 text-slate-600">Civil Contractor XYZ</td>
                      <td className="p-4">
                        <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium border bg-red-50 text-red-700 border-red-200">
                          Open
                        </span>
                      </td>
                      <td className="p-4 text-right">
                        <button className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-medium bg-blue-50 text-blue-700 rounded-lg hover:bg-blue-100 transition-colors">
                          View
                        </button>
                      </td>
                    </tr>
                    <tr className="border-b border-slate-100 hover:bg-slate-50 transition-colors">
                      <td className="p-4 font-medium text-slate-900">DEF-002</td>
                      <td className="p-4 text-slate-600">Incorrect paint color applied</td>
                      <td className="p-4 text-slate-600">Lobby Wall A</td>
                      <td className="p-4 text-slate-600">Painting Subcontractor</td>
                      <td className="p-4">
                        <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium border bg-amber-50 text-amber-700 border-amber-200">
                          Fixed - Pending Verification
                        </span>
                      </td>
                      <td className="p-4 text-right">
                        <button className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-medium bg-blue-50 text-blue-700 rounded-lg hover:bg-blue-100 transition-colors">
                          View
                        </button>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {activeTab === 'itp' && (
            <div>
              <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6">
                <div className="relative flex-1 max-w-md">
                  <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={20} />
                  <input 
                    type="text" 
                    placeholder="Search ITP reference or task..." 
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="w-full pl-10 pr-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  />
                </div>
                <button className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors font-medium">
                  <Plus size={20} />
                  Create ITP
                </button>
              </div>

              <div className="overflow-x-auto">
                <table className="w-full text-left border-collapse">
                  <thead>
                    <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 text-sm">
                      <th className="p-4 font-medium">Reference</th>
                      <th className="p-4 font-medium">Task / Phase</th>
                      <th className="p-4 font-medium">Inspection Type</th>
                      <th className="p-4 font-medium">Inspector</th>
                      <th className="p-4 font-medium">Status</th>
                      <th className="p-4 font-medium text-right">Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {itpRecords.filter(record => 
                      record.reference.toLowerCase().includes(searchQuery.toLowerCase()) ||
                      record.taskDescription.toLowerCase().includes(searchQuery.toLowerCase())
                    ).map((record) => (
                      <tr key={record.id} className="border-b border-slate-100 hover:bg-slate-50 transition-colors">
                        <td className="p-4">
                          <div className="font-mono text-sm font-medium text-slate-900">{record.reference}</div>
                        </td>
                        <td className="p-4">
                          <div className="font-medium text-slate-900">{record.taskDescription}</div>
                          <div className="text-xs text-slate-500">{record.projectPhase}</div>
                        </td>
                        <td className="p-4">
                          <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium border ${getInspectionTypeColor(record.inspectionType)}`}>
                            {record.inspectionType}
                          </span>
                        </td>
                        <td className="p-4 text-slate-600 text-sm">{record.inspector}</td>
                        <td className="p-4">
                          <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium border ${getITPStatusColor(record.status)}`}>
                            {record.status}
                          </span>
                        </td>
                        <td className="p-4 text-right">
                          <button className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-medium bg-blue-50 text-blue-700 rounded-lg hover:bg-blue-100 transition-colors">
                            <CheckSquare size={14} /> Execute
                          </button>
                        </td>
                      </tr>
                    ))}
                    {itpRecords.length === 0 && (
                      <tr>
                        <td colSpan={6} className="p-8 text-center text-slate-500">No ITP records found.</td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          )}
          {activeTab === 'calibration' && (
            <CalibrationRegister />
          )}
        </Box>
      </Paper>
    </Container>
  );
}
