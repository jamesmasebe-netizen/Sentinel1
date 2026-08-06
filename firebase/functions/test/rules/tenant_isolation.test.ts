/**
 * T1-005 — firestore.rules harness + smoke coverage.
 *
 * Proves the emulator-backed rules-testing harness (test/helpers/rules_test_env.ts) works
 * end-to-end, and exercises the four rules helpers — belongsToTenant(), isAdmin(), isManager(),
 * isSheqOfficer() — via allow+deny pairs on one finance collection (`fin_journal_headers`) and one
 * safety collection (`incidents`), per TEST_BACKLOG.md's T1-005 coverage target and
 * TEST_STRATEGY.md §7's binding "every rules test asserts both directions" rule.
 *
 * This is a deliberate 2-collection smoke sample, not the full 116-match-block matrix — that's
 * Tier 2 scope (see TEST_STRATEGY.md §8 / TEST_BACKLOG.md's Tier 2 section).
 */
import { assertFails, assertSucceeds, RulesTestEnvironment } from "@firebase/rules-unit-testing";
import { deleteDoc, doc, getDoc, setDoc, updateDoc } from "firebase/firestore";
import { authedContext, getTestEnv, TENANT_A, TENANT_B } from "../helpers/rules_test_env";

describe("firestore.rules — tenant isolation smoke coverage (T1-005)", () => {
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

  /** Seeds a doc bypassing rules entirely, for tests that need pre-existing data to read/update. */
  async function seed(pathStr: string, data: Record<string, unknown>) {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), pathStr), data);
    });
  }

  describe("fin_journal_headers — belongsToTenant() + isManager() + isAdmin()", () => {
    it("allows a manager in-tenant to create and read a journal header", async () => {
      const manager = authedContext(testEnv, "manager-1", TENANT_A, "manager");
      const ref = doc(manager.firestore(), `tenants/${TENANT_A}/fin_journal_headers/je-allow-1`);
      await assertSucceeds(
        setDoc(ref, { description: "balanced entry", total_debit: 100, total_credit: 100 })
      );
      await assertSucceeds(getDoc(ref));
    });

    it("denies a user from a different tenant from reading or writing", async () => {
      await seed(`tenants/${TENANT_A}/fin_journal_headers/je-deny-tenant`, { description: "seed" });

      const outsider = authedContext(testEnv, "outsider-1", TENANT_B, "manager");
      const ref = doc(outsider.firestore(), `tenants/${TENANT_A}/fin_journal_headers/je-deny-tenant`);
      await assertFails(getDoc(ref));
      await assertFails(setDoc(ref, { description: "cross-tenant write attempt" }));
    });

    it("denies a same-tenant user without manager/admin role from creating a header", async () => {
      const worker = authedContext(testEnv, "worker-1", TENANT_A, "employee");
      const ref = doc(worker.firestore(), `tenants/${TENANT_A}/fin_journal_headers/je-deny-role`);
      await assertFails(setDoc(ref, { description: "should be denied — role" }));
    });

    it("allows an admin to delete a journal header in their tenant", async () => {
      await seed(`tenants/${TENANT_A}/fin_journal_headers/je-admin-delete`, { description: "seed" });
      const admin = authedContext(testEnv, "admin-1", TENANT_A, "admin");
      await assertSucceeds(
        deleteDoc(doc(admin.firestore(), `tenants/${TENANT_A}/fin_journal_headers/je-admin-delete`))
      );
    });

    it("denies a manager (non-admin) from deleting a journal header", async () => {
      await seed(`tenants/${TENANT_A}/fin_journal_headers/je-manager-delete-deny`, {
        description: "seed",
      });
      const manager = authedContext(testEnv, "manager-2", TENANT_A, "manager");
      await assertFails(
        deleteDoc(
          doc(manager.firestore(), `tenants/${TENANT_A}/fin_journal_headers/je-manager-delete-deny`)
        )
      );
    });
  });

  describe("incidents — belongsToTenant() + isSheqOfficer()", () => {
    it("allows any authenticated tenant member to create an incident (no role gate)", async () => {
      const worker = authedContext(testEnv, "worker-2", TENANT_A, "employee");
      const ref = doc(worker.firestore(), `tenants/${TENANT_A}/incidents/inc-allow-1`);
      await assertSucceeds(setDoc(ref, { description: "near miss", severity: "Low" }));
    });

    it("denies a user from a different tenant from creating or reading an incident", async () => {
      await seed(`tenants/${TENANT_A}/incidents/inc-deny-tenant`, { description: "seed" });

      const outsider = authedContext(testEnv, "outsider-2", TENANT_B, "admin");
      const ref = doc(outsider.firestore(), `tenants/${TENANT_A}/incidents/inc-deny-tenant`);
      await assertFails(getDoc(ref));
      await assertFails(setDoc(ref, { description: "cross-tenant write attempt" }));
    });

    it("allows a sheq_officer in-tenant to update an incident", async () => {
      await seed(`tenants/${TENANT_A}/incidents/inc-officer-update`, {
        description: "seed",
        status: "open",
      });
      const officer = authedContext(testEnv, "officer-1", TENANT_A, "sheq_officer");
      await assertSucceeds(
        updateDoc(doc(officer.firestore(), `tenants/${TENANT_A}/incidents/inc-officer-update`), {
          status: "closed",
        })
      );
    });

    it("denies a same-tenant user without sheq/manager/admin role from updating an incident", async () => {
      await seed(`tenants/${TENANT_A}/incidents/inc-worker-update-deny`, {
        description: "seed",
        status: "open",
      });
      const worker = authedContext(testEnv, "worker-3", TENANT_A, "employee");
      await assertFails(
        updateDoc(doc(worker.firestore(), `tenants/${TENANT_A}/incidents/inc-worker-update-deny`), {
          status: "closed",
        })
      );
    });
  });
});
