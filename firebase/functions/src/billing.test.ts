/**
 * Unit tests for `billing.ts`'s precondition-validation paths (T2-003, F-319).
 *
 * F-319 ("The Stripe subscription billing pipeline is disconnected end-to-end") is resolved per
 * docs/fixes/FIX_LIST.md: `createStripeCheckoutSession` now exists and is exported (`export *
 * from './billing'` in src/index.ts), `stripeWebhook` writes `tenants/{tenantId}/subscription/
 * status` (matching `BillingService.getSubscriptionStream()` in
 * lib/features/billing/services/billing_service.dart), and the tier-name bug was resolved by
 * making the webhook's own default tier `'premium'` (matching `isPremiumProvider`'s check AND
 * `SubscriptionTier`'s `free/premium/enterprise` enum in
 * lib/features/billing/models/subscription_models.dart — no `'pro'` tier remains anywhere).
 *
 * This file covers ONLY the code paths that throw/return BEFORE any Stripe or Firestore access —
 * `createStripeCheckoutSession`/`createBillingPortalSession`'s missing-`tenantId` guard, and
 * `stripeWebhook`'s missing-signature-header guard — mirroring T1-002's unit/emulator split.
 * Both `./lib/db`'s `getDb` and the `stripe` package are mocked to THROW if invoked at all, which
 * proves (not just asserts) these guards never reach either external system.
 *
 * The actual Stripe-integration behavior (`createStripeCheckoutSession`'s real request shape,
 * with Stripe itself still mocked since there's no local Stripe emulator) is also covered here,
 * since it never touches Firestore. `createBillingPortalSession`'s Firestore lookup and
 * `stripeWebhook`'s real signature verification + subscription-document write shape — the parts
 * TEST_STRATEGY.md §5 says should go through the emulator rather than a mock — are covered in
 * test/rules/billing.test.ts.
 */
const mockCheckoutCreate = jest.fn();
const mockBillingPortalCreate = jest.fn();
const mockConstructEvent = jest.fn();

jest.mock("./lib/db", () => ({
  getDb: jest.fn(() => {
    throw new Error("getDb() should NOT be called on a guard/precondition path");
  }),
}));

jest.mock("stripe", () => {
  return jest.fn().mockImplementation(() => ({
    checkout: { sessions: { create: (...args: unknown[]) => mockCheckoutCreate(...args) } },
    billingPortal: {
      sessions: { create: (...args: unknown[]) => mockBillingPortalCreate(...args) },
    },
    webhooks: { constructEvent: (...args: unknown[]) => mockConstructEvent(...args) },
  }));
});

import firebaseFunctionsTest from "firebase-functions-test";
import type { CallableRequest } from "firebase-functions/v2/https";
import {
  createStripeCheckoutSession,
  createBillingPortalSession,
  stripeWebhook,
} from "./billing";

const { wrap } = firebaseFunctionsTest();
const wrappedCheckout = wrap(createStripeCheckoutSession);
const wrappedPortal = wrap(createBillingPortalSession);

function buildRequest(data: unknown): CallableRequest {
  const req = {
    data,
    auth: { uid: "test-user-1", token: {} },
    rawRequest: {},
    acceptsStreaming: false,
  };
  return req as unknown as CallableRequest;
}

function buildHttpReq(headers: Record<string, string | undefined>, rawBody?: Buffer) {
  return { headers, rawBody: rawBody ?? Buffer.from("{}") };
}

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

beforeEach(() => {
  mockCheckoutCreate.mockReset();
  mockBillingPortalCreate.mockReset();
  mockConstructEvent.mockReset();
});

describe("createStripeCheckoutSession — validation and Stripe request shape", () => {
  it("rejects a call missing tenantId, never touching Stripe", async () => {
    await expect(wrappedCheckout(buildRequest({}))).rejects.toMatchObject({
      code: "invalid-argument",
    });
    expect(mockCheckoutCreate).not.toHaveBeenCalled();
  });

  it("creates a subscription-mode Checkout Session and returns its url", async () => {
    mockCheckoutCreate.mockResolvedValueOnce({ url: "https://checkout.stripe.com/session123" });

    const result = (await wrappedCheckout(
      buildRequest({ tenantId: "tenant-checkout-1", priceId: "price_real_plan" })
    )) as { url: string };

    expect(result.url).toBe("https://checkout.stripe.com/session123");
    expect(mockCheckoutCreate).toHaveBeenCalledTimes(1);
    const callArgs = mockCheckoutCreate.mock.calls[0][0];
    expect(callArgs.mode).toBe("subscription");
    expect(callArgs.line_items[0].price).toBe("price_real_plan");
    expect(callArgs.metadata.tenantId).toBe("tenant-checkout-1");
  });

  it("falls back to price_mock when no priceId is supplied", async () => {
    mockCheckoutCreate.mockResolvedValueOnce({ url: "https://checkout.stripe.com/session456" });

    await wrappedCheckout(buildRequest({ tenantId: "tenant-checkout-2" }));

    const callArgs = mockCheckoutCreate.mock.calls[0][0];
    expect(callArgs.line_items[0].price).toBe("price_mock");
  });

  it("wraps a Stripe failure as an internal HttpsError", async () => {
    mockCheckoutCreate.mockRejectedValueOnce(new Error("Stripe API is down"));

    await expect(
      wrappedCheckout(buildRequest({ tenantId: "tenant-checkout-3" }))
    ).rejects.toMatchObject({ code: "internal" });
  });
});

describe("createBillingPortalSession — validation (no Firestore/Stripe access)", () => {
  it("rejects a call missing tenantId, never touching Firestore or Stripe", async () => {
    await expect(wrappedPortal(buildRequest({}))).rejects.toMatchObject({
      code: "invalid-argument",
    });
    expect(mockBillingPortalCreate).not.toHaveBeenCalled();
  });
});

describe("stripeWebhook — validation (no Stripe/Firestore access)", () => {
  it("rejects a request missing the stripe-signature header with 400, before touching Stripe or Firestore", async () => {
    const req = buildHttpReq({});
    const res = buildHttpRes();

    await stripeWebhook(req as never, res as never);

    expect(res.statusCode).toBe(400);
    expect(String(res.body)).toContain("Missing stripe-signature");
    expect(mockConstructEvent).not.toHaveBeenCalled();
  });
});
