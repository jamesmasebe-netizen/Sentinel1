/**
 * Wave 2c — firestore.rules matrix, special/system cluster: every AUTHENTICATED-context case —
 * tenant root doc, catch-all inside /tenants/{tenantId}, users/{userId}, fcm_tokens, subscription,
 * bpf_instances, notifications, emergency_drills/equipment/contacts.
 *
 * Root cause found and fixed (2026-08-07): `RulesTestContext.firestore()` must be called AT MOST
 * ONCE per context object. Calling it a second time on the same context — even for a harmless
 * second read/write with no different settings — throws "Firestore has already been started and
 * its settings can no longer be changed" deterministically (confirmed: every failing test in an
 * earlier draft of this file called `.firestore()` twice on the same context; every passing test,
 * including ones with multiple operations, built one doc/collection ref from a single
 * `.firestore()` call and reused it). Every test below now calls `.firestore()` exactly once per
 * context and reuses the returned `Firestore` instance for all subsequent operations in that test.
 */
import { assertFails, assertSucceeds, RulesTestEnvironment } from "@firebase/rules-unit-testing";
import { deleteDoc, doc, getDoc, setDoc, updateDoc } from "firebase/firestore";
import { authedContext, getTestEnv, TENANT_A, TENANT_B } from "../helpers/rules_test_env";

