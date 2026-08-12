// Shared fixture builders for PassportComplianceChecker tests. Seeds
// `fake_cloud_firestore` documents at the same tenant-scoped paths the real
// service reads (`tenants/{tenantId}/{collection}`), matching
// `tenantCollection()` in lib/core/utils/tenant_firestore_extension.dart.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

const testTenantId = 'test-tenant';

/// Seeds a `training_records` doc. [type] drives which branch of
/// `checkEmployeeCompliance` reads it: 'induction' | any other string
/// (treated as a generic training record). Medical certificates moved to
/// `medical_records` (see [seedMedicalRecord]) 2026-08-12 — this collection
/// never had a real writer for that shape.
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

/// Seeds a `medical_records` doc — health's real occupational-medicine
/// record, now what `checkEmployeeCompliance`'s medical-certificate check
/// actually reads (2026-08-12). [dateConducted] defaults to now so a single
/// seeded record is always "the latest" in tests with only one record;
/// override it to test the most-recent-record-wins logic across several.
Future<void> seedMedicalRecord(
  FirebaseFirestore db, {
  required String employeeId,
  DateTime? nextDueDate,
  String status = 'Fit',
  DateTime? dateConducted,
}) async {
  await db.tenantCollection(testTenantId, 'medical_records').add({
    'employeeId': employeeId,
    'status': status,
    'dateConducted': (dateConducted ?? DateTime.now()).toIso8601String(),
    if (nextDueDate != null) 'nextDueDate': nextDueDate.toIso8601String(),
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
