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

    // 1. Check medical certificate — reads health's real medical_records collection (2026-08-12).
    // Previously read training_records where type == 'medical_certificate', but nothing anywhere
    // in lib/ ever wrote that shape, so this check silently reported "No medical certificate on
    // file" for every real employee regardless of their actual medical status.
    //
    // medical_records' own firestore.rules gate READ to isManager()||isSheqOfficer() (rightly —
    // it holds real occupational-health data), but this checker is reachable from QrScannerScreen
    // with no role gate of its own (e.g. gate/security staff running a passport scan). Caught
    // explicitly rather than letting a PERMISSION_DENIED crash the whole compliance check for a
    // legitimate lower-privileged caller — see NEEDS_YOUR_INPUT.md for the real fix this points
    // at (a Cloud Function proxy returning only the pass/fail verdict, not raw medical data).
    bool hasMedicalCert = false;
    bool medicalCertValid = false;
    DateTime? medicalCertExpiry;
    QuerySnapshot<Map<String, dynamic>>? medSnap;
    try {
      medSnap = await _db
          .tenantCollection(_tenantId, 'medical_records')
          .where('employeeId', isEqualTo: employeeId)
          .get();
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
      issues.add('Unable to verify medical status (insufficient permissions)');
    }
    if (medSnap != null && medSnap.docs.isNotEmpty) {
      hasMedicalCert = true;
      // Most recent exam by dateConducted — an employee may have several records over time.
      var latest = medSnap.docs.first;
      var latestDate = DateTime.tryParse(latest.data()['dateConducted']?.toString() ?? '');
      for (final doc in medSnap.docs.skip(1)) {
        final date = DateTime.tryParse(doc.data()['dateConducted']?.toString() ?? '');
        if (date != null && (latestDate == null || date.isAfter(latestDate))) {
          latest = doc;
          latestDate = date;
        }
      }
      final data = latest.data();
      medicalCertExpiry = DateTime.tryParse(data['nextDueDate']?.toString() ?? '');
      final isExpired = medicalCertExpiry != null && medicalCertExpiry.isBefore(now);
      final isUnfit = data['status'] == 'Unfit';
      medicalCertValid = !isExpired && !isUnfit;
      if (isExpired) issues.add('Medical certificate expired');
      if (isUnfit) issues.add('Medical status: Unfit');
    } else if (medSnap != null) {
      // A real, successful query that just found nothing — distinct from medSnap being null,
      // which means the query itself failed (permission-denied) and already added its own issue.
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
    if (issues.any((i) =>
        i.contains('expired') || i.contains('No medical') || i.contains('Unfit'))) {
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
