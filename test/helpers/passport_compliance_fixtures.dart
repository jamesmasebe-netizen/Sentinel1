// Shared fixture builders for PassportComplianceChecker tests. Seeds
// `fake_cloud_firestore` documents at the same tenant-scoped paths the real
// service reads (`tenants/{tenantId}/{collection}`), matching
// `tenantCollection()` in lib/core/utils/tenant_firestore_extension.dart.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

const testTenantId = 'test-tenant';

/// Seeds a `training_records` doc. [type] drives which branch of
/// `checkEmployeeCompliance` reads it: 'medical_certificate' | 'induction' |
/// any other string (treated as a generic training record).
Future<void> seedTrainingRecord(
  FirebaseFirestore db, {
  required String employeeId,
  required String type,
  DateTime? expiryDate,
}) async {
  await db.tenantCollection(testTenantId, 'training_records').add({
    'employeeId': employeeId,
    'type': type,
    if (expiryDate != null) 'expiryDate': expiryDate.toIso8601String(),
  });
}

/// Seeds a `permits` doc. [workers] may contain either raw employee ID
/// strings or `{'employeeId': ...}` maps — the checker supports both shapes.
Future<void> seedPermit(
  FirebaseFirestore db, {
  required String status,
  List<dynamic> workers = const [],
  String? contractorId,
}) async {
  await db.tenantCollection(testTenantId, 'permits').add({
    'status': status,
    'workers': workers,
    if (contractorId != null) 'contractorId': contractorId,
  });
}

/// Seeds a `contractor_safety_files` doc.
Future<void> seedContractorSafetyFile(
  FirebaseFirestore db, {
  required String contractorId,
  required int score,
}) async {
  await db.tenantCollection(testTenantId, 'contractor_safety_files').add({
    'contractorId': contractorId,
    'score': score,
  });
}
