/// <reference types="vite/client" />
import { collection, query, where, getDocs, addDoc, serverTimestamp, Timestamp } from 'firebase/firestore';
import { db } from '../lib/firebase';

export interface EmailPayload {
  to: string;
  subject: string;
  text?: string;
  html?: string;
}

export interface Notification {
  id?: string;
  userId: string;
  title: string;
  message: string;
  type: 'expiry' | 'system' | 'alert';
  status: 'unread' | 'read';
  link?: string;
  createdAt: any;
}

export const NotificationService = {
  async sendEmail(payload: EmailPayload) {
    try {
      const response = await fetch('/api/notifications/send-email', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });
      return await response.json();
    } catch (error) {
      console.error('Failed to send email:', error);
      return { success: false, error };
    }
  },

  async requestPushPermission() {
    if (!('Notification' in window)) {
      console.log('This browser does not support notifications');
      return false;
    }

    const permission = await Notification.requestPermission();
    if (permission === 'granted') {
      return await this.subscribeToPush();
    }
    return false;
  },

  async subscribeToPush() {
    try {
      const registration = await navigator.serviceWorker.ready;
      const publicVapidKey = import.meta.env.VITE_VAPID_PUBLIC_KEY;

      if (!publicVapidKey) {
        console.warn('VAPID public key not found in environment');
        return false;
      }

      const subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: this.urlBase64ToUint8Array(publicVapidKey),
      });

      await fetch('/api/notifications/subscribe', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(subscription),
      });

      return subscription;
    } catch (error) {
      console.error('Failed to subscribe to push:', error);
      return false;
    }
  },

  urlBase64ToUint8Array(base64String: string) {
    const padding = '='.repeat((4 - (base64String.length % 4)) % 4);
    const base64 = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/');
    const rawData = window.atob(base64);
    const outputArray = new Uint8Array(rawData.length);
    for (let i = 0; i < rawData.length; ++i) {
      outputArray[i] = rawData.charCodeAt(i);
    }
    return outputArray;
  },

  async notifyIncidentCreated(incident: any, recipientEmail?: string) {
    const subject = `New Incident Reported: ${incident.title}`;
    const html = `
      <h2>New Incident Alert</h2>
      <p><strong>Title:</strong> ${incident.title}</p>
      <p><strong>Type:</strong> ${incident.type}</p>
      <p><strong>Severity:</strong> ${incident.severity}</p>
      <p><strong>Location:</strong> ${incident.location}</p>
      <p><strong>Reported By:</strong> ${incident.reportedBy}</p>
      <hr />
      <p>Please log in to the Safety Platform to review this incident.</p>
    `;

    if (recipientEmail) {
      await this.sendEmail({ to: recipientEmail, subject, html });
    }
  },

  async notifyCAPAAssigned(capa: any, recipientEmail: string) {
    const subject = `New CAPA Assigned: ${capa.title}`;
    const html = `
      <h2>CAPA Assignment Alert</h2>
      <p>A new Corrective and Preventive Action has been assigned to you.</p>
      <p><strong>Title:</strong> ${capa.title}</p>
      <p><strong>Due Date:</strong> ${capa.dueDate}</p>
      <p><strong>Priority:</strong> ${capa.priority}</p>
      <hr />
      <p>Please log in to the Safety Platform to complete this action.</p>
    `;

    await this.sendEmail({ to: recipientEmail, subject, html });
  }
};

export const checkAndGenerateExpiries = async (userId: string) => {
  const now = new Date();
  const thirtyDaysFromNow = new Date();
  thirtyDaysFromNow.setDate(now.getDate() + 30);

  const notifications: Omit<Notification, 'id'>[] = [];

  // 1. Check Contractor Documents
  const contractorsSnap = await getDocs(collection(db, 'contractors'));
  for (const contractorDoc of contractorsSnap.docs) {
    const contractor = contractorDoc.data();
    const docsSnap = await getDocs(collection(db, `contractors/${contractorDoc.id}/documents`));
    
    for (const doc of docsSnap.docs) {
      const docData = doc.data();
      if (docData.expiryDate && docData.status === 'Approved') {
        const expiry = new Date(docData.expiryDate);
        if (expiry <= thirtyDaysFromNow && expiry > now) {
          notifications.push({
            userId,
            title: 'Document Expiring Soon',
            message: `The ${docData.type} for ${contractor.companyName} expires on ${expiry.toLocaleDateString()}.`,
            type: 'expiry',
            status: 'unread',
            link: '/contractors',
            createdAt: serverTimestamp()
          });
        } else if (expiry <= now) {
          notifications.push({
            userId,
            title: 'Document Expired',
            message: `The ${docData.type} for ${contractor.companyName} has EXPIRED.`,
            type: 'alert',
            status: 'unread',
            link: '/contractors',
            createdAt: serverTimestamp()
          });
        }
      }
    }

    // 2. Check Worker Documents
    const workersSnap = await getDocs(collection(db, `contractors/${contractorDoc.id}/workers`));
    for (const workerDoc of workersSnap.docs) {
      const worker = workerDoc.data();
      const workerDocsSnap = await getDocs(collection(db, `contractors/${contractorDoc.id}/workers/${workerDoc.id}/documents`));
      
      for (const wDoc of workerDocsSnap.docs) {
        const wDocData = wDoc.data();
        if (wDocData.expiryDate && wDocData.status === 'Approved') {
          const expiry = new Date(wDocData.expiryDate);
          if (expiry <= thirtyDaysFromNow && expiry > now) {
            notifications.push({
              userId,
              title: 'Worker Document Expiring',
              message: `${worker.firstName} ${worker.lastName}'s ${wDocData.type} expires on ${expiry.toLocaleDateString()}.`,
              type: 'expiry',
              status: 'unread',
              link: '/contractors',
              createdAt: serverTimestamp()
            });
          } else if (expiry <= now) {
            notifications.push({
              userId,
              title: 'Worker Document Expired',
              message: `${worker.firstName} ${worker.lastName}'s ${wDocData.type} has EXPIRED.`,
              type: 'alert',
              status: 'unread',
              link: '/contractors',
              createdAt: serverTimestamp()
            });
          }
        }
      }
    }
  }

  // 3. Check Permits (PTW)
  const permitsSnap = await getDocs(query(collection(db, 'permits'), where('status', '==', 'Active')));
  for (const permitDoc of permitsSnap.docs) {
    const permit = permitDoc.data();
    if (permit.expiryDate) {
      const expiry = new Date(permit.expiryDate);
      if (expiry <= now) {
        notifications.push({
          userId,
          title: 'Permit Expired',
          message: `Permit #${permit.permitNumber} (${permit.type}) has expired.`,
          type: 'alert',
          status: 'unread',
          link: '/ptw',
          createdAt: serverTimestamp()
        });
      }
    }
  }

  // Deduplicate and Save Notifications
  // In a real app, we'd check if a notification for this specific expiry already exists
  // For this demo, we'll just add them if they are unique in this run
  const existingNotifsSnap = await getDocs(query(collection(db, 'notifications'), where('userId', '==', userId), where('status', '==', 'unread')));
  const existingMessages = existingNotifsSnap.docs.map(d => d.data().message);

  for (const notif of notifications) {
    if (!existingMessages.includes(notif.message)) {
      await addDoc(collection(db, 'notifications'), notif);
    }
  }

  return notifications.length;
};
