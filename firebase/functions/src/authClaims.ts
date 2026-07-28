import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions/v2";
import * as admin from "firebase-admin";

// firestore.rules' belongsToTenant()/isManager()/isAdmin()/isSheqOfficer() helpers all read
// request.auth.token.tenantId and request.auth.token.role — Auth custom claims, not the
// users/{uid} Firestore document's fields. Nothing previously set those claims (see
// docs/fixes/FIX_LIST.md F-003), so this trigger keeps them in sync with the profile document
// AuthService._getOrCreateProfile() already writes on signup/login.
export const syncUserClaims = onDocumentWritten(
  { document: "users/{userId}", region: "europe-west1" },
  async (event) => {
    const after = event.data?.after;
    if (!after || !after.exists) return; // Document deleted — nothing to sync

    const data = after.data();
    const role = data?.role;
    const tenantId = data?.tenantId;

    if (!role || !tenantId) {
      logger.warn(
        `syncUserClaims: users/${event.params.userId} is missing role or tenantId, skipping claims sync.`,
      );
      return;
    }

    const before = event.data?.before?.data();
    if (before?.role === role && before?.tenantId === tenantId) {
      return; // No relevant change — avoid an unnecessary auth write on every profile edit
    }

    await admin.auth().setCustomUserClaims(event.params.userId, { role, tenantId });
    logger.info(
      `syncUserClaims: set claims for users/${event.params.userId} -> role=${role}, tenantId=${tenantId}`,
    );
  },
);
