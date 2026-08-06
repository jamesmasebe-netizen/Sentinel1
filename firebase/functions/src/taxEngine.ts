import { onCall, HttpsError, CallableRequest } from "firebase-functions/v2/https";
import { getDb } from "./lib/db";

interface CalculateTaxRequest {
  tenantId: string;
  total: number;
  jurisdiction: string;
}

/**
 * Computes tax by looking up the real TaxCode record for the given
 * jurisdiction (`fin_tax_codes` — the canonical finance collection scheme,
 * see F-313) instead of a flat simulated rate. Falls back to a 0% rate
 * rather than a fabricated nonzero one if no active TaxCode matches —
 * surfacing the gap is safer than silently guessing a rate on real invoices.
 */
export const calculateTax = onCall(
  { region: "europe-west1" },
  async (request: CallableRequest<CalculateTaxRequest>) => {
    const { tenantId, total, jurisdiction } = request.data;

    if (total == null || !jurisdiction || !tenantId) {
      throw new HttpsError(
        "invalid-argument",
        'The function must be called with "tenantId", "total", and "jurisdiction" arguments.'
      );
    }

    const db = getDb();
    const snap = await db
      .collection("tenants")
      .doc(tenantId)
      .collection("fin_tax_codes")
      .where("jurisdiction_id", "==", jurisdiction)
      .where("is_active", "==", true)
      .limit(1)
      .get();

    const rate = snap.empty ? 0 : (snap.docs[0].data().rate ?? 0);
    const taxAmount = total * rate;

    return {
      jurisdiction,
      taxCodeId: snap.empty ? null : snap.docs[0].id,
      rate,
      originalTotal: total,
      taxAmount,
      totalWithTax: total + taxAmount,
    };
  }
);
