/**
 * Shared Firestore rules-testing harness (T1-005).
 *
 * Wraps `@firebase/rules-unit-testing`'s `initializeTestEnvironment`, loading the *real*
 * `firestore.rules` from the repo root and pointing at the Firestore emulator started by
 * `npm run test:rules` (see package.json's "test:rules" script and jest.rules.config.js, which
 * wrap `firebase emulators:exec --only firestore,auth`).
 *
 * Known limitation, confirmed by reading the installed library's source (checked 2026-08-05
 * against @firebase/rules-unit-testing 3.0.4 as installed, AND against the latest published 5.0.1
 * via `npm pack`): neither `TestEnvironmentConfig` nor `RulesTestContext.firestore(settings)`
 * exposes a `databaseId` option anywhere in the public API or the bundled runtime (grepped the
 * compiled bundle for "databaseId" — zero matches in either version). There is currently no way to
 * point a rules-unit-testing client at Sentinel1's named database
 * (`ai-studio-4bb0fb1c-c6d6-4397-a015-156f3ff9dfb5`, see firebase.json). Clients created by this
 * harness always address the emulator's "(default)" database.
 *
 * This does not weaken what's under test here: the Firestore Emulator loads and enforces
 * firestore.rules at the *project* level, not per-database — see firebase-tools'
 * `FirestoreEmulator.updateRules()` (lib/emulator/firestoreEmulator.js), which PUTs the rules
 * source to `/emulator/v1/projects/{projectId}:securityRules`, a project-scoped endpoint with no
 * database segment. The same rules text is evaluated identically no matter which database name a
 * request addresses, so exercising it via "(default)" validates the exact same
 * belongsToTenant()/isAdmin()/isManager()/isSheqOfficer() logic and match-block outcomes that
 * would apply against the named database in production. Cloud Functions' Admin-SDK writes (see
 * test/rules/journal_posting.test.ts) are a separate concern — Admin SDK bypasses rules entirely
 * regardless of database — and are not affected by this limitation either way.
 */
import * as fs from "fs";
import * as path from "path";
import {
  initializeTestEnvironment,
  RulesTestEnvironment,
  TokenOptions,
} from "@firebase/rules-unit-testing";
import { FIRESTORE_DATABASE_ID } from "../../src/lib/db";

/** Matches .firebaserc's default project — also the project `firebase emulators:exec` boots
 *  (firebase.json sets `emulators.singleProjectMode: true`, so this is somewhat forgiving, but
 *  keeping it explicit avoids relying on that fallback). */
export const PROJECT_ID = "ai-studio-applet-webapp-faf6b";

/** Re-exported from src/lib/db.ts (the single source of truth Cloud Functions actually use) so
 *  test code never hardcodes a second copy of this literal. Documented here for context; not
 *  addressable via this harness, see the module doc comment above. */
export { FIRESTORE_DATABASE_ID };

export const TENANT_A = "tenant-a-rules-test";
export const TENANT_B = "tenant-b-rules-test";

const FIRESTORE_RULES_PATH = path.join(__dirname, "../../../../firestore.rules");

/** Initializes the rules-testing environment against the running Firestore emulator (port 8080,
 *  per firebase.json's `emulators.firestore.port`), loaded with the real firestore.rules. */
export async function getTestEnv(): Promise<RulesTestEnvironment> {
  return initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync(FIRESTORE_RULES_PATH, "utf8"),
      host: "127.0.0.1",
      port: 8080,
    },
  });
}

/** Builds an authenticated context whose mock ID token carries the tenantId/role custom claims
 *  that firestore.rules' belongsToTenant()/isAdmin()/isManager()/isSheqOfficer() helpers read
 *  (via request.auth.token.tenantId / request.auth.token.role). */
export function authedContext(
  testEnv: RulesTestEnvironment,
  uid: string,
  tenantId: string,
  role: string,
  extraClaims: TokenOptions = {}
) {
  return testEnv.authenticatedContext(uid, { tenantId, role, ...extraClaims });
}
