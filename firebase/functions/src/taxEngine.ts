import * as functions from 'firebase-functions';

export const calculateTax = functions.https.onCall((data, context) => {
    const total = data.total;
    const jurisdiction = data.jurisdiction;

    if (total == null || !jurisdiction) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'The function must be called with "total" and "jurisdiction" arguments.'
        );
    }

    // Simulate Stripe Tax call
    const simulatedTaxRate = 0.08; // 8% tax rate
    const taxAmount = total * simulatedTaxRate;

    return {
        jurisdiction: jurisdiction,
        originalTotal: total,
        taxAmount: taxAmount,
        totalWithTax: total + taxAmount
    };
});
