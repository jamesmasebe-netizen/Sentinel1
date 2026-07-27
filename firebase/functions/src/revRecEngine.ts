import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions/v2";
import * as admin from "firebase-admin";

export const revenueRecognition = onDocumentUpdated(
  "tenants/{tenantId}/project_milestones/{milestoneId}",
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    if (!beforeData || !afterData) {
      logger.warn("revenueRecognition: Missing before/after snapshot data.");
      return;
    }

    const previousStatus = beforeData.status;
    const newStatus = afterData.status;

    // Only trigger when status transitions to 'COMPLETED'
    if (previousStatus === "COMPLETED" || newStatus !== "COMPLETED") {
      logger.info("revenueRecognition: No status transition to COMPLETED; skipping.", {
        previousStatus,
        newStatus,
      });
      return;
    }

    const { tenantId, milestoneId } = event.params;
    const milestoneName: string = afterData.name ?? milestoneId;
    const milestoneValue: number = afterData.value ?? 0;

    logger.info("revenueRecognition: Milestone completed, writing journal entry.", {
      tenantId,
      milestoneId,
      milestoneName,
      milestoneValue,
    });

    // Mock dual-entry journal document
    const journalEntry = {
      description: `Revenue recognition for completed milestone: ${milestoneName} (${milestoneId})`,
      totalDebit: milestoneValue,
      totalCredit: milestoneValue,
      type: "revenue_recognition",
      status: "posted",
      milestoneId,
      tenantId,
      recognizedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    const db = admin.firestore();
    const journalRef = db.collection(`tenants/${tenantId}/finance_journals`);
    await journalRef.add(journalEntry);

    logger.info("revenueRecognition: Journal entry posted successfully.", {
      tenantId,
      milestoneId,
    });
  }
);
