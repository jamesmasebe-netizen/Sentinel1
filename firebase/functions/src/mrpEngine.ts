import * as functions from 'firebase-functions/v2';
import * as admin from 'firebase-admin';

// Best Practice MRP Engine: 
// Analyzes supply (Inventory) vs demand (Sales Orders)
// Generates "Suggestions" (Draft Purchase Orders or Draft Production Orders)
// instead of blindly creating live vendor obligations.

export const runMrp = functions.https.onCall(async (request) => {
    const { tenantId } = request.data;
    if (!tenantId) {
        throw new functions.https.HttpsError('invalid-argument', 'tenantId is required');
    }

    const db = admin.firestore();
    const tenantRef = db.collection('tenants').doc(tenantId);

    try {
        // 1. Fetch current inventory (Supply)
        const inventorySnap = await tenantRef.collection('inventory_items').get();
        const inventoryMap: { [itemId: string]: number } = {};
        inventorySnap.docs.forEach(doc => {
            const data = doc.data();
            inventoryMap[doc.id] = data.quantityOnHand || 0;
        });

        // 2. Fetch open Sales Orders (Demand)
        const salesOrdersSnap = await tenantRef.collection('sales_orders')
            .where('status', 'in', ['OPEN', 'CONFIRMED'])
            .get();
        
        const demandMap: { [itemId: string]: number } = {};
        salesOrdersSnap.docs.forEach(doc => {
            const data = doc.data();
            const lines = data.lines || [];
            lines.forEach((line: any) => {
                if (line.itemId) {
                    demandMap[line.itemId] = (demandMap[line.itemId] || 0) + (line.quantity || 0);
                }
            });
        });

        // 3. Identify shortages & generate suggestions
        const suggestions: any[] = [];
        const batch = db.batch();

        for (const [itemId, demandQty] of Object.entries(demandMap)) {
            const supplyQty = inventoryMap[itemId] || 0;
            if (demandQty > supplyQty) {
                const shortage = demandQty - supplyQty;
                
                // Create an MRP Suggestion (Draft PO equivalent)
                const suggestionRef = tenantRef.collection('mrp_suggestions').doc();
                const suggestion = {
                    itemId: itemId,
                    suggestedQuantity: shortage,
                    type: 'PURCHASE', // Could be 'PRODUCTION' if it's a manufactured item
                    status: 'DRAFT',
                    reason: 'Sales Order Demand Exceeds Supply',
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                };
                batch.set(suggestionRef, suggestion);
                suggestions.push(suggestion);
            }
        }

        if (suggestions.length > 0) {
            await batch.commit();
        }

        return { success: true, suggestionsGenerated: suggestions.length };

    } catch (error) {
        console.error("MRP Engine Error:", error);
        throw new functions.https.HttpsError('internal', 'MRP Run Failed');
    }
});
