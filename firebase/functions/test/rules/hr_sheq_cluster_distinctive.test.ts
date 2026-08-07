/**
 * Wave 2c — firestore.rules matrix, HR/SHEQ cluster, part 2: the 6 collections whose role
 * combinations don't match the "standard" shapes covered in hr_sheq_cluster_standard.test.ts —
 * each hand-written since the whole point is that these are exceptions worth getting exactly
 * right, not folding into a generic loop:
 *
 * - bbs_observations: create is open to anyone; update AND delete are both gated to
 *   isSheqOfficer() — there is no separate isAdmin()-only delete tier here, unlike every
 *   "standard" shape collection.
 * - findings: three distinct roles across three operations — create needs isSheqOfficer()
 *   specifically (not manager-or-sheq), update accepts isManager() OR isSheqOfficer(), delete
 *   needs isAdmin().
 * - loto_events: create is manager-or-sheq gated, but update AND delete are BOTH isAdmin()-gated
 *   (most collections only gate delete to admin; here update is admin-only too).
 * - enrollments: create/update have NO role gate at all (any tenant member), only delete is
 *   isAdmin()-gated.
 * - hazards: create is open to anyone ("anyone can report"), update is isSheqOfficer()-gated,
 *   delete is isAdmin()-gated — three different gates across three operations.
 * - safety_flashes: create is manager-or-sheq gated, delete is isAdmin()-gated, but there is NO
 *   `allow update` statement in this block AT ALL — update is implicitly denied for every role,
 *   including admin. Confirmed by reading the real firestore.rules file, not assumed.
 */
import { assertFails, assertSucceeds, RulesTestEnvironment } from "@firebase/rules-unit-testing";
import { deleteDoc, doc, setDoc, updateDoc } from "firebase/firestore";
import { authedContext, getTestEnv, TENANT_A } from "../helpers/rules_test_env";

