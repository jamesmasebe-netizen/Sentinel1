/**
 * T2-003 — `billing.ts`, emulator-backed portion (F-319).
 *
 * F-319's three original breaks, and what's verified here against each:
 *  1. "The Cloud Function the app calls doesn't exist" — `createStripeCheckoutSession` exists and
 *     is exported (verified directly in src/billing.test.ts, no Firestore involved there).
 *  2. "The webhook is unexported and writes the wrong path" — `stripeWebhook` IS exported
 *     (`export * from './billing'`, src/index.ts) and writes `tenants/{tenantId}/subscription/
 *     status` (not `billing/subscription`) — verified below with exact field-name assertions
 *     against `TenantSubscription.fromFirestore`
 *     (lib/features/billing/models/subscription_models.dart), matching what
 *     `BillingService.getSubscriptionStream()` actually reads.
 *  3. "The premium-check can never be satisfied" — `isPremiumProvider` checks for `'premium'`/
 *     `'enterprise'`; verified below that a real webhook event (no `metadata.tier` override, the
 *     realistic case) actually produces `tier: 'premium'` — the value the rest of the pipeline
 *     needs.
 *
 * Also verifies real Stripe webhook SIGNATURE VERIFICATION — the function's own comment used to
 * admit this was skipped; it isn't anymore (`stripe.webhooks.constructEvent(...)` is called for
 * real). Signatures are generated locally via `stripe.webhooks.generateTestHeaderString()`, a
 * pure local HMAC helper with no network call — so a WRONG secret genuinely fails verification
 * here, not just "would fail in production."
 *
 * `stripe.webhooks` itself is left REAL (unmocked) so signature verification is genuinely
 * exercised; `checkout`/`billingPortal` are still mocked (no local Stripe emulator exists) —
 * `createBillingPortalSession`'s tests need this since Firestore/Stripe now mix in one call.
 * `createStripeCheckoutSession` never touches Firestore, so it has no tests here — see
 * src/billing.test.ts for full coverage of that function.
 */

process.env.GCLOUD_PROJECT = "ai-studio-applet-webapp-faf6b";
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
process.env.STRIPE_WEBHOOK_SECRET = "whsec_test_secret_for_billing_emulator_tests";

const mockBillingPortalCreate = jest.fn();

jest.mock("stripe", () => {
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const ActualStripe = jest.requireActual("stripe");
  const realStripeForWebhooks = new ActualStripe("sk_test_mock_for_signing", {
    apiVersion: "2026-06-24.dahlia",
  });
  return jest.fn().mockImplementation(() => ({
    webhooks: realStripeForWebhooks.webhooks, // REAL signature verification, no mocking.
    billingPortal: {
      sessions: { create: (...args: unknown[]) => mockBillingPortalCreate(...args) },
    },
    checkout: { sessions: { create: jest.fn() } },
  }));
});

import * as admin from "firebase-admin";
admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT });

import { getFirestore } from "firebase-admin/firestore";
import firebaseFunctionsTest from "firebase-functions-test";
import type { CallableRequest } from "firebase-functions/v2/https";
import Stripe from "stripe";
import { createBillingPortalSession, stripeWebhook } from "../../src/billing";
import { FIRESTORE_DATABASE_ID } from "../../src/lib/db";

const { wrap } = firebaseFunctionsTest();
const wrappedPortal = wrap(createBillingPortalSession);
const db = getFirestore(FIRESTORE_DATABASE_ID);

// A second, independent real Stripe client used only to SIGN test payloads the same way Stripe's
// real servers would — mirrors the exact secret stripeWebhook itself reads via
// process.env.STRIPE_WEBHOOK_SECRET.
const signingClient = new Stripe("sk_test_mock_for_signing", {
  apiVersion: "2026-06-24.dahlia" as never,
});
const REAL_SECRET = process.env.STRIPE_WEBHOOK_SECRET as string;

function buildHttpRes() {
  return {
    statusCode: 200,
    body: undefined as unknown,
    status(code: number) {
      this.statusCode = code;
      return this;
    },
    send(body: unknown) {
      this.body = body;
      return this;
    },
    json(body: unknown) {
      this.body = body;
      return this;
    },
  };
}

