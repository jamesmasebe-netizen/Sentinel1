import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { FileText, Printer, Download, CheckCircle2, AlertCircle } from 'lucide-react';

interface CoidaClaim {
  id: string;
  employeeName: string;
  idNumber: string;
  incidentDate: string;
  claimNumber: string;
  status: string;
}

export default function CoidaFormGenerator() {
  const [claims, setClaims] = useState<CoidaClaim[]>([]);
  const [selectedClaim, setSelectedClaim] = useState<CoidaClaim | null>(null);

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'coida_claims'), orderBy('createdAt', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setClaims(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as CoidaClaim[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'coida_claims'));
    return () => unsubscribe();
  }, []);

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">W.Cl.2 Form Generator</h2>
          <p className="text-sm text-slate-500">Generate official First Report of Accident forms for the Compensation Fund.</p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="md:col-span-1 space-y-4">
          <h3 className="text-sm font-bold text-slate-400 uppercase tracking-wider">Select Claim</h3>
          <div className="space-y-2 max-h-[400px] overflow-y-auto pr-2">
            {claims.map(claim => (
              <button
                key={claim.id}
                onClick={() => setSelectedClaim(claim)}
                className={`w-full text-left p-3 rounded-lg border transition-all ${
                  selectedClaim?.id === claim.id ? 'border-rose-600 bg-rose-50 ring-1 ring-rose-600' : 'border-slate-200 hover:border-rose-300'
                }`}
              >
                <p className="font-bold text-slate-900 text-sm">{claim.employeeName}</p>
                <p className="text-xs text-slate-500">Incident: {new Date(claim.incidentDate).toLocaleDateString()}</p>
              </button>
            ))}
          </div>
        </div>

        <div className="md:col-span-2">
          {selectedClaim ? (
            <div className="bg-white border border-slate-200 rounded-xl shadow-sm overflow-hidden">
              <div className="p-4 bg-slate-50 border-b border-slate-200 flex justify-between items-center">
                <span className="text-sm font-bold text-slate-700 flex items-center gap-2">
                  <FileText size={18} className="text-rose-600" /> W.Cl.2 Preview
                </span>
                <div className="flex gap-2">
                  <button className="flex items-center gap-1 px-3 py-1.5 bg-white border border-slate-300 rounded text-xs font-medium hover:bg-slate-50">
                    <Printer size={14} /> Print
                  </button>
                  <button className="flex items-center gap-1 px-3 py-1.5 bg-rose-600 text-white rounded text-xs font-medium hover:bg-rose-700">
                    <Download size={14} /> Export PDF
                  </button>
                </div>
              </div>
              <div className="p-8 space-y-8 font-serif text-slate-800">
                <div className="text-center border-b-2 border-slate-900 pb-4">
                  <h1 className="text-xl font-black uppercase">Compensation for Occupational Injuries and Diseases Act, 1993</h1>
                  <h2 className="text-lg font-bold">EMPLOYER'S REPORT OF AN ACCIDENT (W.Cl.2)</h2>
                </div>
                
                <div className="grid grid-cols-2 gap-8 text-sm">
                  <div className="space-y-4">
                    <section>
                      <h3 className="font-bold border-b border-slate-200 mb-2">PART A: EMPLOYER</h3>
                      <p><span className="text-slate-500">Registered Name:</span> [Company Name]</p>
                      <p><span className="text-slate-500">Registration No:</span> [COID Reg No]</p>
                    </section>
                    <section>
                      <h3 className="font-bold border-b border-slate-200 mb-2">PART B: EMPLOYEE</h3>
                      <p><span className="text-slate-500">Full Name:</span> {selectedClaim.employeeName}</p>
                      <p><span className="text-slate-500">ID Number:</span> {selectedClaim.idNumber}</p>
                    </section>
                  </div>
                  <div className="space-y-4">
                    <section>
                      <h3 className="font-bold border-b border-slate-200 mb-2">PART C: ACCIDENT</h3>
                      <p><span className="text-slate-500">Date of Accident:</span> {new Date(selectedClaim.incidentDate).toLocaleDateString()}</p>
                      <p><span className="text-slate-500">Time:</span> [Time from Incident Log]</p>
                      <p><span className="text-slate-500">Place:</span> [Location from Incident Log]</p>
                    </section>
                  </div>
                </div>

                <div className="p-4 bg-amber-50 border border-amber-200 rounded-lg flex items-start gap-3">
                  <AlertCircle className="text-amber-600 shrink-0" size={20} />
                  <p className="text-xs text-amber-800 leading-relaxed">
                    <strong>Note:</strong> This is a digital preview. Ensure all mandatory fields from the primary incident investigation are completed before final submission to the Compensation Commissioner.
                  </p>
                </div>
              </div>
            </div>
          ) : (
            <div className="h-full flex flex-col items-center justify-center p-12 bg-slate-50 rounded-xl border border-dashed border-slate-300 text-slate-500">
              <FileText size={48} className="mb-4 opacity-20" />
              <p>Select a claim from the list to preview the W.Cl.2 form.</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
