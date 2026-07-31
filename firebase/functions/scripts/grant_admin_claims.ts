/**
 * One-time admin bootstrap: grants a user real admin access by setting the
 * same custom auth claims the `syncUserClaims` Cloud Function
 * (firebase/functions/src/authClaims.ts) would normally set automatically
 * on a users/{uid} write. That function isn't deployed yet (blocked on the
 * project's Blaze plan upgrade), so this performs the identical claim shape
 * — { role, tenantId } — as a manual, one-time substitute. No security rule
 * is bypassed and no new privilege path is created; this is the exact same
 * effect the automated trigger would have had.
 *
 * Usage (run from firebase/functions/ — this file is intentionally outside src/,
 * so it's never bundled into the deployed functions; `npm run build` won't compile it):
 *   npm run grant:admin -- you@example.com                       # dry run, logs only
 *   npm run grant:admin -- you@example.com --apply                # writes changes
 *   npm run grant:admin -- you@example.com --apply --tenant=other-tenant
 *   npm run grant:admin -- --uid=<uid> --apply                    # anonymous/bypass users have no email
 *
 * Requires Application Default Credentials for the target project, e.g.:
 *   gcloud auth application-default login
 *   gcloud config set project <your-project-id>
 * or GOOGLE_APPLICATION_CREDENTIALS pointing at a service account key.
 */
import * as admin from "firebase-admin";
import { getFirestore } from "firebase-admin/firestore";

admin.initializeApp();

// This project has no `(default)` Firestore database (creating one requires
// the Blaze plan) — the app's real data lives in this named database
// instead (see firebase.json / lib/main.dart's FirebaseFirestore.instanceFor
// databaseId). admin.firestore() alone targets `(default)` and 404s.
const FIRESTORE_DATABASE_ID = "ai-studio-4bb0fb1c-c6d6-4397-a015-156f3ff9dfb5";
const db = getFirestore(admin.app(), FIRESTORE_DATABASE_ID);

const DEFAULT_TENANT_ID = "sentinel-dev";

async function run() {
  const apply = process.argv.includes("--apply");
  const email = process.argv.find((arg) => arg.includes("@"));
  const uidArg = process.argv.find((arg) => arg.startsWith("--uid="));
  const uid = uidArg ? uidArg.split("=")[1] : undefined;
  const tenantArg = process.argv.find((arg) => arg.startsWith("--tenant="));
  const tenantId = tenantArg ? tenantArg.split("=")[1] : DEFAULT_TENANT_ID;

  if (!email && !uid) {
    console.error("Usage: npm run grant:admin -- <email> [--apply] [--tenant=<tenantId>]");
    console.error("   or: npm run grant:admin -- --uid=<uid> [--apply] [--tenant=<tenantId>]");
    process.exit(1);
  }

  console.log(`Mode: ${apply ? "APPLY (writing changes)" : "DRY RUN (no writes)"}`);
  console.log(`Target: ${email ?? uid} -> role=admin, tenantId=${tenantId}`);

  const user = email
    ? await admin.auth().getUserByEmail(email)
    : await admin.auth().getUser(uid!);
  console.log(`Resolved ${email ?? uid} -> uid=${user.uid}, email=${user.email ?? "(none - anonymous)"} (existing claims: ${JSON.stringify(user.customClaims ?? {})})`);

  if (!apply) {
    console.log("Dry run only. Re-run with --apply to write these changes.");
    return;
  }

  await admin.auth().setCustomUserClaims(user.uid, { role: "admin", tenantId });
  await db.collection("users").doc(user.uid).set(
    { role: "admin", tenantId },
    { merge: true },
  );

  console.log(`Done. ${email ?? user.uid} (uid=${user.uid}) now has role=admin, tenantId=${tenantId}.`);
  console.log("Sign out and back in (or hard-refresh) in the app to pick up the new token claims.");
}

run()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("grant_admin_claims failed:", err);
    process.exit(1);
  });