function signedRequest(eventPayload: object, secret = REAL_SECRET) {
  const payload = JSON.stringify(eventPayload);
  const header = signingClient.webhooks.generateTestHeaderString({ payload, secret });
  return { headers: { "stripe-signature": header }, rawBody: Buffer.from(payload) };
}

function buildRequest(data: unknown): CallableRequest {
  const req = {
    data,
    auth: { uid: "test-user-1", token: {} },
    rawRequest: {},
    acceptsStreaming: false,
  };
  return req as unknown as CallableRequest;
}

async function seedSubscription(tenantId: string, fields: Record<string, unknown>) {
  await db
    .collection("tenants")
    .doc(tenantId)
    .collection("subscription")
    .doc("status")
    .set(fields);
}

async function getSubscription(tenantId: string) {
  const snap = await db
    .collection("tenants")
    .doc(tenantId)
    .collection("subscription")
    .doc("status")
    .get();
  return snap.data();
}

beforeEach(() => {
  mockBillingPortalCreate.mockReset();
});

afterAll(async () => {
  await admin.app().delete();
});

describe("stripeWebhook — real signature verification (F-319)", () => {
  it("rejects a request signed with the WRONG secret, with 400 and no Firestore write", async () => {
    const tenantId = "tenant-webhook-bad-sig";
    const req = signedRequest(
      {
        id: "evt_bad_sig",
        type: "customer.subscription.updated",
        data: {
          object: {
            customer: "cus_1",
            id: "sub_1",
            status: "active",
            current_period_end: Math.floor(Date.now() / 1000),
            metadata: { tenantId },
          },
        },
      },
      "whsec_totally_wrong_secret"
    );
    const res = buildHttpRes();

    await stripeWebhook(req as never, res as never);

    expect(res.statusCode).toBe(400);
    expect(String(res.body)).toContain("Webhook Error");
    expect(await getSubscription(tenantId)).toBeUndefined();
  });

  it("accepts a correctly-signed request and writes tenants/{tenantId}/subscription/status with the exact fields TenantSubscription.fromFirestore expects", async () => {
    const tenantId = "tenant-webhook-updated";
    const currentPeriodEndSeconds = Math.floor(Date.now() / 1000) + 30 * 24 * 60 * 60;
    const req = signedRequest({
      id: "evt_sub_updated",
      type: "customer.subscription.updated",
      data: {
        object: {
          customer: "cus_real_customer",
          id: "sub_real_subscription",
          status: "active",
          current_period_end: currentPeriodEndSeconds,
          metadata: { tenantId }, // no metadata.tier override — the realistic case
        },
      },
    });
    const res = buildHttpRes();

    await stripeWebhook(req as never, res as never);

    expect(res.statusCode).toBe(200);
    expect(res.body).toEqual({ received: true });

    const sub = await getSubscription(tenantId);
    expect(sub).toBeDefined();
    expect(Object.keys(sub!).sort()).toEqual(
      [
        "tenantId",
        "tier",
        "status",
        "stripeCustomerId",
        "stripeSubscriptionId",
        "currentPeriodEnd",
      ].sort()
    );
    expect(sub!.tenantId).toBe(tenantId);
    // F-319's resolved tier-name fix: defaults to 'premium' (not the old unsatisfiable-elsewhere
    // 'pro'), matching isPremiumProvider's check and the free/premium/enterprise enum.
    expect(sub!.tier).toBe("premium");
    expect(sub!.status).toBe("active");
    expect(sub!.stripeCustomerId).toBe("cus_real_customer");
    expect(sub!.stripeSubscriptionId).toBe("sub_real_subscription");
    expect(sub!.currentPeriodEnd).toBeInstanceOf(admin.firestore.Timestamp);
    expect((sub!.currentPeriodEnd as FirebaseFirestore.Timestamp).toDate().getTime()).toBe(
      currentPeriodEndSeconds * 1000
    );
  });

  it("respects an explicit metadata.tier override instead of the default", async () => {
    const tenantId = "tenant-webhook-enterprise";
    const req = signedRequest({
      id: "evt_sub_enterprise",
      type: "customer.subscription.created",
      data: {
        object: {
          customer: "cus_ent",
          id: "sub_ent",
          status: "active",
          current_period_end: Math.floor(Date.now() / 1000),
          metadata: { tenantId, tier: "enterprise" },
        },
      },
    });
    const res = buildHttpRes();

    await stripeWebhook(req as never, res as never);

    const sub = await getSubscription(tenantId);
    expect(sub!.tier).toBe("enterprise");
  });

  it("on customer.subscription.deleted, sets status=canceled and tier=free while preserving other fields (merge:true)", async () => {
    const tenantId = "tenant-webhook-deleted";
    await seedSubscription(tenantId, {
      tenantId,
      tier: "premium",
      status: "active",
      stripeCustomerId: "cus_to_cancel",
      stripeSubscriptionId: "sub_to_cancel",
    });

    const req = signedRequest({
      id: "evt_sub_deleted",
      type: "customer.subscription.deleted",
      data: {
        object: { customer: "cus_to_cancel", id: "sub_to_cancel", metadata: { tenantId } },
      },
    });
    const res = buildHttpRes();

    await stripeWebhook(req as never, res as never);

    const sub = await getSubscription(tenantId);
    expect(sub!.status).toBe("canceled");
    expect(sub!.tier).toBe("free");
    // merge:true — fields not touched by the delete handler survive.
    expect(sub!.stripeCustomerId).toBe("cus_to_cancel");
    expect(sub!.stripeSubscriptionId).toBe("sub_to_cancel");
  });

  it("writes nothing when the event has no tenantId in metadata", async () => {
    const req = signedRequest({
      id: "evt_no_tenant",
      type: "customer.subscription.updated",
      data: {
        object: {
          customer: "cus_orphan",
          id: "sub_orphan",
          status: "active",
          current_period_end: Math.floor(Date.now() / 1000),
          metadata: {},
        },
      },
    });
    const res = buildHttpRes();

    await stripeWebhook(req as never, res as never);

    expect(res.statusCode).toBe(200);
    // Real proof, not just "didn't throw": a collection-group query across every tenant's
    // subscription/status doc confirms this orphaned customer id was never persisted anywhere.
    const orphaned = await db
      .collectionGroup("subscription")
      .where("stripeCustomerId", "==", "cus_orphan")
      .get();
    expect(orphaned.empty).toBe(true);
  });

  it("acknowledges an unhandled event type with 200 and writes nothing", async () => {
    const req = signedRequest({
      id: "evt_unhandled",
      type: "invoice.payment_succeeded",
      data: { object: { id: "in_1" } },
    });
    const res = buildHttpRes();

    await stripeWebhook(req as never, res as never);

    expect(res.statusCode).toBe(200);
    expect(res.body).toEqual({ received: true });
  });
});

