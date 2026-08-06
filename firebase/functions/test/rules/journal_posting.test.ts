/**
 * T1-002 — `postJournalEntry` Cloud Function, emulator-backed portion.
 *
 * Invokes the REAL `postJournalEntry` handler (via `firebase-functions-test`'s `wrap()`) against
 * the Firestore emulator, and asserts the actual transactional writes — not just "a document was
 * written". This is the direct regression test for the precedent bug: this function used to write
 * camelCase/`date`/`totalDebit` field names while the Dart `JournalEntry.fromJson`/
 * `JournalLine.fromJson` (lib/features/finance/models/finance_models.dart) expected snake_case
 * (`transaction_date`, `total_debit`, `account_id`, `debit_amount`, `credit_amount`, etc). Every
 * write assertion below checks exact key sets, not just presence.
 *
 * Lives in test/rules/ (not colocated with src/) because it requires the Firestore emulator via
 * `npm run test:rules` — see jest.rules.config.js and TEST_STRATEGY.md §2/§5.
 *
 * Database note (fixed 2026-08-06): `postJournalEntry` used to call `admin.firestore()`, which
 * takes no `databaseId` and always resolves to "(default)" — a real mismatch, since firebase.json
 * deploys firestore.rules to the named `ai-studio-4bb0fb1c-c6d6-4397-a015-156f3ff9dfb5` database
 * and the Flutter app reads via that same named database (`FirebaseFirestore.instanceFor` in
 * lib/main.dart). Posted journal entries were landing somewhere the app never read from. Fixed by
 * routing every Cloud Function through `getDb()` (src/lib/db.ts), which calls
 * `getFirestore(FIRESTORE_DATABASE_ID)`. This file now reads back through that same named-database
 * handle, matching the function's real (now-correct) target, and includes an explicit regression
 * guard proving nothing lands in "(default)" anymore.
 */

// Must be set before importing "../../src/index" below, since that module calls
// admin.initializeApp() at import time.
process.env.GCLOUD_PROJECT = "ai-studio-applet-webapp-faf6b";
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";

import * as admin from "firebase-admin";
import { getFirestore } from "firebase-admin/firestore";
import firebaseFunctionsTest from "firebase-functions-test";
import type { CallableRequest } from "firebase-functions/v2/https";
import { postJournalEntry } from "../../src/index";
import { FIRESTORE_DATABASE_ID } from "../../src/lib/db";

const { wrap } = firebaseFunctionsTest();
const wrapped = wrap(postJournalEntry);
// Same named-database handle postJournalEntry itself now uses (src/lib/db.ts's getDb()) — NOT
// admin.firestore(), which would silently read back from the wrong ("(default)") database again.
const db = getFirestore(FIRESTORE_DATABASE_ID);

function buildRequest(data: unknown, uid = "test-user-emulator"): CallableRequest {
  const req = {
    data,
    auth: { uid, token: {} },
    rawRequest: {},
    acceptsStreaming: false,
  };
  return req as unknown as CallableRequest;
}

async function seedAccount(
  tenantId: string,
  accountId: string,
  type: string,
  currentBalance = 0
) {
  await db
    .collection("tenants")
    .doc(tenantId)
    .collection("fin_chart_of_accounts")
    .doc(accountId)
    .set({ type, currentBalance, name: accountId });
}

afterAll(async () => {
  await admin.app().delete();
});

