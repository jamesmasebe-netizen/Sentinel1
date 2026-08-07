/**
 * T3-ENGINES — `iotTelemetryIngest` Cloud Function, emulator-backed.
 *
 * Unlike every other Cloud Function tested this session, `iotTelemetryIngest` is an `onRequest`
 * (raw HTTP) handler, not `onCall` — `firebase-functions-test`'s `wrap()` explicitly refuses
 * `onRequest` functions ("Wrap function is only available for `onCall` HTTP functions"). Per
 * Firebase's own documented pattern for testing HTTPS functions, the exported `HttpsFunction` is
 * directly callable as `(req, res)`, so this file invokes it that way with a minimal mock Express
 * response (`status().send()`), against the real Firestore emulator for the device-registry
 * lookup and the multi-collection writes (customer_assets merge, predictive-maintenance work
 * order creation) — a mock can't catch a stale read or a real cross-collection consistency issue,
 * per TEST_STRATEGY.md §5's mock-vs-emulator rule.
 */

process.env.GCLOUD_PROJECT = "ai-studio-applet-webapp-faf6b";
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";

import * as admin from "firebase-admin";
admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT });

import { getFirestore } from "firebase-admin/firestore";
import { iotTelemetryIngest } from "../../src/iotEngine";
import { FIRESTORE_DATABASE_ID } from "../../src/lib/db";

const db = getFirestore(FIRESTORE_DATABASE_ID);

afterAll(async () => {
  await admin.app().delete();
});

function mockRes() {
  const res: any = {};
  res.status = jest.fn().mockReturnValue(res);
  res.send = jest.fn().mockReturnValue(res);
  return res;
}

function mockReq(body: unknown, method = "POST") {
  return { method, body } as any;
}

describe("iotTelemetryIngest — request validation", () => {
  it("rejects a non-POST request with 405", async () => {
    const res = mockRes();
    await iotTelemetryIngest(mockReq({}, "GET"), res);

    expect(res.status).toHaveBeenCalledWith(405);
  });

  it("rejects a request missing deviceId with 400", async () => {
    const res = mockRes();
    await iotTelemetryIngest(mockReq({ telemetry: { temperature: 20 } }), res);

    expect(res.status).toHaveBeenCalledWith(400);
  });

  it("rejects a request missing telemetry with 400", async () => {
    const res = mockRes();
    await iotTelemetryIngest(mockReq({ deviceId: "dev-1" }), res);

    expect(res.status).toHaveBeenCalledWith(400);
  });
});

describe("iotTelemetryIngest — device registry lookup (no tenantId provided)", () => {
  it("returns 404 when the device isn't registered", async () => {
    const res = mockRes();
    await iotTelemetryIngest(
      mockReq({ deviceId: "unregistered-device", telemetry: { temperature: 20 } }),
      res
    );

    expect(res.status).toHaveBeenCalledWith(404);
  });

  it("returns 500 when the registered device has no tenantId mapping", async () => {
    await db.collection("devices").doc("dev-no-tenant").set({});

    const res = mockRes();
    await iotTelemetryIngest(
      mockReq({ deviceId: "dev-no-tenant", telemetry: { temperature: 20 } }),
      res
    );

    expect(res.status).toHaveBeenCalledWith(500);
  });

  it("resolves tenantId from the registry and succeeds", async () => {
    const tenantId = "tenant-iot-registry";
    await db.collection("devices").doc("dev-registered").set({ tenantId });

    const res = mockRes();
    await iotTelemetryIngest(
      mockReq({ deviceId: "dev-registered", telemetry: { temperature: 20 } }),
      res
    );

    expect(res.status).toHaveBeenCalledWith(200);
  });
});

describe("iotTelemetryIngest — trusted-gateway tenantId (registry lookup skipped)", () => {
  it("succeeds using the tenantId provided directly in the payload", async () => {
    const res = mockRes();
    await iotTelemetryIngest(
      mockReq({
        deviceId: "dev-trusted",
        tenantId: "tenant-iot-trusted",
        telemetry: { temperature: 20 },
      }),
      res
    );

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.send).toHaveBeenCalledWith(
      expect.objectContaining({ success: true })
    );
  });
});

describe("iotTelemetryIngest — customer_assets last-telemetry-date update", () => {
  it("merges last_telemetry_date onto the given asset without clobbering existing fields", async () => {
    const tenantId = "tenant-iot-asset";
    await db
      .collection("tenants")
      .doc(tenantId)
      .collection("customer_assets")
      .doc("asset-1")
      .set({ name: "Chiller Unit 1" });

    const res = mockRes();
    await iotTelemetryIngest(
      mockReq({
        deviceId: "dev-asset",
        tenantId,
        assetId: "asset-1",
        telemetry: { temperature: 20 },
      }),
      res
    );

    const assetDoc = await db
      .collection("tenants")
      .doc(tenantId)
      .collection("customer_assets")
      .doc("asset-1")
      .get();
    expect(assetDoc.data()?.name).toBe("Chiller Unit 1"); // preserved, not overwritten
    expect(assetDoc.data()?.last_telemetry_date).toBeInstanceOf(admin.firestore.Timestamp);
  });
});

describe("iotTelemetryIngest — predictive-maintenance work order threshold", () => {
  it("creates a DRAFT/HIGH work order when temperature exceeds 90", async () => {
    const tenantId = "tenant-iot-hot";
    const res = mockRes();
    await iotTelemetryIngest(
      mockReq({
        deviceId: "dev-hot",
        tenantId,
        assetId: "asset-hot",
        customerId: "cust-1",
        telemetry: { temperature: 95 },
      }),
      res
    );

    const workOrders = await db
      .collection("tenants")
      .doc(tenantId)
      .collection("work_orders")
      .get();
    expect(workOrders.size).toBe(1);
    const wo = workOrders.docs[0].data();
    expect(wo.status).toBe("DRAFT");
    expect(wo.priority).toBe("HIGH");
    expect(wo.asset_id).toBe("asset-hot");
    expect(wo.customer_id).toBe("cust-1");
    expect(wo.description).toContain("dev-hot");
    expect(wo.description).toContain("95");
  });

  it("defaults customer_id to INTERNAL when none is provided", async () => {
    const tenantId = "tenant-iot-hot-internal";
    const res = mockRes();
    await iotTelemetryIngest(
      mockReq({
        deviceId: "dev-hot-2",
        tenantId,
        telemetry: { temperature: 95 },
      }),
      res
    );

    const workOrders = await db
      .collection("tenants")
      .doc(tenantId)
      .collection("work_orders")
      .get();
    expect(workOrders.docs[0].data().customer_id).toBe("INTERNAL");
    expect(workOrders.docs[0].data().asset_id).toBeNull();
  });

  it("does NOT create a work order when temperature is at or below 90", async () => {
    const tenantId = "tenant-iot-normal";
    const res = mockRes();
    await iotTelemetryIngest(
      mockReq({ deviceId: "dev-normal", tenantId, telemetry: { temperature: 90 } }),
      res
    );

    const workOrders = await db
      .collection("tenants")
      .doc(tenantId)
      .collection("work_orders")
      .get();
    expect(workOrders.empty).toBe(true);
  });

  it("does not error when temperature is absent from the telemetry payload", async () => {
    const tenantId = "tenant-iot-no-temp";
    const res = mockRes();
    await iotTelemetryIngest(
      mockReq({ deviceId: "dev-no-temp", tenantId, telemetry: { humidity: 40 } }),
      res
    );

    expect(res.status).toHaveBeenCalledWith(200);
  });
});
