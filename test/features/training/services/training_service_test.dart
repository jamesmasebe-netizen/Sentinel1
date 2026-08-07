// Tests for TrainingService (lib/features/training/services/training_service.dart).
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

  test('getComprehensiveEmployeeRecord aggregates enrollments, training_enrollments, and training_records for the employee',
      () async {
    await firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('enrollments')
        .doc('enr-1')
        .set({'employeeId': employeeId, 'courseId': 'course-1'});
    await firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('training_enrollments')
        .doc('te-1')
        .set({'employeeId': employeeId, 'courseId': 'course-2'});
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
    expect(result.enrollments, hasLength(1));
    expect(result.trainingEnrollments, hasLength(1));
    expect(result.trainingRecords, hasLength(1));
    expect(result.trainingRecords.single['certificate'], 'First Aid');
  });

  test('returns empty lists for an employee with no training data', () async {
    final result = await service.getComprehensiveEmployeeRecord('emp-none');

    expect(result.enrollments, isEmpty);
    expect(result.trainingEnrollments, isEmpty);
    expect(result.trainingRecords, isEmpty);
  });
}
