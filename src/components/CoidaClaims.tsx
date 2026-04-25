import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy, doc, updateDoc } from 'firebase/firestore';
import { db, auth, handleFirestoreError } from '../lib/firebase';
import { Plus, X } from 'lucide-react';

interface CoidaClaim {
  id: string;
  employeeName: string;
  idNumber: string;
  incidentDate: string;
  claimNumber: string;
  status: 'Submitted' | 'Accepted' | 'Rejected' | 'Closed';
  lostDays: number;
  rtwStatus: 'Off Sick' | 'Light Duty' | 'Full Duty';
  authorId: string;
  createdAt: string;
}

export default function CoidaClaims() {
  const [claims, setClaims] = useState<CoidaClaim[]>([]);
  const [isAddingClaim, setIsAddingClaim] = useState(false);

  const [employeeName, setEmployeeName] = useState('');
  const [idNumber, setIdNumber] = useState('');
  const [claimIncidentDate, setClaimIncidentDate] = useState('');
  const [claimNumber, setClaimNumber] = useState('');
  const [lostDays, setLostDays] = useState(0);

  useEffect(() => {
    if (!auth.currentUser) return;
    const qClaims = query(collection(db, 'coida_claims'), orderBy('createdAt', 'desc'));
    const unsubClaims = onSnapshot(qClaims, (snapshot) => {
      setClaims(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as CoidaClaim[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'coida_claims'));

    return () => unsubClaims();
  }, []);

  const handleAddClaim = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      await addDoc(collection(db, 'coida_claims'), {
        employeeName,
        idNumber,
        incidentDate: new Date(claimIncidentDate).toISOString(),
        claimNumber,
        status: 'Submitted',
        lostDays: Number(lostDays),
        rtwStatus: 'Off Sick',
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAddingClaim(false);
      setEmployeeName(''); setIdNumber(''); setClaimIncidentDate(''); setClaimNumber(''); setLostDays(0);
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'coida_claims');
    }
  };

  const updateClaimStatus = async (id: string, field: 'status' | 'rtwStatus', value: string) => {
    try {
      await updateDoc(doc(db, 'coida_claims', id), { [field]: value });
    } catch (error) {
      handleFirestoreError(error, 'update' as any, 'coida_claims');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h2 className="text-lg font-bold text-slate-900">COIDA Claims</h2>
        <button
          onClick={() => setIsAddingClaim(true)}
          className="bg-rose-600 text-white px-4 py-2 rounded-lg hover:bg-rose-700 flex items-center gap-2 transition-colors shadow-sm"
        >
          <Plus size={20} /> Log COIDA Claim
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-slate-50 p-4 rounded-lg border border-slate-200">
          <p className="text-xs font-bold text-slate-500 uppercase tracking-wider">Total Claims</p>
          <p className="text-2xl font-bold text-slate-900">{claims.length}</p>
        </div>
        <div className="bg-red-50 p-4 rounded-lg border border-red-200">
          <p className="text-xs font-bold text-red-600 uppercase tracking-wider">Total Lost Days</p>
          <p className="text-2xl font-bold text-red-700">{claims.reduce((acc, curr) => acc + curr.lostDays, 0)}</p>
        </div>
        <div className="bg-amber-50 p-4 rounded-lg border border-amber-200">
          <p className="text-xs font-bold text-amber-600 uppercase tracking-wider">Off Sick</p>
          <p className="text-2xl font-bold text-amber-700">{claims.filter(c => c.rtwStatus === 'Off Sick').length}</p>
        </div>
        <div className="bg-green-50 p-4 rounded-lg border border-green-200">
          <p className="text-xs font-bold text-green-600 uppercase tracking-wider">Full Duty</p>
          <p className="text-2xl font-bold text-green-700">{claims.filter(c => c.rtwStatus === 'Full Duty').length}</p>
        </div>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 text-sm">
              <th className="p-4 font-medium">Employee</th>
              <th className="p-4 font-medium">Claim #</th>
              <th className="p-4 font-medium">Incident Date</th>
              <th className="p-4 font-medium">Lost Days</th>
              <th className="p-4 font-medium">RTW Status</th>
              <th className="p-4 font-medium">Status</th>
            </tr>
          </thead>
          <tbody>
            {claims.length === 0 ? (
              <tr><td colSpan={6} className="p-8 text-center text-slate-500">No COIDA claims recorded.</td></tr>
            ) : (
              claims.map((claim) => (
                <tr key={claim.id} className="border-b border-slate-100 hover:bg-slate-50 transition-colors">
                  <td className="p-4 font-medium text-slate-900">{claim.employeeName}</td>
                  <td className="p-4 text-slate-600 text-sm">{claim.claimNumber}</td>
                  <td className="p-4 text-slate-600 text-sm">{new Date(claim.incidentDate).toLocaleDateString()}</td>
                  <td className="p-4 text-slate-600 text-sm">{claim.lostDays}</td>
                  <td className="p-4">
                    <select
                      value={claim.rtwStatus}
                      onChange={(e) => updateClaimStatus(claim.id, 'rtwStatus', e.target.value)}
                      className={`text-xs font-medium rounded border-slate-300 focus:ring-rose-500 ${
                        claim.rtwStatus === 'Off Sick' ? 'bg-red-100 text-red-700' :
                        claim.rtwStatus === 'Light Duty' ? 'bg-amber-100 text-amber-700' :
                        'bg-green-100 text-green-700'
                      }`}
                    >
                      <option value="Off Sick">Off Sick</option>
                      <option value="Light Duty">Light Duty</option>
                      <option value="Full Duty">Full Duty</option>
                    </select>
                  </td>
                  <td className="p-4">
                    <select
                      value={claim.status}
                      onChange={(e) => updateClaimStatus(claim.id, 'status', e.target.value)}
                      className={`text-xs font-bold uppercase tracking-wider rounded-full border-slate-300 focus:ring-rose-500 ${
                        claim.status === 'Accepted' ? 'bg-green-100 text-green-700' :
                        claim.status === 'Rejected' ? 'bg-red-100 text-red-700' :
                        'bg-blue-100 text-blue-700'
                      }`}
                    >
                      <option value="Submitted">Submitted</option>
                      <option value="Accepted">Accepted</option>
                      <option value="Rejected">Rejected</option>
                      <option value="Closed">Closed</option>
                    </select>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {isAddingClaim && (
        <div className="fixed inset-0 bg-slate-900/50 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md overflow-hidden">
            <div className="p-6 border-b border-slate-200 flex justify-between items-center bg-slate-50">
              <h2 className="text-xl font-bold text-slate-900">Log COIDA Claim</h2>
              <button onClick={() => setIsAddingClaim(false)} className="text-slate-400 hover:text-slate-600">
                <X size={24} />
              </button>
            </div>
            <form onSubmit={handleAddClaim} className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Employee Name</label>
                <input type="text" required value={employeeName} onChange={e => setEmployeeName(e.target.value)} className="w-full p-2.5 border border-slate-300 rounded-lg" />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">ID Number</label>
                <input type="text" required value={idNumber} onChange={e => setIdNumber(e.target.value)} className="w-full p-2.5 border border-slate-300 rounded-lg" />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Incident Date</label>
                <input type="date" required value={claimIncidentDate} onChange={e => setClaimIncidentDate(e.target.value)} className="w-full p-2.5 border border-slate-300 rounded-lg" />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Claim Number (if known)</label>
                <input type="text" value={claimNumber} onChange={e => setClaimNumber(e.target.value)} className="w-full p-2.5 border border-slate-300 rounded-lg" />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Lost Days (Initial)</label>
                <input type="number" min="0" required value={lostDays} onChange={e => setLostDays(Number(e.target.value))} className="w-full p-2.5 border border-slate-300 rounded-lg" />
              </div>
              <div className="flex justify-end gap-3 pt-4 border-t border-slate-200">
                <button type="button" onClick={() => setIsAddingClaim(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg">Cancel</button>
                <button type="submit" className="px-4 py-2 bg-rose-600 text-white rounded-lg hover:bg-rose-700">Save Claim</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
