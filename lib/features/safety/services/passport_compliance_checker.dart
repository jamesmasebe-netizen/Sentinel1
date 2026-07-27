import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/app_providers.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

enum ComplianceLevel { compliant, warning, nonCompliant }

class ComplianceCheckResult {
  final ComplianceLevel level;
  final List<String> issues;
  final bool hasMedicalCert;
  final bool medicalCertValid;
  final DateTime? medicalCertExpiry;
  final int validTrainingCount;
  final int expiredTrainingCount;
  final int activePtwCount;
  final bool inductionCompleted;

  ComplianceCheckResult({
    required this.level,
    required this.issues,
    required this.hasMedicalCert,
    required this.medicalCertValid,
    this.medicalCertExpiry,
    required this.validTrainingCount,
    required this.expiredTrainingCount,
    required this.activePtwCount,
    required this.inductionCompleted,
  });
}

final passportComplianceCheckerProvider = Provider<PassportComplianceChecker>((
  ref,
) {
  final tenantId = ref.read(currentTenantIdProvider) ?? '';
  return PassportComplianceChecker(FirebaseFirestore.instance, tenantId);
});

class PassportComplianceChecker {
  /// Minimum safety file score threshold for compliance (configurable)
  static const int safetyScoreThreshold = 80;

  final FirebaseFirestore _db;
  final String _tenantId;

  PassportComplianceChecker(this._db, this._tenantId);

  Future<ComplianceCheckResult> checkEmployeeCompliance(
    String employeeId,
  ) async {
    final issues = <String>[];
    final now = DateTime.now();

    // 1. Check medical certificate
    bool hasMedicalCert = false;
    bool medicalCertValid = false;
    DateTime? medicalCertExpiry;
    final medSnap =
        await _db
            .tenantCollection(_tenantId, 'training_records')
            .where('employeeId', isEqualTo: employeeId)
            .where('type', isEqualTo: 'medical_certificate')
            .get();
    if (medSnap.docs.isNotEmpty) {
      hasMedicalCert = true;
      final expiryStr = medSnap.docs.first.data()['expiryDate'];
      if (expiryStr != null) {
        medicalCertExpiry = DateTime.tryParse(expiryStr.toString());
        medicalCertValid =
            medicalCertExpiry != null && medicalCertExpiry.isAfter(now);
        if (!medicalCertValid) issues.add('Medical certificate expired');
      } else {
        medicalCertValid = true;
      }
    } else {
      issues.add('No medical certificate on file');
    }

    // 2. Check training records
    final trainingSnap =
        await _db
            .tenantCollection(_tenantId, 'training_records')
            .where('employeeId', isEqualTo: employeeId)
            .get();
    int validCount = 0;
    int expiredCount = 0;
    for (final doc in trainingSnap.docs) {
      final data = doc.data();
      if (data['type'] == 'medical_certificate') continue;
      final expiry = data['expiryDate'];
      if (expiry != null) {
        final expiryDate = DateTime.tryParse(expiry.toString());
        if (expiryDate != null && expiryDate.isBefore(now)) {
          expiredCount++;
        } else {
          validCount++;
        }
      } else {
        validCount++;
      }
    }
    if (expiredCount > 0) {
      issues.add('$expiredCount training record(s) expired');
    }

    // 3. Check induction
    bool inductionCompleted = false;
    final inductionSnap =
        await _db
            .tenantCollection(_tenantId, 'training_records')
            .where('employeeId', isEqualTo: employeeId)
            .where('type', isEqualTo: 'induction')
            .get();
    inductionCompleted = inductionSnap.docs.isNotEmpty;
    if (!inductionCompleted) issues.add('Site induction not completed');

    // 4. Count active PTWs
    final permitsSnap =
        await _db
            .tenantCollection(_tenantId, 'permits')
            .where('status', whereIn: ['active', 'approved'])
            .get();
    final activePtwCount =
        permitsSnap.docs.where((d) {
          final workers = d.data()['workers'] as List<dynamic>? ?? [];
          return workers.any((w) {
            if (w is Map) return w['employeeId'] == employeeId;
            return w.toString() == employeeId;
          });
        }).length;

    // Determine overall level
    ComplianceLevel level;
    if (issues.any((i) => i.contains('expired') || i.contains('No medical'))) {
      level = ComplianceLevel.nonCompliant;
    } else if (issues.isNotEmpty) {
      level = ComplianceLevel.warning;
    } else {
      level = ComplianceLevel.compliant;
    }

    return ComplianceCheckResult(
      level: level,
      issues: issues,
      hasMedicalCert: hasMedicalCert,
      medicalCertValid: medicalCertValid,
      medicalCertExpiry: medicalCertExpiry,
      validTrainingCount: validCount,
      expiredTrainingCount: expiredCount,
      activePtwCount: activePtwCount,
      inductionCompleted: inductionCompleted,
    );
  }

  Future<ComplianceCheckResult> checkContractorCompliance(
    String contractorId,
  ) async {
    final issues = <String>[];

    // Check contractor safety file
    final safetyFileSnap =
        await _db
            .tenantCollection(_tenantId, 'contractor_safety_files')
            .where('contractorId', isEqualTo: contractorId)
            .get();

    bool hasMedicalCert = false;
    bool medicalCertValid = false;
    bool inductionCompleted = false;

    if (safetyFileSnap.docs.isNotEmpty) {
      final data = safetyFileSnap.docs.first.data();
      final score = data['score'] as int? ?? 0;
      if (score < safetyScoreThreshold) {
        issues.add('Safety file score below $safetyScoreThreshold%');
      }
      hasMedicalCert = true;
      medicalCertValid = true;
      inductionCompleted = true;
    } else {
      issues.add('No safety file found');
    }

    // Count active PTWs
    final permitsSnap =
        await _db
            .tenantCollection(_tenantId, 'permits')
            .where('status', whereIn: ['active', 'approved'])
            .where('contractorId', isEqualTo: contractorId)
            .get();

    final activePtwCount = permitsSnap.docs.length;

    ComplianceLevel level;
    if (issues.isNotEmpty) {
      level = ComplianceLevel.nonCompliant;
    } else {
      level = ComplianceLevel.compliant;
    }

    return ComplianceCheckResult(
      level: level,
      issues: issues,
      hasMedicalCert: hasMedicalCert,
      medicalCertValid: medicalCertValid,
      validTrainingCount: 0,
      expiredTrainingCount: 0,
      activePtwCount: activePtwCount,
      inductionCompleted: inductionCompleted,
    );
  }
}
