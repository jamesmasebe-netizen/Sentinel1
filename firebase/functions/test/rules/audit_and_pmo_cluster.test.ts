/**
 * Wave 2c — supplemental cluster: explicit test coverage for the 8 remaining collections added to
 * firestore.rules during the T2c-SENSITIVE security/availability fix (see TEST_BACKLOG.md) that
 * don't fit the managerGated/sheqGated loops already covered elsewhere — audit_logs, counters,
 * the 3 PMO self-logged collections (actuals/expenses/time_entries), and the 2 HR
 * self-service collections (competency_passports/skills_matrix). That fix verified the rules text
 * directly but didn't add dedicated tests; this closes that gap.
 *
 * 2026-08-10: 'timeEntries' (a separate, naming-drift duplicate of 'time_entries' that had no
 * reader anywhere in lib/) was unified onto 'time_entries' and its own rules block removed —
 * dropped from the pmoSelfLogged loop below accordingly.
 */
import { assertFails, assertSucceeds, RulesTestEnvironment } from "@firebase/rules-unit-testing";
import { addDoc, collection, deleteDoc, doc, getDoc, setDoc, updateDoc } from "firebase/firestore";
import { authedContext, getTestEnv, TENANT_A } from "../helpers/rules_test_env";

describe("firestore.rules — audit_logs/PMO/HR-self-service collections (Wave 2c supplemental)", () => {
  let testEnv: RulesTestEnvironment;

  beforeAll(async () => {
    testEnv = await getTestEnv();
  });

  afterAll(async () => {
    await testEnv.cleanup();
  });

  afterEach(async () => {
    await testEnv.clearFirestore();
  });

  async function seed(pathStr: string, data: Record<string, unknown>) {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), pathStr), data);
    });
  }

  describe("audit_logs — immutable, manager-only read, any-role create (regression guard for the T2c-SENSITIVE availability fix)", () => {
    it("allows any employee to create an entry — this is the exact call AuditLogService.logAction makes before every FirestoreService write", async () => {
      const employee = authedContext(testEnv, "employee-audit-1", TENANT_A, "employee");
      await assertSucceeds(
        addDoc(collection(employee.firestore(), `tenants/${TENANT_A}/audit_logs`), {
          action: "CREATE",
          metadata: {},
          tenantId: TENANT_A,
        })
      );
    });

    it("denies a plain employee from reading the audit trail", async () => {
      await seed(`tenants/${TENANT_A}/audit_logs/log-1`, { action: "CREATE" });
      const employee = authedContext(testEnv, "employee-audit-2", TENANT_A, "employee");
      await assertFails(getDoc(doc(employee.firestore(), `tenants/${TENANT_A}/audit_logs/log-1`)));
    });

    it("allows a manager to read, but denies update/delete for everyone — entries are immutable", async () => {
      await seed(`tenants/${TENANT_A}/audit_logs/log-2`, { action: "CREATE" });
      const manager = authedContext(testEnv, "manager-audit-1", TENANT_A, "manager");
      const ref = doc(manager.firestore(), `tenants/${TENANT_A}/audit_logs/log-2`);
      await assertSucceeds(getDoc(ref));
      await assertFails(updateDoc(ref, { action: "TAMPERED" }));
      await assertFails(deleteDoc(ref));
    });
  });

  describe("counters — fully open read+write to any tenant member (transaction-internal ID generation)", () => {
    it("allows any employee to read and write a counter document", async () => {
      const employee = authedContext(testEnv, "employee-counter-1", TENANT_A, "employee");
      const ref = doc(employee.firestore(), `tenants/${TENANT_A}/counters/projects`);
      await assertSucceeds(setDoc(ref, { lastNumber: 1 }));
      await assertSucceeds(getDoc(ref));
    });
  });

  // Shape: read open to any tenant member; create open to any tenant member (self-logged);
  // update/delete gated to isManager().
  const pmoSelfLogged = ["actuals", "expenses", "time_entries"];

  for (const collection of pmoSelfLogged) {
    it(`${collection}: any employee can create (self-logged), but only a manager can update or delete`, async () => {
      const employee = authedContext(testEnv, `employee-${collection}-1`, TENANT_A, "employee");
      await assertSucceeds(
        setDoc(doc(employee.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-1`), {
          note: "seed",
        })
      );

      await seed(`tenants/${TENANT_A}/${collection}/${collection}-2`, { note: "seed" });
      const employee2 = authedContext(testEnv, `employee-${collection}-2`, TENANT_A, "employee");
      await assertFails(
        updateDoc(doc(employee2.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-2`), {
          note: "should be denied",
        })
      );

      const manager = authedContext(testEnv, `manager-${collection}-1`, TENANT_A, "manager");
      const managerRef = doc(manager.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-2`);
      await assertSucceeds(updateDoc(managerRef, { note: "updated" }));
      await assertSucceeds(deleteDoc(managerRef));
    });
  }

  // Found undeclared 2026-08-10 while re-verifying _known_gaps_rollup.md's §1.1 pattern —
  // PmoService.createWbsTask writes here but no rule existed at all, so real writes hit
  // PERMISSION_DENIED. Shape mirrors the parent /projects collection: read open to any tenant
  // member, create/update gated to isManager(), delete gated to isAdmin().
  describe("projects/{id}/wbs — manager create/update, admin delete", () => {
    it("denies a plain employee from creating a WBS task", async () => {
      const employee = authedContext(testEnv, "employee-wbs-1", TENANT_A, "employee");
      await assertFails(
        setDoc(doc(employee.firestore(), `tenants/${TENANT_A}/projects/proj-1/wbs/task-1`), {
          title: "should be denied",
        })
      );
    });

    it("allows a manager to create, read, and update a WBS task", async () => {
      const manager = authedContext(testEnv, "manager-wbs-1", TENANT_A, "manager");
      const ref = doc(manager.firestore(), `tenants/${TENANT_A}/projects/proj-1/wbs/task-2`);
      await assertSucceeds(setDoc(ref, { title: "Foundation pour" }));
      await assertSucceeds(getDoc(ref));
      await assertSucceeds(updateDoc(ref, { title: "Foundation pour — updated" }));
    });

    it("denies a manager from deleting — delete needs isAdmin() specifically", async () => {
      await seed(`tenants/${TENANT_A}/projects/proj-1/wbs/task-3`, { title: "seed" });
      const manager = authedContext(testEnv, "manager-wbs-2", TENANT_A, "manager");
      await assertFails(
        deleteDoc(doc(manager.firestore(), `tenants/${TENANT_A}/projects/proj-1/wbs/task-3`))
      );
    });

    it("allows an admin to delete", async () => {
      await seed(`tenants/${TENANT_A}/projects/proj-1/wbs/task-4`, { title: "seed" });
      const admin = authedContext(testEnv, "admin-wbs-1", TENANT_A, "admin");
      await assertSucceeds(
        deleteDoc(doc(admin.firestore(), `tenants/${TENANT_A}/projects/proj-1/wbs/task-4`))
      );
    });
  });

  // Shape: read/create/update all open to any tenant member; delete gated to isAdmin() — same
  // shape as contractor_prescreens from the sensitive-data cluster.
  const hrSelfService = ["competency_passports", "skills_matrix"];

  for (const collection of hrSelfService) {
    it(`${collection}: any employee can create and update their own record, only admin can delete`, async () => {
      const employee = authedContext(testEnv, `employee-${collection}-1`, TENANT_A, "employee");
      const ref = doc(employee.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-1`);
      await assertSucceeds(setDoc(ref, { note: "seed" }));
      await assertSucceeds(updateDoc(ref, { note: "updated" }));
      await assertFails(deleteDoc(ref));

      const admin = authedContext(testEnv, `admin-${collection}-1`, TENANT_A, "admin");
      await assertSucceeds(
        deleteDoc(doc(admin.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-1`))
      );
    });
  }
});
