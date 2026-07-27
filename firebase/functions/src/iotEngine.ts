import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const iotTelemetryIngest = functions.https.onRequest(async (req, res) => {
  try {
    if (req.method !== 'POST') {
      res.status(405).send('Method Not Allowed');
      return;
    }

    const payload = req.body;
    const { deviceId, assetId, customerId, telemetry } = payload;

    if (!deviceId || !telemetry) {
      res.status(400).send('Missing required fields: deviceId, telemetry');
      return;
    }

    const db = admin.firestore();

    if (assetId) {
      // Use set with merge in case the document doesn't exist, though typically it should
      await db.collection('customer_assets').doc(assetId).set({
        last_telemetry_date: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    }

    const temp = telemetry.temperature;
    // Example threshold evaluation (Temperature > 90)
    if (temp !== undefined && temp > 90) {
      const workOrderRef = db.collection('work_orders').doc();
      const newWorkOrder = {
        id: workOrderRef.id,
        title: 'Predictive Maintenance - High Temperature',
        description: `Automated work order triggered by IoT device ${deviceId} due to temperature reading of ${temp}.`,
        status: 'OPEN',
        scheduledDate: new Date().toISOString(),
        assetId: assetId || null,
        customerId: customerId || null
      };
      
      await workOrderRef.set(newWorkOrder);
      console.log(`Created predictive maintenance work order ${workOrderRef.id} for device ${deviceId}`);
    }

    res.status(200).send({ success: true, message: 'Telemetry processed successfully' });
  } catch (error) {
    console.error('Error processing telemetry:', error);
    res.status(500).send('Internal Server Error');
  }
});
