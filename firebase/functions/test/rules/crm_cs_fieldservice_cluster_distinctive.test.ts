/**
 * Wave 2c — firestore.rules matrix, CRM/Sales/CS/FieldService cluster, part 2: the 3 collections
 * with genuinely distinctive shapes:
 *
 * - cs_tickets: create is open to any tenant member, but update is gated to isManager() —
 *   most collections in this schema gate create and update together; this one splits them.
 *   Its messages subcollection is distinctive too: create is open, but update/delete are BOTH
 *   isAdmin()-gated with no manager tier at all (unlike the parent ticket's isAdmin()-only delete
 *   paired with isManager()-gated update). Its sla_kpi_instances subcollection (moved here
 *   2026-08-07 from the standard file's openWrite loop — it's nested under cs_tickets/{ticketId},
 *   not top-level, matching CustomerServiceService.createSlaInstance's real write path; see
 *   TEST_BACKLOG.md T3-CUSTOMERSERVICE for the bug this fixes) shares messages' open-create shape
 *   but its own manager-gated update (not admin-only) and admin-gated delete.
 * - job_requisitions / job_applications: only the AUTHENTICATED-context cases live here.
 *   job_requisitions' `allow read: if true` and job_applications' `allow create: if true` are
 *   reachable pre-authentication (careers portal, per docs/fixes/FIX_LIST.md F-501) — those two
 *   assertions belong in zzz_unauthenticated_access.test.ts per that file's own stated convention
 *   for every testEnv.unauthenticatedContext() case in this suite, not here.
 */
import { assertFails, assertSucceeds, RulesTestEnvironment } from "@firebase/rules-unit-testing";
import { deleteDoc, doc, getDoc, setDoc, updateDoc } from "firebase/firestore";
import { authedContext, getTestEnv, TENANT_A } from "../helpers/rules_test_env";

