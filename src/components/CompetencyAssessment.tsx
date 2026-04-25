import React, { useState } from 'react';
import { ClipboardCheck, Camera, Upload, CheckCircle2, User, BookOpen } from 'lucide-react';
import { collection, addDoc } from 'firebase/firestore';
import { db, auth, handleFirestoreError } from '../lib/firebase';

interface Props {
  employees: string[];
}

const ASSESSMENT_CRITERIA = [
  "Demonstrates safe operation of equipment",
  "Correctly identifies workplace hazards",
  "Follows standard operating procedures (SOPs)",
  "Uses appropriate Personal Protective Equipment (PPE)",
  "Maintains a clean and organized workspace"
];

export default function CompetencyAssessment({ employees }: Props) {
  const [selectedEmployee, setSelectedEmployee] = useState('');
  const [competency, setCompetency] = useState('');
  const [checklist, setChecklist] = useState<boolean[]>(new Array(ASSESSMENT_CRITERIA.length).fill(false));
  const [notes, setNotes] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [success, setSuccess] = useState(false);

  const toggleCriterion = (idx: number) => {
    const newChecklist = [...checklist];
    newChecklist[idx] = !newChecklist[idx];
    setChecklist(newChecklist);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser || !selectedEmployee || !competency) return;

    setIsSubmitting(true);
    try {
      await addDoc(collection(db, 'competency_assessments'), {
        employeeName: selectedEmployee,
        competency,
        checklist,
        notes,
        assessorName: auth.currentUser.displayName || 'Supervisor',
        assessorId: auth.currentUser.uid,
        date: new Date().toISOString(),
        createdAt: new Date().toISOString()
      });
      
      // Also add to training records if all criteria met
      if (checklist.every(c => c)) {
        const expiryDate = new Date();
        expiryDate.setFullYear(expiryDate.getFullYear() + 2); // Valid for 2 years
        
        await addDoc(collection(db, 'training_records'), {
          employeeName: selectedEmployee,
          idNumber: 'ASSESS-' + Math.random().toString(36).substr(2, 5).toUpperCase(),
          courseName: competency + ' (Practical Assessment)',
          dateCompleted: new Date().toISOString(),
          expiryDate: expiryDate.toISOString(),
          status: 'Active',
          authorId: auth.currentUser.uid,
          createdAt: new Date().toISOString()
        });
      }

      setSuccess(true);
      setTimeout(() => {
        setSuccess(false);
        setSelectedEmployee('');
        setCompetency('');
        setChecklist(new Array(ASSESSMENT_CRITERIA.length).fill(false));
        setNotes('');
      }, 3000);
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'competency_assessments');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="max-w-3xl mx-auto">
      <div className="bg-white border border-slate-200 rounded-xl shadow-sm overflow-hidden">
        <div className="p-6 border-b border-slate-200 bg-slate-50 flex items-center gap-3">
          <div className="bg-blue-600 text-white p-2 rounded-lg">
            <ClipboardCheck size={24} />
          </div>
          <div>
            <h2 className="text-xl font-bold text-slate-900">Practical Competency Assessment</h2>
            <p className="text-sm text-slate-500">Conduct on-the-job verification of employee skills.</p>
          </div>
        </div>

        {success ? (
          <div className="p-12 text-center space-y-4">
            <div className="bg-green-100 text-green-600 w-16 h-16 rounded-full flex items-center justify-center mx-auto">
              <CheckCircle2 size={32} />
            </div>
            <h3 className="text-xl font-bold text-slate-900">Assessment Submitted</h3>
            <p className="text-slate-600">The competency record has been updated successfully.</p>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="p-6 space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1 flex items-center gap-2">
                  <User size={16} className="text-slate-400" />
                  Employee to Assess
                </label>
                <select 
                  required
                  value={selectedEmployee}
                  onChange={(e) => setSelectedEmployee(e.target.value)}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                >
                  <option value="">-- Select Employee --</option>
                  {employees.map(emp => (
                    <option key={emp} value={emp}>{emp}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1 flex items-center gap-2">
                  <BookOpen size={16} className="text-slate-400" />
                  Competency / Skill
                </label>
                <input 
                  type="text" 
                  required
                  placeholder="e.g., Grinder Operation"
                  value={competency}
                  onChange={(e) => setCompetency(e.target.value)}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                />
              </div>
            </div>

            <div className="space-y-3">
              <h3 className="font-bold text-slate-900 text-sm uppercase tracking-wider">Assessment Checklist</h3>
              {ASSESSMENT_CRITERIA.map((criterion, idx) => (
                <label key={idx} className="flex items-start gap-3 p-3 rounded-lg border border-slate-100 hover:bg-slate-50 cursor-pointer transition-colors">
                  <input 
                    type="checkbox" 
                    checked={checklist[idx]}
                    onChange={() => toggleCriterion(idx)}
                    className="mt-1 h-4 w-4 text-blue-600 rounded border-slate-300 focus:ring-blue-500"
                  />
                  <span className="text-slate-700 text-sm">{criterion}</span>
                </label>
              ))}
            </div>

            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Observation Notes</label>
              <textarea 
                rows={3}
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                placeholder="Describe the worker's performance or any areas for improvement..."
                className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <div className="flex items-center gap-4 p-4 bg-slate-50 rounded-xl border border-slate-200">
              <div className="flex-1">
                <p className="text-sm font-bold text-slate-900">Evidence Upload</p>
                <p className="text-xs text-slate-500">Attach photos or documents as proof of competency.</p>
              </div>
              <div className="flex gap-2">
                <button type="button" className="p-2 bg-white border border-slate-300 rounded-lg text-slate-600 hover:bg-slate-50">
                  <Camera size={20} />
                </button>
                <button type="button" className="p-2 bg-white border border-slate-300 rounded-lg text-slate-600 hover:bg-slate-50">
                  <Upload size={20} />
                </button>
              </div>
            </div>

            <button 
              type="submit"
              disabled={isSubmitting}
              className="w-full py-3 bg-blue-600 text-white rounded-lg font-bold hover:bg-blue-700 transition-colors disabled:bg-blue-300 flex items-center justify-center gap-2"
            >
              {isSubmitting ? 'Submitting...' : 'Complete Assessment'}
            </button>
          </form>
        )}
      </div>
    </div>
  );
}
