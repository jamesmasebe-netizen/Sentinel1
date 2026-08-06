/**
 * Unit tests for `syncUserClaims`'s guard/early-return paths (T2-003, F-003).
 *
 * No mocking of `firebase-admin` here at all — deliberately, following T1-002's "no mocking
 * needed or used" precedent for validation-only paths. This file never calls
 * `admin.initializeApp()` on the DEFAULT app (only `firebase-functions-test`'s own separately-
 * named internal app gets initialized, to build fake DocumentSnapshots — see
 * node_modules/firebase-functions-test/lib/app.js). That means `admin.auth()` — which resolves
 * against the default app — genuinely throws "no default app" if the handler ever reaches it.
 * This gives a real (not mocked) proof that the four guard/skip cases below never call
 * `admin.auth().setCustomUserClaims(...)` at all: they resolve cleanly. The final test is the
 * negative control — a genuine role/tenantId change SHOULD reach `admin.auth()`, and does (it
 * rejects with the real "no app" error, not because of any application logic), confirming the
 * guards above are actually selective and not just silently swallowing every case.
 *
 * The real, successful claims-setting behavior — the actual thing F-003 cares about, since
 * `firestore.rules` depends on these claims being both set AND correct — is verified against the
 * real Firebase Auth emulator in test/rules/auth_claims.test.ts.
 */
import firebaseFunctionsTest from "firebase-functions-test";
import { syncUserClaims } from "./authClaims";

const { wrap } = firebaseFunctionsTest();
const wrapped = wrap(syncUserClaims) as (partial: unknown) => Promise<void>;

type UserDocEventPartial = {
  data: {
    before: Record<string, unknown>;
    after: Record<string, unknown>;
  };
  params: { userId: string };
};

function buildEvent(
  before: Record<string, unknown>,
  after: Record<string, unknown>,
  userId = "user-guard-test"
): UserDocEventPartial {
  return { data: { before, after }, params: { userId } };
}

describe("syncUserClaims — guard paths (no admin.auth() access)", () => {
  it("does nothing when the user document was deleted (after does not exist)", async () => {
    await expect(
      wrapped(buildEvent({ role: "employee", tenantId: "tenant-x" }, {}))
    ).resolves.toBeUndefined();
  });

  it("does nothing when the profile is missing role", async () => {
    await expect(
      wrapped(buildEvent({}, { tenantId: "tenant-x" }))
    ).resolves.toBeUndefined();
  });

  it("does nothing when the profile is missing tenantId", async () => {
    await expect(
      wrapped(buildEvent({}, { role: "employee" }))
    ).resolves.toBeUndefined();
  });

  it("does nothing when role and tenantId are both unchanged from before", async () => {
    await expect(
      wrapped(
        buildEvent(
          { role: "employee", tenantId: "tenant-x" },
          { role: "employee", tenantId: "tenant-x" }
        )
      )
    ).resolves.toBeUndefined();
  });

  it("(negative control) a genuine role change DOES attempt to reach admin.auth() — proving the guards above are selective, not blanket no-ops", async () => {
    await expect(
      wrapped(
        buildEvent(
          { role: "employee", tenantId: "tenant-x" },
          { role: "manager", tenantId: "tenant-x" }
        )
      )
    ).rejects.toThrow();
  });
});