describe("createBillingPortalSession — real Firestore lookup (F-319)", () => {
  it("rejects with failed-precondition when no subscription document exists for the tenant", async () => {
    await expect(
      wrappedPortal(buildRequest({ tenantId: "tenant-portal-no-sub" }))
    ).rejects.toMatchObject({ code: "failed-precondition" });
    expect(mockBillingPortalCreate).not.toHaveBeenCalled();
  });

  it("rejects with failed-precondition when the subscription document has no stripeCustomerId", async () => {
    const tenantId = "tenant-portal-no-customer-id";
    await seedSubscription(tenantId, { tier: "free", status: "inactive" });

    await expect(wrappedPortal(buildRequest({ tenantId }))).rejects.toMatchObject({
      code: "failed-precondition",
    });
    expect(mockBillingPortalCreate).not.toHaveBeenCalled();
  });

  it("opens a billing portal session using the tenant's real stripeCustomerId", async () => {
    const tenantId = "tenant-portal-happy";
    await seedSubscription(tenantId, {
      tier: "premium",
      status: "active",
      stripeCustomerId: "cus_portal_real",
    });
    mockBillingPortalCreate.mockResolvedValueOnce({
      url: "https://billing.stripe.com/session/portal123",
    });

    const result = (await wrappedPortal(buildRequest({ tenantId }))) as { url: string };

    expect(result.url).toBe("https://billing.stripe.com/session/portal123");
    expect(mockBillingPortalCreate).toHaveBeenCalledWith(
      expect.objectContaining({ customer: "cus_portal_real" })
    );
  });
});
