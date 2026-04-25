import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, where, doc, updateDoc, deleteDoc } from 'firebase/firestore';
import { db, handleFirestoreError, OperationType } from '../lib/firebase';
import { useAuth } from '../contexts/AuthContext';
import { CheckCircle, Clock, AlertCircle, Plus, Trash2 } from 'lucide-react';
import { ActionItem } from '../pages/RiskManagement';

interface ActionItemsListProps {
  assessmentId: string;
}

export default function ActionItemsList({ assessmentId }: ActionItemsListProps) {
  const { user } = useAuth();
  const [items, setItems] = useState<ActionItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [isAdding, setIsAdding] = useState(false);
  
  const [description, setDescription] = useState('');
  const [assigneeName, setAssigneeName] = useState('');
  const [dueDate, setDueDate] = useState('');

  useEffect(() => {
    if (!user) return;
    
    const q = query(collection(db, 'action_items'), where('assessmentId', '==', assessmentId));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data: ActionItem[] = [];
      snapshot.forEach((doc) => {
        data.push({ id: doc.id, ...doc.data() } as ActionItem);
      });
      setItems(data);
      setLoading(false);
    }, (error) => {
      handleFirestoreError(error, OperationType.LIST, 'action_items');
      setLoading(false);
    });

    return () => unsubscribe();
  }, [user, assessmentId]);

  const handleAdd = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user) return;

    try {
      const newItem = {
        assessmentId,
        description,
        assigneeId: user.uid, // In a real app, this would be selected from a list of users
        assigneeName: assigneeName || user.displayName || 'Unknown User',
        dueDate: new Date(dueDate).toISOString(),
        status: 'Pending'
      };

      await addDoc(collection(db, 'action_items'), newItem);
      setIsAdding(false);
      setDescription('');
      setAssigneeName('');
      setDueDate('');
    } catch (error) {
      handleFirestoreError(error, OperationType.CREATE, 'action_items');
    }
  };

  const handleStatusChange = async (id: string, newStatus: string) => {
    try {
      const updateData: any = { status: newStatus };
      if (newStatus === 'Completed') {
        updateData.completedAt = new Date().toISOString();
        updateData.completedBy = user?.uid;
      }
      await updateDoc(doc(db, 'action_items', id), updateData);
    } catch (error) {
      handleFirestoreError(error, OperationType.UPDATE, `action_items/${id}`);
    }
  };

  const handleDelete = async (id: string) => {
    if (!window.confirm('Delete this action item?')) return;
    try {
      await deleteDoc(doc(db, 'action_items', id));
    } catch (error) {
      handleFirestoreError(error, OperationType.DELETE, `action_items/${id}`);
    }
  };

  if (loading) return <div className="text-sm text-gray-500">Loading action items...</div>;

  return (
    <div className="mt-4 pt-4 border-t border-gray-100">
      <div className="flex justify-between items-center mb-3">
        <h4 className="text-sm font-bold text-gray-700">Action Items ({items.length})</h4>
        <button
          onClick={() => setIsAdding(!isAdding)}
          className="text-xs flex items-center gap-1 text-blue-600 hover:text-blue-800"
        >
          <Plus size={14} /> Add Action
        </button>
      </div>

      {isAdding && (
        <form onSubmit={handleAdd} className="mb-4 bg-gray-50 p-3 rounded-lg border border-gray-200 space-y-3">
          <div>
            <label className="block text-xs font-medium text-gray-700 mb-1">Description</label>
            <input
              type="text" required
              value={description} onChange={e => setDescription(e.target.value)}
              className="w-full text-sm rounded border-gray-300 px-2 py-1"
            />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-medium text-gray-700 mb-1">Assignee Name</label>
              <input
                type="text" required
                value={assigneeName} onChange={e => setAssigneeName(e.target.value)}
                className="w-full text-sm rounded border-gray-300 px-2 py-1"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-gray-700 mb-1">Due Date</label>
              <input
                type="date" required
                value={dueDate} onChange={e => setDueDate(e.target.value)}
                className="w-full text-sm rounded border-gray-300 px-2 py-1"
              />
            </div>
          </div>
          <div className="flex justify-end gap-2">
            <button type="button" onClick={() => setIsAdding(false)} className="text-xs text-gray-500 hover:text-gray-700">Cancel</button>
            <button type="submit" className="text-xs bg-blue-600 text-white px-3 py-1 rounded hover:bg-blue-700">Save</button>
          </div>
        </form>
      )}

      <div className="space-y-2">
        {items.map(item => (
          <div key={item.id} className="flex items-center justify-between bg-white border border-gray-100 p-2 rounded-lg text-sm">
            <div className="flex-1">
              <p className="font-medium text-gray-800">{item.description}</p>
              <div className="flex items-center gap-3 text-xs text-gray-500 mt-1">
                <span>Assigned to: {item.assigneeName}</span>
                <span className={new Date(item.dueDate) < new Date() && item.status !== 'Completed' ? 'text-red-500 font-bold' : ''}>
                  Due: {new Date(item.dueDate).toLocaleDateString()}
                </span>
              </div>
            </div>
            <div className="flex items-center gap-3">
              <select
                value={item.status}
                onChange={(e) => handleStatusChange(item.id, e.target.value)}
                className={`text-xs rounded-full px-2 py-1 border font-medium ${
                  item.status === 'Completed' ? 'bg-green-50 text-green-700 border-green-200' :
                  item.status === 'In Progress' ? 'bg-blue-50 text-blue-700 border-blue-200' :
                  item.status === 'Overdue' ? 'bg-red-50 text-red-700 border-red-200' :
                  'bg-gray-50 text-gray-700 border-gray-200'
                }`}
              >
                <option value="Pending">Pending</option>
                <option value="In Progress">In Progress</option>
                <option value="Completed">Completed</option>
                <option value="Overdue">Overdue</option>
              </select>
              <button onClick={() => handleDelete(item.id)} className="text-gray-400 hover:text-red-600">
                <Trash2 size={14} />
              </button>
            </div>
          </div>
        ))}
        {items.length === 0 && !isAdding && (
          <p className="text-xs text-gray-500 italic">No action items assigned.</p>
        )}
      </div>
    </div>
  );
}
