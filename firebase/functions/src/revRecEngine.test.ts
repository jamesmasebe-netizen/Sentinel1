/**
 * Unit tests for `revenueRecognition`'s guard logic (T2-003).
 *
 * Scope is deliberate and narrow, mirroring T1-002's split: only the code paths that return
 * BEFORE any Firestore access — missing before/after snapshot data, a milestone that was already
 * COMPLETED (no-op re-trigger), and a status transition that isn't a transition *into* COMPLETED.
 * All three `return` before `getDb()` is ever called in `./revRecEngine.ts`.
 *
 * `./lib/db`'s `getDb` is mocked to *throw* if invoked at all — this doesn't just assert "the
 * write didn't happen", it actively proves these guard paths never even attempt Firestore access,
 * the same proof style T1-002 established for `postJournalEntry`'s validation-only unit tests.
 *
 * The real write path (the transition-to-COMPLETED case that actually posts a journal entry) is
 * covered separately against the real Firestore emulator in test/rules/rev_rec_engine.test.ts,
 * per TEST_STRATEGY.md §5 — this function's write is exactly the kind of Dart-model-consumed,
 * field-shape-sensitive write the strategy calls out (it lands in fin_journal_headers, the same
 * collection `postJournalEntry` had its real field-name bug in).
 */
import firebaseFunctionsTest from "firebase-functions-test";

jest.mock("./lib/db", () => ({
  getDb: jest.fn(() => {
    throw new Error("getDb() should NOT be called on a guard/skip path");
  }),
}));

import { revenueRecognition } from "./revRecEngine";

const { wrap } = firebaseFunctionsTest();
const wrapped = wrap(revenueRecognition) as (
  partial: unknown
) => Promise<void>;

type MilestoneEventPartial = {
  data: {
    before: Record<string, unknown>;
    after: Record<string, unknown>;
  };
  params: { tenantId: string; milestoneId: string };
};

function buildEvent(
  before: Record<string, unknown>,
  after: Record<string, unknown>,
  params = { tenantId: "tenant-revrec-unit", milestoneId: "milestone-1" }
): MilestoneEventPartial {
  return { data: { before, after }, params };
}

describe("revenueRecognition — guard paths (no Firestore access)", () => {
  it("does nothing when the milestone was already COMPLETED before this update", async () => {
    await expect(
      wrapped(
        buildEvent(
          { status: "COMPLETED", name: "M1", value: 500 },
          { status: "COMPLETED", name: "M1", value: 500 }
        )
      )
    ).resolves.toBeUndefined();
  });

  it("does nothing when the new status is not COMPLETED", async () => {
    await expect(
      wrapped(
        buildEvent(
          { status: "IN_PROGRESS", name: "M1", value: 500 },
          { status: "BLOCKED", name: "M1", value: 500 }
        )
      )
    ).resolves.toBeUndefined();
  });

  it("does nothing on a non-COMPLETED -> non-COMPLETED transition", async () => {
    await expect(
      wrapped(
        buildEvent(
          { status: "NOT_STARTED", name: "M1", value: 500 },
          { status: "IN_PROGRESS", name: "M1", value: 500 }
        )
      )
    ).resolves.toBeUndefined();
  });
});
