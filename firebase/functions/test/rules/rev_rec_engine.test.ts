/**
 * T2-003 — `revenueRecognition` Cloud Function, emulator-backed portion.
 *
 * Invokes the REAL `revenueRecognition` handler (via `firebase-functions-test`'s `wrap()`)
 * against the Firestore emulator and asserts the actual write into `fin_journal_headers` — not
 * just "a document was written". Per TEST_STRATEGY.md §5, every test touching a Firestore write
 * must assert exact field names against the Dart model that reads it back
 * (`JournalEntry.fromJson` in lib/features/finance/models/finance_models.dart), the same rigor
 * `postJournalEntry`'s emulator test (journal_posting.test.ts) applies — this function writes
 * into the exact same collection.
 *
 * Lives in test/rules/ (not colocated with src/) because it requires the Firestore emulator via
 * `npm run test:rules` — see jest.rules.config.js and TEST_STRATEGY.md §2/§5. The guard/skip
 * paths that never touch Firestore are covered, without the emulator, in
 * src/revRecEngine.test.ts.
 */

process.env.GCLOUD_PROJECT = "ai-studio-applet-webapp-faf6b";
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";

import * as admin from "firebase-admin";
admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT });

import { getFirestore } from "firebase-admin/firestore";
import firebaseFunctionsTest from "firebase-functions-test";
import { revenueRecognition } from "../../src/revRecEngine";
import { FIRESTORE_DATABASE_ID } from "../../src/lib/db";

const { wrap } = firebaseFunctionsTest();
const wrapped = wrap(revenueRecognition) as (partial: unknown) => Promise<void>;
const db = getFirestore(FIRESTORE_DATABASE_ID);

type MilestoneEventPartial = {
  data: {
    before: Record<string, unknown>;
    after: Record<string, unknown>;
  };
  params: { tenantId: string; milestoneId: string };
};

function buildEvent(
  tenantId: string,
  milestoneId: string,
  before: Record<string, unknown>,
  after: Record<string, unknown>
): MilestoneEventPartial {
  return { data: { before, after }, params: { tenantId, milestoneId } };
}

afterAll(async () => {
  await admin.app().delete();
});

describe("revenueRecognition — emulator-backed transactional write (T2-003)", () => {
  it("posts a journal entry with the exact snake_case field names the Dart JournalEntry model expects", async () => {
    const tenantId = "tenant-revrec-success";
    const milestoneId = "milestone-completed-1";

    await wrapped(
      buildEvent(
        tenantId,
        milestoneId,
        { status: "IN_PROGRESS", name: "Phase 1 delivery", value: 25000 },
        { status: "COMPLETED", name: "Phase 1 delivery", value: 25000 }
      )
    );

    const headersSnap = await db
      .collection("tenants")
      .doc(tenantId)
      .collection("fin_journal_headers")
      .get();
    expect(headersSnap.size).toBe(1);

    const header = headersSnap.docs[0].data();
    expect(Object.keys(header).sort()).toEqual(
      [
        "description",
        "total_debit",
        "total_credit",
        "type",
        "status",
        "source_module",
        "source_reference_id",
        "currency_code",
        "transaction_date",
        "created_at",
      ].sort()
    );
    // Regression guard against the camelCase shape postJournalEntry used to write.
    expect(header).not.toHaveProperty("totalDebit");
    expect(header).not.toHaveProperty("totalCredit");
    expect(header).not.toHaveProperty("date");

    expect(header.description).toBe(
      `Revenue recognition for completed milestone: Phase 1 delivery (${milestoneId})`
    );
    expect(header.total_debit).toBe(25000);
    expect(header.total_credit).toBe(25000);
    expect(header.type).toBe("REVENUE_RECOGNITION");
    expect(header.status).toBe("POSTED");
    expect(header.source_module).toBe("PROJECTS");
    expect(header.source_reference_id).toBe(milestoneId);
    expect(header.currency_code).toBe("USD");
    expect(header.transaction_date).toBeInstanceOf(admin.firestore.Timestamp);
    expect(header.created_at).toBeInstanceOf(admin.firestore.Timestamp);

    // Regression guard for the database-targeting bug this whole file's fix addressed
    // (fixed 2026-08-06, see T1-002's resolved note): nothing should land in "(default)".
    const defaultHeaders = await admin
      .firestore()
      .collection("tenants")
      .doc(tenantId)
      .collection("fin_journal_headers")
      .get();
    expect(defaultHeaders.empty).toBe(true);
  });

  it("falls back to the milestone id and 0 value when name/value are missing", async () => {
    const tenantId = "tenant-revrec-fallback";
    const milestoneId = "milestone-no-name-or-value";

    await wrapped(
      buildEvent(tenantId, milestoneId, { status: "IN_PROGRESS" }, { status: "COMPLETED" })
    );

    const headersSnap = await db
      .collection("tenants")
      .doc(tenantId)
      .collection("fin_journal_headers")
      .get();
    expect(headersSnap.size).toBe(1);
    const header = headersSnap.docs[0].data();
    expect(header.description).toBe(
      `Revenue recognition for completed milestone: ${milestoneId} (${milestoneId})`
    );
    expect(header.total_debit).toBe(0);
    expect(header.total_credit).toBe(0);
  });

  it("does not write a second journal entry when the milestone is edited again while already COMPLETED", async () => {
    const tenantId = "tenant-revrec-no-retrigger";
    const milestoneId = "milestone-already-done";

    // A second, unrelated field edit on an already-COMPLETED milestone should not re-fire.
    await wrapped(
      buildEvent(
        tenantId,
        milestoneId,
        { status: "COMPLETED", name: "M", value: 100 },
        { status: "COMPLETED", name: "M (renamed)", value: 100 }
      )
    );

    const headersSnap = await db
      .collection("tenants")
      .doc(tenantId)
      .collection("fin_journal_headers")
      .get();
    expect(headersSnap.empty).toBe(true);
  });
});
