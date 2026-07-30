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

    const journalEntry = {
      description: `Revenue recognition for completed milestone: ${milestoneName} (${milestoneId})`,
      total_debit: milestoneValue,
      total_credit: milestoneValue,
      type: "REVENUE_RECOGNITION",
      status: "POSTED",
      source_module: "PROJECTS",
      source_reference_id: milestoneId,
      currency_code: "USD",
      transaction_date: admin.firestore.FieldValue.serverTimestamp(),
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    };

    const db = admin.firestore();
    const journalRef = db.collection(`tenants/${tenantId}/fin_journal_headers`);
    await journalRef.add(journalEntry);

    logger.info("revenueRecognition: Journal entry posted successfully.", {
      tenantId,
      milestoneId,
    });
  }
);
