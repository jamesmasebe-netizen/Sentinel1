import React, { useState } from 'react';
import { PlayCircle, CheckCircle2, XCircle, Award, BookOpen, ChevronRight } from 'lucide-react';
import { collection, addDoc } from 'firebase/firestore';
import { db, auth, handleFirestoreError } from '../lib/firebase';

interface Module {
  id: string;
  title: string;
  description: string;
  duration: string;
  questions: Question[];
}

interface Question {
  id: number;
  text: string;
  options: string[];
  correctAnswer: number;
}

const MODULES: Module[] = [
  {
    id: 'fire-safety',
    title: 'Basic Fire Safety',
    description: 'Learn the fundamentals of fire prevention and emergency response.',
    duration: '10 mins',
    questions: [
      {
        id: 1,
        text: 'What is the first thing you should do if you discover a fire?',
        options: ['Try to put it out', 'Raise the alarm', 'Call your manager', 'Gather your belongings'],
        correctAnswer: 1
      },
      {
        id: 2,
        text: 'Which type of fire extinguisher is best for electrical fires?',
        options: ['Water', 'Foam', 'CO2', 'Wet Chemical'],
        correctAnswer: 2
      }
    ]
  },
  {
    id: 'manual-handling',
    title: 'Manual Handling Basics',
    description: 'Safe techniques for lifting and moving heavy objects.',
    duration: '15 mins',
    questions: [
      {
        id: 1,
        text: 'When lifting a heavy object, you should bend your:',
        options: ['Back', 'Knees', 'Waist', 'Neck'],
        correctAnswer: 1
      },
      {
        id: 2,
        text: 'What should you do before attempting a lift?',
        options: ['Check the weight', 'Assess the path', 'Ask for help if needed', 'All of the above'],
        correctAnswer: 3
      }
    ]
  }
];

export default function DigitalTraining() {
  const [selectedModule, setSelectedModule] = useState<Module | null>(null);
  const [currentQuestionIdx, setCurrentQuestionIdx] = useState(0);
  const [answers, setAnswers] = useState<number[]>([]);
  const [quizResult, setQuizResult] = useState<{ score: number, passed: boolean } | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const startQuiz = (module: Module) => {
    setSelectedModule(module);
    setCurrentQuestionIdx(0);
    setAnswers([]);
    setQuizResult(null);
  };

  const handleAnswer = (optionIdx: number) => {
    const newAnswers = [...answers, optionIdx];
    setAnswers(newAnswers);

    if (currentQuestionIdx < (selectedModule?.questions.length || 0) - 1) {
      setCurrentQuestionIdx(currentQuestionIdx + 1);
    } else {
      // Calculate score
      const score = newAnswers.reduce((acc, ans, idx) => {
        return ans === selectedModule!.questions[idx].correctAnswer ? acc + 1 : acc;
      }, 0);
      const percentage = (score / selectedModule!.questions.length) * 100;
      const passed = percentage >= 80;
      setQuizResult({ score: percentage, passed });
      
      if (passed) {
        saveTrainingRecord(selectedModule!.title);
      }
    }
  };

  const saveTrainingRecord = async (courseName: string) => {
    if (!auth.currentUser) return;
    setIsSubmitting(true);
    try {
      const expiryDate = new Date();
      expiryDate.setFullYear(expiryDate.getFullYear() + 1); // Valid for 1 year

      await addDoc(collection(db, 'training_records'), {
        employeeName: auth.currentUser.displayName || 'Current User',
        idNumber: 'INTERNAL-' + auth.currentUser.uid.slice(0, 5),
        courseName: courseName + ' (Digital)',
        dateCompleted: new Date().toISOString(),
        expiryDate: expiryDate.toISOString(),
        status: 'Active',
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'training_records');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="space-y-6">
      {!selectedModule ? (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {MODULES.map(module => (
            <div key={module.id} className="bg-white border border-slate-200 rounded-xl p-6 hover:shadow-md transition-shadow">
              <div className="flex items-start gap-4 mb-4">
                <div className="bg-blue-50 p-3 rounded-lg text-blue-600">
                  <BookOpen size={24} />
                </div>
                <div>
                  <h3 className="font-bold text-slate-900">{module.title}</h3>
                  <p className="text-sm text-slate-500">{module.duration} • {module.questions.length} Questions</p>
                </div>
              </div>
              <p className="text-slate-600 text-sm mb-6">{module.description}</p>
              <button 
                onClick={() => startQuiz(module)}
                className="w-full py-2.5 bg-blue-600 text-white rounded-lg font-bold hover:bg-blue-700 transition-colors flex items-center justify-center gap-2"
              >
                <PlayCircle size={18} />
                Start Module
              </button>
            </div>
          ))}
        </div>
      ) : (
        <div className="max-w-2xl mx-auto bg-white border border-slate-200 rounded-xl shadow-lg overflow-hidden">
          <div className="bg-slate-900 p-6 text-white flex justify-between items-center">
            <div>
              <h3 className="font-bold text-lg">{selectedModule.title}</h3>
              <p className="text-slate-400 text-sm">Question {currentQuestionIdx + 1} of {selectedModule.questions.length}</p>
            </div>
            <button onClick={() => setSelectedModule(null)} className="text-slate-400 hover:text-white">
              <XCircle size={24} />
            </button>
          </div>

          <div className="p-8">
            {!quizResult ? (
              <div className="space-y-6">
                <h4 className="text-xl font-medium text-slate-900">{selectedModule.questions[currentQuestionIdx].text}</h4>
                <div className="grid grid-cols-1 gap-3">
                  {selectedModule.questions[currentQuestionIdx].options.map((option, idx) => (
                    <button
                      key={idx}
                      onClick={() => handleAnswer(idx)}
                      className="w-full text-left p-4 rounded-xl border border-slate-200 hover:border-blue-500 hover:bg-blue-50 transition-all group flex items-center justify-between"
                    >
                      <span className="text-slate-700 group-hover:text-blue-700">{option}</span>
                      <ChevronRight size={18} className="text-slate-300 group-hover:text-blue-500" />
                    </button>
                  ))}
                </div>
              </div>
            ) : (
              <div className="text-center py-8 space-y-6">
                <div className={`w-20 h-20 rounded-full flex items-center justify-center mx-auto ${quizResult.passed ? 'bg-green-100 text-green-600' : 'bg-red-100 text-red-600'}`}>
                  {quizResult.passed ? <Award size={40} /> : <XCircle size={40} />}
                </div>
                <div>
                  <h4 className="text-2xl font-bold text-slate-900">{quizResult.passed ? 'Congratulations!' : 'Keep Practicing'}</h4>
                  <p className="text-slate-600">You scored {quizResult.score}%</p>
                </div>
                <div className="p-4 rounded-lg bg-slate-50 text-sm text-slate-600">
                  {quizResult.passed 
                    ? 'Your training record has been automatically updated. You are now certified in this competency.' 
                    : 'You need at least 80% to pass. Please review the material and try again.'}
                </div>
                <button 
                  onClick={() => setSelectedModule(null)}
                  className="px-8 py-3 bg-slate-900 text-white rounded-lg font-bold hover:bg-slate-800 transition-colors"
                >
                  Back to Modules
                </button>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
