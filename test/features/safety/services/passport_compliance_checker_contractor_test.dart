// Tests for PassportComplianceChecker.checkContractorCompliance — the
// safety-file-based equivalent of employee compliance, consumed by the
// contractor list/QR scanner. Notable asymmetry vs. the employee path (see
// passport_compliance_checker_test.dart): there is no `warning` level here —
// checkContractorCompliance only ever returns compliant or nonCompliant,
// since its `issues.isNotEmpty` branch goes straight to nonCompliant with no
// intermediate bucket. That asymmetry is deliberately pinned down below.
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

  group('fully compliant contractor', () {
    test('safety file with score >= threshold -> compliant, no issues',
        () async {
      const contractorId = 'CTR-001';
      await seedContractorSafetyFile(db, contractorId: contractorId, score: 92);

      final result = await checker.checkContractorCompliance(contractorId);

      expect(result.level, ComplianceLevel.compliant);
      expect(result.issues, isEmpty);
      expect(result.hasMedicalCert, isTrue);
      expect(result.medicalCertValid, isTrue);
      expect(result.inductionCompleted, isTrue);
    });

    test('boundary: score exactly at the 80% threshold passes (not < 80)',
        () async {
      const contractorId = 'CTR-002';
      await seedContractorSafetyFile(db, contractorId: contractorId, score: 80);

      final result = await checker.checkContractorCompliance(contractorId);

      expect(result.issues, isEmpty);
      expect(result.level, ComplianceLevel.compliant);
    });
  });

  group('safety-file score below threshold -> nonCompliant', () {
    test('boundary: score one point below threshold (79) fails', () async {
      const contractorId = 'CTR-010';
      await seedContractorSafetyFile(db, contractorId: contractorId, score: 79);

      final result = await checker.checkContractorCompliance(contractorId);

      expect(result.issues, contains('Safety file score below 80%'));
      // No `warning` level exists for contractors — a failing score goes
      // straight to nonCompliant.
      expect(result.level, ComplianceLevel.nonCompliant);
    });

    test('a low score still marks hasMedicalCert/induction true, since those '
        'booleans only reflect "a safety file exists", not the score',
        () async {
      const contractorId = 'CTR-011';
      await seedContractorSafetyFile(db, contractorId: contractorId, score: 10);

      final result = await checker.checkContractorCompliance(contractorId);

      expect(result.hasMedicalCert, isTrue);
      expect(result.medicalCertValid, isTrue);
      expect(result.inductionCompleted, isTrue);
      expect(result.level, ComplianceLevel.nonCompliant);
    });
  });

  group('no safety file on record -> nonCompliant', () {
    test('zero contractor_safety_files docs for the contractor', () async {
      const contractorId = 'CTR-020';

      final result = await checker.checkContractorCompliance(contractorId);

      expect(result.hasMedicalCert, isFalse);
      expect(result.medicalCertValid, isFalse);
      expect(result.inductionCompleted, isFalse);
      expect(result.issues, contains('No safety file found'));
      expect(result.level, ComplianceLevel.nonCompliant);
    });
  });

  group('active PTW counting', () {
    test('counts only active/approved permits tagged with this contractorId',
        () async {
      const contractorId = 'CTR-030';
      await seedContractorSafetyFile(db, contractorId: contractorId, score: 95);
      await seedPermit(db, status: 'active', contractorId: contractorId);
      await seedPermit(db, status: 'approved', contractorId: contractorId);
      // Not counted: wrong status.
      await seedPermit(db, status: 'closed', contractorId: contractorId);
      // Not counted: different contractor.
      await seedPermit(db, status: 'active', contractorId: 'CTR-999');

      final result = await checker.checkContractorCompliance(contractorId);

      expect(result.activePtwCount, 2);
    });
  });
}
