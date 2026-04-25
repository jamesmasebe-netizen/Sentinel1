import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy, doc, updateDoc } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { 
  GraduationCap, 
  Users, 
  AlertTriangle, 
  CheckCircle, 
  XCircle, 
  Plus, 
  PlayCircle,
  FileSignature,
  QrCode,
  Sparkles,
  Loader2,
  BookOpen,
  LayoutDashboard,
  Calendar,
  ClipboardCheck,
  Building2,
  TrendingUp,
  Trophy
} from 'lucide-react';
import TrainingExpiryAlerts from '../components/TrainingExpiryAlerts';
import CompetencyPassport from '../components/CompetencyPassport';
import LearningPaths from '../components/LearningPaths';
import DigitalTraining from '../components/DigitalTraining';
import SkillsMatrix from '../components/SkillsMatrix';
import TrainingScheduler from '../components/TrainingScheduler';
import CompetencyAssessment from '../components/CompetencyAssessment';
import ContractorCompliance from '../components/ContractorCompliance';
import PredictiveTraining from '../components/PredictiveTraining';
import SafetyGamification from '../components/SafetyGamification';

interface TrainingRecord {
  id: string;
  employeeName: string;
  idNumber: string;
  courseName: string;
  dateCompleted: string;
  expiryDate: string;
  status: 'Active' | 'Expired';
  contractorId?: string;
  contractorName?: string;
  authorId: string;
  createdAt: string;
}

interface ToolboxTalk {
  id: string;
  topic: string;
  date: string;
  conductorName: string;
  location: string;
  attendees: string[];
  contractorId?: string;
  contractorName?: string;
  authorId: string;
  createdAt: string;
}

