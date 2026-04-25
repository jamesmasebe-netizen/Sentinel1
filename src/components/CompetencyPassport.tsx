import React, { useState } from 'react';
import { QRCodeSVG } from 'qrcode.react';
import { User, CheckCircle, XCircle } from 'lucide-react';

interface TrainingRecord {
  id: string;
  employeeName: string;
  idNumber: string;
  courseName: string;
  expiryDate: string;
  status: 'Active' | 'Expired';
}

interface Props {
  records: TrainingRecord[];
}

export default function CompetencyPassport({ records }: Props) {
  const [scannedId, setScannedId] = useState('');
  const [scannedRecord, setScannedRecord] = useState<TrainingRecord | null>(null);

  const handleScan = (e: React.FormEvent) => {
    e.preventDefault();
    const record = records.find(r => r.idNumber === scannedId);
    setScannedRecord(record || null);
  };

  return (
    <div className="space-y-8">
      <div className="bg-white p-6 rounded-xl shadow-sm border border-slate-200">
        <h2 className="text-lg font-bold text-slate-900 mb-4">Competency Scanner</h2>
        <form onSubmit={handleScan} className="flex gap-2">
          <input 
            type="text" 
            placeholder="Enter Employee ID Number" 
            value={scannedId} 
            onChange={(e) => setScannedId(e.target.value)}
            className="flex-1 p-2 border border-slate-300 rounded-lg"
          />
          <button type="submit" className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700">Scan</button>
        </form>

        {scannedRecord && (
          <div className="mt-6 p-4 bg-slate-50 rounded-lg border border-slate-200">
            <div className="flex items-center gap-3 mb-2">
              <User className="text-slate-500" />
              <h3 className="font-bold text-slate-900">{scannedRecord.employeeName}</h3>
            </div>
            <p className="text-sm text-slate-600">Course: <span className="font-medium">{scannedRecord.courseName}</span></p>
            <p className="text-sm text-slate-600">Expiry: {new Date(scannedRecord.expiryDate).toLocaleDateString()}</p>
            <div className="mt-2">
              {scannedRecord.status === 'Active' ? (
                <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800 border border-green-200">
                  <CheckCircle size={12} /> Active
                </span>
              ) : (
                <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-red-100 text-red-800 border border-red-200">
                  <XCircle size={12} /> Expired
                </span>
              )}
            </div>
          </div>
        )}
      </div>

      <div className="bg-white p-6 rounded-xl shadow-sm border border-slate-200">
        <h2 className="text-lg font-bold text-slate-900 mb-4">My Competency Passport</h2>
        <div className="flex flex-col items-center">
          <QRCodeSVG value="https://ais-dev-sdb56jp6kvtx6b3gmg666z-301222461237.europe-west1.run.app/training" size={200} />
          <p className="mt-4 text-sm text-slate-500">Scan this code to verify your training status.</p>
        </div>
      </div>
    </div>
  );
}
