import React, { useState, useEffect } from 'react';
import { collection, onSnapshot, query, orderBy, addDoc } from 'firebase/firestore';
import { db, auth, handleFirestoreError } from '../lib/firebase';
import { 
  Stethoscope, 
  Ear, 
  Eye, 
  Wind, 
  FileText, 
  Plus, 
  X, 
  AlertTriangle,
  CheckCircle2,
  Search
} from 'lucide-react';

interface SurveillanceRecord {
  id: string;
  employeeName: string;
  idNumber: string;
  testType: 'Audiometry' | 'Spirometry (Lung)' | 'Vision' | 'Biological Monitoring';
  result: 'Pass' | 'Referral Required' | 'Fail';
  notes: string;
  dateConducted: string;
  nextDueDate: string;
  practitionerName: string;
}

export default function HealthSurveillanceRecords() {
  const [records, setRecords] = useState<SurveillanceRecord[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');

  // Form State
  const [employeeName, setEmployeeName] = useState('');
  const [idNumber, setIdNumber] = useState('');
  const [testType, setTestType] = useState<SurveillanceRecord['testType']>('Audiometry');
  const [result, setResult] = useState<SurveillanceRecord['result']>('Pass');
  const [notes, setNotes] = useState('');
  const [dateConducted, setDateConducted] = useState('');
  const [nextDueDate, setNextDueDate] = useState('');

  useEffect(() => {
    const q = query(collection(db, 'health_surveillance'), orderBy('dateConducted', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setRecords(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as SurveillanceRecord[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'health_surveillance'));

    return () => unsubscribe();
  }, []);

  const handleAddRecord = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;

    try {
      await addDoc(collection(db, 'health_surveillance'), {
        employeeName,
        idNumber,
        testType,
        result,
        notes,
        dateConducted: new Date(dateConducted).toISOString(),
        nextDueDate: new Date(nextDueDate).toISOString(),
        practitionerName: auth.currentUser.email || 'Unknown Practitioner',
        createdAt: new Date().toISOString()
      });
      setIsAdding(false);
      // Reset
      setEmployeeName('');
      setIdNumber('');
      setNotes('');
      setDateConducted('');
      setNextDueDate('');
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'health_surveillance');
    }
  };

  const getTestIcon = (type: string) => {
    switch (type) {
      case 'Audiometry': return <Ear size={18} className="text-blue-500" />;
      case 'Spirometry (Lung)': return <Wind size={18} className="text-teal-500" />;
      case 'Vision': return <Eye size={18} className="text-indigo-500" />;
      default: return <Stethoscope size={18} className="text-slate-500" />;
    }
  };

  const filteredRecords = records.filter(r => 
    r.employeeName.toLowerCase().includes(searchTerm.toLowerCase()) ||
    r.idNumber.includes(searchTerm)
  );

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row justify-between items-center gap-4">
        <div className="flex items-center gap-3">
          <div className="bg-blue-50 p-2 rounded-lg text-blue-600">
            <Stethoscope size={24} />
          </div>
          <div>
            <h2 className="text-xl font-bold text-slate-900">Health Surveillance Records</h2>
            <p className="text-sm text-slate-500">Encrypted audiometry, spirometry, and vision screening results</p>
          </div>
        </div>
        <div className="flex gap-3 w-full md:w-auto">
          <div className="relative flex-1 md:w-64">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
            <input 
              type="text"
              placeholder="Search employee..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <button 
            onClick={() => setIsAdding(true)}
            className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-xl hover:bg-blue-700 transition-colors font-bold"
          >
            <Plus size={20} />
            Log Test
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {filteredRecords.map(record => {
          const isDueSoon = new Date(record.nextDueDate).getTime() - new Date().getTime() < 30 * 24 * 60 * 60 * 1000;
          
          return (
            <div key={record.id} className="bg-white border border-slate-200 rounded-2xl p-5 shadow-sm hover:shadow-md transition-all">
              <div className="flex justify-between items-start mb-4">
                <div className="flex items-center gap-3">
                  <div className="bg-slate-50 p-2.5 rounded-xl">
                    {getTestIcon(record.testType)}
                  </div>
                  <div>
                    <h3 className="font-bold text-slate-900">{record.employeeName}</h3>
                    <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">{record.idNumber}</p>
                  </div>
                </div>
                <span className={`text-[10px] font-bold uppercase px-2 py-1 rounded-lg border ${
                  record.result === 'Pass' ? 'bg-green-50 text-green-700 border-green-200' :
                  record.result === 'Referral Required' ? 'bg-amber-50 text-amber-700 border-amber-200' :
                  'bg-red-50 text-red-700 border-red-200'
                }`}>
                  {record.result}
                </span>
              </div>

              <div className="bg-slate-50 rounded-xl p-4 mb-4">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-[10px] font-bold text-slate-400 uppercase">Test Type</span>
                  <span className="text-xs font-bold text-slate-700">{record.testType}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-[10px] font-bold text-slate-400 uppercase">Date</span>
                  <span className="text-xs font-bold text-slate-700">{new Date(record.dateConducted).toLocaleDateString()}</span>
                </div>
              </div>

              <div className="flex items-center justify-between pt-4 border-t border-slate-100">
                <div className="flex items-center gap-1.5">
                  {isDueSoon ? (
                    <AlertTriangle size={14} className="text-amber-500" />
                  ) : (
                    <CheckCircle2 size={14} className="text-green-500" />
                  )}
                  <span className={`text-[10px] font-bold uppercase ${isDueSoon ? 'text-amber-600' : 'text-slate-500'}`}>
                    Next Due: {new Date(record.nextDueDate).toLocaleDateString()}
                  </span>
                </div>
                <button className="text-blue-600 hover:text-blue-800 p-1">
                  <FileText size={16} />
                </button>
              </div>
            </div>
          );
        })}
        {filteredRecords.length === 0 && (
          <div className="col-span-full py-12 text-center bg-slate-50 rounded-2xl border-2 border-dashed border-slate-200">
            <Stethoscope className="mx-auto text-slate-300 mb-3" size={40} />
            <p className="text-slate-500 font-medium">No surveillance records found.</p>
          </div>
        )}
      </div>

      {isAdding && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex justify-between items-center">
              <h2 className="text-xl font-bold text-slate-900">Log Surveillance Test</h2>
              <button onClick={() => setIsAdding(false)} className="text-slate-400 hover:text-slate-600">
                <X size={24} />
              </button>
            </div>
            <form onSubmit={handleAddRecord} className="p-6 space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Employee Name</label>
                  <input 
                    type="text" 
                    required
                    value={employeeName}
                    onChange={(e) => setEmployeeName(e.target.value)}
                    className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">ID Number</label>
                  <input 
                    type="text" 
                    required
                    value={idNumber}
                    onChange={(e) => setIdNumber(e.target.value)}
                    className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Test Type</label>
                  <select 
                    value={testType}
                    onChange={(e) => setTestType(e.target.value as any)}
                    className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="Audiometry">Audiometry</option>
                    <option value="Spirometry (Lung)">Spirometry (Lung)</option>
                    <option value="Vision">Vision</option>
                    <option value="Biological Monitoring">Biological Monitoring</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Result</label>
                  <select 
                    value={result}
                    onChange={(e) => setResult(e.target.value as any)}
                    className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="Pass">Pass</option>
                    <option value="Referral Required">Referral Required</option>
                    <option value="Fail">Fail</option>
                  </select>
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Clinical Notes</label>
                <textarea 
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  rows={2}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Date Conducted</label>
                  <input 
                    type="date" 
                    required
                    value={dateConducted}
                    onChange={(e) => setDateConducted(e.target.value)}
                    className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Next Due Date</label>
                  <input 
                    type="date" 
                    required
                    value={nextDueDate}
                    onChange={(e) => setNextDueDate(e.target.value)}
                    className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>
              <div className="pt-4 flex justify-end gap-3">
                <button 
                  type="button"
                  onClick={() => setIsAdding(false)}
                  className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
                >
                  Cancel
                </button>
                <button 
                  type="submit"
                  className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors font-bold"
                >
                  Save Record
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
