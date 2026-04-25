import React from 'react';
import { AlertTriangle } from 'lucide-react';

interface TrainingRecord {
  id: string;
  employeeName: string;
  courseName: string;
  expiryDate: string;
  status: 'Active' | 'Expired';
}

interface Props {
  records: TrainingRecord[];
}

export default function TrainingExpiryAlerts({ records }: Props) {
  const expiringSoon = records.filter(record => 
    record.status === 'Active' && 
    (new Date(record.expiryDate).getTime() - new Date().getTime() < 30 * 24 * 60 * 60 * 1000)
  );

  if (expiringSoon.length === 0) return null;

  return (
    <div className="bg-amber-50 border-l-4 border-amber-500 p-4 rounded-lg shadow-sm mb-6">
      <div className="flex items-start gap-3">
        <AlertTriangle className="text-amber-600 shrink-0" size={24} />
        <div>
          <h3 className="font-bold text-amber-900">Training Expiry Alerts ({expiringSoon.length})</h3>
          <p className="text-sm text-amber-700 mb-2">The following certifications are expiring within 30 days:</p>
          <ul className="text-sm text-amber-800 space-y-1">
            {expiringSoon.map(record => (
              <li key={record.id} className="flex gap-2">
                <span className="font-medium">{record.employeeName}</span> - {record.courseName} (Expires: {new Date(record.expiryDate).toLocaleDateString()})
              </li>
            ))}
          </ul>
        </div>
      </div>
    </div>
  );
}
