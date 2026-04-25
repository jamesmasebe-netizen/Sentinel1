import React, { useState, useEffect } from 'react';
import { collection, query, onSnapshot, doc, updateDoc, getDocs, where, limit } from 'firebase/firestore';
import { db, handleFirestoreError, OperationType } from '../lib/firebase';
import { useAuth } from '../contexts/AuthContext';
import { CheckCircle, Clock, AlertCircle, Filter, Search } from 'lucide-react';

interface ActionItem {
  id: string;
  title: string;
  type: 'Incident' | 'CAPA' | 'Observation' | 'Permit' | 'RiskAction' | 'RiskAssessment' | 'Audit' | 'ContractorAudit' | 'DynamicRiskAssessment' | 'EquipmentInspection';
  status: string;
  dueDate: string;
  assigneeName: string;
  collectionName: string;
}

export default function UnifiedActionItemTracker() {
  const { profile } = useAuth();
  const [items, setItems] = useState<ActionItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('All');
  const [search, setSearch] = useState('');

  useEffect(() => {
    if (!profile?.siteId) return;

      const fetchAllActionItems = async () => {
        const collections = [
          { name: 'action_items', type: 'RiskAction' as const },
          { name: 'incidents', type: 'Incident' as const },
          { name: 'capas', type: 'CAPA' as const },
          { name: 'observations', type: 'Observation' as const },
          { name: 'permits', type: 'Permit' as const },
          { name: 'risk_assessments', type: 'RiskAssessment' as const },
          { name: 'audits', type: 'Audit' as const },
          { name: 'contractor_audits', type: 'ContractorAudit' as const },
          { name: 'dynamic_risk_assessments', type: 'DynamicRiskAssessment' as const },
          { name: 'equipment_inspections', type: 'EquipmentInspection' as const }
        ];

        try {
          const fetchPromises = collections.map(async (coll) => {
            const q = query(
              collection(db, coll.name), 
              where('siteId', '==', profile.siteId),
              limit(20)
            );
            const snap = await getDocs(q);
            return snap.docs.map(doc => {
              const data = doc.data();
              return {
                id: doc.id,
                title: data.title || data.description || data.type || data.hazard || 'Untitled',
                type: coll.type,
                status: data.status || 'Pending',
                dueDate: data.dueDate || data.createdAt || data.date || data.timestamp || new Date().toISOString(),
                assigneeName: data.assigneeName || 'Unassigned',
                collectionName: coll.name
              } as ActionItem;
            });
          });

          const results = await Promise.all(fetchPromises);
          const allItems = results.flat();
          
          setItems(allItems.sort((a, b) => new Date(a.dueDate).getTime() - new Date(b.dueDate).getTime()));
        } catch (error) {
          handleFirestoreError(error, OperationType.LIST, 'multiple collections');
        } finally {
          setLoading(false);
        }
      };

    fetchAllActionItems();
  }, [profile]);

  const filteredItems = items.filter(item => 
    (filter === 'All' || item.status === filter) &&
    (item.title.toLowerCase().includes(search.toLowerCase()))
  );

  const handleStatusChange = async (item: ActionItem, newStatus: string) => {
    try {
      await updateDoc(doc(db, item.collectionName, item.id), { status: newStatus });
      setItems(prev => prev.map(i => i.id === item.id ? { ...i, status: newStatus } : i));
    } catch (error) {
      handleFirestoreError(error, OperationType.UPDATE, `${item.collectionName}/${item.id}`);
    }
  };

  if (loading) return <div className="p-6 text-slate-500">Loading action items...</div>;

  return (
    <div className="p-6 bg-white rounded-xl shadow-sm border border-slate-200">
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-xl font-bold text-slate-900">Unified Action Item Tracker</h2>
        <div className="flex gap-2">
          <input 
            type="text" placeholder="Search..." value={search} onChange={e => setSearch(e.target.value)}
            className="px-3 py-2 border border-slate-300 rounded-lg text-sm"
          />
          <select value={filter} onChange={e => setFilter(e.target.value)} className="px-3 py-2 border border-slate-300 rounded-lg text-sm">
            <option value="All">All Statuses</option>
            <option value="Pending">Pending</option>
            <option value="In Progress">In Progress</option>
            <option value="Completed">Completed</option>
          </select>
        </div>
      </div>

      <div className="space-y-2">
        {filteredItems.map(item => (
          <div key={item.id} className="flex items-center justify-between bg-slate-50 p-4 rounded-lg border border-slate-100">
            <div>
              <p className="font-bold text-slate-900">{item.title}</p>
              <p className="text-xs text-slate-500">{item.type} • Assigned to: {item.assigneeName} • Due: {new Date(item.dueDate).toLocaleDateString()}</p>
            </div>
            <select
              value={item.status}
              onChange={(e) => handleStatusChange(item, e.target.value)}
              className="text-xs rounded-full px-3 py-1 border font-medium bg-white"
            >
              <option value="Pending">Pending</option>
              <option value="In Progress">In Progress</option>
              <option value="Completed">Completed</option>
            </select>
          </div>
        ))}
      </div>
    </div>
  );
}