describe("firestore.rules — special cluster: authenticated-context cases (Wave 2c)", () => {
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

  describe("tenants/{tenantId} — the tenant root document itself", () => {
    it("allows any same-tenant member to read the tenant doc", async () => {
      await seed(`tenants/${TENANT_A}`, { name: "Acme Co" });
      const worker = authedContext(testEnv, "worker-root-1", TENANT_A, "employee");
      await assertSucceeds(getDoc(doc(worker.firestore(), `tenants/${TENANT_A}`)));
    });

    it("denies a cross-tenant user from reading the tenant doc", async () => {
      await seed(`tenants/${TENANT_A}`, { name: "Acme Co" });
      const outsider = authedContext(testEnv, "outsider-root-1", TENANT_B, "admin");
      await assertFails(getDoc(doc(outsider.firestore(), `tenants/${TENANT_A}`)));
    });

    it("denies a same-tenant manager (non-admin) from writing the tenant doc — root write is admin-only, stricter than most isManager()-gated collections", async () => {
      const manager = authedContext(testEnv, "manager-root-1", TENANT_A, "manager");
      await assertFails(setDoc(doc(manager.firestore(), `tenants/${TENANT_A}`), { name: "Renamed" }));
    });

    it("allows a same-tenant admin to write the tenant doc", async () => {
      const admin = authedContext(testEnv, "admin-root-1", TENANT_A, "admin");
      await assertSucceeds(setDoc(doc(admin.firestore(), `tenants/${TENANT_A}`), { name: "Acme Co" }));
    });
  });

  describe("catch-all inside /tenants/{tenantId} — match /{collection}/{docId}", () => {
    // Confirmed by grepping the real firestore.rules file: no block anywhere declares this name.
    const undeclaredCollection = "some_totally_undeclared_collection_xyz";

    it("allows a same-tenant member to read a doc under an undeclared collection name (falls through to the catch-all's read rule)", async () => {
      await seed(`tenants/${TENANT_A}/${undeclaredCollection}/doc-1`, { note: "seed" });
      const worker = authedContext(testEnv, "worker-catchall-1", TENANT_A, "employee");
      await assertSucceeds(
        getDoc(doc(worker.firestore(), `tenants/${TENANT_A}/${undeclaredCollection}/doc-1`))
      );
    });

    it("denies ANY write under an undeclared collection name, even for an admin — write: if false is unconditional", async () => {
      const admin = authedContext(testEnv, "admin-catchall-1", TENANT_A, "admin");
      await assertFails(
        setDoc(doc(admin.firestore(), `tenants/${TENANT_A}/${undeclaredCollection}/doc-2`), {
          note: "should be denied regardless of role",
        })
      );
    });

    it("denies a cross-tenant user from reading a doc under an undeclared collection name", async () => {
      await seed(`tenants/${TENANT_A}/${undeclaredCollection}/doc-3`, { note: "seed" });
      const outsider = authedContext(testEnv, "outsider-catchall-1", TENANT_B, "admin");
      await assertFails(
        getDoc(doc(outsider.firestore(), `tenants/${TENANT_A}/${undeclaredCollection}/doc-3`))
      );
    });
  });

  describe("top-level fallback (authenticated cases) — match /{document=**}", () => {
    // The F-301 regression guard: a service that accidentally writes to the Firestore root
    // (bypassing tenant scoping entirely) must be rejected here, for every role including admin.
    const rootLevelPath = "some_root_level_collection_never_declared/doc-1";

    it("denies a root-level (non-tenant-scoped) write for an admin", async () => {
      const admin = authedContext(testEnv, "admin-fallback-1", TENANT_A, "admin");
      await assertFails(setDoc(doc(admin.firestore(), rootLevelPath), { note: "root escape attempt" }));
    });

    it("denies a root-level (non-tenant-scoped) read for an admin", async () => {
      await seed(rootLevelPath, { note: "seed" });
      const admin = authedContext(testEnv, "admin-fallback-2", TENANT_A, "admin");
      await assertFails(getDoc(doc(admin.firestore(), rootLevelPath)));
    });
  });

  describe("users/{userId} — global profiles, self-access only, no tenant concept", () => {
    it("allows a user to read and write their own profile doc", async () => {
      const alice = authedContext(testEnv, "alice-uid", TENANT_A, "employee");
      const ref = doc(alice.firestore(), "users/alice-uid");
      await assertSucceeds(setDoc(ref, { displayName: "Alice" }));
      await assertSucceeds(getDoc(ref));
    });

    it("denies a user from reading a different user's profile doc, even within the same tenant", async () => {
      await seed("users/bob-uid", { displayName: "Bob" });
      const alice = authedContext(testEnv, "alice-uid-2", TENANT_A, "employee");
      await assertFails(getDoc(doc(alice.firestore(), "users/bob-uid")));
    });

    it("denies a user from writing a different user's profile doc, even as an admin of the same tenant", async () => {
      const admin = authedContext(testEnv, "admin-users-1", TENANT_A, "admin");
      await assertFails(
        setDoc(doc(admin.firestore(), "users/someone-elses-uid"), { displayName: "Hijacked" })
      );
    });
  });

  describe("fcm_tokens — combined read+write, no role gate beyond tenant membership", () => {
    it("allows any same-tenant role (even non-privileged) to read and write", async () => {
      const worker = authedContext(testEnv, "worker-fcm-1", TENANT_A, "employee");
      const ref = doc(worker.firestore(), `tenants/${TENANT_A}/fcm_tokens/token-1`);
      await assertSucceeds(setDoc(ref, { token: "abc" }));
      await assertSucceeds(getDoc(ref));
    });

    it("denies a cross-tenant user from reading or writing", async () => {
      await seed(`tenants/${TENANT_A}/fcm_tokens/token-2`, { token: "xyz" });
      const outsider = authedContext(testEnv, "outsider-fcm-1", TENANT_B, "admin");
      const ref = doc(outsider.firestore(), `tenants/${TENANT_A}/fcm_tokens/token-2`);
      await assertFails(getDoc(ref));
      await assertFails(setDoc(ref, { token: "hijack" }));
    });
  });

  describe("subscription — read any tenant member, write admin-only (mirrors the tenant-root shape)", () => {
    it("allows a same-tenant member to read", async () => {
      await seed(`tenants/${TENANT_A}/subscription/status`, { tier: "premium" });
      const worker = authedContext(testEnv, "worker-sub-1", TENANT_A, "employee");
      await assertSucceeds(getDoc(doc(worker.firestore(), `tenants/${TENANT_A}/subscription/status`)));
    });

    it("denies a same-tenant manager (non-admin) from writing", async () => {
      const manager = authedContext(testEnv, "manager-sub-1", TENANT_A, "manager");
      await assertFails(
        setDoc(doc(manager.firestore(), `tenants/${TENANT_A}/subscription/status`), { tier: "premium" })
      );
    });

    it("allows a same-tenant admin to write", async () => {
      const admin = authedContext(testEnv, "admin-sub-1", TENANT_A, "admin");
      await assertSucceeds(
        setDoc(doc(admin.firestore(), `tenants/${TENANT_A}/subscription/status`), { tier: "premium" })
      );
    });
  });

  describe("bpf_instances / notifications / emergency_* — familiar shapes, compact coverage", () => {
    it("bpf_instances: manager can create, employee cannot, admin can delete, manager cannot delete", async () => {
      const manager = authedContext(testEnv, "manager-bpf", TENANT_A, "manager");
      const managerRef = doc(manager.firestore(), `tenants/${TENANT_A}/bpf_instances/bpf-1`);
      await assertSucceeds(setDoc(managerRef, { note: "seed" }));
      await assertFails(deleteDoc(managerRef));

      const worker = authedContext(testEnv, "worker-bpf", TENANT_A, "employee");
      await assertFails(
        setDoc(doc(worker.firestore(), `tenants/${TENANT_A}/bpf_instances/bpf-deny`), {
          note: "should be denied",
        })
      );

      const admin = authedContext(testEnv, "admin-bpf", TENANT_A, "admin");
      await assertSucceeds(deleteDoc(doc(admin.firestore(), `tenants/${TENANT_A}/bpf_instances/bpf-1`)));
    });

    it("notifications: any same-tenant role can create/update, cross-tenant is denied", async () => {
      const worker = authedContext(testEnv, "worker-notif", TENANT_A, "employee");
      const ref = doc(worker.firestore(), `tenants/${TENANT_A}/notifications/notif-1`);
      await assertSucceeds(setDoc(ref, { note: "seed" }));
      await assertSucceeds(updateDoc(ref, { note: "updated" }));

      const outsider = authedContext(testEnv, "outsider-notif", TENANT_B, "admin");
      await assertFails(getDoc(doc(outsider.firestore(), `tenants/${TENANT_A}/notifications/notif-1`)));
    });

    for (const collection of ["emergency_drills", "emergency_equipment", "emergency_contacts"]) {
      it(`${collection}: manager OR sheq_officer can create, plain employee cannot, admin can delete`, async () => {
        const manager = authedContext(testEnv, `manager-${collection}`, TENANT_A, "manager");
        await assertSucceeds(
          setDoc(doc(manager.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-mgr`), {
            note: "seed",
          })
        );

        const officer = authedContext(testEnv, `officer-${collection}`, TENANT_A, "sheq_officer");
        await assertSucceeds(
          setDoc(doc(officer.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-officer`), {
            note: "seed",
          })
        );

        const worker = authedContext(testEnv, `worker-${collection}`, TENANT_A, "employee");
        await assertFails(
          setDoc(doc(worker.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-deny`), {
            note: "should be denied",
          })
        );

        const admin = authedContext(testEnv, `admin-${collection}`, TENANT_A, "admin");
        await assertSucceeds(
          deleteDoc(doc(admin.firestore(), `tenants/${TENANT_A}/${collection}/${collection}-mgr`))
        );
      });
    }
  });
});
