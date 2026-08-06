// Tests for WorkersCompService's claims surface
// (lib/features/workers_comp/services/workers_comp_service.dart) — the service layer extracted
// from workers_comp's previously-inline Firestore calls in claims_tab.dart/rtw_tab.dart (Wave 2b,
// 2026-08-06), mirroring compliance_service_test.dart's structure/rigor. Split from the checklist
// half (workers_comp_service_checklist_test.dart) to respect the 200-line threshold (AGENTS.md §4).
//
// FIXED 2026-08-06: createClaim now routes through FirestoreService.createDocument (offline-queue
// + audit-log), not a direct Firestore write — see compliance_service_test.dart's header comment
// for the full story. Stream/update tests seed raw claims directly (updateClaimStatus/
// updateClaimRtwStatus were always direct writes already, matching the original, so those are
// unaffected).
//
// Specific focus: claims_tab.dart and rtw_tab.dart previously each hand-copied a generic
// `_updateStatus(id, field, value)` Firestore field-updater verbatim; this file asserts the two
// typed replacement methods (updateClaimStatus/updateClaimRtwStatus) each touch only their own
// field, never the other's.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sentinel1/core/providers/app_providers.dart';
import 'package:sentinel1/core/services/offline_sync_service.dart';
import 'package:sentinel1/features/workers_comp/models/workers_comp_claim.dart';
import 'package:sentinel1/features/workers_comp/services/workers_comp_service.dart';

class MockOfflineSyncService extends Mock implements OfflineSyncService {}

const _tenantId = 'test-tenant';
const _otherTenantId = 'other-tenant';

