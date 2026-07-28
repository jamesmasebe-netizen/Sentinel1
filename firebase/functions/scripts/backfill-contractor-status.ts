/**
 * One-time backfill for contractors written before the fix in
 * add_contractor_form.dart (docs/fixes/FIX_LIST.md F-219): `status` and
 * `complianceStatus` used to be stored lowercase (`.toLowerCase()`), while
 * every reader (ContractorList's filter, its status chip color/label) always
 * expected the capitalized dropdown values. New writes are fixed; this
 * script corrects any documents written before the fix landed.
 *
 * Usage (run from firebase/functions/ — this file is intentionally outside src/,
 * so it's never bundled into the deployed functions; `npm run build` won't compile it):
 *   npm run backfill:contractor-status                  # dry run, logs only
 *   npm run backfill:contractor-status -- --apply        # writes changes
 *
 * Requires Application Default Credentials for the target project, e.g.:
 *   gcloud auth application-default login
 *   gcloud config set project <your-project-id>
 * or GOOGLE_APPLICATION_CREDENTIALS pointing at a service account key.
 */
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

const STATUS_MAP: Record<string, string> = {
  active: "Active",
  inactive: "Inactive",
  suspended: "Suspended",
};

const COMPLIANCE_STATUS_MAP: Record<string, string> = {
  compliant: "Compliant",
  "non-compliant": "Non-compliant",
  pending: "Pending",
};

function correctedValue(
  raw: unknown,
  map: Record<string, string>,
): string | undefined {
  if (typeof raw !== "string") return undefined;
  if (Object.values(map).includes(raw)) return undefined; // already correct
  const fixed = map[raw.toLowerCase()];
  return fixed; // undefined if it's some other unrecognized value — leave alone, don't guess
}

async function run() {
  const apply = process.argv.includes("--apply");
  console.log(`Backfill mode: ${apply ? "APPLY (writing changes)" : "DRY RUN (no writes)"}`);

  // contractors live at tenants/{tenantId}/contractors/{id} — collectionGroup
  // finds them across every tenant in one query.
  const snap = await db.collectionGroup("contractors").get();
  console.log(`Scanned ${snap.size} contractor document(s) across all tenants.`);

  let toFix = 0;
  let batch = db.batch();
  let batchCount = 0;

  for (const doc of snap.docs) {
    const data = doc.data();
    const statusFix = correctedValue(data.status, STATUS_MAP);
    const complianceFix = correctedValue(data.complianceStatus, COMPLIANCE_STATUS_MAP);

    if (!statusFix && !complianceFix) continue;

    toFix++;
    const update: Record<string, string> = {};
    if (statusFix) update.status = statusFix;
    if (complianceFix) update.complianceStatus = complianceFix;

    console.log(
      `${doc.ref.path}: status ${data.status ?? "(unset)"} -> ${statusFix ?? "(unchanged)"}, ` +
        `complianceStatus ${data.complianceStatus ?? "(unset)"} -> ${complianceFix ?? "(unchanged)"}`,
    );

    if (apply) {
      batch.update(doc.ref, update);
      batchCount++;
      // Firestore batches cap at 500 writes.
      if (batchCount === 500) {
        await batch.commit();
        batch = db.batch();
        batchCount = 0;
      }
    }
  }

  if (apply && batchCount > 0) {
    await batch.commit();
  }

  console.log(
    `${toFix} document(s) ${apply ? "updated" : "would be updated"}.` +
      (apply ? "" : " Re-run with --apply to write these changes."),
  );
}

run()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("Backfill failed:", err);
    process.exit(1);
  });
