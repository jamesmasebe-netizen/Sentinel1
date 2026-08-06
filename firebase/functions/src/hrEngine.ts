import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions/v2";
import * as admin from "firebase-admin";
import { getDb } from "./lib/db";

// `Employee` (lib/features/people/models/employee.dart) has no tier/seniority field at all — a
// prior version of this rate keyed off `employee.tier`, a field that never existed on real data,
// so every real employee always fell through to this same flat fallback rate anyway. Rather than
// invent a tier concept the data model doesn't have, this is now the one real rate everyone gets.
const MONTHLY_ACCRUAL_DAYS = 1;

export const accrueLeave = onSchedule("0 0 * * *", async (_event) => {
  logger.info("accrueLeave: Starting monthly leave accrual job.");

  const db = getDb();
  // Employees live at tenants/{tenantId}/employees (see HrService, lib/features/people/services/
  // hr_service.dart) — a scheduled job runs across every tenant, so a collectionGroup query is
  // the correct way to reach all of them in one pass (same pattern already used elsewhere in this
  // codebase for cross-tenant scheduled queries — see index.ts's permits/incidents/
  // training_records collectionGroup queries).
  const employeesSnapshot = await db.collectionGroup("employees").get();

  if (employeesSnapshot.empty) {
    logger.info("accrueLeave: No employees found.");
    return;
  }

  const batch = db.batch();
  let processed = 0;

  for (const doc of employeesSnapshot.docs) {
    const employee = doc.data();
    const employeeId = doc.id;
    const name: string = employee.fullName ?? employeeId;

    // Don't accrue leave for staff who aren't currently active (Employee.status,
    // employee.dart:11: "Active, Suspended").
    if (employee.status !== "Active") {
      continue;
    }

    batch.update(doc.ref, {
      leaveBalance: admin.firestore.FieldValue.increment(MONTHLY_ACCRUAL_DAYS),
    });
    processed++;

    logger.info(
      `accrueLeave: Added ${MONTHLY_ACCRUAL_DAYS} accrued leave day(s) to employee "${name}" (ID: ${employeeId}).`
    );
  }

  if (processed > 0) {
    await batch.commit();
  }

  logger.info(`accrueLeave: Leave accrual job completed. Processed ${processed} employee(s).`);
});
