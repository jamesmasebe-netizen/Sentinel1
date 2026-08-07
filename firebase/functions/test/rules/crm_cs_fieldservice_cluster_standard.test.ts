/**
 * Wave 2c — firestore.rules matrix, CRM/Sales/CS/FieldService cluster, part 1: the 15 collections
 * sharing one of two standard shapes (confirmed by reading the real firestore.rules text
 * directly). The 3 genuinely distinctive collections (cs_tickets + its messages subcollection,
 * job_requisitions, job_applications) get hand-written coverage in
 * crm_cs_fieldservice_cluster_distinctive.test.ts instead — job_requisitions/job_applications also
 * have public, pre-authentication read/create cases covered in zzz_unauthenticated_access.test.ts
 * per that file's own stated convention (see its header comment).
 *
 * Binding rule (see TEST_STRATEGY.md §7): call `.firestore()` at most once per context object,
 * ever. Every context here uses a globally-unique uid and exactly one `.firestore()` call.
 */
import { assertFails, assertSucceeds, RulesTestEnvironment } from "@firebase/rules-unit-testing";
import { deleteDoc, doc, getDoc, setDoc } from "firebase/firestore";
import { authedContext, getTestEnv, TENANT_A, TENANT_B } from "../helpers/rules_test_env";

describe("firestore.rules — CRM/Sales/CS/FieldService cluster: standard-shape collections (Wave 2c)", () => {
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

  // Shape A: create/update open to any tenant member (no role gate), delete gated to isAdmin().
  const openWrite = [
    "leads",
    "opportunities",
    "accounts",
    "contacts",
    "customerJourneys",
    "activities",
    "deals",
    "sla_kpi_instances", // "System/Cloud Function-generated" per the source comment, but same shape
  ];

  // Shape B: create/update gated to isManager(), delete to isAdmin() — same shape as the
  // Finance/SCM cluster's managerGated collections.
  const managerGated = [
    "quotes",
    "cs_assets",
    "cs_knowledge_articles",
    "route_plans",
    "customer_assets",
    "iot_devices",
    "campaigns",
  ];

  for (const collection of openWrite) {
    it(`${collection}: any tenant member can create (no role gate), only admin can delete`, async () => {
      const employee = authedContext(testEnv, `employee-${collection}-1`, TENANT_A, "employee");
      const employeeRef = doc(employee.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-a`);
      await assertSucceeds(setDoc(employeeRef, { note: "seed" }));
      await assertFails(deleteDoc(employeeRef));

      const admin = authedContext(testEnv, `admin-${collection}-1`, TENANT_A, "admin");
      await assertSucceeds(
        deleteDoc(doc(admin.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-a`))
      );
    });

    it(`${collection}: denies a cross-tenant user from reading or creating`, async () => {
      await seed(`tenants/${TENANT_A}/${collection}/${collection}-cross`, { note: "seed" });
      const outsider = authedContext(testEnv, `outsider-${collection}-1`, TENANT_B, "employee");
      const outsiderFirestore = outsider.firestore();
      await assertFails(getDoc(doc(outsiderFirestore, `tenants/${TENANT_A}/${collection}/${collection}-cross`)));
      await assertFails(
        setDoc(doc(outsiderFirestore, `tenants/${TENANT_A}/${collection}/${collection}-cross2`), {
          note: "cross-tenant write attempt",
        })
      );
    });
  }

  for (const collection of managerGated) {
    it(`${collection}: manager can create, employee cannot, admin can delete, manager cannot delete`, async () => {
      const manager = authedContext(testEnv, `manager-${collection}-1`, TENANT_A, "manager");
      const managerRef = doc(manager.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-a`);
      await assertSucceeds(setDoc(managerRef, { note: "seed" }));
      await assertFails(deleteDoc(managerRef));

      const employee = authedContext(testEnv, `employee-${collection}-1`, TENANT_A, "employee");
      await assertFails(
        setDoc(doc(employee.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-deny`), {
          note: "should be denied",
        })
      );

      const admin = authedContext(testEnv, `admin-${collection}-1`, TENANT_A, "admin");
      await assertSucceeds(
        deleteDoc(doc(admin.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-a`))
      );
    });

    it(`${collection}: read is NOT role-gated — a plain employee can read, but a cross-tenant user cannot`, async () => {
      await seed(`tenants/${TENANT_A}/${collection}/${collection}-read`, { note: "seed" });
      const employee = authedContext(testEnv, `employee-${collection}-2`, TENANT_A, "employee");
      await assertSucceeds(
        getDoc(doc(employee.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-read`))
      );

      const outsider = authedContext(testEnv, `outsider-${collection}-1`, TENANT_B, "admin");
      await assertFails(
        getDoc(doc(outsider.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-read`))
      );
    });
  }
});
