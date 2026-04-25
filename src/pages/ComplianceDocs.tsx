import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy, doc, deleteDoc, updateDoc } from 'firebase/firestore';
import { db, handleFirestoreError, OperationType } from '../lib/firebase';
import { useAuth } from '../contexts/AuthContext';
import { FileText, ClipboardCheck, UserCheck, Plus, Download, Trash2, X, FileBadge, Calendar } from 'lucide-react';

interface DocumentRecord {
  id: string;
  title: string;
  type: string;
  version: string;
  status: string;
  contractorId?: string;
  contractorName?: string;
  authorId: string;
  createdAt: string;
}

interface Audit {
  id: string;
  title: string;
  type: string;
  date: string;
  auditorName: string;
  score: number;
  status: string;
  contractorId?: string;
  contractorName?: string;
  authorId: string;
  createdAt: string;
}

interface LegalAppointment {
  id: string;
  appointeeName: string;
  role: string;
  appointedBy: string;
  dateAppointed: string;
  expiryDate: string;
  status: string;
  contractorId?: string;
  contractorName?: string;
  authorId: string;
  createdAt: string;
}

export default function ComplianceDocs() {
  const { user } = useAuth();
  
  // Data State
  const [documents, setDocuments] = useState<DocumentRecord[]>([]);
  const [audits, setAudits] = useState<Audit[]>([]);
  const [appointments, setAppointments] = useState<LegalAppointment[]>([]);
  const [contractors, setContractors] = useState<{id: string, companyName: string}[]>([]);
  const [loading, setLoading] = useState(true);

  // UI State
  const [activeTab, setActiveTab] = useState<'docs' | 'audits' | 'appointments'>('docs');
  const [isAddingDoc, setIsAddingDoc] = useState(false);
  const [isAddingAudit, setIsAddingAudit] = useState(false);
  const [isAddingAppointment, setIsAddingAppointment] = useState(false);

  // Form States
  const [selectedContractorId, setSelectedContractorId] = useState('');
  const [docTitle, setDocTitle] = useState('');
  const [docType, setDocType] = useState('Policy');
  const [docVersion, setDocVersion] = useState('v1.0');

  const [auditTitle, setAuditTitle] = useState('');
  const [auditType, setAuditType] = useState('Safety Walk');
  const [auditDate, setAuditDate] = useState(new Date().toISOString().slice(0, 10));
  const [auditorName, setAuditorName] = useState('');
  const [auditScore, setAuditScore] = useState(100);

  const [appointeeName, setAppointeeName] = useState('');
  const [apptRole, setApptRole] = useState('');
  const [appointedBy, setAppointedBy] = useState('');
  const [dateAppointed, setDateAppointed] = useState(new Date().toISOString().slice(0, 10));
  const [expiryDate, setExpiryDate] = useState(new Date(new Date().setFullYear(new Date().getFullYear() + 1)).toISOString().slice(0, 10));

  useEffect(() => {
    if (!user) return;

    const qDocs = query(collection(db, 'documents'), orderBy('createdAt', 'desc'));
    const unsubDocs = onSnapshot(qDocs, (snapshot) => {
      const data: DocumentRecord[] = [];
      snapshot.forEach((doc) => data.push({ id: doc.id, ...doc.data() } as DocumentRecord));
      setDocuments(data);
    }, (error) => handleFirestoreError(error, OperationType.LIST, 'documents'));

    const qAudits = query(collection(db, 'audits'), orderBy('date', 'desc'));
    const unsubAudits = onSnapshot(qAudits, (snapshot) => {
      const data: Audit[] = [];
      snapshot.forEach((doc) => data.push({ id: doc.id, ...doc.data() } as Audit));
      setAudits(data);
    }, (error) => handleFirestoreError(error, OperationType.LIST, 'audits'));

    const qAppts = query(collection(db, 'legal_appointments'), orderBy('expiryDate', 'asc'));
    const unsubAppts = onSnapshot(qAppts, (snapshot) => {
      const data: LegalAppointment[] = [];
      snapshot.forEach((doc) => data.push({ id: doc.id, ...doc.data() } as LegalAppointment));
      setAppointments(data);
      setLoading(false);
    }, (error) => handleFirestoreError(error, OperationType.LIST, 'legal_appointments'));

    const qContractors = query(collection(db, 'contractors'));
    const unsubContractors = onSnapshot(qContractors, (snapshot) => {
      setContractors(snapshot.docs.map(doc => ({ id: doc.id, companyName: doc.data().companyName })));
    });

    return () => {
      unsubDocs();
      unsubAudits();
      unsubAppts();
      unsubContractors();
    };
  }, [user]);

  const handleAddDocument = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user) return;

    try {
      const contractor = contractors.find(c => c.id === selectedContractorId);
      await addDoc(collection(db, 'documents'), {
        title: docTitle,
        type: docType,
        version: docVersion,
        status: 'Published',
        contractorId: selectedContractorId,
        contractorName: contractor?.companyName || '',
        authorId: user.uid,
        createdAt: new Date().toISOString()
      });
      setIsAddingDoc(false);
      setDocTitle('');
      setDocVersion('v1.0');
      setSelectedContractorId('');
    } catch (error) {
      handleFirestoreError(error, OperationType.CREATE, 'documents');
    }
  };

  const handleAddAudit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user) return;

    try {
      const contractor = contractors.find(c => c.id === selectedContractorId);
      await addDoc(collection(db, 'audits'), {
        title: auditTitle,
        type: auditType,
        date: new Date(auditDate).toISOString(),
        auditorName,
        score: Number(auditScore),
        status: 'Completed',
        contractorId: selectedContractorId,
        contractorName: contractor?.companyName || '',
        authorId: user.uid,
        createdAt: new Date().toISOString()
      });
      setIsAddingAudit(false);
      setAuditTitle('');
      setAuditorName('');
      setAuditScore(100);
      setSelectedContractorId('');
    } catch (error) {
      handleFirestoreError(error, OperationType.CREATE, 'audits');
    }
  };

  const handleAddAppointment = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user) return;

    try {
      const contractor = contractors.find(c => c.id === selectedContractorId);
      await addDoc(collection(db, 'legal_appointments'), {
        appointeeName,
        role: apptRole,
        appointedBy,
        dateAppointed: new Date(dateAppointed).toISOString(),
        expiryDate: new Date(expiryDate).toISOString(),
        status: 'Active',
        contractorId: selectedContractorId,
        contractorName: contractor?.companyName || '',
        authorId: user.uid,
        createdAt: new Date().toISOString()
      });
      setIsAddingAppointment(false);
      setAppointeeName('');
      setApptRole('');
      setAppointedBy('');
      setSelectedContractorId('');
    } catch (error) {
      handleFirestoreError(error, OperationType.CREATE, 'legal_appointments');
    }
  };

  const deleteDocument = async (id: string) => {
    if (window.confirm('Are you sure you want to delete this document record?')) {
      try {
        await deleteDoc(doc(db, 'documents', id));
      } catch (error) {
        handleFirestoreError(error, OperationType.DELETE, `documents/${id}`);
      }
    }
  };

  const getScoreColor = (score: number) => {
    if (score >= 90) return 'text-green-600';
    if (score >= 75) return 'text-amber-600';
    return 'text-red-600';
  };

  const getExpiryColor = (expiryDate: string) => {
    const daysUntilExpiry = Math.ceil((new Date(expiryDate).getTime() - new Date().getTime()) / (1000 * 3600 * 24));
    if (daysUntilExpiry < 0) return 'text-red-600 font-bold bg-red-50 px-2 py-1 rounded';
    if (daysUntilExpiry <= 30) return 'text-amber-600 font-bold bg-amber-50 px-2 py-1 rounded';
    return 'text-gray-600';
  };

  return (
    <div className="space-y-6">
      {/* Tabs */}
      <div className="flex space-x-2 border-b border-gray-200 overflow-x-auto">
        <button
          onClick={() => setActiveTab('docs')}
          className={`px-4 py-2 font-medium text-sm border-b-2 transition-colors whitespace-nowrap ${
            activeTab === 'docs' ? 'border-blue-600 text-blue-600' : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
          }`}
        >
          <div className="flex items-center gap-2"><FileText size={16}/> Document Control</div>
        </button>
        <button
          onClick={() => setActiveTab('audits')}
          className={`px-4 py-2 font-medium text-sm border-b-2 transition-colors whitespace-nowrap ${
            activeTab === 'audits' ? 'border-blue-600 text-blue-600' : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
          }`}
        >
          <div className="flex items-center gap-2"><ClipboardCheck size={16}/> Audits & Inspections</div>
        </button>
        <button
          onClick={() => setActiveTab('appointments')}
          className={`px-4 py-2 font-medium text-sm border-b-2 transition-colors whitespace-nowrap ${
            activeTab === 'appointments' ? 'border-blue-600 text-blue-600' : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
          }`}
        >
          <div className="flex items-center gap-2"><UserCheck size={16}/> Legal Appointments</div>
        </button>
      </div>

      {/* Documents Tab */}
      {activeTab === 'docs' && (
        <div className="space-y-6">
          <div className="flex justify-end">
            <button onClick={() => setIsAddingDoc(true)} className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 flex items-center gap-2">
              <Plus size={20} /> Upload Document
            </button>
          </div>

          {isAddingDoc && (
            <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-200">
              <div className="flex justify-between items-center mb-4">
                <h2 className="text-lg font-bold">Add New Document</h2>
                <button onClick={() => setIsAddingDoc(false)} className="text-gray-400 hover:text-gray-600"><X size={24} /></button>
              </div>
              <form onSubmit={handleAddDocument} className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Document Title</label>
                    <input type="text" required value={docTitle} onChange={(e) => setDocTitle(e.target.value)} className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:ring-2 focus:ring-blue-500" placeholder="e.g. Health & Safety Policy" />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Contractor (CR 7 Linkage)</label>
                    <select value={selectedContractorId} onChange={(e) => setSelectedContractorId(e.target.value)} className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:ring-2 focus:ring-blue-500">
                      <option value="">-- Internal / No Contractor --</option>
                      {contractors.map(c => (
                        <option key={c.id} value={c.id}>{c.companyName}</option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Type</label>
                    <select value={docType} onChange={(e) => setDocType(e.target.value)} className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:ring-2 focus:ring-blue-500">
                      <option value="Policy">Policy</option>
                      <option value="Procedure">Procedure</option>
                      <option value="Manual">Manual</option>
                      <option value="Form">Form</option>
                      <option value="Other">Other</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Version</label>
                    <input type="text" required value={docVersion} onChange={(e) => setDocVersion(e.target.value)} className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:ring-2 focus:ring-blue-500" placeholder="e.g. v1.0" />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">File Upload (Simulated)</label>
                    <input type="file" disabled className="w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-sm file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100" />
                  </div>
                </div>
                <div className="flex justify-end pt-4">
                  <button type="submit" className="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700 font-medium">Save Document</button>
                </div>
              </form>
            </div>
          )}

          <div className="bg-white shadow-sm rounded-xl border border-gray-200 overflow-hidden">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Document</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Type</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Version & Status</th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {documents.map((doc) => (
                  <tr key={doc.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4">
                      <div className="flex items-center">
                        <FileText className="text-gray-400 mr-3" size={20} />
                        <div>
                          <div className="font-medium text-gray-900">{doc.title}</div>
                          {doc.contractorName && (
                            <div className="text-xs text-blue-600 font-medium">Contractor: {doc.contractorName}</div>
                          )}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{doc.type}</td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm font-medium text-gray-900">{doc.version}</div>
                      <div className="text-xs text-green-600">{doc.status}</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      <button className="text-blue-600 hover:text-blue-900 mr-4" title="Download">
                        <Download size={18} />
                      </button>
                      <button onClick={() => deleteDocument(doc.id)} className="text-red-600 hover:text-red-900" title="Delete">
                        <Trash2 size={18} />
                      </button>
                    </td>
                  </tr>
                ))}
                {documents.length === 0 && !loading && (
                  <tr><td colSpan={4} className="px-6 py-8 text-center text-gray-500">No documents found.</td></tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Audits Tab */}
      {activeTab === 'audits' && (
        <div className="space-y-6">
          <div className="flex justify-end">
            <button onClick={() => setIsAddingAudit(true)} className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 flex items-center gap-2">
              <Plus size={20} /> Log Audit
            </button>
          </div>

          {isAddingAudit && (
            <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-200">
              <div className="flex justify-between items-center mb-4">
                <h2 className="text-lg font-bold">Log Audit / Inspection</h2>
                <button onClick={() => setIsAddingAudit(false)} className="text-gray-400 hover:text-gray-600"><X size={24} /></button>
              </div>
              <form onSubmit={handleAddAudit} className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Audit Title</label>
                    <input type="text" required value={auditTitle} onChange={(e) => setAuditTitle(e.target.value)} className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:ring-2 focus:ring-blue-500" placeholder="e.g. Monthly Site Inspection" />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Contractor (CR 7 Linkage)</label>
                    <select value={selectedContractorId} onChange={(e) => setSelectedContractorId(e.target.value)} className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:ring-2 focus:ring-blue-500">
                      <option value="">-- Internal / No Contractor --</option>
                      {contractors.map(c => (
                        <option key={c.id} value={c.id}>{c.companyName}</option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Type</label>
                    <select value={auditType} onChange={(e) => setAuditType(e.target.value)} className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:ring-2 focus:ring-blue-500">
                      <option value="Internal">Internal Audit</option>
                      <option value="External">External Audit</option>
                      <option value="Safety Walk">Safety Walk</option>
                      <option value="Compliance">Compliance Check</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Date</label>
                    <input type="date" required value={auditDate} onChange={(e) => setAuditDate(e.target.value)} className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:ring-2 focus:ring-blue-500" />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Auditor Name</label>
                    <input type="text" required value={auditorName} onChange={(e) => setAuditorName(e.target.value)} className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:ring-2 focus:ring-blue-500" />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Score (%)</label>
                    <input type="number" min="0" max="100" required value={auditScore} onChange={(e) => setAuditScore(Number(e.target.value))} className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:ring-2 focus:ring-blue-500" />
                  </div>
                </div>
                <div className="flex justify-end pt-4">
                  <button type="submit" className="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700 font-medium">Save Audit</button>
                </div>
              </form>
            </div>
          )}

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {audits.map((audit) => (
              <div key={audit.id} className="bg-white p-5 rounded-xl shadow-sm border border-gray-200 hover:shadow-md transition-shadow">
                <div className="flex justify-between items-start mb-4">
                  <div>
                    <h3 className="font-bold text-gray-900">{audit.title}</h3>
                    <p className="text-xs text-gray-500">{audit.type}</p>
                    {audit.contractorName && (
                      <p className="text-xs text-blue-600 font-bold mt-1">Contractor: {audit.contractorName}</p>
                    )}
                  </div>
                  <div className={`text-xl font-bold ${getScoreColor(audit.score)}`}>
                    {audit.score}%
                  </div>
                </div>
                <div className="space-y-2 text-sm text-gray-600">
                  <div className="flex items-center gap-2"><Calendar size={16}/> {new Date(audit.date).toLocaleDateString()}</div>
                  <div className="flex items-center gap-2"><UserCheck size={16}/> {audit.auditorName}</div>
                </div>
              </div>
            ))}
            {audits.length === 0 && !loading && (
              <div className="col-span-full p-8 text-center text-gray-500 bg-white rounded-xl border border-gray-200">No audits recorded.</div>
            )}
          </div>
        </div>
      )}

      {/* Legal Appointments Tab */}
      {activeTab === 'appointments' && (
        <div className="space-y-6">
          <div className="flex justify-end">
            <button onClick={() => setIsAddingAppointment(true)} className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 flex items-center gap-2">
              <Plus size={20} /> New Appointment
            </button>
          </div>

          {isAddingAppointment && (
            <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-200">
              <div className="flex justify-between items-center mb-4">
                <h2 className="text-lg font-bold">Create Legal Appointment</h2>
                <button onClick={() => setIsAddingAppointment(false)} className="text-gray-400 hover:text-gray-600"><X size={24} /></button>
              </div>
              <form onSubmit={handleAddAppointment} className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Appointee Name</label>
                    <input type="text" required value={appointeeName} onChange={(e) => setAppointeeName(e.target.value)} className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:ring-2 focus:ring-blue-500" placeholder="e.g. Jane Smith" />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Contractor (CR 7 Linkage)</label>
                    <select value={selectedContractorId} onChange={(e) => setSelectedContractorId(e.target.value)} className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:ring-2 focus:ring-blue-500">
                      <option value="">-- Internal / No Contractor --</option>
                      {contractors.map(c => (
                        <option key={c.id} value={c.id}>{c.companyName}</option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Role / Section</label>
                    <input type="text" required value={apptRole} onChange={(e) => setApptRole(e.target.value)} className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:ring-2 focus:ring-blue-500" placeholder="e.g. 16.2 Appointee, First Aider" />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Appointed By</label>
                    <input type="text" required value={appointedBy} onChange={(e) => setAppointedBy(e.target.value)} className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:ring-2 focus:ring-blue-500" placeholder="e.g. CEO Name" />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Date Appointed</label>
                    <input type="date" required value={dateAppointed} onChange={(e) => setDateAppointed(e.target.value)} className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:ring-2 focus:ring-blue-500" />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Expiry Date</label>
                    <input type="date" required value={expiryDate} onChange={(e) => setExpiryDate(e.target.value)} className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:ring-2 focus:ring-blue-500" />
                  </div>
                </div>
                <div className="flex justify-end pt-4">
                  <button type="submit" className="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700 font-medium">Save Appointment</button>
                </div>
              </form>
            </div>
          )}

          <div className="bg-white shadow-sm rounded-xl border border-gray-200 overflow-hidden">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Appointee & Role</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Appointed By</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Expiry Date</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {appointments.map((appt) => (
                  <tr key={appt.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4">
                      <div className="font-medium text-gray-900">{appt.appointeeName}</div>
                      <div className="text-xs text-gray-500 flex items-center gap-1 mt-1"><FileBadge size={12}/> {appt.role}</div>
                      {appt.contractorName && (
                        <div className="text-xs text-blue-600 font-bold mt-1">Contractor: {appt.contractorName}</div>
                      )}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{appt.appointedBy}</td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`text-sm ${getExpiryColor(appt.expiryDate)}`}>
                        {new Date(appt.expiryDate).toLocaleDateString()}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${
                        appt.status === 'Active' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                      }`}>
                        {appt.status}
                      </span>
                    </td>
                  </tr>
                ))}
                {appointments.length === 0 && !loading && (
                  <tr><td colSpan={4} className="px-6 py-8 text-center text-gray-500">No legal appointments found.</td></tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}
