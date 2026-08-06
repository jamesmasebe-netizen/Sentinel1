/**
 * T2-003 — `runMrp` Cloud Function, emulator-backed portion.
 *
 * Invokes the REAL `runMrp` handler (via `firebase-functions-test`'s `wrap()`) against the
 * Firestore emulator: real reads of `inventory_items`/`sales_orders`/`so_lines`, a real
 * `db.batch()` write into `mrp_suggestions`. Field names are checked exactly against
 * `InventoryItem`/`SalesOrder`/`SalesOrderLine`/`MrpSuggestion` in
 * lib/features/supply_chain/models/scm_models.dart, per TEST_STRATEGY.md §5. The
 * precondition-only validation path is covered without the emulator in src/mrpEngine.test.ts.
 *
 * REAL BUG FOUND while first writing these tests, FIXED 2026-08-06: `runMrp` used to compute
 * demand by reading a `lines` array directly off each `sales_orders` document, but `SalesOrder`
 * has no such field — there was no `SalesOrderLine` model or `so_lines` subcollection anywhere.
 * `demandMap` was always empty for every real order, so `runMrp` could never generate a real
 * suggestion in production. Fixed by adding `SalesOrderLine`/`so_lines` CRUD to `ScmService`
 * (mirroring the existing `PurchaseOrderLine`/`po_lines` pattern exactly) and a matching
 * `firestore.rules` nested rule, then pointing `runMrp`'s demand computation at each order's real
 * `so_lines` subcollection (`item_id`/`quantity`, snake_case per `SalesOrderLine.toJson()`)
 * instead of the nonexistent `data.lines`. The first test below is the regression guard: it seeds
 * data through the exact real shape (`so_lines` documents, not an embedded array) and proves a
 * real shortage is now correctly detected. A UI to actually create sales-order line items through
 * the app doesn't exist yet (mirrors `docs/fixes/FIX_LIST.md` F-202's shape for PO lines, before
 * that fix) — that remains a separate, larger follow-up; this fix makes the backend/Cloud
 * Function correct and ready for that UI once built.
 */

process.env.GCLOUD_PROJECT = "ai-studio-applet-webapp-faf6b";
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";

import * as admin from "firebase-admin";
admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT });

import { getFirestore } from "firebase-admin/firestore";
import firebaseFunctionsTest from "firebase-functions-test";
import type { CallableRequest } from "firebase-functions/v2/https";
import { runMrp } from "../../src/mrpEngine";
import { FIRESTORE_DATABASE_ID } from "../../src/lib/db";

const { wrap } = firebaseFunctionsTest();
const wrapped = wrap(runMrp);
const db = getFirestore(FIRESTORE_DATABASE_ID);

function buildRequest(data: unknown): CallableRequest {
  const req = {
    data,
    auth: { uid: "test-user-1", token: {} },
    rawRequest: {},
    acceptsStreaming: false,
  };
  return req as unknown as CallableRequest;
}

async function seedInventoryItem(tenantId: string, itemId: string, stockLevel: number) {
  await db
    .collection("tenants")
    .doc(tenantId)
    .collection("inventory_items")
    .doc(itemId)
    .set({ stock_level: stockLevel, name: itemId });
}

async function seedSalesOrder(tenantId: string, orderId: string, data: Record<string, unknown>) {
  await db.collection("tenants").doc(tenantId).collection("sales_orders").doc(orderId).set(data);
}

/** Seeds a real `so_lines` subcollection doc — the shape `ScmService.createSalesOrderLine()` /
 *  `SalesOrderLine.toJson()` actually write (snake_case `item_id`/`quantity`/`unit_price`), not
 *  an embedded array on the order document itself. */
async function seedSalesOrderLine(
  tenantId: string,
  orderId: string,
  lineId: string,
  itemId: string,
  quantity: number
) {
  await db
    .collection("tenants")
    .doc(tenantId)
    .collection("sales_orders")
    .doc(orderId)
    .collection("so_lines")
    .doc(lineId)
    .set({ item_id: itemId, quantity, unit_price: 0 });
}

afterAll(async () => {
  await admin.app().delete();
});

