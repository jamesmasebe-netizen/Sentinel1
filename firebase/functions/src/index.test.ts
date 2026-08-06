/**
 * Unit tests for `postJournalEntry`'s synchronous validation logic (T1-002, unit portion).
 *
 * Scope is deliberate and narrow: only the code paths that throw BEFORE any Firestore access —
 * the `request.auth` check, the required-field check, and the debit === credit balance check (see
 * `postJournalEntry` in `./index.ts`). All three run before `db.collection(...)` /
 * `db.runTransaction(...)` are ever touched, so these tests are safe and fast without an emulator.
 *
 * The transactional write path — the one with the field-name-shape precedent bug (this function
 * used to write camelCase/`date`/`totalDebit`; the Dart `JournalEntry.fromJson`/`JournalLine.fromJson`
 * in lib/features/finance/models/finance_models.dart read snake_case/`transaction_date`/`total_debit`)
 * — is covered separately, against the real Firestore emulator, in
 * `test/rules/journal_posting.test.ts`. Per TEST_STRATEGY.md §5, `db.runTransaction` needs the
 * emulator (a mock can't catch a stale read or a double-increment); it is intentionally NOT exercised
 * here.
 */
import { postJournalEntry } from "./index";
import firebaseFunctionsTest from "firebase-functions-test";
import type { CallableRequest } from "firebase-functions/v2/https";

const { wrap } = firebaseFunctionsTest();
const wrapped = wrap(postJournalEntry);

function buildRequest(data: unknown, authed = true): CallableRequest {
  const req = {
    data,
    auth: authed ? { uid: "test-user-1", token: {} } : undefined,
    rawRequest: {},
    acceptsStreaming: false,
  };
  return req as unknown as CallableRequest;
}

const balancedTwoLines = {
  tenantId: "tenant-unit-test",
  date: new Date().toISOString(),
  description: "unit test entry",
  lines: [
    { accountId: "acc-asset", debit: 100, credit: 0, memo: "debit leg" },
    { accountId: "acc-revenue", debit: 0, credit: 100, memo: "credit leg" },
  ],
};

describe("postJournalEntry — validation (no Firestore access)", () => {
  it("rejects unauthenticated calls", async () => {
    await expect(wrapped(buildRequest(balancedTwoLines, false))).rejects.toMatchObject({
      code: "unauthenticated",
    });
  });

  it("rejects a call missing tenantId", async () => {
    const { tenantId: _tenantId, ...rest } = balancedTwoLines;
    await expect(wrapped(buildRequest(rest))).rejects.toMatchObject({
      code: "invalid-argument",
    });
  });

  it("rejects a call missing date", async () => {
    const { date: _date, ...rest } = balancedTwoLines;
    await expect(wrapped(buildRequest(rest))).rejects.toMatchObject({
      code: "invalid-argument",
    });
  });

  it("rejects an entry with fewer than 2 lines", async () => {
    await expect(
      wrapped(buildRequest({ ...balancedTwoLines, lines: [balancedTwoLines.lines[0]] }))
    ).rejects.toMatchObject({ code: "invalid-argument" });
  });

  it("rejects an unbalanced entry (debit != credit) before any Firestore write", async () => {
    const unbalanced = {
      ...balancedTwoLines,
      lines: [
        { accountId: "acc-asset", debit: 100, credit: 0, memo: "debit leg" },
        { accountId: "acc-revenue", debit: 0, credit: 50, memo: "credit leg — short" },
      ],
    };
    await expect(wrapped(buildRequest(unbalanced))).rejects.toMatchObject({
      code: "failed-precondition",
      message: expect.stringContaining("Unbalanced entry"),
    });
  });

  it("rejects an unbalanced entry even when the gap is small but over the 0.001 tolerance", async () => {
    const barelyUnbalanced = {
      ...balancedTwoLines,
      lines: [
        { accountId: "acc-asset", debit: 100, credit: 0, memo: "debit leg" },
        { accountId: "acc-revenue", debit: 0, credit: 99.99, memo: "credit leg — 0.01 short" },
      ],
    };
    await expect(wrapped(buildRequest(barelyUnbalanced))).rejects.toMatchObject({
      code: "failed-precondition",
    });
  });
});