describe("firestore.rules — CRM/Sales/CS/FieldService cluster: distinctive-shape collections (Wave 2c)", () => {
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

  describe("cs_tickets — create open to any tenant member, but update needs isManager()", () => {
    it("allows any employee to create a ticket", async () => {
      const employee = authedContext(testEnv, "employee-ticket-1", TENANT_A, "employee");
      await assertSucceeds(
        setDoc(doc(employee.firestore(), `tenants/${TENANT_A}/cs_tickets/ticket-1`), {
          note: "seed",
        })
      );
    });

    it("denies a plain employee from updating (unlike create, update needs isManager())", async () => {
      await seed(`tenants/${TENANT_A}/cs_tickets/ticket-2`, { note: "seed" });
      const employee = authedContext(testEnv, "employee-ticket-2", TENANT_A, "employee");
      await assertFails(
        updateDoc(doc(employee.firestore(), `tenants/${TENANT_A}/cs_tickets/ticket-2`), {
          note: "should be denied",
        })
      );
    });

    it("allows a manager to update, but denies them from deleting — delete needs isAdmin(), not isManager()", async () => {
      await seed(`tenants/${TENANT_A}/cs_tickets/ticket-3`, { note: "seed" });
      const manager = authedContext(testEnv, "manager-ticket-1", TENANT_A, "manager");
      const ref = doc(manager.firestore(), `tenants/${TENANT_A}/cs_tickets/ticket-3`);
      await assertSucceeds(updateDoc(ref, { note: "updated" }));
      await assertFails(deleteDoc(ref));
    });

    it("allows an admin to delete", async () => {
      await seed(`tenants/${TENANT_A}/cs_tickets/ticket-4`, { note: "seed" });
      const admin = authedContext(testEnv, "admin-ticket-1", TENANT_A, "admin");
      await assertSucceeds(
        deleteDoc(doc(admin.firestore(), `tenants/${TENANT_A}/cs_tickets/ticket-4`))
      );
    });
  });

  describe("cs_tickets/{ticketId}/messages — create open, but update+delete are BOTH isAdmin()-gated (no manager tier)", () => {
    it("allows any employee to post a message", async () => {
      await seed(`tenants/${TENANT_A}/cs_tickets/ticket-msg-1`, { note: "seed" });
      const employee = authedContext(testEnv, "employee-msg-1", TENANT_A, "employee");
      await assertSucceeds(
        setDoc(doc(employee.firestore(), `tenants/${TENANT_A}/cs_tickets/ticket-msg-1/messages/msg-1`), {
          note: "seed",
        })
      );
    });

    it("denies a manager (not just an employee) from updating or deleting a message — needs isAdmin(), not isManager()", async () => {
      await seed(`tenants/${TENANT_A}/cs_tickets/ticket-msg-2`, { note: "seed" });
      await seed(`tenants/${TENANT_A}/cs_tickets/ticket-msg-2/messages/msg-2`, { note: "seed" });
      const manager = authedContext(testEnv, "manager-msg-1", TENANT_A, "manager");
      const ref = doc(manager.firestore(), `tenants/${TENANT_A}/cs_tickets/ticket-msg-2/messages/msg-2`);
      await assertFails(updateDoc(ref, { note: "should be denied" }));
      await assertFails(deleteDoc(ref));
    });

    it("allows an admin to update and delete a message", async () => {
      await seed(`tenants/${TENANT_A}/cs_tickets/ticket-msg-3`, { note: "seed" });
      await seed(`tenants/${TENANT_A}/cs_tickets/ticket-msg-3/messages/msg-3`, { note: "seed" });
      const admin = authedContext(testEnv, "admin-msg-1", TENANT_A, "admin");
      const ref = doc(admin.firestore(), `tenants/${TENANT_A}/cs_tickets/ticket-msg-3/messages/msg-3`);
      await assertSucceeds(updateDoc(ref, { note: "updated" }));
      await assertSucceeds(deleteDoc(ref));
    });
  });

  describe("cs_tickets/{ticketId}/sla_kpi_instances — nested under the ticket, not top-level (regression guard, see file header)", () => {
    it("allows any employee to create an instance", async () => {
      await seed(`tenants/${TENANT_A}/cs_tickets/ticket-sla-1`, { note: "seed" });
      const employee = authedContext(testEnv, "employee-sla-1", TENANT_A, "employee");
      await assertSucceeds(
        setDoc(doc(employee.firestore(), `tenants/${TENANT_A}/cs_tickets/ticket-sla-1/sla_kpi_instances/sla-1`), {
          note: "seed",
        })
      );
    });

    it("denies a plain employee from deleting — delete needs isAdmin()", async () => {
      await seed(`tenants/${TENANT_A}/cs_tickets/ticket-sla-2`, { note: "seed" });
      await seed(`tenants/${TENANT_A}/cs_tickets/ticket-sla-2/sla_kpi_instances/sla-2`, { note: "seed" });
      const employee = authedContext(testEnv, "employee-sla-2", TENANT_A, "employee");
      await assertFails(
        deleteDoc(doc(employee.firestore(), `tenants/${TENANT_A}/cs_tickets/ticket-sla-2/sla_kpi_instances/sla-2`))
      );
    });

    it("allows an admin to delete", async () => {
      await seed(`tenants/${TENANT_A}/cs_tickets/ticket-sla-3`, { note: "seed" });
      await seed(`tenants/${TENANT_A}/cs_tickets/ticket-sla-3/sla_kpi_instances/sla-3`, { note: "seed" });
      const admin = authedContext(testEnv, "admin-sla-1", TENANT_A, "admin");
      await assertSucceeds(
        deleteDoc(doc(admin.firestore(), `tenants/${TENANT_A}/cs_tickets/ticket-sla-3/sla_kpi_instances/sla-3`))
      );
    });
  });

  describe("job_requisitions — authenticated cases (public `read: if true` covered in zzz_unauthenticated_access.test.ts)", () => {
    it("allows a manager to create/update, denies a plain employee", async () => {
      const manager = authedContext(testEnv, "manager-jobreq-1", TENANT_A, "manager");
      const ref = doc(manager.firestore(), `tenants/${TENANT_A}/job_requisitions/req-1`);
      await assertSucceeds(setDoc(ref, { note: "seed" }));
      await assertSucceeds(updateDoc(ref, { note: "updated" }));

      const employee = authedContext(testEnv, "employee-jobreq-1", TENANT_A, "employee");
      await assertFails(
        setDoc(doc(employee.firestore(), `tenants/${TENANT_A}/job_requisitions/req-2`), {
          note: "should be denied",
        })
      );
    });

    it("allows an admin to delete, denies a plain manager from deleting", async () => {
      await seed(`tenants/${TENANT_A}/job_requisitions/req-3`, { note: "seed" });
      const manager = authedContext(testEnv, "manager-jobreq-2", TENANT_A, "manager");
      await assertFails(
        deleteDoc(doc(manager.firestore(), `tenants/${TENANT_A}/job_requisitions/req-3`))
      );

      const admin = authedContext(testEnv, "admin-jobreq-1", TENANT_A, "admin");
      await assertSucceeds(
        deleteDoc(doc(admin.firestore(), `tenants/${TENANT_A}/job_requisitions/req-3`))
      );
    });
  });

  describe("job_applications — read AND update/delete both need isManager(), no separate admin-only delete tier (public `create: if true` covered in zzz_unauthenticated_access.test.ts)", () => {
    it("denies a plain employee from reading an application — this is one of the 11 collections the catch-all vulnerability used to expose (see T2c-SENSITIVE)", async () => {
      await seed(`tenants/${TENANT_A}/job_applications/app-1`, { note: "seed" });
      const employee = authedContext(testEnv, "employee-jobapp-1", TENANT_A, "employee");
      await assertFails(
        getDoc(doc(employee.firestore(), `tenants/${TENANT_A}/job_applications/app-1`))
      );
    });

    it("allows a manager to read, update, and delete — unlike most collections, delete does NOT require isAdmin() specifically", async () => {
      await seed(`tenants/${TENANT_A}/job_applications/app-2`, { note: "seed" });
      const manager = authedContext(testEnv, "manager-jobapp-1", TENANT_A, "manager");
      const ref = doc(manager.firestore(), `tenants/${TENANT_A}/job_applications/app-2`);
      await assertSucceeds(getDoc(ref));
      await assertSucceeds(updateDoc(ref, { status: "reviewed" }));
      await assertSucceeds(deleteDoc(ref));
    });
  });
});
