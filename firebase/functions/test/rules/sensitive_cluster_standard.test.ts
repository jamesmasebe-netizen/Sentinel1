/**
 * Wave 2c — firestore.rules matrix, sensitive-data cluster, part 1: the 7 collections sharing the
 * "standard" shape for this cluster — read open to any tenant member, create/update gated to
 * isManager() || isSheqOfficer(), delete gated to isAdmin(). The 5 collections with genuinely
 * role-gated READ access or other distinctive shapes (medical_records, coida_claims,
 * coida_compliance_checklist, contractor_documents, contractor_prescreens) get hand-written
 * coverage in sensitive_cluster_distinctive.test.ts instead.
 */
import { assertFails, assertSucceeds, RulesTestEnvironment } from "@firebase/rules-unit-testing";
import { deleteDoc, doc, getDoc, setDoc } from "firebase/firestore";
import { authedContext, getTestEnv, TENANT_A, TENANT_B } from "../helpers/rules_test_env";

describe("firestore.rules — sensitive-data cluster: standard-shape collections (Wave 2c)", () => {
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

  // Both compliance spellings (F-108/F-109) — declared separately in firestore.rules, tested
  // separately here since a copy-paste drift between the two declarations would otherwise go
  // unnoticed. first_aid_log (singular) was a similar leftover-spelling safety net for F-104,
  // removed 2026-08-10 once confirmed zero code anywhere still reads/writes it — only the real
  // 'first_aid_logs' spelling remains.
  const standardShape = [
    "hygiene_surveys",
    "first_aid_logs",
    "safety_file_submissions",
    "contractor_safety_files",
    "compliance_docs",
    "compliance_documents",
  ];

  for (const collection of standardShape) {
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

    it(`${collection}: read is NOT role-gated — a plain employee can read, but a cross-tenant user cannot`, async () => {
      await seed(`tenants/${TENANT_A}/${collection}/${collection}-read`, { note: "seed" });
      const employee = authedContext(testEnv, `employee-${collection}-2`, TENANT_A, "employee");
      const employeeRef = doc(employee.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-read`);
      // A plain employee's read here should NOT be denied (unlike medical_records/coida_* in the
      // distinctive file) — this collection's read has no role gate, only tenant membership.
      await assertSucceeds(getDoc(employeeRef));

      const outsider = authedContext(testEnv, `outsider-${collection}-1`, TENANT_B, "admin");
      await assertFails(
        getDoc(doc(outsider.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-read`))
      );
    });
  }
});
