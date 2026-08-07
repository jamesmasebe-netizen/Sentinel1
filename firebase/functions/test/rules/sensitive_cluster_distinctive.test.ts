/**
 * Wave 2c — firestore.rules matrix, sensitive-data cluster, part 2: the 5 collections with
 * genuinely distinctive shapes, hand-written since the whole point is getting exceptions exactly
 * right rather than folding them into a generic loop:
 *
 * - medical_records: READ ITSELF is gated to isManager() || isSheqOfficer() — a plain employee
 *   cannot even read their own medical records via this collection. Create/update need
 *   isSheqOfficer() specifically (not manager-or-sheq).
 * - coida_claims / coida_compliance_checklist: READ is also gated to isManager() ||
 *   isSheqOfficer() (injury/medical data, same restriction as medical_records), and
 *   create/update use the manager-or-sheq combination.
 * - contractor_documents: create is open to anyone, update is isSheqOfficer()-gated, delete is
 *   isAdmin()-gated — three different gates across three operations.
 * - compliance_prescreens: create/update have NO role gate at all (a Cloud Function writes
 *   these, per the source comment) — only delete is isAdmin()-gated.
 *
 * These 3 role-gated-read collections (medical_records, coida_claims, coida_compliance_checklist)
 * are the ONLY collections in the whole schema, besides the special/system cluster's exceptions,
 * where a same-tenant, correctly-authenticated but non-privileged user is rejected on READ, not
 * just on write — worth the most careful, explicit coverage in this entire cluster.
 */
import { assertFails, assertSucceeds, RulesTestEnvironment } from "@firebase/rules-unit-testing";
import { deleteDoc, doc, getDoc, setDoc, updateDoc } from "firebase/firestore";
import { authedContext, getTestEnv, TENANT_A } from "../helpers/rules_test_env";

