import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { HeartHandshake, Plus, Users, Target, Calendar } from 'lucide-react';

interface Campaign {
  id: string;
  title: string;
  description: string;
  startDate: string;
  endDate: string;
  targetParticipants: number;
  enrolledParticipants: number;
  status: 'Active' | 'Upcoming' | 'Completed';
  createdAt: string;
}

export default function WellnessCampaigns() {
  const [campaigns, setCampaigns] = useState<Campaign[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    startDate: '',
    endDate: '',
    targetParticipants: 0,
    status: 'Upcoming' as Campaign['status']
  });

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'wellness_campaigns'), orderBy('createdAt', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as Campaign[];
      setCampaigns(data);
    }, (error) => handleFirestoreError(error, 'list' as any, 'wellness_campaigns'));
    return () => unsubscribe();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      await addDoc(collection(db, 'wellness_campaigns'), {
        ...formData,
        enrolledParticipants: 0,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAdding(false);
      setFormData({ title: '', description: '', startDate: '', endDate: '', targetParticipants: 0, status: 'Upcoming' });
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'wellness_campaigns');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">Health Promotion & Wellness</h2>
          <p className="text-sm text-slate-500">Manage employee wellness campaigns and initiatives.</p>
        </div>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700">
          <Plus size={18} /> Create Campaign
        </button>
      </div>

      {isAdding && (
        <div className="bg-slate-50 p-4 rounded-lg border border-slate-200 mb-6">
          <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="md:col-span-2">
              <label className="block text-sm font-medium text-slate-700 mb-1">Campaign Title</label>
              <input type="text" required placeholder="e.g., Stop Smoking Initiative 2026" value={formData.title} onChange={e => setFormData({...formData, title: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div className="md:col-span-2">
              <label className="block text-sm font-medium text-slate-700 mb-1">Description</label>
              <textarea required value={formData.description} onChange={e => setFormData({...formData, description: e.target.value})} className="w-full p-2 border rounded-lg" rows={2}></textarea>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Start Date</label>
              <input type="date" required value={formData.startDate} onChange={e => setFormData({...formData, startDate: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">End Date</label>
              <input type="date" required value={formData.endDate} onChange={e => setFormData({...formData, endDate: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Target Participants</label>
              <input type="number" min="1" required value={formData.targetParticipants} onChange={e => setFormData({...formData, targetParticipants: parseInt(e.target.value) || 0})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Status</label>
              <select value={formData.status} onChange={e => setFormData({...formData, status: e.target.value as any})} className="w-full p-2 border rounded-lg">
                <option value="Upcoming">Upcoming</option>
                <option value="Active">Active</option>
                <option value="Completed">Completed</option>
              </select>
            </div>
            <div className="md:col-span-2 flex justify-end gap-2 mt-2">
              <button type="button" onClick={() => setIsAdding(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg">Cancel</button>
              <button type="submit" className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">Launch Campaign</button>
            </div>
          </form>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {campaigns.map(campaign => {
          const progress = campaign.targetParticipants > 0 ? Math.min(100, Math.round((campaign.enrolledParticipants / campaign.targetParticipants) * 100)) : 0;
          return (
            <div key={campaign.id} className="border border-slate-200 rounded-xl p-5 bg-white shadow-sm hover:shadow-md transition-shadow">
              <div className="flex justify-between items-start mb-3">
                <div className="bg-rose-50 p-2 rounded-lg text-rose-600"><HeartHandshake size={24} /></div>
                <span className={`text-xs px-2.5 py-1 rounded-full font-medium ${
                  campaign.status === 'Active' ? 'bg-green-100 text-green-800' :
                  campaign.status === 'Completed' ? 'bg-slate-100 text-slate-800' :
                  'bg-blue-100 text-blue-800'
                }`}>
                  {campaign.status}
                </span>
              </div>
              <h3 className="font-semibold text-slate-900 mb-1">{campaign.title}</h3>
              <p className="text-sm text-slate-500 mb-4 line-clamp-2">{campaign.description}</p>
              
              <div className="space-y-3">
                <div className="flex items-center gap-2 text-sm text-slate-600">
                  <Calendar size={16} className="text-slate-400" />
                  <span>{new Date(campaign.startDate).toLocaleDateString()} - {new Date(campaign.endDate).toLocaleDateString()}</span>
                </div>
                
                <div className="pt-3 border-t border-slate-100">
                  <div className="flex justify-between items-center mb-1">
                    <span className="text-xs font-medium text-slate-500 flex items-center gap-1"><Users size={14}/> Enrollment</span>
                    <span className="text-xs font-bold text-slate-700">{campaign.enrolledParticipants} / {campaign.targetParticipants}</span>
                  </div>
                  <div className="w-full bg-slate-100 rounded-full h-2">
                    <div className="bg-rose-500 h-2 rounded-full" style={{ width: `${progress}%` }}></div>
                  </div>
                </div>
              </div>
            </div>
          );
        })}
        {campaigns.length === 0 && !isAdding && (
          <div className="col-span-full p-8 text-center text-slate-500 bg-slate-50 rounded-xl border border-dashed border-slate-300">
            No wellness campaigns active.
          </div>
        )}
      </div>
    </div>
  );
}
