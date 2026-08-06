/**
 * Unit tests for `calculateTax`'s precondition-validation path (T2-003).
 *
 * Scope mirrors T1-002: only the `invalid-argument` guard, which throws BEFORE `getDb()` is ever
 * called (see `./taxEngine.ts` — the required-field check runs first, the Firestore query runs
 * after). `./lib/db`'s `getDb` is mocked to throw if invoked, proving the guard never touches
 * Firestore, not just that no assertion happened to check it.
 *
 * The real value of this function — looking up the correct `fin_tax_codes` record by
 * jurisdiction + active flag and computing the tax amount from it — requires a real Firestore
 * query (compound `where` filters) to trust, per TEST_STRATEGY.md §5's preference for the
 * emulator over mocking query behavior. That's covered in test/rules/tax_engine.test.ts.
 */
import firebaseFunctionsTest from "firebase-functions-test";
import type { CallableRequest } from "firebase-functions/v2/https";

jest.mock("./lib/db", () => ({
  getDb: jest.fn(() => {
    throw new Error("getDb() should NOT be called when required arguments are missing");
  }),
}));

import { calculateTax } from "./taxEngine";

const { wrap } = firebaseFunctionsTest();
const wrapped = wrap(calculateTax);

function buildRequest(data: unknown): CallableRequest {
  const req = {
    data,
    auth: { uid: "test-user-1", token: {} },
    rawRequest: {},
    acceptsStreaming: false,
  };
  return req as unknown as CallableRequest;
}

describe("calculateTax — validation (no Firestore access)", () => {
  it("rejects a call missing tenantId", async () => {
    await expect(
      wrapped(buildRequest({ total: 100, jurisdiction: "US-CA" }))
    ).rejects.toMatchObject({ code: "invalid-argument" });
  });

  it("rejects a call missing jurisdiction", async () => {
    await expect(
      wrapped(buildRequest({ tenantId: "tenant-1", total: 100 }))
    ).rejects.toMatchObject({ code: "invalid-argument" });
  });

  it("rejects a call missing total", async () => {
    await expect(
      wrapped(buildRequest({ tenantId: "tenant-1", jurisdiction: "US-CA" }))
    ).rejects.toMatchObject({ code: "invalid-argument" });
  });

  it("rejects a call with total explicitly null (nullish, not just falsy-zero)", async () => {
    await expect(
      wrapped(buildRequest({ tenantId: "tenant-1", jurisdiction: "US-CA", total: null }))
    ).rejects.toMatchObject({ code: "invalid-argument" });
  });

  it("accepts total === 0 (a legitimate zero-value invoice, not a missing argument)", async () => {
    // total=0 must NOT be rejected by the `total == null` check (0 is falsy but not nullish).
    // This call proceeds past validation into the mocked getDb(), which throws — so a rejection
    // happening for a DIFFERENT reason than "invalid-argument" proves validation let it through.
    await expect(
      wrapped(buildRequest({ tenantId: "tenant-1", jurisdiction: "US-CA", total: 0 }))
    ).rejects.not.toMatchObject({ code: "invalid-argument" });
  });
});