export default function TrainingCompetency() {
  const [activeTab, setActiveTab] = useState<'records' | 'matrix' | 'toolbox' | 'digital' | 'passport' | 'learning' | 'scheduler' | 'assessment' | 'contractors' | 'predictive' | 'milestones'>('records');
  const [trainingRecords, setTrainingRecords] = useState<TrainingRecord[]>([]);
  const [toolboxTalks, setToolboxTalks] = useState<ToolboxTalk[]>([]);
  const [contractors, setContractors] = useState<{id: string, companyName: string}[]>([]);
  
  const [isAddingRecord, setIsAddingRecord] = useState(false);
  const [isAddingTalk, setIsAddingTalk] = useState(false);

  // Form States
  const [selectedContractorId, setSelectedContractorId] = useState('');
  
  // Training Form
  const [employeeName, setEmployeeName] = useState('');
  const [idNumber, setIdNumber] = useState('');
  const [courseName, setCourseName] = useState('');
  const [dateCompleted, setDateCompleted] = useState('');
  const [expiryDate, setExpiryDate] = useState('');

  // Toolbox Talk Form
  const [topic, setTopic] = useState('');
  const [talkDate, setTalkDate] = useState('');
  const [location, setLocation] = useState('');
  const [attendeesInput, setAttendeesInput] = useState('');

  useEffect(() => {
    if (!auth.currentUser) return;

    const qTraining = query(collection(db, 'training_records'), orderBy('createdAt', 'desc'));
    const unsubscribeTraining = onSnapshot(qTraining, (snapshot) => {
      const records = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as TrainingRecord[];
      
      // Auto-update expired status
      const now = new Date().getTime();
      records.forEach(record => {
        if (record.status === 'Active' && new Date(record.expiryDate).getTime() < now) {
          updateDoc(doc(db, 'training_records', record.id), { status: 'Expired' }).catch(console.error);
        }
      });
      
      setTrainingRecords(records);
    }, (error) => {
      handleFirestoreError(error, 'list' as any, 'training_records');
    });

    const qTalks = query(collection(db, 'toolbox_talks'), orderBy('date', 'desc'));
    const unsubscribeTalks = onSnapshot(qTalks, (snapshot) => {
      const talks = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as ToolboxTalk[];
      setToolboxTalks(talks);
    }, (error) => {
      handleFirestoreError(error, 'list' as any, 'toolbox_talks');
    });

    const qContractors = query(collection(db, 'contractors'));
    const unsubscribeContractors = onSnapshot(qContractors, (snapshot) => {
      setContractors(snapshot.docs.map(doc => ({ id: doc.id, companyName: doc.data().companyName })));
    });

    return () => {
      unsubscribeTraining();
      unsubscribeTalks();
      unsubscribeContractors();
    };
  }, []);

  const handleAddRecord = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;

    try {
      const contractor = contractors.find(c => c.id === selectedContractorId);
      const newRecord = {
        employeeName,
        idNumber,
        courseName,
        dateCompleted: new Date(dateCompleted).toISOString(),
        expiryDate: new Date(expiryDate).toISOString(),
        status: new Date(expiryDate).getTime() > new Date().getTime() ? 'Active' : 'Expired',
        contractorId: selectedContractorId,
        contractorName: contractor?.companyName || '',
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      };

      await addDoc(collection(db, 'training_records'), newRecord);
      setIsAddingRecord(false);
      setEmployeeName('');
      setIdNumber('');
      setCourseName('');
      setDateCompleted('');
      setExpiryDate('');
      setSelectedContractorId('');
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'training_records');
    }
  };

  const handleAddTalk = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;

    try {
      const attendeesArray = attendeesInput.split(',').map(a => a.trim()).filter(a => a);
      const contractor = contractors.find(c => c.id === selectedContractorId);
      
      const newTalk = {
        topic,
        date: new Date(talkDate).toISOString(),
        conductorName: auth.currentUser.displayName || 'Unknown User',
        location,
        attendees: attendeesArray,
        contractorId: selectedContractorId,
        contractorName: contractor?.companyName || '',
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      };

      await addDoc(collection(db, 'toolbox_talks'), newTalk);
      setIsAddingTalk(false);
      setTopic('');
      setTalkDate('');
      setLocation('');
      setAttendeesInput('');
      setSelectedContractorId('');
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'toolbox_talks');
    }
  };

  return (
    <div className="max-w-7xl mx-auto space-y-6">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">Training & Competency</h1>
          <p className="text-slate-500">Manage inductions, toolbox talks, and competency matrices.</p>
        </div>
        <div className="flex gap-3">
          {activeTab === 'records' && (
            <button 
              onClick={() => setIsAddingRecord(true)}
              className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
            >
              <Plus size={20} />
              Log Training
            </button>
          )}
          {activeTab === 'toolbox' && (
            <button 
              onClick={() => setIsAddingTalk(true)}
              className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
            >
              <Plus size={20} />
              Log Toolbox Talk
            </button>
          )}
        </div>
      </div>

      {/* Tabs */}
      <div className="flex overflow-x-auto border-b border-slate-200 hide-scrollbar">
        <button
          onClick={() => setActiveTab('records')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'records' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <GraduationCap size={18} />
          Training Records
        </button>
        <button
          onClick={() => setActiveTab('matrix')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'matrix' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <LayoutDashboard size={18} />
          Skills Matrix
        </button>
        <button
          onClick={() => setActiveTab('toolbox')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'toolbox' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Users size={18} />
          Toolbox Talks
        </button>
        <button
          onClick={() => setActiveTab('digital')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'digital' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <PlayCircle size={18} />
          Digital Training
        </button>
        <button
          onClick={() => setActiveTab('passport')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'passport' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <QrCode size={18} />
          Competency Passport
        </button>
        <button
          onClick={() => setActiveTab('learning')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'learning' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Sparkles size={18} />
          Learning Paths
        </button>
        <button
          onClick={() => setActiveTab('scheduler')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'scheduler' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Calendar size={18} />
          Scheduler
        </button>
        <button
          onClick={() => setActiveTab('assessment')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'assessment' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <ClipboardCheck size={18} />
          Assessment
        </button>
        <button
          onClick={() => setActiveTab('contractors')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'contractors' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Building2 size={18} />
          Contractors
        </button>
        <button
          onClick={() => setActiveTab('predictive')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'predictive' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <TrendingUp size={18} />
          Predictive
        </button>
        <button
          onClick={() => setActiveTab('milestones')}
          className={`flex items-center gap-2 px-4 py-3 border-b-2 font-medium whitespace-nowrap transition-colors ${
            activeTab === 'milestones' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          }`}
        >
          <Trophy size={18} />
          Milestones
        </button>
      </div>

      {/* Content Area */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        
        {/* Records Tab */}
        {activeTab === 'records' && (
          <div className="p-6">
            <TrainingExpiryAlerts records={trainingRecords} />
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 text-sm">
                    <th className="p-4 font-medium">Employee Name</th>
                    <th className="p-4 font-medium">Contractor</th>
                    <th className="p-4 font-medium">Course / Competency</th>
                    <th className="p-4 font-medium">Date Completed</th>
                    <th className="p-4 font-medium">Expiry Date</th>
                    <th className="p-4 font-medium">Status</th>
                  </tr>
                </thead>
                <tbody>
                  {trainingRecords.length === 0 ? (
                    <tr>
                      <td colSpan={5} className="p-8 text-center text-slate-500">
                        No training records found.
                      </td>
                    </tr>
                  ) : (
                    trainingRecords.map((record) => {
                      const isExpiringSoon = record.status === 'Active' && 
                        (new Date(record.expiryDate).getTime() - new Date().getTime() < 30 * 24 * 60 * 60 * 1000); // 30 days
                      
                      return (
                        <tr key={record.id} className="border-b border-slate-100 hover:bg-slate-50 transition-colors">
                          <td className="p-4 font-medium text-slate-900">{record.employeeName}</td>
                          <td className="p-4 text-slate-600">{record.contractorName || 'Internal'}</td>
                          <td className="p-4 text-slate-600">{record.courseName}</td>
                          <td className="p-4 text-slate-600">{new Date(record.dateCompleted).toLocaleDateString()}</td>
                          <td className="p-4">
                            <div className="flex items-center gap-2">
                              <span className={isExpiringSoon ? 'text-amber-600 font-medium' : 'text-slate-600'}>
                                {new Date(record.expiryDate).toLocaleDateString()}
                              </span>
                              {isExpiringSoon && <AlertTriangle size={16} className="text-amber-500" />}
                            </div>
                          </td>
                          <td className="p-4">
                            {record.status === 'Active' ? (
                              <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800 border border-green-200">
                                <CheckCircle size={12} /> Active
                              </span>
                            ) : (
                              <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-red-100 text-red-800 border border-red-200">
                                <XCircle size={12} /> Expired
                              </span>
                            )}
                          </td>
                        </tr>
                      );
                    })
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* Matrix Tab */}
        {activeTab === 'matrix' && (
          <div className="p-6">
            <SkillsMatrix records={trainingRecords} />
          </div>
        )}

        {/* Toolbox Talks Tab */}
        {activeTab === 'toolbox' && (
          <div className="p-6">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {toolboxTalks.map((talk) => (
                <div key={talk.id} className="border border-slate-200 rounded-xl p-5 bg-white hover:shadow-md transition-shadow">
                  <div className="flex items-start gap-3 mb-4">
                    <div className="bg-blue-50 p-2 rounded-lg text-blue-600 shrink-0">
                      <Users size={24} />
                    </div>
                    <div>
                      <h3 className="font-semibold text-slate-900 line-clamp-2">{talk.topic}</h3>
                      <p className="text-sm text-slate-500">{new Date(talk.date).toLocaleDateString()}</p>
                      {talk.contractorName && (
                        <p className="text-xs text-blue-600 font-bold mt-1">Contractor: {talk.contractorName}</p>
                      )}
                    </div>
                  </div>
                  
                  <div className="space-y-2 text-sm text-slate-600 mb-4">
                    <p><span className="font-medium text-slate-700">Conductor:</span> {talk.conductorName}</p>
                    <p><span className="font-medium text-slate-700">Location:</span> {talk.location}</p>
                  </div>

                  <div className="bg-slate-50 rounded-lg p-3 border border-slate-100">
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-xs font-semibold text-slate-500 uppercase">Attendees ({talk.attendees.length})</span>
                      <FileSignature size={14} className="text-slate-400" />
                    </div>
                    <div className="flex flex-wrap gap-1">
                      {talk.attendees.map((attendee, idx) => (
                        <span key={idx} className="inline-block bg-white border border-slate-200 text-slate-600 text-xs px-2 py-1 rounded">
                          {attendee}
                        </span>
                      ))}
                    </div>
                  </div>
                </div>
              ))}
              {toolboxTalks.length === 0 && (
                <div className="col-span-full p-8 text-center text-slate-500 bg-slate-50 rounded-xl border border-dashed border-slate-300">
                  No toolbox talks logged yet.
                </div>
              )}
            </div>
          </div>
        )}

        {/* Digital Training Tab */}
        {activeTab === 'digital' && (
          <div className="p-6">
            <DigitalTraining />
          </div>
        )}

        {/* Competency Passport Tab */}
        {activeTab === 'passport' && (
          <div className="p-6">
            <CompetencyPassport records={trainingRecords} />
          </div>
        )}

        {/* Learning Paths Tab */}
        {activeTab === 'learning' && (
          <div className="p-6">
            <LearningPaths records={trainingRecords} />
          </div>
        )}

        {/* Scheduler Tab */}
        {activeTab === 'scheduler' && (
          <div className="p-6">
            <TrainingScheduler records={trainingRecords} />
          </div>
        )}

        {/* Assessment Tab */}
        {activeTab === 'assessment' && (
          <div className="p-6">
            <CompetencyAssessment employees={Array.from(new Set(trainingRecords.map(r => r.employeeName)))} />
          </div>
        )}

        {/* Contractor Compliance Tab */}
        {activeTab === 'contractors' && (
          <div className="p-6">
            <ContractorCompliance records={trainingRecords} contractors={contractors} />
          </div>
        )}

        {/* Predictive Analysis Tab */}
        {activeTab === 'predictive' && (
          <div className="p-6">
            <PredictiveTraining records={trainingRecords} />
          </div>
        )}

        {/* Safety Milestones Tab */}
        {activeTab === 'milestones' && (
          <div className="p-6">
            <SafetyGamification records={trainingRecords} talks={toolboxTalks} />
          </div>
        )}
      </div>

      {/* Add Training Record Modal */}
      {isAddingRecord && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex justify-between items-center">
              <h2 className="text-xl font-bold text-slate-900">Log Training Record</h2>
              <button onClick={() => setIsAddingRecord(false)} className="text-slate-400 hover:text-slate-600">
                <XCircle size={24} />
              </button>
            </div>
            <form onSubmit={handleAddRecord} className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Employee Name</label>
                <input 
                  type="text" 
                  required
                  value={employeeName}
                  onChange={(e) => setEmployeeName(e.target.value)}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Contractor (CR 7 Linkage)</label>
                <select 
                  value={selectedContractorId}
                  onChange={(e) => setSelectedContractorId(e.target.value)}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                >
                  <option value="">-- Internal / No Contractor --</option>
                  {contractors.map(c => (
                    <option key={c.id} value={c.id}>{c.companyName}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">ID / Passport Number</label>
                <input 
                  type="text" 
                  required
                  value={idNumber}
                  onChange={(e) => setIdNumber(e.target.value)}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent font-mono"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Course / Competency</label>
                <input 
                  type="text" 
                  required
                  value={courseName}
                  onChange={(e) => setCourseName(e.target.value)}
                  placeholder="e.g., First Aid Level 1"
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Date Completed</label>
                  <input 
                    type="date" 
                    required
                    value={dateCompleted}
                    onChange={(e) => setDateCompleted(e.target.value)}
                    className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Expiry Date</label>
                  <input 
                    type="date" 
                    required
                    value={expiryDate}
                    onChange={(e) => setExpiryDate(e.target.value)}
                    className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  />
                </div>
              </div>
              <div className="pt-4 flex justify-end gap-3">
                <button 
                  type="button"
                  onClick={() => setIsAddingRecord(false)}
                  className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
                >
                  Cancel
                </button>
                <button 
                  type="submit"
                  className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                >
                  Save Record
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Add Toolbox Talk Modal */}
      {isAddingTalk && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex justify-between items-center">
              <h2 className="text-xl font-bold text-slate-900">Log Toolbox Talk</h2>
              <button onClick={() => setIsAddingTalk(false)} className="text-slate-400 hover:text-slate-600">
                <XCircle size={24} />
              </button>
            </div>
            <form onSubmit={handleAddTalk} className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Topic Discussed</label>
                <input 
                  type="text" 
                  required
                  value={topic}
                  onChange={(e) => setTopic(e.target.value)}
                  placeholder="e.g., Safe Lifting Techniques"
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Contractor (CR 7 Linkage)</label>
                <select 
                  value={selectedContractorId}
                  onChange={(e) => setSelectedContractorId(e.target.value)}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                >
                  <option value="">-- Internal / No Contractor --</option>
                  {contractors.map(c => (
                    <option key={c.id} value={c.id}>{c.companyName}</option>
                  ))}
                </select>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Date</label>
                  <input 
                    type="date" 
                    required
                    value={talkDate}
                    onChange={(e) => setTalkDate(e.target.value)}
                    className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Location</label>
                  <input 
                    type="text" 
                    required
                    value={location}
                    onChange={(e) => setLocation(e.target.value)}
                    className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Attendees (comma separated)</label>
                <textarea 
                  required
                  value={attendeesInput}
                  onChange={(e) => setAttendeesInput(e.target.value)}
                  placeholder="John Doe, Jane Smith, Mike Johnson"
                  rows={3}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
              <div className="pt-4 flex justify-end gap-3">
                <button 
                  type="button"
                  onClick={() => setIsAddingTalk(false)}
                  className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
                >
                  Cancel
                </button>
                <button 
                  type="submit"
                  className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                >
                  Save Register
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

    </div>
  );
}
