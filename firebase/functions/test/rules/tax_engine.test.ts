/**
 * T2-003 — `calculateTax` Cloud Function, emulator-backed portion.
 *
 * `calculateTax`'s entire value proposition (per its own doc comment, referencing F-313) is that
 * it looks up a REAL `fin_tax_codes` record by `jurisdiction_id` + `is_active`, instead of a
 * fabricated flat rate. That's a compound Firestore query — worth trusting against the real
 * emulator rather than a mocked query chain, per TEST_STRATEGY.md §5. The precondition-only
 * validation path is covered without the emulator in src/taxEngine.test.ts.
 *
 * Field names used to seed `fin_tax_codes` here (`jurisdiction_id`, `is_active`, `rate`) are
 * confirmed against `TaxCode.fromJson` in
 * lib/features/finance/models/finance_models.dart (they match exactly — no drift found).
 */

process.env.GCLOUD_PROJECT = "ai-studio-applet-webapp-faf6b";
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";

import * as admin from "firebase-admin";
admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT });

import { getFirestore } from "firebase-admin/firestore";
import firebaseFunctionsTest from "firebase-functions-test";
import type { CallableRequest } from "firebase-functions/v2/https";
import { calculateTax } from "../../src/taxEngine";
import { FIRESTORE_DATABASE_ID } from "../../src/lib/db";

const { wrap } = firebaseFunctionsTest();
const wrapped = wrap(calculateTax);
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

async function seedTaxCode(
  tenantId: string,
  id: string,
  fields: { jurisdiction_id: string; is_active: boolean; rate: number }
) {
  await db
    .collection("tenants")
    .doc(tenantId)
    .collection("fin_tax_codes")
    .doc(id)
    .set(fields);
}

afterAll(async () => {
  await admin.app().delete();
});

describe("calculateTax — emulator-backed real Firestore query (T2-003)", () => {
  it("picks the active tax code for the given jurisdiction and computes the tax correctly", async () => {
    const tenantId = "tenant-tax-happy-path";
    await seedTaxCode(tenantId, "code-ca-active", {
      jurisdiction_id: "US-CA",
      is_active: true,
      rate: 0.0725,
    });
    // A different jurisdiction and an inactive code for the SAME jurisdiction must both be
    // ignored — proves the compound where() filter is actually applied, not just the first doc.
    await seedTaxCode(tenantId, "code-ny-active", {
      jurisdiction_id: "US-NY",
      is_active: true,
      rate: 0.08875,
    });
    await seedTaxCode(tenantId, "code-ca-inactive", {
      jurisdiction_id: "US-CA",
      is_active: false,
      rate: 0.5,
    });

    const result = (await wrapped(
      buildRequest({ tenantId, total: 1000, jurisdiction: "US-CA" })
    )) as {
      jurisdiction: string;
      taxCodeId: string | null;
      rate: number;
      originalTotal: number;
      taxAmount: number;
      totalWithTax: number;
    };

    expect(result.jurisdiction).toBe("US-CA");
    expect(result.taxCodeId).toBe("code-ca-active");
    expect(result.rate).toBe(0.0725);
    expect(result.originalTotal).toBe(1000);
    expect(result.taxAmount).toBeCloseTo(72.5, 5);
    expect(result.totalWithTax).toBeCloseTo(1072.5, 5);
  });

  it("falls back to a 0% rate and a null taxCodeId when no active tax code matches the jurisdiction", async () => {
    const tenantId = "tenant-tax-no-match";
    // Only an inactive code exists for this jurisdiction.
    await seedTaxCode(tenantId, "code-tx-inactive", {
      jurisdiction_id: "US-TX",
      is_active: false,
      rate: 0.0625,
    });

    const result = (await wrapped(
      buildRequest({ tenantId, total: 500, jurisdiction: "US-TX" })
    )) as {
      taxCodeId: string | null;
      rate: number;
      taxAmount: number;
      totalWithTax: number;
    };

    expect(result.taxCodeId).toBeNull();
    expect(result.rate).toBe(0);
    expect(result.taxAmount).toBe(0);
    expect(result.totalWithTax).toBe(500);
  });

  it("falls back to a 0% rate when the jurisdiction has no tax code at all (not just none active)", async () => {
    const tenantId = "tenant-tax-empty";
    const result = (await wrapped(
      buildRequest({ tenantId, total: 250, jurisdiction: "ZZ-NOWHERE" })
    )) as { taxCodeId: string | null; rate: number };

    expect(result.taxCodeId).toBeNull();
    expect(result.rate).toBe(0);
  });

  it("does not leak a tax code from a different tenant with the same jurisdiction id", async () => {
    const tenantA = "tenant-tax-isolation-a";
    const tenantB = "tenant-tax-isolation-b";
    await seedTaxCode(tenantA, "code-a", {
      jurisdiction_id: "US-CA",
      is_active: true,
      rate: 0.1,
    });
    // Tenant B never seeds a US-CA code at all.

    const result = (await wrapped(
      buildRequest({ tenantId: tenantB, total: 100, jurisdiction: "US-CA" })
    )) as { taxCodeId: string | null; rate: number };

    expect(result.taxCodeId).toBeNull();
    expect(result.rate).toBe(0);
  });
});
