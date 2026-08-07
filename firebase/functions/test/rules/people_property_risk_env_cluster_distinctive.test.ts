/**
 * Wave 2c — firestore.rules matrix, People/Property/Risk/Environment cluster, part 2: the 4
 * collections with genuinely distinctive shapes:
 *
 * - work_orders: standard manager-gated shape, but tested explicitly (rather than folded into the
 *   standard file's loop) because of its tasks subcollection, which needs a real parent doc path.
 * - environmental_spills: create is open to any employee ("Anyone can report a spill" per the
 *   source comment), but update AND delete are BOTH isSheqOfficer()-gated with no separate
 *   admin-only delete tier — same shape as HR/SHEQ's bbs_observations.
 * - actionItems: create is open to any employee ("Anyone can raise an action item"), update is
 *   isManager()-gated, delete is isAdmin()-gated — three different gates across three operations,
 *   same shape as cs_tickets from the CRM/CS cluster.
 * - integrations: the only collection in the whole schema (besides the tenant root and
 *   subscription) where READ itself is admin-only, not just write — holds API keys/webhook
 *   secrets per the source comment, so even a manager cannot read it.
 */
import { assertFails, assertSucceeds, RulesTestEnvironment } from "@firebase/rules-unit-testing";
import { deleteDoc, doc, getDoc, setDoc, updateDoc } from "firebase/firestore";
import { authedContext, getTestEnv, TENANT_A } from "../helpers/rules_test_env";

describe("firestore.rules — People/Property/Risk/Environment cluster: distinctive-shape collections (Wave 2c)", () => {
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

  describe("work_orders/{workOrderId}/tasks — inherits the parent's manager-gated shape", () => {
    it("allows a manager to create a task, denies an employee, allows an admin to delete", async () => {
      await seed(`tenants/${TENANT_A}/work_orders/wo-1`, { note: "seed" });
      const manager = authedContext(testEnv, "manager-wotask-1", TENANT_A, "manager");
      const taskRef = doc(manager.firestore(), `tenants/${TENANT_A}/work_orders/wo-1/tasks/task-1`);
      await assertSucceeds(setDoc(taskRef, { note: "seed" }));
      await assertFails(deleteDoc(taskRef));

      const employee = authedContext(testEnv, "employee-wotask-1", TENANT_A, "employee");
      await assertFails(
        setDoc(doc(employee.firestore(), `tenants/${TENANT_A}/work_orders/wo-1/tasks/task-deny`), {
          note: "should be denied",
        })
      );

      const admin = authedContext(testEnv, "admin-wotask-1", TENANT_A, "admin");
      await assertSucceeds(
        deleteDoc(doc(admin.firestore(), `tenants/${TENANT_A}/work_orders/wo-1/tasks/task-1`))
      );
    });
  });

  describe("environmental_spills — open create, but update+delete are BOTH isSheqOfficer()-gated (no admin-only delete tier)", () => {
    it("allows any employee to report a spill", async () => {
      const employee = authedContext(testEnv, "employee-spill-1", TENANT_A, "employee");
      await assertSucceeds(
        setDoc(doc(employee.firestore(), `tenants/${TENANT_A}/environmental_spills/spill-1`), {
          note: "seed",
        })
      );
    });

    it("denies a plain manager (non-sheq) from updating or deleting", async () => {
      await seed(`tenants/${TENANT_A}/environmental_spills/spill-2`, { note: "seed" });
      const manager = authedContext(testEnv, "manager-spill-1", TENANT_A, "manager");
      const ref = doc(manager.firestore(), `tenants/${TENANT_A}/environmental_spills/spill-2`);
      await assertFails(updateDoc(ref, { note: "should be denied" }));
      await assertFails(deleteDoc(ref));
    });

    it("allows a sheq_officer to update and delete", async () => {
      await seed(`tenants/${TENANT_A}/environmental_spills/spill-3`, { note: "seed" });
      const officer = authedContext(testEnv, "officer-spill-1", TENANT_A, "sheq_officer");
      const ref = doc(officer.firestore(), `tenants/${TENANT_A}/environmental_spills/spill-3`);
      await assertSucceeds(updateDoc(ref, { note: "updated" }));
      await assertSucceeds(deleteDoc(ref));
    });
  });

  describe("actionItems — open create, isManager()-gated update, isAdmin()-gated delete", () => {
    it("allows any employee to raise an action item", async () => {
      const employee = authedContext(testEnv, "employee-actionitem-1", TENANT_A, "employee");
      await assertSucceeds(
        setDoc(doc(employee.firestore(), `tenants/${TENANT_A}/actionItems/item-1`), {
          note: "seed",
        })
      );
    });

    it("denies a plain employee from updating — update needs isManager()", async () => {
      await seed(`tenants/${TENANT_A}/actionItems/item-2`, { note: "seed" });
      const employee = authedContext(testEnv, "employee-actionitem-2", TENANT_A, "employee");
      await assertFails(
        updateDoc(doc(employee.firestore(), `tenants/${TENANT_A}/actionItems/item-2`), {
          note: "should be denied",
        })
      );
    });

    it("allows a manager to update but not delete; only an admin can delete", async () => {
      await seed(`tenants/${TENANT_A}/actionItems/item-3`, { note: "seed" });
      const manager = authedContext(testEnv, "manager-actionitem-1", TENANT_A, "manager");
      const ref = doc(manager.firestore(), `tenants/${TENANT_A}/actionItems/item-3`);
      await assertSucceeds(updateDoc(ref, { note: "updated" }));
      await assertFails(deleteDoc(ref));

      const admin = authedContext(testEnv, "admin-actionitem-1", TENANT_A, "admin");
      await assertSucceeds(
        deleteDoc(doc(admin.firestore(), `tenants/${TENANT_A}/actionItems/item-3`))
      );
    });
  });

  describe("integrations — admin-only for BOTH read and write (API keys/webhook secrets)", () => {
    it("denies a plain employee AND a manager from reading", async () => {
      await seed(`tenants/${TENANT_A}/integrations/stripe`, { apiKey: "secret" });
      const employee = authedContext(testEnv, "employee-integration-1", TENANT_A, "employee");
      await assertFails(
        getDoc(doc(employee.firestore(), `tenants/${TENANT_A}/integrations/stripe`))
      );

      const manager = authedContext(testEnv, "manager-integration-1", TENANT_A, "manager");
      await assertFails(
        getDoc(doc(manager.firestore(), `tenants/${TENANT_A}/integrations/stripe`))
      );
    });

    it("allows an admin to read and write", async () => {
      const admin = authedContext(testEnv, "admin-integration-1", TENANT_A, "admin");
      const ref = doc(admin.firestore(), `tenants/${TENANT_A}/integrations/webhook`);
      await assertSucceeds(setDoc(ref, { apiKey: "secret" }));
      await assertSucceeds(getDoc(ref));
    });
  });
});
