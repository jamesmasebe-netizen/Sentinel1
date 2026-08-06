/**
 * T2-003 — `syncUserClaims`, emulator-backed portion (F-003).
 *
 * F-003's whole point: `firestore.rules`' `belongsToTenant()`/`isManager()`/`isAdmin()`/
 * `isSheqOfficer()` helpers all read Firebase Auth CUSTOM CLAIMS (`request.auth.token.tenantId`/
 * `.role`), not the `users/{uid}` Firestore document. A test that only checks "did
 * `setCustomUserClaims` get called with the right arguments" (a mock) can't actually prove the
 * claims are readable back the way the rules need them — this file uses the REAL Firebase Auth
 * emulator (`--only firestore,auth` in package.json's "test:rules" script; port 9099 per
 * firebase.json) end to end: real `admin.auth().createUser()`, the real `syncUserClaims` handler
 * via `wrap()`, then a real `admin.auth().getUser(uid).customClaims` read-back.
 *
 * The guard/skip paths that never reach `admin.auth()` at all are covered, without the emulator,
 * in src/authClaims.test.ts.
 */

process.env.GCLOUD_PROJECT = "ai-studio-applet-webapp-faf6b";
process.env.FIREBASE_AUTH_EMULATOR_HOST = "127.0.0.1:9099";

import * as admin from "firebase-admin";
admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT });

import firebaseFunctionsTest from "firebase-functions-test";
import { syncUserClaims } from "../../src/authClaims";

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
  userId: string,
  before: Record<string, unknown>,
  after: Record<string, unknown>
): UserDocEventPartial {
  return { data: { before, after }, params: { userId } };
}

afterAll(async () => {
  await admin.app().delete();
});

describe("syncUserClaims — emulator-backed real Auth claims (T2-003, F-003)", () => {
  it("sets role/tenantId custom claims on profile creation, readable back from a real Auth user", async () => {
    const uid = "auth-claims-create";
    await admin.auth().createUser({ uid, email: `${uid}@example.com` });

    await wrapped(buildEvent(uid, {}, { role: "manager", tenantId: "tenant-claims-a" }));

    const user = await admin.auth().getUser(uid);
    expect(user.customClaims).toEqual({ role: "manager", tenantId: "tenant-claims-a" });
  });

  it("updates claims when role changes on an existing profile", async () => {
    const uid = "auth-claims-role-change";
    await admin.auth().createUser({ uid, email: `${uid}@example.com` });
    await admin.auth().setCustomUserClaims(uid, { role: "employee", tenantId: "tenant-claims-b" });

    await wrapped(
      buildEvent(
        uid,
        { role: "employee", tenantId: "tenant-claims-b" },
        { role: "manager", tenantId: "tenant-claims-b" }
      )
    );

    const user = await admin.auth().getUser(uid);
    expect(user.customClaims).toEqual({ role: "manager", tenantId: "tenant-claims-b" });
  });

  it("does NOT call setCustomUserClaims when role and tenantId are both unchanged — proven by leaving deliberately mismatched pre-set claims untouched", async () => {
    const uid = "auth-claims-no-op";
    await admin.auth().createUser({ uid, email: `${uid}@example.com` });
    // Deliberately mismatched vs. what the Firestore before/after below say, so that if the
    // handler incorrectly called setCustomUserClaims anyway, this assertion would catch it.
    await admin.auth().setCustomUserClaims(uid, { role: "stale-role", tenantId: "stale-tenant" });

    await wrapped(
      buildEvent(
        uid,
        { role: "employee", tenantId: "tenant-claims-c" },
        { role: "employee", tenantId: "tenant-claims-c" }
      )
    );

    const user = await admin.auth().getUser(uid);
    expect(user.customClaims).toEqual({ role: "stale-role", tenantId: "stale-tenant" });
  });

  it("does NOT set claims when the profile is missing role or tenantId", async () => {
    const uid = "auth-claims-missing-fields";
    await admin.auth().createUser({ uid, email: `${uid}@example.com` });

    await wrapped(buildEvent(uid, {}, { role: "employee" })); // tenantId missing

    const user = await admin.auth().getUser(uid);
    expect(user.customClaims ?? {}).toEqual({});
  });

  it("does NOT set claims when the profile document was deleted", async () => {
    const uid = "auth-claims-deleted-doc";
    await admin.auth().createUser({ uid, email: `${uid}@example.com` });
    await admin.auth().setCustomUserClaims(uid, { role: "employee", tenantId: "tenant-claims-d" });

    await wrapped(buildEvent(uid, { role: "employee", tenantId: "tenant-claims-d" }, {}));

    const user = await admin.auth().getUser(uid);
    // Claims survive untouched — the trigger returned before ever calling admin.auth() again.
    expect(user.customClaims).toEqual({ role: "employee", tenantId: "tenant-claims-d" });
  });
});
