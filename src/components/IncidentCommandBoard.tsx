import React, { useState, useEffect } from 'react';
import { collection, onSnapshot, query, addDoc, doc, updateDoc, orderBy, deleteDoc } from 'firebase/firestore';
import { db, auth, handleFirestoreError } from '../lib/firebase';
import { 
  Layout, 
  Target, 
  CheckCircle2, 
  Clock, 
  User, 
  Plus, 
  X, 
  AlertCircle, 
  ShieldAlert,
  MoreVertical,
  Trash2
} from 'lucide-react';

interface ICSTask {
  id: string;
  objective: string;
  assignee: string;
  priority: 'Critical' | 'High' | 'Medium' | 'Low';
  status: 'Pending' | 'In Progress' | 'Completed' | 'Blocked';
  timestamp: string;
}

export default function IncidentCommandBoard() {
  const [tasks, setTasks] = useState<ICSTask[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  
  // Form State
  const [objective, setObjective] = useState('');
  const [assignee, setAssignee] = useState('');
  const [priority, setPriority] = useState<ICSTask['priority']>('High');

  useEffect(() => {
    const q = query(collection(db, 'ics_tasks'), orderBy('timestamp', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setTasks(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as ICSTask[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'ics_tasks'));

    return () => unsubscribe();
  }, []);

  const handleAddTask = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser || !objective) return;

    try {
      await addDoc(collection(db, 'ics_tasks'), {
        objective,
        assignee,
        priority,
        status: 'Pending',
        timestamp: new Date().toISOString()
      });
      setIsAdding(false);
      setObjective('');
      setAssignee('');
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'ics_tasks');
    }
  };

  const updateStatus = async (id: string, status: ICSTask['status']) => {
    try {
      await updateDoc(doc(db, 'ics_tasks', id), { status });
    } catch (error) {
      handleFirestoreError(error, 'update' as any, 'ics_tasks');
    }
  };

  const deleteTask = async (id: string) => {
    if (!window.confirm('Delete this objective?')) return;
    try {
      await deleteDoc(doc(db, 'ics_tasks', id));
    } catch (error) {
      handleFirestoreError(error, 'delete' as any, 'ics_tasks');
    }
  };

  const getPriorityColor = (p: string) => {
    switch (p) {
      case 'Critical': return 'text-red-600 bg-red-50 border-red-100';
      case 'High': return 'text-amber-600 bg-amber-50 border-amber-100';
      case 'Medium': return 'text-blue-600 bg-blue-50 border-blue-100';
      default: return 'text-slate-600 bg-slate-50 border-slate-100';
    }
  };

  const getStatusColor = (s: string) => {
    switch (s) {
      case 'Completed': return 'text-green-600 bg-green-50';
      case 'In Progress': return 'text-blue-600 bg-blue-50';
      case 'Blocked': return 'text-red-600 bg-red-50';
      default: return 'text-slate-400 bg-slate-50';
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row justify-between items-center gap-4">
        <div className="flex items-center gap-3">
          <div className="bg-slate-900 p-2 rounded-lg text-white">
            <Layout size={24} />
          </div>
          <div>
            <h2 className="text-xl font-bold text-slate-900">Incident Command (ICS) Board</h2>
            <p className="text-sm text-slate-500">Real-time tactical objective tracking for Incident Commanders</p>
          </div>
        </div>
        <button 
          onClick={() => setIsAdding(true)}
          className="w-full md:w-auto flex items-center justify-center gap-2 bg-slate-900 text-white px-6 py-3 rounded-xl font-bold hover:bg-slate-800 transition-all shadow-lg"
        >
          <Plus size={20} />
          New Objective
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {['Pending', 'In Progress', 'Blocked', 'Completed'].map(status => (
          <div key={status} className="bg-slate-50/50 rounded-2xl p-4 border border-slate-100 h-fit min-h-[400px]">
            <div className="flex items-center justify-between mb-4 px-2">
              <h3 className="font-bold text-slate-900 flex items-center gap-2">
                <span className={`w-2 h-2 rounded-full ${
                  status === 'Pending' ? 'bg-slate-400' :
                  status === 'In Progress' ? 'bg-blue-500' :
                  status === 'Blocked' ? 'bg-red-500' : 'bg-green-500'
                }`}></span>
                {status}
              </h3>
              <span className="text-xs font-bold text-slate-400 bg-white px-2 py-0.5 rounded-full border border-slate-100">
                {tasks.filter(t => t.status === status).length}
              </span>
            </div>

            <div className="space-y-4">
              {tasks.filter(t => t.status === status).map(task => (
                <div key={task.id} className="bg-white border border-slate-200 rounded-xl p-4 shadow-sm hover:shadow-md transition-all group">
                  <div className="flex justify-between items-start mb-2">
                    <span className={`text-[10px] font-bold uppercase px-2 py-0.5 rounded border ${getPriorityColor(task.priority)}`}>
                      {task.priority}
                    </span>
                    <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                      <button onClick={() => deleteTask(task.id)} className="text-slate-300 hover:text-red-500 p-1">
                        <Trash2 size={14} />
                      </button>
                    </div>
                  </div>
                  <h4 className="text-sm font-bold text-slate-900 mb-3 leading-snug">{task.objective}</h4>
                  <div className="flex flex-col gap-3 pt-3 border-t border-slate-50">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-1.5 text-[10px] text-slate-500 font-bold uppercase">
                        <User size={12} />
                        {task.assignee || 'Unassigned'}
                      </div>
                      <div className="flex items-center gap-1 text-[10px] text-slate-400">
                        <Clock size={12} />
                        {new Date(task.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                      </div>
                    </div>
                    <div className="flex gap-1">
                      {['Pending', 'In Progress', 'Blocked', 'Completed'].filter(s => s !== status).map(s => (
                        <button 
                          key={s}
                          onClick={() => updateStatus(task.id, s as any)}
                          className="flex-1 text-[8px] font-bold uppercase py-1 rounded bg-slate-50 text-slate-400 hover:bg-slate-100 hover:text-slate-600 transition-colors"
                        >
                          {s.split(' ')[0]}
                        </button>
                      ))}
                    </div>
                  </div>
                </div>
              ))}
              {tasks.filter(t => t.status === status).length === 0 && (
                <div className="py-8 text-center text-slate-300 italic text-xs">
                  No tasks here.
                </div>
              )}
            </div>
          </div>
        ))}
      </div>

      {/* Add Task Modal */}
      {isAdding && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex justify-between items-center">
              <h2 className="text-xl font-bold text-slate-900">New Tactical Objective</h2>
              <button onClick={() => setIsAdding(false)} className="text-slate-400 hover:text-slate-600">
                <X size={24} />
              </button>
            </div>
            <form onSubmit={handleAddTask} className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Objective / Task</label>
                <textarea 
                  required
                  value={objective}
                  onChange={(e) => setObjective(e.target.value)}
                  placeholder="e.g., Isolate main gas valve in Sector 4"
                  rows={3}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-slate-900"
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Assignee</label>
                  <input 
                    type="text" 
                    value={assignee}
                    onChange={(e) => setAssignee(e.target.value)}
                    placeholder="e.g., Chief Warden"
                    className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-slate-900"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Priority</label>
                  <select 
                    value={priority}
                    onChange={(e) => setPriority(e.target.value as any)}
                    className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-slate-900"
                  >
                    <option value="Critical">Critical</option>
                    <option value="High">High</option>
                    <option value="Medium">Medium</option>
                    <option value="Low">Low</option>
                  </select>
                </div>
              </div>
              <div className="pt-4 flex justify-end gap-3">
                <button 
                  type="button"
                  onClick={() => setIsAdding(false)}
                  className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
                >
                  Cancel
                </button>
                <button 
                  type="submit"
                  className="px-4 py-2 bg-slate-900 text-white rounded-lg hover:bg-slate-800 transition-colors font-bold"
                >
                  Assign Objective
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
