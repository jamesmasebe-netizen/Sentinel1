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
    let { tenantId } = payload; // Can be provided by trusted gateway

    if (!deviceId || !telemetry) {
      res.status(400).send('Missing required fields: deviceId, telemetry');
      return;
    }

    const db = admin.firestore();

    // Option A: Trusted Gateway / JWT enriched tenantId
    // Option B: Central Registry Lookup (Best Practice for raw device telemetry)
    if (!tenantId) {
      const deviceDoc = await db.collection('devices').doc(deviceId).get();
      if (!deviceDoc.exists) {
        res.status(404).send('Device not found in registry');
        return;
      }
      tenantId = deviceDoc.data()?.tenantId;
      if (!tenantId) {
        res.status(500).send('Device registry missing tenant mapping');
        return;
      }
    }

    if (assetId) {
      // Use set with merge in case the document doesn't exist, though typically it should
      await db.collection('tenants').doc(tenantId).collection('customer_assets').doc(assetId).set({
        last_telemetry_date: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    }

    const temp = telemetry.temperature;
    // Example threshold evaluation (Temperature > 90)
    if (temp !== undefined && temp > 90) {
      const workOrderRef = db.collection('tenants').doc(tenantId).collection('work_orders').doc();
      const newWorkOrder = {
        id: workOrderRef.id,
        work_order_number: workOrderRef.id,
        description: `Predictive Maintenance - High Temperature\nAutomated work order triggered by IoT device ${deviceId} due to temperature reading of ${temp}.`,
        status: 'DRAFT',
        priority: 'HIGH',
        scheduling: {
          scheduled_start: admin.firestore.FieldValue.serverTimestamp(),
        },
        asset_id: assetId || null,
        customer_id: customerId || 'INTERNAL',
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
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
