import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const preScreenComplianceDocument = functions.https.onCall(async (data, context) => {
  const { documentId, documentUrl, tenantId } = data;

  if (!documentId || !documentUrl || !tenantId) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required parameters');
  }

  // TODO: Integrate Gemini Vision API here
  // const geminiResponse = await callGeminiVision(documentUrl);

  const mockResponse = {
    extractedDates: {
      'medicalCertExpiry': '2026-12-01'
    },
    extractedCertifications: {
      'firstAid': 'Level 2'
    },
    flags: [
      {
        field: 'medicalCertExpiry',
        issue: 'Expiring soon',
        severity: 'warning',
        detectedValue: '2026-12-01',
        expectedValue: 'Valid for at least 6 months'
      }
    ],
    confidenceScore: 0.95
  };

  const firestore = admin.firestore();
  
  await firestore.collection('tenants').doc(tenantId).collection('compliance_prescreens').add({
    documentId,
    submissionId: 'mock-submission',
    status: 'completed',
    flags: mockResponse.flags,
    confidenceScore: mockResponse.confidenceScore,
    extractedDates: mockResponse.extractedDates,
    extractedCertifications: mockResponse.extractedCertifications,
    processedAt: admin.firestore.FieldValue.serverTimestamp()
  });

  return { success: true };
});
