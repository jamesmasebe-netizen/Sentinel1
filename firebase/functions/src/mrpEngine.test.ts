/**
 * Unit tests for `runMrp`'s precondition-validation path (T2-003).
 *
 * Scope mirrors T1-002: only the `invalid-argument` guard (missing `tenantId`), which throws
 * BEFORE `getDb()` is ever called in `./mrpEngine.ts`. `./lib/db`'s `getDb` is mocked to throw if
 * invoked, proving the guard never touches Firestore.
 *
 * The real supply-vs-demand shortage math and the `mrp_suggestions` batch write are covered
 * against the real Firestore emulator in test/rules/mrp_engine.test.ts — that file also documents
 * a real data-shape bug found while first writing these tests, and fixed 2026-08-06 (see its
 * header comment): `runMrp` used to read a `data.lines` array directly off each `sales_orders`
 * document, which never existed on `SalesOrder`. Fixed by adding a real `SalesOrderLine`/
 * `so_lines` subcollection (mirroring the existing `PurchaseOrderLine`/`po_lines` pattern) and
 * pointing the demand computation at it.
 */
import firebaseFunctionsTest from "firebase-functions-test";
import type { CallableRequest } from "firebase-functions/v2/https";

jest.mock("./lib/db", () => ({
  getDb: jest.fn(() => {
    throw new Error("getDb() should NOT be called when tenantId is missing");
  }),
}));

import { runMrp } from "./mrpEngine";

const { wrap } = firebaseFunctionsTest();
const wrapped = wrap(runMrp);

function buildRequest(data: unknown): CallableRequest {
  const req = {
    data,
    auth: { uid: "test-user-1", token: {} },
    rawRequest: {},
    acceptsStreaming: false,
  };
  return req as unknown as CallableRequest;
}

describe("runMrp — validation (no Firestore access)", () => {
  it("rejects a call missing tenantId", async () => {
    await expect(wrapped(buildRequest({}))).rejects.toMatchObject({
      code: "invalid-argument",
    });
  });
});
