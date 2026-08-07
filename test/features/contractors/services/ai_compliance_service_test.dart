// Tests for AiComplianceService (lib/features/contractors/services/ai_compliance_service.dart).
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sentinel1/features/contractors/models/compliance_prescreen_models.dart';
import 'package:sentinel1/features/contractors/services/ai_compliance_service.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class MockHttpsCallable extends Mock implements HttpsCallable {}

class MockHttpsCallableResult extends Mock
    implements HttpsCallableResult<dynamic> {}

void main() {
  const tenantId = 'tenant-contractors-1';

  group('triggerPreScreen', () {
    late MockFirebaseFunctions functions;
    late MockHttpsCallable callable;
    late AiComplianceService service;

    setUp(() {
      functions = MockFirebaseFunctions();
      callable = MockHttpsCallable();
      service = AiComplianceService(FakeFirebaseFirestore(), functions, tenantId);
      when(() => functions.httpsCallable('preScreenComplianceDocument')).thenReturn(callable);
    });

    test('calls the callable with documentId, documentUrl, and tenantId', () async {
      final result = MockHttpsCallableResult();
      when(() => callable.call<dynamic>(any())).thenAnswer((_) async => result);

      await service.triggerPreScreen('doc-1', 'https://storage.test/doc-1.pdf');

      final captured = verify(() => callable.call<dynamic>(captureAny())).captured.single as Map;
      expect(captured, {
        'documentId': 'doc-1',
        'documentUrl': 'https://storage.test/doc-1.pdf',
        'tenantId': tenantId,
      });
    });

    test('is a no-op when there is no active tenant', () async {
      final noTenantService = AiComplianceService(FakeFirebaseFirestore(), functions, '');

      await noTenantService.triggerPreScreen('doc-2', 'https://storage.test/doc-2.pdf');

      verifyNever(() => callable.call<dynamic>(any()));
    });

    test('rethrows a callable failure rather than swallowing it', () async {
      when(() => callable.call<dynamic>(any())).thenThrow(Exception('function unavailable'));

      await expectLater(
        () => service.triggerPreScreen('doc-3', 'https://storage.test/doc-3.pdf'),
        throwsException,
      );
    });
  });

  group('streamPreScreenResult', () {
    late FakeFirebaseFirestore firestore;
    late AiComplianceService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = AiComplianceService(firestore, MockFirebaseFunctions(), tenantId);
    });

    test('returns null when no pre-screen result exists yet for the document', () async {
      final result = await service.streamPreScreenResult('doc-4').first;
      expect(result, isNull);
    });

    test('returns the matching result, parsed correctly', () async {
      await firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('compliance_prescreens')
          .doc('screen-1')
          .set({
        'documentId': 'doc-5',
        'submissionId': 'sub-1',
        'status': 'completed',
        'flags': [],
        'confidenceScore': 0.92,
        'extractedDates': {},
        'extractedCertifications': {},
      });

      final result = await service.streamPreScreenResult('doc-5').first;

      expect(result, isNotNull);
      expect(result!.status, PreScreenStatus.completed);
      expect(result.confidenceScore, 0.92);
    });

    test('returns null when there is no active tenant', () async {
      final noTenantService = AiComplianceService(firestore, MockFirebaseFunctions(), '');
      final result = await noTenantService.streamPreScreenResult('doc-6').first;
      expect(result, isNull);
    });
  });
}