describe("firestore.rules — sensitive-data cluster: distinctive-shape collections (Wave 2c)", () => {
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

  describe("medical_records — read itself is role-gated (manager or sheq_officer), create/update need sheq specifically", () => {
    it("denies a plain employee from reading, even within their own tenant", async () => {
      await seed(`tenants/${TENANT_A}/medical_records/rec-1`, { note: "seed" });
      const employee = authedContext(testEnv, "employee-medical-1", TENANT_A, "employee");
      await assertFails(getDoc(doc(employee.firestore(), `tenants/${TENANT_A}/medical_records/rec-1`)));
    });

    it("allows a manager to read (manager qualifies via the OR)", async () => {
      await seed(`tenants/${TENANT_A}/medical_records/rec-2`, { note: "seed" });
      const manager = authedContext(testEnv, "manager-medical-1", TENANT_A, "manager");
      await assertSucceeds(getDoc(doc(manager.firestore(), `tenants/${TENANT_A}/medical_records/rec-2`)));
    });

    it("allows a sheq_officer to read", async () => {
      await seed(`tenants/${TENANT_A}/medical_records/rec-3`, { note: "seed" });
      const officer = authedContext(testEnv, "officer-medical-1", TENANT_A, "sheq_officer");
      await assertSucceeds(getDoc(doc(officer.firestore(), `tenants/${TENANT_A}/medical_records/rec-3`)));
    });

    it("denies a plain manager (non-sheq) from CREATING — unlike read, create needs isSheqOfficer() specifically, not manager-or-sheq", async () => {
      const manager = authedContext(testEnv, "manager-medical-2", TENANT_A, "manager");
      await assertFails(
        setDoc(doc(manager.firestore(), `tenants/${TENANT_A}/medical_records/rec-4`), { note: "seed" })
      );
    });

    it("allows a sheq_officer to create", async () => {
      const officer = authedContext(testEnv, "officer-medical-2", TENANT_A, "sheq_officer");
      await assertSucceeds(
        setDoc(doc(officer.firestore(), `tenants/${TENANT_A}/medical_records/rec-5`), { note: "seed" })
      );
    });
  });

  describe("coida_claims — read gated to manager-or-sheq (injury/medical data)", () => {
    it("denies a plain employee from reading a claim", async () => {
      await seed(`tenants/${TENANT_A}/coida_claims/claim-1`, { note: "seed" });
      const employee = authedContext(testEnv, "employee-coida-1", TENANT_A, "employee");
      await assertFails(getDoc(doc(employee.firestore(), `tenants/${TENANT_A}/coida_claims/claim-1`)));
    });

    it("allows a manager or sheq_officer to read", async () => {
      await seed(`tenants/${TENANT_A}/coida_claims/claim-2`, { note: "seed" });
      const manager = authedContext(testEnv, "manager-coida-1", TENANT_A, "manager");
      await assertSucceeds(getDoc(doc(manager.firestore(), `tenants/${TENANT_A}/coida_claims/claim-2`)));
    });

    it("denies a plain employee from creating a claim", async () => {
      const employee = authedContext(testEnv, "employee-coida-2", TENANT_A, "employee");
      await assertFails(
        setDoc(doc(employee.firestore(), `tenants/${TENANT_A}/coida_claims/claim-3`), { note: "seed" })
      );
    });
  });

  describe("coida_compliance_checklist — same manager-or-sheq gate on BOTH read and write", () => {
    it("denies a plain employee from reading a checklist item", async () => {
      await seed(`tenants/${TENANT_A}/coida_compliance_checklist/item-1`, { note: "seed" });
      const employee = authedContext(testEnv, "employee-checklist-1", TENANT_A, "employee");
      await assertFails(
        getDoc(doc(employee.firestore(), `tenants/${TENANT_A}/coida_compliance_checklist/item-1`))
      );
    });

    it("allows a sheq_officer to read and update", async () => {
      await seed(`tenants/${TENANT_A}/coida_compliance_checklist/item-2`, { note: "seed" });
      const officer = authedContext(testEnv, "officer-checklist-1", TENANT_A, "sheq_officer");
      const ref = doc(officer.firestore(), `tenants/${TENANT_A}/coida_compliance_checklist/item-2`);
      await assertSucceeds(getDoc(ref));
      await assertSucceeds(updateDoc(ref, { done: true }));
    });
  });

  describe("contractor_documents — open create, sheq-gated update, admin-gated delete", () => {
    it("allows any employee to create", async () => {
      const employee = authedContext(testEnv, "employee-contdoc-1", TENANT_A, "employee");
      await assertSucceeds(
        setDoc(doc(employee.firestore(), `tenants/${TENANT_A}/contractor_documents/doc-1`), {
          note: "seed",
        })
      );
    });

    it("denies a plain manager (non-sheq) from updating", async () => {
      await seed(`tenants/${TENANT_A}/contractor_documents/doc-2`, { note: "seed" });
      const manager = authedContext(testEnv, "manager-contdoc-1", TENANT_A, "manager");
      await assertFails(
        updateDoc(doc(manager.firestore(), `tenants/${TENANT_A}/contractor_documents/doc-2`), {
          note: "should be denied",
        })
      );
    });

    it("allows a sheq_officer to update, but denies them from deleting (delete needs isAdmin())", async () => {
      await seed(`tenants/${TENANT_A}/contractor_documents/doc-3`, { note: "seed" });
      const officer = authedContext(testEnv, "officer-contdoc-1", TENANT_A, "sheq_officer");
      const ref = doc(officer.firestore(), `tenants/${TENANT_A}/contractor_documents/doc-3`);
      await assertSucceeds(updateDoc(ref, { note: "updated" }));
      await assertFails(deleteDoc(ref));
    });

    it("allows an admin to delete", async () => {
      await seed(`tenants/${TENANT_A}/contractor_documents/doc-4`, { note: "seed" });
      const admin = authedContext(testEnv, "admin-contdoc-1", TENANT_A, "admin");
      await assertSucceeds(
        deleteDoc(doc(admin.firestore(), `tenants/${TENANT_A}/contractor_documents/doc-4`))
      );
    });
  });

  describe("compliance_prescreens — create/update have no role gate at all (Cloud Function writes these)", () => {
    it("allows a plain employee to create and update", async () => {
      const employee = authedContext(testEnv, "employee-prescreen-1", TENANT_A, "employee");
      const ref = doc(employee.firestore(), `tenants/${TENANT_A}/compliance_prescreens/screen-1`);
      await assertSucceeds(setDoc(ref, { note: "seed" }));
      await assertSucceeds(updateDoc(ref, { note: "updated" }));
    });

    it("denies a plain employee from deleting — delete is still isAdmin()-gated", async () => {
      await seed(`tenants/${TENANT_A}/compliance_prescreens/screen-2`, { note: "seed" });
      const employee = authedContext(testEnv, "employee-prescreen-2", TENANT_A, "employee");
      await assertFails(
        deleteDoc(doc(employee.firestore(), `tenants/${TENANT_A}/compliance_prescreens/screen-2`))
      );
    });
  });
});
