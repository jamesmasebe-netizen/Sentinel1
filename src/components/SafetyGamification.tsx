import React from 'react';
import { Trophy, Medal, Star, Target, Shield, Zap, Award, CheckCircle } from 'lucide-react';

interface TrainingRecord {
  id: string;
  employeeName: string;
  courseName: string;
  status: 'Active' | 'Expired';
}

interface ToolboxTalk {
  id: string;
  attendees: string[];
}

interface Props {
  records: TrainingRecord[];
  talks: ToolboxTalk[];
}

interface Badge {
  id: string;
  name: string;
  description: string;
  icon: React.ReactNode;
  color: string;
  isEarned: boolean;
}

export default function SafetyGamification({ records, talks }: Props) {
  const currentUser = "Current User"; // In a real app, this would be the logged-in user's name
  
  const userRecords = records.filter(r => r.employeeName === currentUser);
  const userTalks = talks.filter(t => t.attendees.includes(currentUser));
  
  const points = (userRecords.length * 50) + (userTalks.length * 10);
  const level = Math.floor(points / 100) + 1;
  const progressToNextLevel = points % 100;

  const badges: Badge[] = [
    {
      id: 'induction-pro',
      name: 'Induction Pro',
      description: 'Complete your first site safety induction.',
      icon: <Shield size={24} />,
      color: 'bg-blue-500',
      isEarned: userRecords.some(r => r.courseName.toLowerCase().includes('induction'))
    },
    {
      id: 'quiz-master',
      name: 'Quiz Master',
      description: 'Pass 3 digital training modules with 100%.',
      icon: <Zap size={24} />,
      color: 'bg-amber-500',
      isEarned: userRecords.filter(r => r.courseName.includes('(Digital)')).length >= 3
    },
    {
      id: 'toolbox-regular',
      name: 'Toolbox Regular',
      description: 'Attend 5 toolbox talks.',
      icon: <Users size={24} />,
      color: 'bg-green-500',
      isEarned: userTalks.length >= 5
    },
    {
      id: 'competency-champion',
      name: 'Competency Champion',
      description: 'Maintain 5 active certifications.',
      icon: <Trophy size={24} />,
      color: 'bg-purple-500',
      isEarned: userRecords.filter(r => r.status === 'Active').length >= 5
    },
    {
      id: 'safety-leader',
      name: 'Safety Leader',
      description: 'Reach Level 5 in safety competency.',
      icon: <Award size={24} />,
      color: 'bg-red-500',
      isEarned: level >= 5
    }
  ];

  return (
    <div className="space-y-8">
      {/* Profile Header */}
      <div className="bg-gradient-to-br from-slate-900 to-slate-800 rounded-2xl p-8 text-white shadow-xl relative overflow-hidden">
        <div className="relative z-10 flex flex-col md:flex-row items-center gap-8">
          <div className="relative">
            <div className="w-24 h-24 rounded-full bg-blue-600 flex items-center justify-center text-3xl font-bold border-4 border-white/20">
              {level}
            </div>
            <div className="absolute -bottom-2 -right-2 bg-amber-500 text-white p-1.5 rounded-full border-2 border-slate-900">
              <Star size={16} fill="currentColor" />
            </div>
          </div>
          
          <div className="flex-1 text-center md:text-left">
            <h2 className="text-2xl font-bold mb-1">Safety Level {level}</h2>
            <p className="text-slate-400 text-sm mb-4">You have earned {points} Safety Points so far!</p>
            
            <div className="max-w-md">
              <div className="flex justify-between text-xs font-bold uppercase tracking-wider mb-2">
                <span className="text-blue-400">Level {level}</span>
                <span className="text-slate-500">Level {level + 1}</span>
              </div>
              <div className="w-full bg-white/10 rounded-full h-3">
                <div 
                  className="h-3 rounded-full bg-blue-500 transition-all duration-1000 shadow-[0_0_10px_rgba(59,130,246,0.5)]" 
                  style={{ width: `${progressToNextLevel}%` }}
                />
              </div>
              <p className="text-[10px] text-slate-500 mt-2 text-right">{100 - progressToNextLevel} points to next level</p>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="bg-white/5 rounded-xl p-4 text-center border border-white/10">
              <p className="text-2xl font-bold text-white">{userRecords.length}</p>
              <p className="text-[10px] text-slate-500 uppercase font-bold">Certificates</p>
            </div>
            <div className="bg-white/5 rounded-xl p-4 text-center border border-white/10">
              <p className="text-2xl font-bold text-white">{userTalks.length}</p>
              <p className="text-[10px] text-slate-500 uppercase font-bold">Talks</p>
            </div>
          </div>
        </div>
        
        {/* Decorative background */}
        <div className="absolute top-0 right-0 w-96 h-96 bg-blue-600/10 rounded-full blur-3xl -mr-48 -mt-48"></div>
      </div>

      {/* Badges Grid */}
      <div className="space-y-4">
        <h3 className="font-bold text-slate-900 flex items-center gap-2">
          <Medal size={20} className="text-amber-500" />
          Safety Achievement Badges
        </h3>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {badges.map(badge => (
            <div 
              key={badge.id} 
              className={`p-5 rounded-2xl border transition-all ${
                badge.isEarned 
                  ? 'bg-white border-slate-200 shadow-sm hover:shadow-md' 
                  : 'bg-slate-50 border-slate-100 opacity-60 grayscale'
              }`}
            >
              <div className="flex items-start gap-4">
                <div className={`p-3 rounded-xl text-white ${badge.isEarned ? badge.color : 'bg-slate-300'}`}>
                  {badge.icon}
                </div>
                <div>
                  <h4 className="font-bold text-slate-900">{badge.name}</h4>
                  <p className="text-xs text-slate-500 mt-1">{badge.description}</p>
                  {badge.isEarned && (
                    <div className="mt-3 flex items-center gap-1 text-[10px] font-bold text-green-600 uppercase">
                      <CheckCircle size={12} />
                      Unlocked
                    </div>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Leaderboard Placeholder */}
      <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm">
        <div className="flex items-center justify-between mb-6">
          <h3 className="font-bold text-slate-900 flex items-center gap-2">
            <Target size={20} className="text-blue-600" />
            Safety Champions Leaderboard
          </h3>
          <button className="text-xs font-bold text-blue-600 hover:underline">View All</button>
        </div>
        <div className="space-y-4">
          {[
            { name: 'John Doe', points: 1250, level: 13 },
            { name: 'Jane Smith', points: 980, level: 10 },
            { name: 'Mike Johnson', points: 840, level: 9 }
          ].map((user, idx) => (
            <div key={idx} className="flex items-center justify-between p-3 rounded-xl hover:bg-slate-50 transition-colors">
              <div className="flex items-center gap-4">
                <span className="text-sm font-bold text-slate-400 w-4">{idx + 1}</span>
                <div className="w-10 h-10 rounded-full bg-slate-100 flex items-center justify-center font-bold text-slate-600">
                  {user.name.charAt(0)}
                </div>
                <div>
                  <p className="text-sm font-bold text-slate-900">{user.name}</p>
                  <p className="text-[10px] text-slate-500 uppercase">Level {user.level}</p>
                </div>
              </div>
              <div className="text-right">
                <p className="text-sm font-bold text-blue-600">{user.points}</p>
                <p className="text-[10px] text-slate-500 uppercase font-bold">Points</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

// Helper icons for badges
function Users({ size }: { size: number }) {
  return (
    <svg 
      width={size} 
      height={size} 
      viewBox="0 0 24 24" 
      fill="none" 
      stroke="currentColor" 
      strokeWidth="2" 
      strokeLinecap="round" 
      strokeLinejoin="round"
    >
      <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" />
      <circle cx="9" cy="7" r="4" />
      <path d="M22 21v-2a4 4 0 0 0-3-3.87" />
      <path d="M16 3.13a4 4 0 0 1 0 7.75" />
    </svg>
  );
}
