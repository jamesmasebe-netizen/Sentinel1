import * as admin from 'firebase-admin';
import { NotificationService } from '../services/notificationService';

// Initialize Firebase Admin gracefully
try {
  if (!admin.apps.length) {
    // Check if we have credentials, otherwise use a mock or skip initialization
    if (process.env.GOOGLE_APPLICATION_CREDENTIALS || process.env.FIREBASE_CONFIG) {
      admin.initializeApp({
        credential: admin.credential.applicationDefault(),
      });
    } else {
      console.warn("Firebase Admin credentials not found. Admin SDK features will be disabled.");
    }
  }
} catch (error) {
  console.error("Failed to initialize Firebase Admin:", error);
}

export const generateSafetyFlash = async () => {
  if (!admin.apps.length) {
    console.warn("Skipping Safety Flash generation: Firebase Admin not initialized.");
    return;
  }

  const db = admin.firestore();
  const oneWeekAgo = new Date();
  oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);

  // 1. Fetch data from the last week
  const incidentsSnap = await db.collection('incidents').where('createdAt', '>=', oneWeekAgo.toISOString()).get();
  const capasSnap = await db.collection('capas').where('createdAt', '>=', oneWeekAgo.toISOString()).get();
  
  const incidents = incidentsSnap.docs.map(d => d.data());
  const capas = capasSnap.docs.map(d => d.data());

  // 2. Generate summary using Gemini (simulated for now)
  const summary = `
    <h2>Weekly Safety Flash Report</h2>
    <p>Total Incidents: ${incidents.length}</p>
    <p>Total CAPAs: ${capas.length}</p>
    <p>Key Trends: [Gemini analysis would go here]</p>
  `;

  // 3. Send email to safety team
  await NotificationService.sendEmail({
    to: 'safety-team@example.com',
    subject: 'Weekly Safety Flash Report',
    html: summary
  });

  console.log('Safety Flash report generated and sent.');
};
