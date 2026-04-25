import React, { useState, useEffect } from 'react';
import { collection, query, where, onSnapshot, orderBy, updateDoc, doc, deleteDoc, limit } from 'firebase/firestore';
import { db, handleFirestoreError, OperationType } from '../lib/firebase';
import { useAuth } from '../contexts/AuthContext';
import { Bell, X, Check, Trash2, ExternalLink, AlertTriangle, Clock, Info } from 'lucide-react';
import { checkAndGenerateExpiries } from '../services/notificationService';

export default function NotificationCenter() {
  const { user } = useAuth();
  const [notifications, setNotifications] = useState<any[]>([]);
  const [isOpen, setIsOpen] = useState(false);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!user) return;

    const q = query(
      collection(db, 'notifications'),
      where('userId', '==', user.uid),
      orderBy('createdAt', 'desc'),
      limit(20)
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data: any[] = [];
      snapshot.forEach((doc) => {
        data.push({ id: doc.id, ...doc.data() });
      });
      setNotifications(data);
    }, (error) => handleFirestoreError(error, OperationType.LIST, 'notifications'));

    return () => unsubscribe();
  }, [user]);

  const handleMarkAsRead = async (id: string) => {
    try {
      await updateDoc(doc(db, 'notifications', id), { status: 'read' });
    } catch (error) {
      handleFirestoreError(error, OperationType.UPDATE, `notifications/${id}`);
    }
  };

  const handleDelete = async (id: string) => {
    try {
      await deleteDoc(doc(db, 'notifications', id));
    } catch (error) {
      handleFirestoreError(error, OperationType.DELETE, `notifications/${id}`);
    }
  };

  const handleCheckExpiries = async () => {
    if (!user) return;
    setLoading(true);
    try {
      await checkAndGenerateExpiries(user.uid);
    } catch (error) {
      console.error("Error checking expiries", error);
    } finally {
      setLoading(false);
    }
  };

  const unreadCount = notifications.filter(n => n.status === 'unread').length;

  const getIcon = (type: string) => {
    switch (type) {
      case 'alert': return <AlertTriangle className="text-red-500" size={18} />;
      case 'expiry': return <Clock className="text-amber-500" size={18} />;
      default: return <Info className="text-blue-500" size={18} />;
    }
  };

  return (
    <div className="relative">
      <button 
        onClick={() => setIsOpen(!isOpen)}
        className="relative p-2 text-slate-300 hover:text-white hover:bg-slate-800 rounded-full transition-colors"
      >
        <Bell size={20} />
        {unreadCount > 0 && (
          <span className="absolute top-0 right-0 bg-red-600 text-white text-[10px] font-bold px-1.5 py-0.5 rounded-full border-2 border-slate-900">
            {unreadCount}
          </span>
        )}
      </button>

      {isOpen && (
        <div className="absolute right-0 mt-2 w-80 sm:w-96 bg-white rounded-xl shadow-2xl border border-gray-200 z-[100] overflow-hidden">
          <div className="p-4 border-b border-gray-100 flex justify-between items-center bg-gray-50">
            <h3 className="font-bold text-gray-900 flex items-center gap-2">
              <Bell size={18} className="text-blue-600" /> Notifications
            </h3>
            <div className="flex items-center gap-2">
              <button 
                onClick={handleCheckExpiries}
                disabled={loading}
                className="text-xs text-blue-600 hover:text-blue-800 font-medium disabled:opacity-50"
              >
                {loading ? 'Checking...' : 'Check Expiries'}
              </button>
              <button onClick={() => setIsOpen(false)} className="text-gray-400 hover:text-gray-600">
                <X size={20} />
              </button>
            </div>
          </div>

          <div className="max-h-[400px] overflow-y-auto">
            {notifications.length === 0 ? (
              <div className="p-8 text-center text-gray-500">
                <Bell size={32} className="mx-auto mb-2 text-gray-200" />
                <p>No notifications yet</p>
              </div>
            ) : (
              <div className="divide-y divide-gray-100">
                {notifications.map((notif) => (
                  <div key={notif.id} className={`p-4 hover:bg-gray-50 transition-colors ${notif.status === 'unread' ? 'bg-blue-50/30' : ''}`}>
                    <div className="flex gap-3">
                      <div className="mt-1">{getIcon(notif.type)}</div>
                      <div className="flex-1">
                        <div className="flex justify-between items-start">
                          <h4 className={`text-sm font-bold ${notif.status === 'unread' ? 'text-gray-900' : 'text-gray-600'}`}>
                            {notif.title}
                          </h4>
                          <span className="text-[10px] text-gray-400 whitespace-nowrap">
                            {notif.createdAt?.toDate().toLocaleDateString()}
                          </span>
                        </div>
                        <p className="text-xs text-gray-600 mt-1 leading-relaxed">
                          {notif.message}
                        </p>
                        <div className="flex justify-between items-center mt-3">
                          <div className="flex gap-2">
                            {notif.status === 'unread' && (
                              <button 
                                onClick={() => handleMarkAsRead(notif.id)}
                                className="text-[10px] flex items-center gap-1 bg-white border border-gray-200 px-2 py-1 rounded hover:bg-gray-50 text-gray-600"
                              >
                                <Check size={10} /> Mark read
                              </button>
                            )}
                            <button 
                              onClick={() => handleDelete(notif.id)}
                              className="text-[10px] flex items-center gap-1 bg-white border border-gray-200 px-2 py-1 rounded hover:bg-red-50 hover:text-red-600 text-gray-600"
                            >
                              <Trash2 size={10} /> Delete
                            </button>
                          </div>
                          {notif.link && (
                            <a 
                              href={notif.link}
                              className="text-[10px] text-blue-600 hover:underline flex items-center gap-1"
                            >
                              View <ExternalLink size={10} />
                            </a>
                          )}
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
          
          {notifications.length > 0 && (
            <div className="p-3 bg-gray-50 border-t border-gray-100 text-center">
              <button className="text-xs text-gray-500 hover:text-gray-700 font-medium">
                View all notifications
              </button>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
