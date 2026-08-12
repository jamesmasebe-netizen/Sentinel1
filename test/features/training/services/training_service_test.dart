// Tests for TrainingService (lib/features/training/services/training_service.dart).
//
// FIXED 2026-08-12: 'enrollments' and 'training_enrollments' unified onto one collection
// ('enrollments', discriminated by Enrollment.source) — the identical underlying concept
// (self-paced vs. manager-assigned course progress) previously split across 2 collections for no
// real reason. getComprehensiveEmployeeRecord is now a 2-way fan-out (enrollments +
// training_records), not 3-way.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel1/features/training/services/training_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late TrainingService service;
  const tenantId = 'tenant-training-1';
  const employeeId = 'emp-1';

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = TrainingService(firestore, tenantId);
  });

  test('getComprehensiveEmployeeRecord aggregates enrollments (self-paced + manager-assigned) and training_records for the employee',
      () async {
    await firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('enrollments')
        .doc('enr-1')
        .set({'employeeId': employeeId, 'courseId': 'course-1', 'source': 'self_paced'});
    await firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('enrollments')
        .doc('enr-2')
        .set({'employeeId': employeeId, 'courseId': 'course-2', 'source': 'manager_assigned'});
    await firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('training_records')
        .doc('tr-1')
        .set({'employeeId': employeeId, 'certificate': 'First Aid'});
    // A different employee's data should not leak into this record.
    await firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('training_records')
        .doc('tr-2')
        .set({'employeeId': 'emp-2', 'certificate': 'Forklift'});

    final result = await service.getComprehensiveEmployeeRecord(employeeId);

    expect(result.employeeId, employeeId);
    expect(result.enrollments, hasLength(2));
    expect(
      result.enrollments.map((e) => e['source']),
      containsAll(['self_paced', 'manager_assigned']),
    );
    expect(result.trainingRecords, hasLength(1));
    expect(result.trainingRecords.single['certificate'], 'First Aid');
  });

  test('returns empty lists for an employee with no training data', () async {
    final result = await service.getComprehensiveEmployeeRecord('emp-none');

    expect(result.enrollments, isEmpty);
    expect(result.trainingRecords, isEmpty);
  });
}