describe("runMrp — emulator-backed reads/batch write (T2-003)", () => {
  it("REGRESSION: order with no so_lines subcollection contributes zero demand (an order can legitimately have no lines yet)", async () => {
    const tenantId = "tenant-mrp-real-shape-gap";
    await seedInventoryItem(tenantId, "item-widget", 0);
    // Exactly what SalesOrder.toJson() produces — a header with no lines subcollection seeded.
    await seedSalesOrder(tenantId, "so-1", {
      order_number: "SO-1001",
      account_id: "acct-1",
      status: "OPEN",
      order_date: null,
      total_amount: 500,
    });

    const result = (await wrapped(buildRequest({ tenantId }))) as {
      success: boolean;
      suggestionsGenerated: number;
    };

    expect(result.success).toBe(true);
    expect(result.suggestionsGenerated).toBe(0);

    const suggestions = await db
      .collection("tenants")
      .doc(tenantId)
      .collection("mrp_suggestions")
      .get();
    expect(suggestions.empty).toBe(true);
  });

  it("generates a correctly-shaped suggestion when demand from a real so_lines subcollection exceeds supply", async () => {
    const tenantId = "tenant-mrp-shortage";
    await seedInventoryItem(tenantId, "item-bolt", 10);
    await seedSalesOrder(tenantId, "so-2", { status: "OPEN" });
    await seedSalesOrderLine(tenantId, "so-2", "line-1", "item-bolt", 30);

    const result = (await wrapped(buildRequest({ tenantId }))) as {
      success: boolean;
      suggestionsGenerated: number;
    };
    expect(result.success).toBe(true);
    expect(result.suggestionsGenerated).toBe(1);

    const suggestions = await db
      .collection("tenants")
      .doc(tenantId)
      .collection("mrp_suggestions")
      .get();
    expect(suggestions.size).toBe(1);
    const suggestion = suggestions.docs[0].data();

    // Exact field-shape check against MrpSuggestion.fromJson (scm_models.dart:557-566) — it
    // reads itemId/suggestedQuantity/type/status/reason. createdAt is written but not modeled
    // (harmless extra field, not a mismatch).
    expect(Object.keys(suggestion).sort()).toEqual(
      ["itemId", "suggestedQuantity", "type", "status", "reason", "createdAt"].sort()
    );
    expect(suggestion.itemId).toBe("item-bolt");
    expect(suggestion.suggestedQuantity).toBe(20); // 30 demand - 10 supply
    expect(suggestion.type).toBe("PURCHASE");
    expect(suggestion.status).toBe("DRAFT");
    expect(suggestion.reason).toBe("Sales Order Demand Exceeds Supply");
    expect(suggestion.createdAt).toBeInstanceOf(admin.firestore.Timestamp);
  });

  it("does not generate a suggestion when supply already covers demand", async () => {
    const tenantId = "tenant-mrp-sufficient-supply";
    await seedInventoryItem(tenantId, "item-nut", 100);
    await seedSalesOrder(tenantId, "so-3", { status: "CONFIRMED" });
    await seedSalesOrderLine(tenantId, "so-3", "line-1", "item-nut", 40);

    const result = (await wrapped(buildRequest({ tenantId }))) as {
      suggestionsGenerated: number;
    };
    expect(result.suggestionsGenerated).toBe(0);
  });

  it("aggregates demand for the same item across multiple open orders (and multiple lines) before comparing to supply", async () => {
    const tenantId = "tenant-mrp-aggregate-demand";
    await seedInventoryItem(tenantId, "item-panel", 15);
    await seedSalesOrder(tenantId, "so-4a", { status: "OPEN" });
    await seedSalesOrderLine(tenantId, "so-4a", "line-1", "item-panel", 10);
    await seedSalesOrder(tenantId, "so-4b", { status: "CONFIRMED" });
    await seedSalesOrderLine(tenantId, "so-4b", "line-1", "item-panel", 12);

    const result = (await wrapped(buildRequest({ tenantId }))) as {
      suggestionsGenerated: number;
    };
    expect(result.suggestionsGenerated).toBe(1);

    const suggestions = await db
      .collection("tenants")
      .doc(tenantId)
      .collection("mrp_suggestions")
      .get();
    // Aggregate demand = 22, supply = 15, shortage = 7.
    expect(suggestions.docs[0].data().suggestedQuantity).toBe(7);
  });

  it("ignores sales orders whose status is not OPEN or CONFIRMED", async () => {
    const tenantId = "tenant-mrp-status-filter";
    await seedInventoryItem(tenantId, "item-cancelled-demand", 0);
    await seedSalesOrder(tenantId, "so-5", { status: "CANCELLED" });
    await seedSalesOrderLine(tenantId, "so-5", "line-1", "item-cancelled-demand", 999);

    const result = (await wrapped(buildRequest({ tenantId }))) as {
      suggestionsGenerated: number;
    };
    expect(result.suggestionsGenerated).toBe(0);
  });
});
