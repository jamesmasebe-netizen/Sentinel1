import * as functions from 'firebase-functions/v2';
import * as admin from 'firebase-admin';
import { getDb } from './lib/db';

// Best Practice MRP Engine:
// Analyzes supply (Inventory) vs demand (Sales Orders)
// Generates "Suggestions" (Draft Purchase Orders or Draft Production Orders)
// instead of blindly creating live vendor obligations.

export const runMrp = functions.https.onCall(async (request) => {
    const { tenantId } = request.data;
    if (!tenantId) {
        throw new functions.https.HttpsError('invalid-argument', 'tenantId is required');
    }

    const db = getDb();
    const tenantRef = db.collection('tenants').doc(tenantId);

    try {
        // 1. Fetch current inventory (Supply)
        const inventorySnap = await tenantRef.collection('inventory_items').get();
        const inventoryMap: { [itemId: string]: number } = {};
        // Manufactured items (assembled in-house from a BOM) get a Production suggestion
        // instead of a Purchase one — see the type assignment below. item_type is the same
        // field InventoryItemForm's dropdown writes (RAW_MATERIAL/COMPONENT/SUB_ASSEMBLY/
        // FINISHED_GOOD/CONSUMABLE/ASSET); FINISHED_GOOD/SUB_ASSEMBLY are the ones actually
        // built, not bought.
        const manufacturedTypes = new Set(['FINISHED_GOOD', 'SUB_ASSEMBLY']);
        const itemTypeMap: { [itemId: string]: string } = {};
        inventorySnap.docs.forEach(doc => {
            const data = doc.data();
            // F-201: was data.quantityOnHand, a key the Dart client never writes.
            // stock_level is what InventoryItem/ScmService actually persist.
            inventoryMap[doc.id] = data.stock_level || 0;
            itemTypeMap[doc.id] = data.item_type || '';
        });

        // 2. Fetch open Sales Orders (Demand)
        const salesOrdersSnap = await tenantRef.collection('sales_orders')
            .where('status', 'in', ['OPEN', 'CONFIRMED'])
            .get();

        // Demand lives in each order's own `so_lines` subcollection (see
        // ScmService.createSalesOrderLine / SalesOrderLine in scm_models.dart) — a
        // SalesOrder document itself has no `lines` field. Fetched per-order rather than
        // via a collectionGroup query so results stay scoped to exactly the
        // already-tenant-and-status-filtered orders above, with no extra filtering needed.
        const demandMap: { [itemId: string]: number } = {};
        const lineSnaps = await Promise.all(
            salesOrdersSnap.docs.map(doc => doc.ref.collection('so_lines').get())
        );
        lineSnaps.forEach(linesSnap => {
            linesSnap.docs.forEach(lineDoc => {
                const line = lineDoc.data();
                if (line.item_id) {
                    demandMap[line.item_id] = (demandMap[line.item_id] || 0) + (line.quantity || 0);
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
                
                // Create an MRP Suggestion (Draft PO/Production Order equivalent)
                const suggestionRef = tenantRef.collection('mrp_suggestions').doc();
                const suggestion = {
                    itemId: itemId,
                    suggestedQuantity: shortage,
                    type: manufacturedTypes.has(itemTypeMap[itemId]) ? 'PRODUCTION' : 'PURCHASE',
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
