import React, { useState, useEffect } from 'react';
import { AlertTriangle, CheckCircle, Clock, Activity, ArrowUpRight } from 'lucide-react';
import { collection, query, where, onSnapshot, orderBy, limit } from 'firebase/firestore';
import { db } from '../lib/firebase';
import { useAuth } from '../contexts/AuthContext';
import { useNavigate } from 'react-router-dom';
import SiteMap from '../components/SiteMap';
import { NotificationService } from '../services/notificationService';
import { Bell } from 'lucide-react';
import ExecutiveBentoDashboard from './ExecutiveBentoDashboard';

export default function Dashboard() {
  const { profile } = useAuth();
  const navigate = useNavigate();
  const [incidents, setIncidents] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [pushEnabled, setPushEnabled] = useState(false);

  useEffect(() => {
    if ('Notification' in window) {
      setPushEnabled(Notification.permission === 'granted');
    }
  }, []);

  const handleEnablePush = async () => {
    const success = await NotificationService.requestPushPermission();
    if (success) {
      setPushEnabled(true);
      alert('Push notifications enabled!');
    } else {
      alert('Failed to enable push notifications. Please check browser settings.');
    }
  };

  useEffect(() => {
    if (!profile?.siteId) return;

    const q = query(
      collection(db, 'incidents'),
      where('siteId', '==', profile.siteId),
      orderBy('createdAt', 'desc'),
      limit(5)
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      setIncidents(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
      setLoading(false);
    });

    return () => unsubscribe();
  }, [profile?.siteId]);

  // If Executive/Admin, show the new Bento Dashboard instead
  if (profile?.role === 'admin' || profile?.role === 'executive') {
    return <ExecutiveBentoDashboard />;
  }

  const stats = [
    { name: 'LTIFR', value: '0.45', icon: Activity, color: 'text-green-600', bg: 'bg-green-100' },
    { name: 'Open Incidents', value: incidents.length, icon: AlertTriangle, color: 'text-amber-600', bg: 'bg-amber-100' },
    { name: 'Pending Maintenance', value: '8', icon: Clock, color: 'text-blue-600', bg: 'bg-blue-100' },
    { name: 'Compliance Score', value: '94%', icon: CheckCircle, color: 'text-emerald-600', bg: 'bg-emerald-100' },
  ];

  const incidentLocations = incidents
    .filter(inc => inc.location && inc.location.includes(','))
    .map(inc => {
      const [lat, lng] = inc.location.split(',').map(Number);
      return {
        lat,
        lng,
        name: inc.title,
        status: (inc.severity === 'Critical' || inc.severity === 'Major' ? 'Red' : inc.severity === 'Moderate' ? 'Amber' : 'Green') as 'Red' | 'Amber' | 'Green'
      };
    });

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 tracking-tight">Dashboard</h1>
          <p className="text-gray-500 font-medium">Real-time analytics for {profile?.siteId || 'your site'}.</p>
        </div>
        <div className="flex items-center gap-3">
          {!pushEnabled && (
            <button 
              onClick={handleEnablePush}
              className="flex items-center gap-2 px-4 py-2 bg-slate-100 text-slate-700 rounded-lg text-sm font-bold hover:bg-slate-200 transition-colors"
            >
              <Bell size={16} /> Enable Notifications
            </button>
          )}
      </div>
    </div>

    <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
        {stats.map((item) => (
          <div key={item.name} className="bg-white overflow-hidden shadow-sm rounded-xl border border-gray-100 hover:border-blue-200 transition-colors">
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <div className={`p-3 rounded-lg ${item.bg}`}>
                    <item.icon className={`h-6 w-6 ${item.color}`} aria-hidden="true" />
                  </div>
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-semibold text-gray-500 truncate">{item.name}</dt>
                    <dd>
                      <div className="text-2xl font-black text-gray-900">{item.value}</div>
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white shadow-sm rounded-xl border border-gray-100 p-6">
          <h2 className="text-lg font-bold text-gray-900 mb-4">Site Map</h2>
          <div className="h-[300px] relative rounded-xl overflow-hidden">
            <SiteMap locations={incidentLocations} />
          </div>
        </div>

        <div className="bg-white shadow-sm rounded-xl border border-gray-100 p-6">
          <h2 className="text-lg font-bold text-gray-900 mb-4">Action Center</h2>
          <div className="space-y-4">
            {[
              { title: 'Sign off on SOP: Working at Heights', type: 'Document', urgent: true },
              { title: 'Complete daily site inspection', type: 'Task', urgent: false },
              { title: 'Review Incident Report #INC-2026-042', type: 'Review', urgent: true },
            ].map((action, i) => (
              <div key={i} className="flex items-center justify-between p-4 bg-gray-50 rounded-xl border border-gray-100 hover:border-blue-100 transition-colors cursor-pointer">
                <div>
                  <p className="text-sm font-bold text-gray-900">{action.title}</p>
                  <p className="text-xs text-gray-500 font-medium">{action.type}</p>
                </div>
                <button className={`px-3 py-1 text-xs font-bold rounded-full ${
                  action.urgent ? 'bg-red-100 text-red-700' : 'bg-blue-100 text-blue-700'
                }`}>
                  {action.urgent ? 'Urgent' : 'Pending'}
                </button>
              </div>
            ))}
          </div>
        </div>

        <div className="bg-white shadow-sm rounded-xl border border-gray-100 p-6">
          <h2 className="text-lg font-bold text-gray-900 mb-4">Recent Incidents</h2>
          <div className="space-y-4">
            {incidents.length > 0 ? (
              incidents.map((incident) => (
                <div key={incident.id} className="flex items-center justify-between p-4 bg-gray-50 rounded-xl border border-gray-100">
                  <div>
                    <p className="text-sm font-bold text-gray-900">{incident.title}</p>
                    <p className="text-xs text-gray-500 font-medium">{incident.type} • {incident.severity}</p>
                  </div>
                  <span className={`px-2 py-1 text-[10px] font-black uppercase rounded-md ${
                    incident.status === 'Open' ? 'bg-red-100 text-red-700' : 'bg-green-100 text-green-700'
                  }`}>
                    {incident.status}
                  </span>
                </div>
              ))
            ) : (
              <div className="text-center py-8 text-gray-500">
                <AlertTriangle className="mx-auto h-8 w-8 text-gray-400 mb-2" />
                <p className="font-medium">No recent incidents reported.</p>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
