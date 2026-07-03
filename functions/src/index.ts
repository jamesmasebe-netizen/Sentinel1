import { onDocumentWritten } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

admin.initializeApp();

export const syncUserClaims = onDocumentWritten("users/{userId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    logger.error("No data associated with the event");
    return;
  }

  const userId = event.params.userId;
  const afterData = snapshot.after.data();

  if (!afterData) {
    // Document was deleted
    logger.info(`User ${userId} deleted. Skipping custom claim update.`);
    return;
  }

  const tenantId = afterData.tenantId;
  const role = afterData.role;

  try {
    const currentRecord = await admin.auth().getUser(userId);
    const currentClaims = currentRecord.customClaims || {};

    if (currentClaims.tenantId === tenantId && currentClaims.role === role) {
      logger.info(`Claims for ${userId} are already up to date.`);
      return;
    }

    await admin.auth().setCustomUserClaims(userId, {
      ...currentClaims,
      tenantId,
      role,
    });
    logger.info(`Successfully updated claims for user ${userId}: tenantId=${tenantId}, role=${role}`);
  } catch (error) {
    logger.error(`Error updating custom claims for user ${userId}:`, error);
  }
});

export * from "./billing";
export { platformApi } from './api';