WorkersCompClaim _buildClaim({
  String id = '',
  String employeeId = 'emp-1',
  String employeeName = 'Jane Worker',
  String idNumber = '8501015800086',
  String claimNumber = 'CLM-1',
  DateTime? incidentDate,
  int lostDays = 5,
  String status = 'Submitted',
  String rtwStatus = 'Off Sick',
  String siteId = _tenantId,
}) {
  return WorkersCompClaim(
    id: id,
    employeeId: employeeId,
    employeeName: employeeName,
    idNumber: idNumber,
    claimNumber: claimNumber,
    incidentDate: incidentDate ?? DateTime.now().subtract(const Duration(days: 3)),
    lostDays: lostDays,
    status: status,
    rtwStatus: rtwStatus,
    authorId: 'author-1',
    siteId: siteId,
    createdAt: DateTime.now(),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(OfflineOperation.create);
    registerFallbackValue(<String, dynamic>{});
  });

  late FakeFirebaseFirestore db;
  late MockOfflineSyncService offlineSync;
  late ProviderContainer container;
  late WorkersCompService service;

  setUp(() {
    db = FakeFirebaseFirestore();
    offlineSync = MockOfflineSyncService();
    when(() => offlineSync.queueOperation(
          operation: any(named: 'operation'),
          collection: any(named: 'collection'),
          data: any(named: 'data'),
          documentId: any(named: 'documentId'),
        )).thenAnswer((_) async => 'queued-op-1');

    container = ProviderContainer(overrides: [
      firestoreProvider.overrideWithValue(db),
      offlineSyncServiceProvider.overrideWithValue(offlineSync),
      currentTenantIdProvider.overrideWithValue(_tenantId),
    ]);
    addTearDown(container.dispose);
    service = container.read(workersCompServiceProvider);
  });

  List<dynamic> capturedQueueArgs() {
    return verify(() => offlineSync.queueOperation(
          operation: captureAny(named: 'operation'),
          collection: captureAny(named: 'collection'),
          data: captureAny(named: 'data'),
          documentId: captureAny(named: 'documentId'),
        )).captured;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> rawClaims() async {
    final snap = await db.collection('tenants').doc(_tenantId).collection('coida_claims').get();
    return snap.docs;
  }

  Future<String> seedRawClaim(WorkersCompClaim claim, {String tenantId = _tenantId}) async {
    final ref = await db
        .collection('tenants')
        .doc(tenantId)
        .collection('coida_claims')
        .add(claim.toFirestore());
    return ref.id;
  }

  group('createClaim', () {
    test('queues the exact field shape ClaimsTab previously wrote inline, via the offline-first path',
        () async {
      await service.createClaim(_buildClaim(
        employeeId: 'emp-42',
        employeeName: 'John Smith',
        idNumber: '9001015800089',
        claimNumber: 'CLM-042',
        lostDays: 12,
      ));

      final args = capturedQueueArgs();
      expect(args[1], 'tenants/$_tenantId/coida_claims');
      final data = args[2] as Map<String, dynamic>;
      expect(data.keys.toSet(), {
        'employeeId',
        'employeeName',
        'idNumber',
        'claimNumber',
        'incidentDate',
        'lostDays',
        'status',
        'rtwStatus',
        'authorId',
        'siteId',
        'createdAt',
      });
      expect(data['employeeId'], 'emp-42');
      expect(data['employeeName'], 'John Smith');
      expect(data['claimNumber'], 'CLM-042');
      expect(data['lostDays'], 12);
      expect(data['status'], 'Submitted');
      expect(data['rtwStatus'], 'Off Sick');
      // Dates are ISO8601 strings, not Timestamps — matching ClaimsTab's previous
      // `.toIso8601String()` inline write and RtwTab's plain-string reads.
      expect(data['incidentDate'], isA<String>());
      expect(DateTime.tryParse(data['incidentDate'] as String), isNotNull);
      expect(data['createdAt'], isA<String>());
      expect(DateTime.tryParse(data['createdAt'] as String), isNotNull);
    });
  });

  group('streamClaims', () {
    test('returns only this tenant\'s claims, newest first', () async {
      await seedRawClaim(_buildClaim(employeeName: 'Older Claim'));
      await Future.delayed(const Duration(milliseconds: 5));
      await seedRawClaim(_buildClaim(employeeName: 'Newer Claim'));
      await seedRawClaim(_buildClaim(employeeName: 'Other Tenant Claim', siteId: _otherTenantId),
          tenantId: _otherTenantId);

      final claims = await service.streamClaims().first;

      expect(claims.map((c) => c.employeeName), ['Newer Claim', 'Older Claim']);
    });
  });

  group('streamActiveRtwCases', () {
    test('excludes Closed claims and other tenants', () async {
      await seedRawClaim(_buildClaim(employeeName: 'Open Case', status: 'Submitted'));
      await seedRawClaim(_buildClaim(employeeName: 'Accepted Case', status: 'Accepted'));
      await seedRawClaim(_buildClaim(employeeName: 'Closed Case', status: 'Closed'));
      await seedRawClaim(
          _buildClaim(employeeName: 'Other Tenant Open', status: 'Submitted', siteId: _otherTenantId),
          tenantId: _otherTenantId);

      final claims = await service.streamActiveRtwCases().first;

      expect(claims.map((c) => c.employeeName).toSet(), {'Open Case', 'Accepted Case'});
    });
  });

  group('updateClaimStatus vs updateClaimRtwStatus', () {
    test('updateClaimStatus changes only status, leaving rtwStatus untouched', () async {
      final id = await seedRawClaim(_buildClaim(status: 'Submitted', rtwStatus: 'Off Sick'));

      await service.updateClaimStatus(id, 'Accepted');

      final data = (await rawClaims()).single.data();
      expect(data['status'], 'Accepted');
      expect(data['rtwStatus'], 'Off Sick');
    });

    test('updateClaimRtwStatus changes only rtwStatus, leaving status untouched', () async {
      final id = await seedRawClaim(_buildClaim(status: 'Submitted', rtwStatus: 'Off Sick'));

      await service.updateClaimRtwStatus(id, 'Light Duty');

      final data = (await rawClaims()).single.data();
      expect(data['rtwStatus'], 'Light Duty');
      expect(data['status'], 'Submitted');
    });

    test('both methods together only ever touch their own field, cumulatively', () async {
      final id = await seedRawClaim(_buildClaim(status: 'Submitted', rtwStatus: 'Off Sick'));

      await service.updateClaimStatus(id, 'Accepted');
      await service.updateClaimRtwStatus(id, 'Full Duty');
      await service.updateClaimRtwStatus(id, 'Light Duty');

      final data = (await rawClaims()).single.data();
      expect(data['status'], 'Accepted');
      expect(data['rtwStatus'], 'Light Duty');
    });
  });
}
