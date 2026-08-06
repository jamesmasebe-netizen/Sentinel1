/**
 * T2-003 — `accrueLeave`, emulator-backed portion.
 *
 * FIXED 2026-08-06: `accrueLeave` used to be a triple no-op — it queried a root-level
 * `hr_employees` collection nothing writes to (real employees live at
 * `tenants/{tenantId}/employees`, written by `HrService`), its accrual-rate lookup keyed off a
 * `tier` field `Employee` doesn't have, and it never called a Firestore write method at all, only
 * `logger.info()`-ing what it "would" do. Fixed by: (1) querying via `db.collectionGroup("employees")`
 * so the scheduled job reaches every tenant's real employees in one pass (mirroring index.ts's
 * existing cross-tenant collectionGroup pattern for `permits`/`incidents`/`training_records`);
 * (2) dropping the nonexistent tier concept in favor of one flat `MONTHLY_ACCRUAL_DAYS` rate
 * (the same value every real employee always fell back to anyway, since no employee has ever had
 * a `tier`); (3) actually writing the accrual via a real `db.batch()` of
 * `leaveBalance: FieldValue.increment(...)` updates, skipping employees whose `status` isn't
 * `'Active'`. There is no meaningful precondition/validation path to unit-test in isolation
 * anymore (the function takes no arguments and every code path touches Firestore), so — per
 * TEST_STRATEGY.md §5's preference for emulator-backed assertions over deep mocking of anything
 * that writes — all of this function's tests now live here against the real emulator; the
 * previous `src/hrEngine.test.ts` (which existed specifically to prove this function never wrote
 * anything) has been removed as obsolete.
 */

process.env.GCLOUD_PROJECT = "ai-studio-applet-webapp-faf6b";
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";

import * as admin from "firebase-admin";
admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT });

import { getFirestore } from "firebase-admin/firestore";
import firebaseFunctionsTest from "firebase-functions-test";
import { accrueLeave } from "../../src/hrEngine";
import { FIRESTORE_DATABASE_ID } from "../../src/lib/db";

const { wrap } = firebaseFunctionsTest();
// wrap()'s type overloads don't include a v2 ScheduleFunction shape (a TS declaration gap, not a
// runtime one — wrapV2's actual implementation only checks `.run`'s arity). Cast through `any` to
// select the right overload, matching the pattern already used for postJournalEntry-adjacent
// scheduled-function tests in this codebase.
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const wrapped = wrap(accrueLeave as any) as (partial?: unknown) => Promise<unknown>;
const db = getFirestore(FIRESTORE_DATABASE_ID);

function employeeRef(tenantId: string, employeeId: string) {
  return db.collection("tenants").doc(tenantId).collection("employees").doc(employeeId);
}

async function seedEmployee(
  tenantId: string,
  employeeId: string,
  overrides: Record<string, unknown> = {}
) {
  await employeeRef(tenantId, employeeId).set({
    id: employeeId,
    authUserId: `auth-${employeeId}`,
    fullName: overrides.fullName ?? employeeId,
    email: `${employeeId}@example.com`,
    department: "Ops",
    jobTitle: "Technician",
    ohsRoles: [],
    managerId: null,
    leaveBalance: 5.0,
    status: "Active",
    ...overrides,
  });
}

afterAll(async () => {
  await admin.app().delete();
});

describe("accrueLeave — emulator-backed collectionGroup read + batch write (T2-003)", () => {
  it("increments leaveBalance by the flat monthly accrual rate for an active employee", async () => {
    const tenantId = "tenant-hr-accrual-basic";
    await seedEmployee(tenantId, "emp-1", { leaveBalance: 5.0 });

    await wrapped();

    const after = await employeeRef(tenantId, "emp-1").get();
    expect(after.data()!.leaveBalance).toBe(6.0); // 5.0 + MONTHLY_ACCRUAL_DAYS (1)
  });

  it("does not accrue leave for a Suspended employee", async () => {
    const tenantId = "tenant-hr-accrual-suspended";
    await seedEmployee(tenantId, "emp-suspended", {
      leaveBalance: 3.0,
      status: "Suspended",
    });

    await wrapped();

    const after = await employeeRef(tenantId, "emp-suspended").get();
    expect(after.data()!.leaveBalance).toBe(3.0);
  });

  it("reaches employees across multiple tenants in a single scheduled run", async () => {
    const tenantA = "tenant-hr-accrual-multi-a";
    const tenantB = "tenant-hr-accrual-multi-b";
    await seedEmployee(tenantA, "emp-a", { leaveBalance: 0 });
    await seedEmployee(tenantB, "emp-b", { leaveBalance: 10 });

    await wrapped();

    const afterA = await employeeRef(tenantA, "emp-a").get();
    const afterB = await employeeRef(tenantB, "emp-b").get();
    expect(afterA.data()!.leaveBalance).toBe(1);
    expect(afterB.data()!.leaveBalance).toBe(11);
  });

  it("resolves without throwing on a repeat run (idempotent-safe, not just a one-shot)", async () => {
    // The Firestore emulator's state is shared across this whole file (and process), so by this
    // point the collectionGroup query is guaranteed non-empty from the earlier tests above —
    // this isn't exercising the empty-snapshot early-return branch specifically (that's a plain
    // Dart/TS `if (snapshot.empty)` with no Firestore-specific behavior worth emulator-testing).
    // What this proves: running the job again doesn't throw or double-apply in a way that errors.
    await expect(wrapped()).resolves.toBeUndefined();
  });
});
