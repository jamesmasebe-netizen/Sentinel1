import React, { useState, useEffect } from 'react';
import { X, Printer, ShieldAlert, CheckCircle, AlertTriangle, MapPin, Box, FileText, Globe, Users, CheckSquare } from 'lucide-react';
import { RiskAssessment, RiskSignOff } from '../pages/RiskManagement';
import { collection, query, where, onSnapshot } from 'firebase/firestore';
import { db } from '../lib/firebase';
import { QRCodeSVG } from 'qrcode.react';

interface SWPModalProps {
  assessment: RiskAssessment;
  onClose: () => void;
}

const SWPModal: React.FC<SWPModalProps> = ({ assessment, onClose }) => {
  const [signOffs, setSignOffs] = useState<RiskSignOff[]>([]);

  useEffect(() => {
    const q = query(
      collection(db, 'risk_signoffs'),
      where('assessmentId', '==', assessment.id),
      where('version', '==', assessment.version || 1)
    );
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data: RiskSignOff[] = [];
      snapshot.forEach((doc) => {
        data.push({ id: doc.id, ...doc.data() } as RiskSignOff);
      });
      setSignOffs(data);
    });
    return () => unsubscribe();
  }, [assessment.id, assessment.version]);

  const handlePrint = () => {
    window.print();
  };

  const swpUrl = `${window.location.origin}/risk?id=${assessment.id}`;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4 print:p-0 print:bg-white overflow-y-auto">
      <div className="bg-white rounded-xl shadow-xl w-full max-w-4xl max-h-[90vh] overflow-y-auto print:max-h-none print:shadow-none print:w-full print:rounded-none relative flex flex-col">
        
        {/* Header - Hidden on print */}
        <div className="sticky top-0 bg-white border-b border-gray-200 p-4 flex justify-between items-center z-10 print:hidden">
          <h2 className="text-xl font-bold text-gray-900">Safe Work Procedure (SWP)</h2>
          <div className="flex items-center gap-3">
            <button
              onClick={handlePrint}
              className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
            >
              <Printer size={18} />
              Print SWP
            </button>
            <button
              onClick={onClose}
              className="p-2 text-gray-500 hover:bg-gray-100 rounded-full transition-colors"
            >
              <X size={24} />
            </button>
          </div>
        </div>

        {/* Printable Content */}
        <div className="p-8 print:p-0 flex-1">
          
          {/* Print Header */}
          <div className="border-b-4 border-blue-800 pb-6 mb-6">
            <div className="flex justify-between items-start">
              <div className="flex-1">
                <h1 className="text-3xl font-black text-gray-900 uppercase tracking-tight">Safe Work Procedure</h1>
                <h2 className="text-xl font-bold text-blue-800 mt-2">{assessment.taskName}</h2>
              </div>
              <div className="flex items-start gap-4">
                <div className="text-right text-sm text-gray-600">
                  <p><strong>Document ID:</strong> SWP-{assessment.id.substring(0, 6).toUpperCase()}</p>
                  <p><strong>Version:</strong> {assessment.version || 1}.0</p>
                  <p><strong>Date:</strong> {new Date(assessment.createdAt).toLocaleDateString()}</p>
                  <p><strong>Status:</strong> <span className="uppercase font-bold text-green-600">{assessment.status}</span></p>
                </div>
                <div className="bg-white p-1 border border-gray-200 rounded">
                  <QRCodeSVG value={swpUrl} size={64} />
                </div>
              </div>
            </div>
          </div>

          {/* Task Details Grid */}
          <div className="grid grid-cols-2 gap-6 mb-8">
            <div className="bg-gray-50 p-4 rounded-lg border border-gray-200">
              <h3 className="text-sm font-bold text-gray-500 uppercase tracking-wider mb-2">Location & Equipment</h3>
              <div className="space-y-2">
                <p className="flex items-center gap-2 text-gray-800 text-sm">
                  <MapPin size={16} className="text-gray-400" />
                  <strong>Location:</strong> {assessment.location || 'N/A'}
                </p>
                <p className="flex items-center gap-2 text-gray-800 text-sm">
                  <Box size={16} className="text-gray-400" />
                  <strong>Asset/Equipment:</strong> {assessment.assetName || 'N/A'}
                </p>
              </div>
            </div>
            <div className="bg-gray-50 p-4 rounded-lg border border-gray-200">
              <h3 className="text-sm font-bold text-gray-500 uppercase tracking-wider mb-2">Personnel Requirements</h3>
              <div className="space-y-2">
                <p className="text-gray-800 text-sm">
                  <strong>Author:</strong> {assessment.authorName}
                </p>
                <p className="text-gray-800 text-sm">
                  <strong>Approver:</strong> {assessment.approverName || 'Pending'}
                </p>
              </div>
            </div>
          </div>

          {/* Prerequisites */}
          <div className="mb-8">
            <h3 className="text-lg font-bold text-gray-900 border-b-2 border-gray-200 pb-2 mb-4">1. Prerequisites & Requirements</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <h4 className="font-semibold text-gray-800 mb-2 flex items-center gap-2 text-sm">
                  <ShieldAlert size={18} className="text-blue-600" /> Required PPE
                </h4>
                {assessment.requiredPPE && assessment.requiredPPE.length > 0 ? (
                  <ul className="list-disc list-inside space-y-1 text-gray-700 ml-2 text-sm">
                    {assessment.requiredPPE.map((ppe, i) => (
                      <li key={i}>{ppe}</li>
                    ))}
                  </ul>
                ) : (
                  <p className="text-gray-500 italic text-sm">No specific PPE listed.</p>
                )}
              </div>
              <div>
                <h4 className="font-semibold text-gray-800 mb-2 flex items-center gap-2 text-sm">
                  <CheckCircle size={18} className="text-green-600" /> Required Competencies
                </h4>
                {assessment.requiredCompetencies && assessment.requiredCompetencies.length > 0 ? (
                  <ul className="list-disc list-inside space-y-1 text-gray-700 ml-2 text-sm">
                    {assessment.requiredCompetencies.map((comp, i) => (
                      <li key={i}>{comp}</li>
                    ))}
                  </ul>
                ) : (
                  <p className="text-gray-500 italic text-sm">No specific competencies listed.</p>
                )}
              </div>
            </div>
          </div>

          {/* Hazards & Environmental */}
          <div className="mb-8 grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <h3 className="text-lg font-bold text-gray-900 border-b-2 border-gray-200 pb-2 mb-4">2. Identified Hazards</h3>
              <div className="bg-red-50 border-l-4 border-red-500 p-4 rounded-r-lg">
                <div className="flex items-start gap-3">
                  <AlertTriangle className="text-red-600 mt-0.5 flex-shrink-0" size={20} />
                  <div>
                    <p className="text-red-900 font-medium text-sm">{assessment.hazard}</p>
                    <p className="text-red-700 text-xs mt-1">
                      Risk Level: {assessment.residualRiskScore >= 15 ? 'HIGH' : assessment.residualRiskScore >= 8 ? 'MEDIUM' : 'LOW'} 
                      (Score: {assessment.residualRiskScore})
                    </p>
                  </div>
                </div>
              </div>
            </div>
            <div>
              <h3 className="text-lg font-bold text-gray-900 border-b-2 border-gray-200 pb-2 mb-4">3. Environmental Impacts</h3>
              {assessment.environmentalImpacts && assessment.environmentalImpacts.length > 0 ? (
                <div className="bg-emerald-50 border-l-4 border-emerald-500 p-4 rounded-r-lg">
                  <div className="flex items-start gap-3">
                    <Globe className="text-emerald-600 mt-0.5 flex-shrink-0" size={20} />
                    <ul className="list-disc list-inside space-y-1 text-emerald-900 text-sm">
                      {assessment.environmentalImpacts.map((env, i) => (
                        <li key={i}>{env}</li>
                      ))}
                    </ul>
                  </div>
                </div>
              ) : (
                <p className="text-gray-500 italic text-sm">No specific environmental impacts listed.</p>
              )}
            </div>
          </div>

          {/* Safe Work Procedure Steps (Controls) */}
          <div className="mb-8">
            <h3 className="text-lg font-bold text-gray-900 border-b-2 border-gray-200 pb-2 mb-4">4. Safe Work Procedure / Controls</h3>
            <div className="space-y-4">
              {assessment.controls.map((control, index) => (
                <div key={index} className="flex gap-4 p-4 border border-gray-200 rounded-lg bg-white">
                  <div className="flex-shrink-0 w-8 h-8 bg-blue-100 text-blue-800 rounded-full flex items-center justify-center font-bold text-sm">
                    {index + 1}
                  </div>
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <span className="font-semibold text-gray-900 text-sm">{control.type} Control</span>
                      {control.isCritical && (
                        <span className="bg-red-100 text-red-800 text-[10px] px-2 py-0.5 rounded-full font-bold uppercase tracking-wider">
                          Critical Step
                        </span>
                      )}
                    </div>
                    <p className="text-gray-700 text-sm">{control.description}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Compliance & Consultation */}
          <div className="mb-8 grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <h3 className="text-lg font-bold text-gray-900 border-b-2 border-gray-200 pb-2 mb-4">5. Applicable Legislation</h3>
              {assessment.applicableLegislation && assessment.applicableLegislation.length > 0 ? (
                <ul className="list-disc list-inside space-y-1 text-gray-700 text-sm ml-2">
                  {assessment.applicableLegislation.map((leg, i) => (
                    <li key={i}>{leg}</li>
                  ))}
                </ul>
              ) : (
                <p className="text-gray-500 italic text-sm">No specific legislation listed.</p>
              )}
            </div>
            <div>
              <h3 className="text-lg font-bold text-gray-900 border-b-2 border-gray-200 pb-2 mb-4">6. Consultation</h3>
              {assessment.consultedStakeholders && assessment.consultedStakeholders.length > 0 ? (
                <div className="flex flex-wrap gap-2">
                  {assessment.consultedStakeholders.map((stakeholder, i) => (
                    <span key={i} className="px-2 py-1 bg-gray-100 text-gray-700 rounded text-xs border border-gray-200 flex items-center gap-1">
                      <Users size={12} /> {stakeholder}
                    </span>
                  ))}
                </div>
              ) : (
                <p className="text-gray-500 italic text-sm">No specific stakeholders consulted.</p>
              )}
            </div>
          </div>

          {/* Digital Sign-off Section */}
          <div className="mt-12 pt-8 border-t-2 border-gray-800">
            <h3 className="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
              <CheckSquare size={20} /> 7. Digital Acknowledgements
            </h3>
            {signOffs.length > 0 ? (
              <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4 mb-8">
                {signOffs.map((signOff) => (
                  <div key={signOff.id} className="bg-slate-50 p-3 rounded border border-slate-200 flex items-center justify-between">
                    <div className="flex flex-col">
                      <span className="text-xs font-bold text-gray-900">{signOff.userName}</span>
                      <span className="text-[10px] text-gray-500">{new Date(signOff.signedAt).toLocaleString()}</span>
                    </div>
                    <CheckCircle size={16} className="text-green-600" />
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-sm text-gray-500 italic mb-8">No digital sign-offs recorded yet.</p>
            )}

            {/* Manual Sign-off Table (for printed version) */}
            <div className="hidden print:block">
              <h4 className="text-sm font-bold text-gray-900 mb-2">Additional Personnel Acknowledgement</h4>
              <table className="w-full border-collapse border border-gray-300 text-sm">
                <thead>
                  <tr className="bg-gray-100">
                    <th className="border border-gray-300 p-3 text-left w-1/3">Print Name</th>
                    <th className="border border-gray-300 p-3 text-left w-1/3">Signature</th>
                    <th className="border border-gray-300 p-3 text-left w-1/3">Date</th>
                  </tr>
                </thead>
                <tbody>
                  {[1, 2, 3].map((row) => (
                    <tr key={row}>
                      <td className="border border-gray-300 p-6"></td>
                      <td className="border border-gray-300 p-6"></td>
                      <td className="border border-gray-300 p-6"></td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

        </div>
      </div>
    </div>
  );
};

export default SWPModal;
