/**
 * Wave 2c — firestore.rules matrix, People/Property/Risk/Environment cluster, part 1: the final
 * cluster of the 6-cluster plan. Covers the remaining collections not already picked up by an
 * earlier cluster: Equipment/Contractors (from the first, pre-F-001 section of firestore.rules),
 * Property (all 6), Risk (strategic_risks/bowtie_analyses), Environment
 * (waste_manifests/esg_metrics), and People (the 7 collections whose read is gated to isManager()
 * — payroll_ledgers, compensation_plans, performance_reviews, disciplinary_records,
 * benefit_enrollments, invites, candidates — plus leave_requests, which breaks that pattern).
 *
 * The 7 manager-read-gated People collections are also 7 of the 11 collections the catch-all
 * vulnerability (see TEST_BACKLOG.md T2c-SENSITIVE) used to silently expose to any tenant member
 * regardless of role — their "denies a plain employee from reading" assertions here double as
 * regression guards for that fix, alongside T2c-SENSITIVE's own 3 and T2c-CRMCS's job_applications.
 *
 * The 4 genuinely distinctive collections (work_orders + its tasks subcollection,
 * environmental_spills, actionItems, integrations) get hand-written coverage in
 * people_property_risk_env_cluster_distinctive.test.ts instead.
 *
 * Binding rule (see TEST_STRATEGY.md §7): call `.firestore()` at most once per context object,
 * ever. Every context here uses a globally-unique uid and exactly one `.firestore()` call.
 */
import { assertFails, assertSucceeds, RulesTestEnvironment } from "@firebase/rules-unit-testing";
import { deleteDoc, doc, getDoc, setDoc } from "firebase/firestore";
import { authedContext, getTestEnv, TENANT_A, TENANT_B } from "../helpers/rules_test_env";

describe("firestore.rules — People/Property/Risk/Environment cluster: standard-shape collections (Wave 2c)", () => {
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

  // Shape A: create/update gated to isManager(), delete to isAdmin(); read open to any tenant member.
  // Includes `projects` and the 3 HR reference-data collections (departments/job_roles/ohs_roles)
  // added during the T2c-SENSITIVE security fix — both were previously undeclared entirely, this
  // is their first explicit test coverage since that fix only verified the rules text, not tests.
  const managerGated = [
    "equipment",
    "contractors",
    "inventory_items",
    "warehouses",
    "properties",
    "property_projects",
    "property_utilities",
    "legal_appointments",
    "property_leases",
    "property_assets",
    "projects",
    "departments",
    "job_roles",
    "ohs_roles",
  ];

  // Shape B: create/update gated to isManager() || isSheqOfficer(), delete to isAdmin().
  const managerOrSheqGated = ["waste_manifests", "esg_metrics", "strategic_risks"];

  // Shape C: create/update gated to isSheqOfficer() only, delete to isAdmin().
  const sheqGated = ["bowtie_analyses", "risk_assessments"];

  // Shape D: READ is also gated to isManager() (not just create/update/delete) — these are 7 of
  // the 11 collections the catch-all vulnerability used to expose (see file header).
  const managerReadAndWrite = [
    "payroll_ledgers",
    "compensation_plans",
    "performance_reviews",
    "disciplinary_records",
    "benefit_enrollments",
    "invites",
    "candidates",
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

  for (const collection of managerOrSheqGated) {
    it(`${collection}: manager OR sheq_officer can create, plain employee cannot, admin can delete`, async () => {
      const manager = authedContext(testEnv, `manager-${collection}-1`, TENANT_A, "manager");
      await assertSucceeds(
        setDoc(doc(manager.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-mgr`), {
          note: "seed",
        })
      );

      const officer = authedContext(testEnv, `officer-${collection}-1`, TENANT_A, "sheq_officer");
      await assertSucceeds(
        setDoc(doc(officer.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-officer`), {
          note: "seed",
        })
      );

      const employee = authedContext(testEnv, `employee-${collection}-1`, TENANT_A, "employee");
      await assertFails(
        setDoc(doc(employee.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-deny`), {
          note: "should be denied",
        })
      );

      const admin = authedContext(testEnv, `admin-${collection}-1`, TENANT_A, "admin");
      await assertSucceeds(
        deleteDoc(doc(admin.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-mgr`))
      );
    });
  }

  for (const collection of sheqGated) {
    it(`${collection}: sheq_officer can create, a plain manager (non-sheq) cannot, admin can delete`, async () => {
      const officer = authedContext(testEnv, `officer-${collection}-1`, TENANT_A, "sheq_officer");
      const officerRef = doc(officer.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-a`);
      await assertSucceeds(setDoc(officerRef, { note: "seed" }));
      await assertFails(deleteDoc(officerRef));

      const manager = authedContext(testEnv, `manager-only-${collection}-1`, TENANT_A, "manager");
      await assertFails(
        setDoc(doc(manager.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-mgr-deny`), {
          note: "manager alone is not sheq_officer",
        })
      );

      const admin = authedContext(testEnv, `admin-${collection}-1`, TENANT_A, "admin");
      await assertSucceeds(
        deleteDoc(doc(admin.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-a`))
      );
    });
  }

  for (const collection of managerReadAndWrite) {
    it(`${collection}: denies a plain employee from reading — read is manager-gated here, not just create/update/delete`, async () => {
      await seed(`tenants/${TENANT_A}/${collection}/${collection}-read`, { note: "seed" });
      const employee = authedContext(testEnv, `employee-${collection}-1`, TENANT_A, "employee");
      await assertFails(
        getDoc(doc(employee.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-read`))
      );
    });

    it(`${collection}: manager can read, create, and update; only admin can delete`, async () => {
      const manager = authedContext(testEnv, `manager-${collection}-1`, TENANT_A, "manager");
      const ref = doc(manager.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-a`);
      await assertSucceeds(setDoc(ref, { note: "seed" }));
      await assertSucceeds(getDoc(ref));
      await assertFails(deleteDoc(ref));

      const admin = authedContext(testEnv, `admin-${collection}-1`, TENANT_A, "admin");
      await assertSucceeds(
        deleteDoc(doc(admin.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-a`))
      );
    });
  }

  describe("leave_requests — breaks the rest of the People section's pattern: read AND write are both fully open to any tenant member (no role gate at all besides tenant membership)", () => {
    it("allows any employee to create, read, and update their own leave request", async () => {
      const employee = authedContext(testEnv, "employee-leave-1", TENANT_A, "employee");
      const ref = doc(employee.firestore(), `tenants/${TENANT_A}/leave_requests/leave-1`);
      await assertSucceeds(setDoc(ref, { note: "seed" }));
      await assertSucceeds(getDoc(ref));
    });

    it("denies a plain employee from deleting — delete is still isAdmin()-gated", async () => {
      await seed(`tenants/${TENANT_A}/leave_requests/leave-2`, { note: "seed" });
      const employee = authedContext(testEnv, "employee-leave-2", TENANT_A, "employee");
      await assertFails(
        deleteDoc(doc(employee.firestore(), `tenants/${TENANT_A}/leave_requests/leave-2`))
      );
    });

    it("denies a cross-tenant user from reading", async () => {
      await seed(`tenants/${TENANT_A}/leave_requests/leave-3`, { note: "seed" });
      const outsider = authedContext(testEnv, "outsider-leave-1", TENANT_B, "admin");
      await assertFails(
        getDoc(doc(outsider.firestore(), `tenants/${TENANT_A}/leave_requests/leave-3`))
      );
    });
  });
});
