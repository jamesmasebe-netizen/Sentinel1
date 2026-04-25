import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { Users, Plus, MessageSquare, Calendar, CheckCircle2, AlertCircle } from 'lucide-react';

interface StakeholderCommunication {
  id: string;
  stakeholderName: string;
  stakeholderType: 'Regulator' | 'Neighbor' | 'NGO' | 'Supplier' | 'Customer';
  communicationType: 'Complaint' | 'Inquiry' | 'Meeting' | 'Inspection';
  description: string;
  actionTaken: string;
  status: 'Open' | 'Resolved';
  date: string;
  createdAt: string;
}

export default function EnvironmentalStakeholderLog() {
  const [communications, setCommunications] = useState<StakeholderCommunication[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [formData, setFormData] = useState({
    stakeholderName: '',
    stakeholderType: 'Neighbor' as StakeholderCommunication['stakeholderType'],
    communicationType: 'Inquiry' as StakeholderCommunication['communicationType'],
    description: '',
    actionTaken: '',
    status: 'Open' as StakeholderCommunication['status'],
    date: ''
  });

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'env_stakeholder_comms'), orderBy('date', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setCommunications(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as StakeholderCommunication[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'env_stakeholder_comms'));
    return () => unsubscribe();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      await addDoc(collection(db, 'env_stakeholder_comms'), {
        ...formData,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAdding(false);
      setFormData({ stakeholderName: '', stakeholderType: 'Neighbor', communicationType: 'Inquiry', description: '', actionTaken: '', status: 'Open', date: '' });
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'env_stakeholder_comms');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">Stakeholder Engagement Log</h2>
          <p className="text-sm text-slate-500">Record communications with neighbors, NGOs, regulators, and other stakeholders.</p>
        </div>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700">
          <Plus size={18} /> Log Communication
        </button>
      </div>

      {isAdding && (
        <div className="bg-slate-50 p-4 rounded-lg border border-slate-200 mb-6">
          <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Stakeholder Name</label>
              <input type="text" required placeholder="e.g., Dept of Forestry, Green NGO" value={formData.stakeholderName} onChange={e => setFormData({...formData, stakeholderName: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Stakeholder Type</label>
              <select value={formData.stakeholderType} onChange={e => setFormData({...formData, stakeholderType: e.target.value as any})} className="w-full p-2 border rounded-lg">
                <option value="Regulator">Regulator / Government</option>
                <option value="Neighbor">Neighbor / Community</option>
                <option value="NGO">NGO / Environmental Group</option>
                <option value="Supplier">Supplier</option>
                <option value="Customer">Customer</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Communication Type</label>
              <select value={formData.communicationType} onChange={e => setFormData({...formData, communicationType: e.target.value as any})} className="w-full p-2 border rounded-lg">
                <option value="Complaint">Complaint</option>
                <option value="Inquiry">Inquiry</option>
                <option value="Meeting">Meeting</option>
                <option value="Inspection">Inspection / Audit</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Date</label>
              <input type="date" required value={formData.date} onChange={e => setFormData({...formData, date: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div className="md:col-span-2">
              <label className="block text-sm font-medium text-slate-700 mb-1">Description</label>
              <textarea required value={formData.description} onChange={e => setFormData({...formData, description: e.target.value})} className="w-full p-2 border rounded-lg" rows={2}></textarea>
            </div>
            <div className="md:col-span-2">
              <label className="block text-sm font-medium text-slate-700 mb-1">Action Taken / Response</label>
              <textarea value={formData.actionTaken} onChange={e => setFormData({...formData, actionTaken: e.target.value})} className="w-full p-2 border rounded-lg" rows={2}></textarea>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Status</label>
              <select value={formData.status} onChange={e => setFormData({...formData, status: e.target.value as any})} className="w-full p-2 border rounded-lg">
                <option value="Open">Open</option>
                <option value="Resolved">Resolved</option>
              </select>
            </div>
            <div className="md:col-span-2 flex justify-end gap-2 mt-2">
              <button type="button" onClick={() => setIsAdding(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg">Cancel</button>
              <button type="submit" className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">Save Communication</button>
            </div>
          </form>
        </div>
      )}

      <div className="space-y-4">
        {communications.map(comm => (
          <div key={comm.id} className="border border-slate-200 rounded-xl p-5 bg-white shadow-sm hover:shadow-md transition-shadow">
            <div className="flex justify-between items-start mb-4">
              <div className="flex items-center gap-3">
                <div className="bg-blue-50 p-2 rounded-lg text-blue-600"><Users size={24} /></div>
                <div>
                  <h3 className="font-bold text-slate-900">{comm.stakeholderName}</h3>
                  <p className="text-xs text-slate-500 font-bold uppercase tracking-wider">{comm.stakeholderType}</p>
                </div>
              </div>
              <span className={`text-[10px] px-2 py-1 rounded-full font-bold uppercase tracking-wider ${
                comm.status === 'Resolved' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
              }`}>
                {comm.status}
              </span>
            </div>
            
            <div className="bg-slate-50 p-3 rounded-lg border border-slate-100 mb-4">
              <div className="flex items-center gap-2 text-xs font-bold text-slate-400 uppercase mb-2">
                <MessageSquare size={12} /> {comm.communicationType}
              </div>
              <p className="text-sm text-slate-600">{comm.description}</p>
            </div>

            <div className="flex items-center justify-between text-xs text-slate-400 pt-3 border-t border-slate-100">
              <span className="flex items-center gap-1"><Calendar size={12}/> Date: <span className="text-slate-700 font-medium">{new Date(comm.date).toLocaleDateString()}</span></span>
              {comm.actionTaken && (
                <span className="flex items-center gap-1 text-green-600"><CheckCircle2 size={12}/> Actioned</span>
              )}
            </div>
          </div>
        ))}
        {communications.length === 0 && !isAdding && (
          <div className="p-8 text-center text-slate-500 bg-slate-50 rounded-xl border border-dashed border-slate-300">
            No stakeholder communications logged.
          </div>
        )}
      </div>
    </div>
  );
}