describe("postJournalEntry — emulator-backed transactional writes (T1-002)", () => {
  it("writes a header + lines with the exact snake_case field names the Dart model expects, and updates account balances", async () => {
    const tenantId = "tenant-journal-posting-success";
    await seedAccount(tenantId, "acc-cash", "asset", 0);
    await seedAccount(tenantId, "acc-sales", "revenue", 0);

    const isoDate = "2026-08-01T00:00:00.000Z";
    const result = (await wrapped(
      buildRequest(
        {
          tenantId,
          date: isoDate,
          description: "Cash sale",
          lines: [
            { accountId: "acc-cash", debit: 150, credit: 0, memo: "Cash received" },
            { accountId: "acc-sales", debit: 0, credit: 150, memo: "Revenue recognized" },
          ],
        },
        "uid-journal-poster"
      )
    )) as { success: boolean; journalId: string };

    expect(result.success).toBe(true);
    expect(typeof result.journalId).toBe("string");
    expect(result.journalId.length).toBeGreaterThan(0);

    // --- Header: exact key set + exact values, matching JournalEntry.fromJson() ---
    const headerRef = db
      .collection("tenants")
      .doc(tenantId)
      .collection("fin_journal_headers")
      .doc(result.journalId);
    const headerSnap = await headerRef.get();
    expect(headerSnap.exists).toBe(true);
    const header = headerSnap.data()!;

    expect(Object.keys(header).sort()).toEqual(
      [
        "transaction_date",
        "description",
        "source_module",
        "type",
        "currency_code",
        "total_debit",
        "total_credit",
        "created_by",
        "status",
        "posted_at",
      ].sort()
    );
    // Regression guard: the old buggy shape wrote these camelCase/renamed keys instead.
    expect(header).not.toHaveProperty("date");
    expect(header).not.toHaveProperty("totalDebit");
    expect(header).not.toHaveProperty("totalCredit");

    expect(header.transaction_date).toBeInstanceOf(admin.firestore.Timestamp);
    expect((header.transaction_date as FirebaseFirestore.Timestamp).toDate().toISOString()).toBe(
      isoDate
    );
    expect(header.description).toBe("Cash sale");
    expect(header.source_module).toBe("GL");
    expect(header.type).toBe("STANDARD");
    expect(header.currency_code).toBe("USD");
    expect(header.total_debit).toBe(150);
    expect(header.total_credit).toBe(150);
    expect(header.created_by).toBe("uid-journal-poster");
    expect(header.status).toBe("POSTED");
    expect(header.posted_at).toBeInstanceOf(admin.firestore.Timestamp);

    // --- Lines: exact key set + exact values, matching JournalLine.fromJson() ---
    const linesSnap = await headerRef.collection("lines").get();
    expect(linesSnap.size).toBe(2);

    const linesByAccount = new Map(linesSnap.docs.map((d) => [d.data().account_id, d.data()]));
    const cashLine = linesByAccount.get("acc-cash")!;
    const salesLine = linesByAccount.get("acc-sales")!;
    expect(cashLine).toBeDefined();
    expect(salesLine).toBeDefined();

    for (const line of [cashLine, salesLine]) {
      expect(Object.keys(line).sort()).toEqual(
        ["account_id", "debit_amount", "credit_amount", "description"].sort()
      );
      // Regression guard: the old buggy shape used these camelCase keys instead.
      expect(line).not.toHaveProperty("accountId");
      expect(line).not.toHaveProperty("debit");
      expect(line).not.toHaveProperty("credit");
    }
    expect(cashLine.debit_amount).toBe(150);
    expect(cashLine.credit_amount).toBe(0);
    expect(cashLine.description).toBe("Cash received");
    expect(salesLine.debit_amount).toBe(0);
    expect(salesLine.credit_amount).toBe(150);
    expect(salesLine.description).toBe("Revenue recognized");

    // --- Account balances: asset increases by (debit - credit), revenue by (credit - debit) ---
    const cashAccount = await db
      .collection("tenants")
      .doc(tenantId)
      .collection("fin_chart_of_accounts")
      .doc("acc-cash")
      .get();
    const salesAccount = await db
      .collection("tenants")
      .doc(tenantId)
      .collection("fin_chart_of_accounts")
      .doc("acc-sales")
      .get();
    expect(cashAccount.data()!.currentBalance).toBe(150);
    expect(salesAccount.data()!.currentBalance).toBe(150);

    // Regression guard for the database-targeting bug: nothing should have landed in
    // "(default)" — if getDb() ever regresses to admin.firestore(), this catches it.
    const defaultDb = admin.firestore();
    const defaultHeaders = await defaultDb
      .collection("tenants")
      .doc(tenantId)
      .collection("fin_journal_headers")
      .get();
    expect(defaultHeaders.empty).toBe(true);
  });

  it("rejects an unbalanced entry and writes nothing to Firestore", async () => {
    const tenantId = "tenant-journal-posting-unbalanced";
    await seedAccount(tenantId, "acc-cash", "asset", 0);
    await seedAccount(tenantId, "acc-sales", "revenue", 0);

    await expect(
      wrapped(
        buildRequest({
          tenantId,
          date: new Date().toISOString(),
          description: "Unbalanced attempt",
          lines: [
            { accountId: "acc-cash", debit: 100, credit: 0, memo: "debit" },
            { accountId: "acc-sales", debit: 0, credit: 40, memo: "credit — short" },
          ],
        })
      )
    ).rejects.toMatchObject({ code: "failed-precondition" });

    const headers = await db
      .collection("tenants")
      .doc(tenantId)
      .collection("fin_journal_headers")
      .get();
    expect(headers.empty).toBe(true);

    // Balances must be untouched too — nothing should have reached the transaction.
    const cashAccount = await db
      .collection("tenants")
      .doc(tenantId)
      .collection("fin_chart_of_accounts")
      .doc("acc-cash")
      .get();
    expect(cashAccount.data()!.currentBalance).toBe(0);
  });

  it("rejects an entry referencing a non-existent account, inside the transaction, writing nothing", async () => {
    const tenantId = "tenant-journal-posting-missing-account";
    await seedAccount(tenantId, "acc-cash", "asset", 0);
    // Deliberately do NOT seed "acc-ghost".

    await expect(
      wrapped(
        buildRequest({
          tenantId,
          date: new Date().toISOString(),
          description: "References a missing account",
          lines: [
            { accountId: "acc-cash", debit: 75, credit: 0, memo: "debit" },
            { accountId: "acc-ghost", debit: 0, credit: 75, memo: "credit — no such account" },
          ],
        })
      )
    ).rejects.toMatchObject({ code: "not-found" });

    const headers = await db
      .collection("tenants")
      .doc(tenantId)
      .collection("fin_journal_headers")
      .get();
    expect(headers.empty).toBe(true);

    const cashAccount = await db
      .collection("tenants")
      .doc(tenantId)
      .collection("fin_chart_of_accounts")
      .doc("acc-cash")
      .get();
    expect(cashAccount.data()!.currentBalance).toBe(0);
  });
});
