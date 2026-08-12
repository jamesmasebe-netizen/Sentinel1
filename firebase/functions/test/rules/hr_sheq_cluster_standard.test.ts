/**
 * Wave 2c — firestore.rules matrix, HR/SHEQ cluster, part 1: the 10 collections sharing one of
 * three "standard" shapes (read: any tenant member; create/update: gated by role; delete:
 * isAdmin()). The 6 collections with genuinely distinct role combinations (bbs_observations,
 * findings, loto_events, enrollments, hazards, safety_flashes) get explicit, hand-written
 * coverage in hr_sheq_cluster_distinctive.test.ts instead of being forced into this table.
 *
 * 2026-08-12: 'training_enrollments' (previously manager-or-sheq-gated) unified onto
 * 'enrollments' — a separate, always fully-open-to-any-tenant-member collection (see
 * hr_sheq_cluster_distinctive.test.ts) — dropped from this list accordingly.
 *
 * Binding rule (see TEST_STRATEGY.md §7): call `.firestore()` at most once per context object,
 * ever — calling it twice throws a deterministic "already started" SDK error. Every context here
 * uses a globally-unique uid and is used for exactly one `.firestore()` call.
 */
import { assertFails, assertSucceeds, RulesTestEnvironment } from "@firebase/rules-unit-testing";
import { deleteDoc, doc, setDoc } from "firebase/firestore";
import { authedContext, getTestEnv, TENANT_A, TENANT_B } from "../helpers/rules_test_env";

describe("firestore.rules — HR/SHEQ cluster: standard-shape collections (Wave 2c)", () => {
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

  // Shape A: create/update gated to isManager(), delete to isAdmin().
  const managerGated = ["employees", "ppe_inventory"];
  // Shape B: create/update gated to isSheqOfficer(), delete to isAdmin().
  const sheqGated = ["permits", "capas", "dynamic_risk_assessments"];
  // Shape C: create/update gated to isManager() || isSheqOfficer(), delete to isAdmin().
  const managerOrSheqGated = [
    "training_records",
    "contractor_inductions",
    "ppe_compliance",
    "courses",
    "toolbox_talks",
  ];

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

    it(`${collection}: denies a cross-tenant user from reading or creating`, async () => {
      await seed(`tenants/${TENANT_A}/${collection}/${collection}-cross`, { note: "seed" });
      const outsider = authedContext(testEnv, `outsider-${collection}-1`, TENANT_B, "admin");
      await assertFails(
        setDoc(doc(outsider.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-cross`), {
          note: "cross-tenant write attempt",
        })
      );
    });
  }

  for (const collection of sheqGated) {
    it(`${collection}: sheq_officer can create, employee cannot, admin can delete, sheq_officer cannot delete`, async () => {
      const officer = authedContext(testEnv, `officer-${collection}-1`, TENANT_A, "sheq_officer");
      const officerRef = doc(officer.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-b`);
      await assertSucceeds(setDoc(officerRef, { note: "seed" }));
      await assertFails(deleteDoc(officerRef));

      const employee = authedContext(testEnv, `employee-${collection}-2`, TENANT_A, "employee");
      await assertFails(
        setDoc(doc(employee.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-deny2`), {
          note: "should be denied",
        })
      );

      const admin = authedContext(testEnv, `admin-${collection}-2`, TENANT_A, "admin");
      await assertSucceeds(
        deleteDoc(doc(admin.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-b`))
      );
    });

    it(`${collection}: a plain manager (no sheq role) cannot create`, async () => {
      const manager = authedContext(testEnv, `manager-only-${collection}-1`, TENANT_A, "manager");
      await assertFails(
        setDoc(doc(manager.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-mgr-deny`), {
          note: "manager alone is not sheq_officer",
        })
      );
    });
  }

  for (const collection of managerOrSheqGated) {
    it(`${collection}: manager OR sheq_officer can create, plain employee cannot, admin can delete`, async () => {
      const manager = authedContext(testEnv, `manager-${collection}-3`, TENANT_A, "manager");
      await assertSucceeds(
        setDoc(doc(manager.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-mgr`), {
          note: "seed",
        })
      );

      const officer = authedContext(testEnv, `officer-${collection}-3`, TENANT_A, "sheq_officer");
      await assertSucceeds(
        setDoc(doc(officer.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-officer`), {
          note: "seed",
        })
      );

      const employee = authedContext(testEnv, `employee-${collection}-3`, TENANT_A, "employee");
      await assertFails(
        setDoc(doc(employee.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-deny3`), {
          note: "should be denied",
        })
      );

      const admin = authedContext(testEnv, `admin-${collection}-3`, TENANT_A, "admin");
      await assertSucceeds(
        deleteDoc(doc(admin.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-mgr`))
      );
    });
  }
});