describe("firestore.rules — HR/SHEQ cluster: distinctive-shape collections (Wave 2c)", () => {
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

  describe("bbs_observations — open create, sheq-gated update AND delete (no admin-only delete tier)", () => {
    it("allows any employee to create an observation", async () => {
      const employee = authedContext(testEnv, "employee-bbs-1", TENANT_A, "employee");
      await assertSucceeds(
        setDoc(doc(employee.firestore(), `tenants/${TENANT_A}/bbs_observations/obs-1`), {
          note: "near miss",
        })
      );
    });

    it("denies a plain manager (non-sheq) from updating or deleting", async () => {
      await seed(`tenants/${TENANT_A}/bbs_observations/obs-2`, { note: "seed" });
      const manager = authedContext(testEnv, "manager-bbs-1", TENANT_A, "manager");
      const ref = doc(manager.firestore(), `tenants/${TENANT_A}/bbs_observations/obs-2`);
      await assertFails(updateDoc(ref, { note: "updated" }));
      await assertFails(deleteDoc(ref));
    });

    it("allows a sheq_officer to update AND delete — there is no separate admin-only delete gate here", async () => {
      await seed(`tenants/${TENANT_A}/bbs_observations/obs-3`, { note: "seed" });
      const officer = authedContext(testEnv, "officer-bbs-1", TENANT_A, "sheq_officer");
      const ref = doc(officer.firestore(), `tenants/${TENANT_A}/bbs_observations/obs-3`);
      await assertSucceeds(updateDoc(ref, { note: "updated" }));
      await assertSucceeds(deleteDoc(ref));
    });
  });

  describe("findings — three distinct role gates across create/update/delete", () => {
    it("denies a plain manager (non-sheq) from creating — create needs isSheqOfficer() specifically", async () => {
      const manager = authedContext(testEnv, "manager-findings-1", TENANT_A, "manager");
      await assertFails(
        setDoc(doc(manager.firestore(), `tenants/${TENANT_A}/findings/finding-1`), { note: "seed" })
      );
    });

    it("allows a sheq_officer to create", async () => {
      const officer = authedContext(testEnv, "officer-findings-1", TENANT_A, "sheq_officer");
      await assertSucceeds(
        setDoc(doc(officer.firestore(), `tenants/${TENANT_A}/findings/finding-2`), { note: "seed" })
      );
    });

    it("allows a plain manager to update (update accepts manager OR sheq, unlike create)", async () => {
      await seed(`tenants/${TENANT_A}/findings/finding-3`, { note: "seed" });
      const manager = authedContext(testEnv, "manager-findings-2", TENANT_A, "manager");
      await assertSucceeds(
        updateDoc(doc(manager.firestore(), `tenants/${TENANT_A}/findings/finding-3`), {
          note: "updated by manager",
        })
      );
    });

    it("denies a manager from deleting — delete needs isAdmin()", async () => {
      await seed(`tenants/${TENANT_A}/findings/finding-4`, { note: "seed" });
      const manager = authedContext(testEnv, "manager-findings-3", TENANT_A, "manager");
      await assertFails(deleteDoc(doc(manager.firestore(), `tenants/${TENANT_A}/findings/finding-4`)));
    });

    it("allows an admin to delete", async () => {
      await seed(`tenants/${TENANT_A}/findings/finding-5`, { note: "seed" });
      const admin = authedContext(testEnv, "admin-findings-1", TENANT_A, "admin");
      await assertSucceeds(deleteDoc(doc(admin.firestore(), `tenants/${TENANT_A}/findings/finding-5`)));
    });
  });

  describe("loto_events — create is manager-or-sheq, but update AND delete are BOTH admin-only", () => {
    it("allows a manager to create", async () => {
      const manager = authedContext(testEnv, "manager-loto-1", TENANT_A, "manager");
      await assertSucceeds(
        setDoc(doc(manager.firestore(), `tenants/${TENANT_A}/loto_events/loto-1`), { note: "seed" })
      );
    });

    it("denies the SAME manager role from updating — unlike most collections, update is admin-only here, not manager-or-sheq", async () => {
      await seed(`tenants/${TENANT_A}/loto_events/loto-2`, { note: "seed" });
      const manager = authedContext(testEnv, "manager-loto-2", TENANT_A, "manager");
      await assertFails(
        updateDoc(doc(manager.firestore(), `tenants/${TENANT_A}/loto_events/loto-2`), {
          note: "should be denied",
        })
      );
    });

    it("denies a sheq_officer from updating too — update genuinely requires isAdmin(), not isSheqOfficer()", async () => {
      await seed(`tenants/${TENANT_A}/loto_events/loto-3`, { note: "seed" });
      const officer = authedContext(testEnv, "officer-loto-1", TENANT_A, "sheq_officer");
      await assertFails(
        updateDoc(doc(officer.firestore(), `tenants/${TENANT_A}/loto_events/loto-3`), {
          note: "should be denied",
        })
      );
    });

    it("allows an admin to update and delete", async () => {
      await seed(`tenants/${TENANT_A}/loto_events/loto-4`, { note: "seed" });
      const admin = authedContext(testEnv, "admin-loto-1", TENANT_A, "admin");
      const ref = doc(admin.firestore(), `tenants/${TENANT_A}/loto_events/loto-4`);
      await assertSucceeds(updateDoc(ref, { note: "updated" }));
      await assertSucceeds(deleteDoc(ref));
    });
  });

  describe("enrollments — create/update have NO role gate at all, only delete is admin-gated", () => {
    it("allows a plain employee to create and update", async () => {
      const employee = authedContext(testEnv, "employee-enroll-1", TENANT_A, "employee");
      const ref = doc(employee.firestore(), `tenants/${TENANT_A}/enrollments/enroll-1`);
      await assertSucceeds(setDoc(ref, { note: "seed" }));
      await assertSucceeds(updateDoc(ref, { note: "updated" }));
    });

    it("denies a plain employee from deleting", async () => {
      await seed(`tenants/${TENANT_A}/enrollments/enroll-2`, { note: "seed" });
      const employee = authedContext(testEnv, "employee-enroll-2", TENANT_A, "employee");
      await assertFails(deleteDoc(doc(employee.firestore(), `tenants/${TENANT_A}/enrollments/enroll-2`)));
    });

    it("allows an admin to delete", async () => {
      await seed(`tenants/${TENANT_A}/enrollments/enroll-3`, { note: "seed" });
      const admin = authedContext(testEnv, "admin-enroll-1", TENANT_A, "admin");
      await assertSucceeds(deleteDoc(doc(admin.firestore(), `tenants/${TENANT_A}/enrollments/enroll-3`)));
    });
  });

  describe("hazards — three different gates: open create, sheq-gated update, admin-gated delete", () => {
    it("allows any employee to report (create) a hazard", async () => {
      const employee = authedContext(testEnv, "employee-hazard-1", TENANT_A, "employee");
      await assertSucceeds(
        setDoc(doc(employee.firestore(), `tenants/${TENANT_A}/hazards/hazard-1`), { note: "seed" })
      );
    });

    it("denies a plain manager (non-sheq) from updating a hazard", async () => {
      await seed(`tenants/${TENANT_A}/hazards/hazard-2`, { note: "seed" });
      const manager = authedContext(testEnv, "manager-hazard-1", TENANT_A, "manager");
      await assertFails(
        updateDoc(doc(manager.firestore(), `tenants/${TENANT_A}/hazards/hazard-2`), {
          note: "should be denied",
        })
      );
    });

    it("allows a sheq_officer to update a hazard", async () => {
      await seed(`tenants/${TENANT_A}/hazards/hazard-3`, { note: "seed" });
      const officer = authedContext(testEnv, "officer-hazard-1", TENANT_A, "sheq_officer");
      await assertSucceeds(
        updateDoc(doc(officer.firestore(), `tenants/${TENANT_A}/hazards/hazard-3`), { note: "updated" })
      );
    });

    it("denies a sheq_officer (non-admin) from deleting — delete needs isAdmin() specifically", async () => {
      await seed(`tenants/${TENANT_A}/hazards/hazard-4`, { note: "seed" });
      const officer = authedContext(testEnv, "officer-hazard-2", TENANT_A, "sheq_officer");
      await assertFails(deleteDoc(doc(officer.firestore(), `tenants/${TENANT_A}/hazards/hazard-4`)));
    });
  });

  describe("safety_flashes — create manager-or-sheq, delete admin, NO update rule declared at all", () => {
    it("allows a manager to create", async () => {
      const manager = authedContext(testEnv, "manager-flash-1", TENANT_A, "manager");
      await assertSucceeds(
        setDoc(doc(manager.firestore(), `tenants/${TENANT_A}/safety_flashes/flash-1`), { note: "seed" })
      );
    });

    it("denies UPDATE for every role, including admin — this block has no allow-update statement at all", async () => {
      await seed(`tenants/${TENANT_A}/safety_flashes/flash-2`, { note: "seed" });
      const admin = authedContext(testEnv, "admin-flash-1", TENANT_A, "admin");
      await assertFails(
        updateDoc(doc(admin.firestore(), `tenants/${TENANT_A}/safety_flashes/flash-2`), {
          note: "should be denied — no update rule exists for this collection",
        })
      );
    });

    it("allows an admin to delete", async () => {
      await seed(`tenants/${TENANT_A}/safety_flashes/flash-3`, { note: "seed" });
      const admin = authedContext(testEnv, "admin-flash-2", TENANT_A, "admin");
      await assertSucceeds(
        deleteDoc(doc(admin.firestore(), `tenants/${TENANT_A}/safety_flashes/flash-3`))
      );
    });
  });
});
