import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

final trainingServiceProvider = Provider<TrainingService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final tenantId = ref.watch(currentTenantIdProvider) ?? "";
  return TrainingService(firestore, tenantId);
});

/// Unified 2026-08-12: 'enrollments' now covers both self-paced (CoursePlayerScreen) and
/// manager-assigned (AllocateCourseForm) progress tracking, discriminated by Enrollment.source —
/// previously 2 separate collections ('enrollments'/'training_enrollments') for the identical
/// underlying concept. 'training_records' stays separate — a genuinely different concept
/// (completion/qualification certificates, not in-progress tracking).
class ComprehensiveTrainingRecord {
  final String employeeId;
  final List<Map<String, dynamic>> enrollments;
  final List<Map<String, dynamic>> trainingRecords;

  ComprehensiveTrainingRecord({
    required this.employeeId,
    required this.enrollments,
    required this.trainingRecords,
  });
}

class TrainingService {
  final FirebaseFirestore _firestore;
  final String _tenantId;

  TrainingService(this._firestore, this._tenantId);

  Future<ComprehensiveTrainingRecord> getComprehensiveEmployeeRecord(String employeeId) async {
    final futures = await Future.wait([
      _firestore.tenantCollection(_tenantId, 'enrollments').where('employeeId', isEqualTo: employeeId).get(),
      _firestore.tenantCollection(_tenantId, 'training_records').where('employeeId', isEqualTo: employeeId).get(),
    ]);

    return ComprehensiveTrainingRecord(
      employeeId: employeeId,
      enrollments: futures[0].docs.map((d) => {'id': d.id, ...d.data()}).toList(),
      trainingRecords: futures[1].docs.map((d) => {'id': d.id, ...d.data()}).toList(),
    );
  }
}
