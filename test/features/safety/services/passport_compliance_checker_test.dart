// Tests for PassportComplianceChecker.checkEmployeeCompliance — the single
// source of truth for whether an employee is compliant to work, consumed by
// the QR scanner and contractor/employee list screens. Safety-critical: a
// false "compliant" here means someone works without valid medical
// clearance, induction, or training. Uses fake_cloud_firestore per
// docs/testing/TEST_STRATEGY.md (provider/service test row) — this does NOT
// assert authorization/rules behavior, only compliance-derivation logic.
//
// FIXED 2026-08-12: the medical-certificate check now reads health's real
// `medical_records` collection (see seedMedicalRecord in
// passport_compliance_fixtures.dart) instead of `training_records` filtered
// by `type == 'medical_certificate'` — nothing anywhere ever wrote that
// shape, so this check silently failed "No medical certificate on file" for
// every real employee regardless of their actual medical status. Also now
// checks the record's real `status` field (an `Unfit` result fails the
// check even with a future `nextDueDate`), not just expiry.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel1/features/safety/services/passport_compliance_checker.dart';

import '../../../helpers/passport_compliance_fixtures.dart';

void main() {
  late FakeFirebaseFirestore db;
  late PassportComplianceChecker checker;

  setUp(() {
    db = FakeFirebaseFirestore();
    checker = PassportComplianceChecker(db, testTenantId);
  });

  final future = DateTime.now().add(const Duration(days: 365));
  final past = DateTime.now().subtract(const Duration(days: 1));

  group('fully compliant employee', () {
    test('valid medical cert + valid training + induction -> compliant, no issues',
        () async {
      const empId = 'EMP-001';
      await seedMedicalRecord(db, employeeId: empId, nextDueDate: future);
      await seedTrainingRecord(db,
          employeeId: empId, type: 'induction');
      await seedTrainingRecord(db,
          employeeId: empId, type: 'first_aid', expiryDate: future);

      final result = await checker.checkEmployeeCompliance(empId);

      expect(result.level, ComplianceLevel.compliant);
      expect(result.issues, isEmpty);
      expect(result.hasMedicalCert, isTrue);
      expect(result.medicalCertValid, isTrue);
      expect(result.inductionCompleted, isTrue);
      // The induction record counts as a generic valid training too
      // (induction + first_aid) — medical is now a separate collection
      // entirely, not filtered out of this count anymore.
      expect(result.validTrainingCount, 2);
      expect(result.expiredTrainingCount, 0);
    });

    test('medical record with no nextDueDate field is treated as perpetually valid',
        () async {
      const empId = 'EMP-002';
      await seedMedicalRecord(db, employeeId: empId); // no nextDueDate
      await seedTrainingRecord(db, employeeId: empId, type: 'induction');

      final result = await checker.checkEmployeeCompliance(empId);

      expect(result.hasMedicalCert, isTrue);
      expect(result.medicalCertValid, isTrue);
      expect(result.medicalCertExpiry, isNull);
      expect(result.issues, isEmpty);
      expect(result.level, ComplianceLevel.compliant);
    });

    test('picks the most recent record by dateConducted when several exist', () async {
      const empId = 'EMP-003';
      await seedMedicalRecord(db,
          employeeId: empId,
          status: 'Unfit',
          dateConducted: DateTime.now().subtract(const Duration(days: 365)));
      await seedMedicalRecord(db,
          employeeId: empId,
          status: 'Fit',
          nextDueDate: future,
          dateConducted: DateTime.now());
      await seedTrainingRecord(db, employeeId: empId, type: 'induction');

      final result = await checker.checkEmployeeCompliance(empId);

      expect(result.medicalCertValid, isTrue);
      expect(result.issues, isEmpty);
    });
  });

  group('expired training -> nonCompliant', () {
    test('one expired non-medical training record fails the employee', () async {
      const empId = 'EMP-010';
      await seedMedicalRecord(db, employeeId: empId, nextDueDate: future);
      await seedTrainingRecord(db, employeeId: empId, type: 'induction');
      await seedTrainingRecord(db,
          employeeId: empId, type: 'working_at_heights', expiryDate: past);

      final result = await checker.checkEmployeeCompliance(empId);

      // Boundary case: the code's level rule treats ANY issue whose message
      // contains "expired" as nonCompliant, not merely "warning" — even a
      // single expired training record (not the medical cert) fails hard.
      expect(result.level, ComplianceLevel.nonCompliant);
      expect(result.issues, contains('1 training record(s) expired'));
      expect(result.expiredTrainingCount, 1);
      // The induction record counts as a valid generic training too (see
      // note above) — only `working_at_heights` is expired.
      expect(result.validTrainingCount, 1);
    });

    test('counts multiple expired and valid trainings independently', () async {
      const empId = 'EMP-011';
      await seedMedicalRecord(db, employeeId: empId, nextDueDate: future);
      await seedTrainingRecord(db, employeeId: empId, type: 'induction');
      await seedTrainingRecord(db,
          employeeId: empId, type: 'confined_space', expiryDate: past);
      await seedTrainingRecord(db,
          employeeId: empId, type: 'fire_safety', expiryDate: past);
      await seedTrainingRecord(db,
          employeeId: empId, type: 'first_aid', expiryDate: future);
      // No-expiry training records also count as valid.
      await seedTrainingRecord(db, employeeId: empId, type: 'orientation');

      final result = await checker.checkEmployeeCompliance(empId);

      expect(result.expiredTrainingCount, 2);
      // induction + first_aid + orientation are all valid (no-expiry counts
      // as valid too).
      expect(result.validTrainingCount, 3);
      expect(result.issues, contains('2 training record(s) expired'));
      expect(result.level, ComplianceLevel.nonCompliant);
    });
  });

  group('missing induction -> warning', () {
    test('otherwise-compliant employee without induction is a warning, not nonCompliant',
        () async {
      const empId = 'EMP-020';
      await seedMedicalRecord(db, employeeId: empId, nextDueDate: future);
      // No induction record seeded at all.

      final result = await checker.checkEmployeeCompliance(empId);

      expect(result.inductionCompleted, isFalse);
      expect(result.issues, ['Site induction not completed']);
      expect(result.level, ComplianceLevel.warning);
    });
  });

  group('expired medical cert -> nonCompliant', () {
    test('medical record past its nextDueDate fails hard', () async {
      const empId = 'EMP-030';
      await seedMedicalRecord(db, employeeId: empId, nextDueDate: past);
      await seedTrainingRecord(db, employeeId: empId, type: 'induction');

      final result = await checker.checkEmployeeCompliance(empId);

      expect(result.hasMedicalCert, isTrue);
      expect(result.medicalCertValid, isFalse);
      expect(result.medicalCertExpiry, past);
      expect(result.issues, contains('Medical certificate expired'));
      expect(result.level, ComplianceLevel.nonCompliant);
    });

    test('a Fit-status record is still valid even close to its next due date', () async {
      const empId = 'EMP-031';
      await seedMedicalRecord(db, employeeId: empId, status: 'Fit', nextDueDate: future);
      await seedTrainingRecord(db, employeeId: empId, type: 'induction');

      final result = await checker.checkEmployeeCompliance(empId);

      expect(result.medicalCertValid, isTrue);
      expect(result.issues, isEmpty);
    });

    test('an Unfit-status record fails even with a future nextDueDate', () async {
      const empId = 'EMP-032';
      await seedMedicalRecord(db, employeeId: empId, status: 'Unfit', nextDueDate: future);
      await seedTrainingRecord(db, employeeId: empId, type: 'induction');

      final result = await checker.checkEmployeeCompliance(empId);

      expect(result.hasMedicalCert, isTrue);
      expect(result.medicalCertValid, isFalse);
      expect(result.issues, contains('Medical status: Unfit'));
      expect(result.level, ComplianceLevel.nonCompliant);
    });
  });

  group('no medical certificate on file -> nonCompliant', () {
    test('zero medical_records docs for the employee', () async {
      const empId = 'EMP-040';
      await seedTrainingRecord(db, employeeId: empId, type: 'induction');

      final result = await checker.checkEmployeeCompliance(empId);

      expect(result.hasMedicalCert, isFalse);
      expect(result.medicalCertValid, isFalse);
      expect(result.medicalCertExpiry, isNull);
      expect(result.issues, contains('No medical certificate on file'));
      expect(result.level, ComplianceLevel.nonCompliant);
    });
  });

  group('active PTW counting', () {
    test('counts permits where the employee appears as a map-shaped worker',
        () async {
      const empId = 'EMP-050';
      await seedMedicalRecord(db, employeeId: empId, nextDueDate: future);
      await seedTrainingRecord(db, employeeId: empId, type: 'induction');
      await seedPermit(db, status: 'active', workers: [
        {'employeeId': empId},
        {'employeeId': 'someone-else'},
      ]);
      await seedPermit(db, status: 'approved', workers: [empId]);
      // Not counted: wrong status.
      await seedPermit(db, status: 'closed', workers: [empId]);
      // Not counted: different employee.
      await seedPermit(db, status: 'active', workers: ['someone-else']);

      final result = await checker.checkEmployeeCompliance(empId);

      expect(result.activePtwCount, 2);
    });
  });
}
