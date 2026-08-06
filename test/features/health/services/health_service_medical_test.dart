// Tests for HealthService (lib/features/health/services/health_service.dart) — medical_records
// coverage. Wave 2b service-layer extraction, mirroring compliance_service_test.dart's pattern.
// This collection had no field-shape bug (MedicalForm already wrote `employeeName` correctly,
// unlike first_aid_logs) — this file verifies the extraction preserves exact prior behavior,
// plus that the status distribution MedicalsTab aggregates into Fit/Restricted/Unfit counts for
// OHStatChip survives the stream unchanged.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel1/core/providers/app_providers.dart';
import 'package:sentinel1/features/health/models/medical_record.dart';
import 'package:sentinel1/features/health/services/health_service.dart';

const _tenantId = 'test-tenant';
const _otherTenantId = 'other-tenant';

MedicalRecord _buildRecord({
  String id = '',
  String employeeId = 'emp-1',
  String employeeName = 'Alice Smith',
  String idNumber = '8001015800080',
  String medicalType = 'Annual',
  String status = 'Fit',
  String restrictions = '',
  String practitionerName = 'Dr. Naidoo',
  String facility = 'Occu-Health Clinic',
  DateTime? dateConducted,
  DateTime? nextDueDate,
  String siteId = _tenantId,
}) {
  return MedicalRecord(
    id: id,
    employeeId: employeeId,
    employeeName: employeeName,
    idNumber: idNumber,
    medicalType: medicalType,
    status: status,
    restrictions: restrictions,
    practitionerName: practitionerName,
    facility: facility,
    dateConducted: dateConducted ?? DateTime.now(),
    nextDueDate: nextDueDate ?? DateTime.now().add(const Duration(days: 365)),
    authorId: 'author-1',
    siteId: siteId,
    createdAt: DateTime.now(),
  );
}

void main() {
  late FakeFirebaseFirestore db;
  late ProviderContainer container;
  late HealthService service;

  setUp(() {
    db = FakeFirebaseFirestore();
    container = ProviderContainer(overrides: [
      firestoreProvider.overrideWithValue(db),
      currentTenantIdProvider.overrideWithValue(_tenantId),
    ]);
    addTearDown(container.dispose);
    service = container.read(healthServiceProvider);
  });

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> rawDocs() async {
    final snap =
        await db.collection('tenants').doc(_tenantId).collection('medical_records').get();
    return snap.docs;
  }

  group('createMedicalRecord', () {
    test('writes the exact field shape MedicalForm previously wrote inline', () async {
      await service.createMedicalRecord(_buildRecord(
        employeeName: 'Thabo Nkosi',
        medicalType: 'Exit',
        status: 'Fit with Restrictions',
        restrictions: 'No heavy lifting',
      ));

      final docs = await rawDocs();
      expect(docs, hasLength(1));
      final data = docs.single.data();
      expect(data.keys.toSet(), {
        'employeeId',
        'employeeName',
        'idNumber',
        'medicalType',
        'status',
        'restrictions',
        'practitionerName',
        'facility',
        'dateConducted',
        'nextDueDate',
        'authorId',
        'siteId',
        'createdAt',
      });
      expect(data['employeeName'], 'Thabo Nkosi');
      expect(data['status'], 'Fit with Restrictions');
      expect(data['restrictions'], 'No heavy lifting');
      expect(data['dateConducted'], isA<String>());
      expect(data['nextDueDate'], isA<String>());
      expect(DateTime.tryParse(data['nextDueDate'] as String), isNotNull);
    });
  });

  group('streamMedicalRecords', () {
    test('returns only this tenant\'s records, newest first', () async {
      await service.createMedicalRecord(_buildRecord(employeeName: 'Older Record'));
      await Future.delayed(const Duration(milliseconds: 5));
      await service.createMedicalRecord(_buildRecord(employeeName: 'Newer Record'));
      await db
          .collection('tenants')
          .doc(_otherTenantId)
          .collection('medical_records')
          .add(_buildRecord(employeeName: 'Other Tenant Record', siteId: _otherTenantId)
              .toFirestore());

      final records = await service.streamMedicalRecords().first;

      expect(records.map((r) => r.employeeName), ['Newer Record', 'Older Record']);
    });

    test('preserves each record\'s status distribution for MedicalsTab\'s Fit/Restricted/Unfit '
        'aggregation', () async {
      await service.createMedicalRecord(_buildRecord(employeeName: 'A', status: 'Fit'));
      await service.createMedicalRecord(
          _buildRecord(employeeName: 'B', status: 'Fit with Restrictions'));
      await service.createMedicalRecord(_buildRecord(employeeName: 'C', status: 'Unfit'));

      final records = await service.streamMedicalRecords().first;

      // Same classification MedicalsTab's build() applies to the streamed list.
      final fit = records.where((r) => r.status == 'Fit').length;
      final restricted = records.where((r) => r.status.contains('Restriction')).length;
      final unfit = records.where((r) => r.status == 'Unfit').length;
      expect(records, hasLength(3));
      expect(fit, 1);
      expect(restricted, 1);
      expect(unfit, 1);
    });
  });
}
