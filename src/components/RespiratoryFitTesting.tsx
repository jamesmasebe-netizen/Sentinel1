import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { UserCheck, Plus, Shield, Calendar, AlertCircle } from 'lucide-react';

interface FitTest {
  id: string;
  employeeName: string;
  maskType: string;
  maskSize: 'Small' | 'Medium' | 'Large' | 'Universal';
  testMethod: 'Qualitative (Saccharin/Bitrex)' | 'Quantitative (PortaCount)';
  result: 'Pass' | 'Fail';
  fitFactor?: number;
  testDate: string;
  expiryDate: string;
  createdAt: string;
}

export default function RespiratoryFitTesting() {
  const [tests, setTests] = useState<FitTest[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [formData, setFormData] = useState({
    employeeName: '',
    maskType: '3M 6200 Half-Face',
    maskSize: 'Medium' as FitTest['maskSize'],
    testMethod: 'Qualitative (Saccharin/Bitrex)' as FitTest['testMethod'],
    result: 'Pass' as FitTest['result'],
    fitFactor: 0,
    testDate: '',
    expiryDate: ''
  });

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'respiratory_fit_tests'), orderBy('testDate', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as FitTest[];
      setTests(data);
    }, (error) => handleFirestoreError(error, 'list' as any, 'respiratory_fit_tests'));
    return () => unsubscribe();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      await addDoc(collection(db, 'respiratory_fit_tests'), {
        ...formData,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAdding(false);
      setFormData({ employeeName: '', maskType: '3M 6200 Half-Face', maskSize: 'Medium', testMethod: 'Qualitative (Saccharin/Bitrex)', result: 'Pass', fitFactor: 0, testDate: '', expiryDate: '' });
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'respiratory_fit_tests');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">Respiratory Fit Testing (RPFT)</h2>
          <p className="text-sm text-slate-500">Manage mask fit tests and compliance for respiratory protection.</p>
        </div>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700">
          <Plus size={18} /> Log Fit Test
        </button>
      </div>

      {isAdding && (
        <div className="bg-slate-50 p-4 rounded-lg border border-slate-200 mb-6">
          <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Employee Name</label>
              <input type="text" required value={formData.employeeName} onChange={e => setFormData({...formData, employeeName: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Mask Model/Type</label>
              <input type="text" required value={formData.maskType} onChange={e => setFormData({...formData, maskType: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Mask Size</label>
              <select value={formData.maskSize} onChange={e => setFormData({...formData, maskSize: e.target.value as any})} className="w-full p-2 border rounded-lg">
                <option value="Small">Small</option>
                <option value="Medium">Medium</option>
                <option value="Large">Large</option>
                <option value="Universal">Universal</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Test Method</label>
              <select value={formData.testMethod} onChange={e => setFormData({...formData, testMethod: e.target.value as any})} className="w-full p-2 border rounded-lg">
                <option value="Qualitative (Saccharin/Bitrex)">Qualitative (Saccharin/Bitrex)</option>
                <option value="Quantitative (PortaCount)">Quantitative (PortaCount)</option>
              </select>
            </div>
            <div className="grid grid-cols-2 gap-2">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Test Date</label>
                <input type="date" required value={formData.testDate} onChange={e => setFormData({...formData, testDate: e.target.value})} className="w-full p-2 border rounded-lg" />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Expiry Date</label>
                <input type="date" required value={formData.expiryDate} onChange={e => setFormData({...formData, expiryDate: e.target.value})} className="w-full p-2 border rounded-lg" />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-2">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Result</label>
                <select value={formData.result} onChange={e => setFormData({...formData, result: e.target.value as any})} className="w-full p-2 border rounded-lg">
                  <option value="Pass">Pass</option>
                  <option value="Fail">Fail</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Fit Factor (if Quant.)</label>
                <input type="number" value={formData.fitFactor} onChange={e => setFormData({...formData, fitFactor: parseInt(e.target.value) || 0})} className="w-full p-2 border rounded-lg" />
              </div>
            </div>
            <div className="md:col-span-2 flex justify-end gap-2 mt-2">
              <button type="button" onClick={() => setIsAdding(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg">Cancel</button>
              <button type="submit" className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">Save Test</button>
            </div>
          </form>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {tests.map(test => (
          <div key={test.id} className="border border-slate-200 rounded-xl p-5 bg-white shadow-sm hover:shadow-md transition-shadow">
            <div className="flex justify-between items-start mb-4">
              <div className="bg-blue-50 p-2 rounded-lg text-blue-600"><Shield size={24} /></div>
              <span className={`text-xs px-2.5 py-1 rounded-full font-medium ${
                test.result === 'Pass' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
              }`}>
                {test.result}
              </span>
            </div>
            <h3 className="font-bold text-slate-900 truncate">{test.employeeName}</h3>
            <p className="text-xs text-slate-500 mb-4">{test.maskType} ({test.maskSize})</p>
            
            <div className="space-y-2 text-sm text-slate-600">
              <div className="flex justify-between">
                <span className="text-slate-400">Method:</span>
                <span className="font-medium truncate ml-2">{test.testMethod.split(' ')[0]}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400 flex items-center gap-1"><Calendar size={14}/> Tested:</span>
                <span className="font-medium">{new Date(test.testDate).toLocaleDateString()}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400 flex items-center gap-1"><Calendar size={14}/> Expiry:</span>
                <span className={`font-bold ${new Date(test.expiryDate) < new Date() ? 'text-red-600' : 'text-slate-700'}`}>
                  {new Date(test.expiryDate).toLocaleDateString()}
                </span>
              </div>
            </div>
            
            {new Date(test.expiryDate) < new Date() && (
              <div className="mt-4 p-2 bg-red-50 rounded flex items-center gap-2 text-red-700 text-[10px] font-bold uppercase tracking-wider">
                <AlertCircle size={14} /> Re-test Required
              </div>
            )}
          </div>
        ))}
        {tests.length === 0 && !isAdding && (
          <div className="col-span-full p-8 text-center text-slate-500 bg-slate-50 rounded-xl border border-dashed border-slate-300">
            No respiratory fit tests logged.
          </div>
        )}
      </div>
    </div>
  );
}
