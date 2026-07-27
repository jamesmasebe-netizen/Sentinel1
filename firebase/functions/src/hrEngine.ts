import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions/v2";
import * as admin from "firebase-admin";

const ACCRUAL_RATES: Record<string, number> = {
  SENIOR: 2,    // 2 days/month
  JUNIOR: 1.5,  // 1.5 days/month
};

const DEFAULT_ACCRUAL_RATE = 1; // fallback for unknown tiers

export const accrueLeave = onSchedule("0 0 * * *", async (_event) => {
  logger.info("accrueLeave: Starting monthly leave accrual job.");

  const db = admin.firestore();
  const employeesSnapshot = await db.collection("hr_employees").get();

  if (employeesSnapshot.empty) {
    logger.info("accrueLeave: No employees found in hr_employees collection.");
    return;
  }

  let processed = 0;

  for (const doc of employeesSnapshot.docs) {
    const employee = doc.data();
    const employeeId = doc.id;
    const tier: string = (employee.tier ?? "").toUpperCase();
    const name: string = employee.name ?? employeeId;

    const accrualDays = ACCRUAL_RATES[tier] ?? DEFAULT_ACCRUAL_RATE;

    logger.info(
      `accrueLeave: Would add ${accrualDays} accrued leave day(s) to employee "${name}" (ID: ${employeeId}, Tier: ${tier || "UNKNOWN"}).`
    );

    processed++;
  }

  logger.info(`accrueLeave: Leave accrual job completed. Processed ${processed} employee(s).`);
});
