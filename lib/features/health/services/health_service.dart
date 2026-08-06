import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/tenant_firestore_extension.dart';
import '../models/first_aid_entry.dart';
import '../models/hygiene_survey.dart';
import '../models/medical_record.dart';

final healthServiceProvider = Provider<HealthService>((ref) {
  return HealthService(
    ref.watch(firestoreProvider),
    ref.watch(firestoreServiceProvider),
    ref.watch(currentTenantIdProvider) ?? '',
  );
});

/// Live-streams the current tenant's `first_aid_logs`, newest first, mirroring `FirstAidTab`'s
/// previous inline query exactly.
final firstAidLogProvider = StreamProvider.autoDispose<List<FirstAidEntry>>((ref) {
  return ref.watch(healthServiceProvider).streamFirstAidLog();
});

/// Live-streams the current tenant's `hygiene_surveys`, newest first, mirroring `HygieneTab`'s
/// previous inline query exactly.
final hygieneSurveysProvider = StreamProvider.autoDispose<List<HygieneSurvey>>((ref) {
  return ref.watch(healthServiceProvider).streamHygieneSurveys();
});

/// Live-streams the current tenant's `medical_records`, newest first, mirroring `MedicalsTab`'s
/// previous inline query exactly (client-side Fit/Restricted/Unfit aggregation stays in the
/// widget, same as before).
final medicalRecordsProvider = StreamProvider.autoDispose<List<MedicalRecord>>((ref) {
  return ref.watch(healthServiceProvider).streamMedicalRecords();
});

/// Combined service for the health module's 3 small tenant-scoped collections
/// (`first_aid_logs`, `hygiene_surveys`, `medical_records`) — small enough individually to not
/// warrant separate service classes, unlike `risk` which is being split per-collection.
class HealthService {
  final FirebaseFirestore _db;
  final FirestoreService _firestoreService;
  final String _tenantId;

  HealthService(this._db, this._firestoreService, this._tenantId);

  CollectionReference<Map<String, dynamic>> get _firstAidRef =>
      _db.tenantCollection(_tenantId, 'first_aid_logs');

  CollectionReference<Map<String, dynamic>> get _hygieneRef =>
      _db.tenantCollection(_tenantId, 'hygiene_surveys');

  CollectionReference<Map<String, dynamic>> get _medicalRef =>
      _db.tenantCollection(_tenantId, 'medical_records');

  /// Routes through FirestoreService.createDocument (not a direct write) to preserve
  /// FirstAidForm's original offline-queue + audit-log behavior.
  Future<void> createFirstAidEntry(FirstAidEntry entry) async {
    await _firestoreService.createDocument(
      tenantId: _tenantId,
      collection: 'first_aid_logs',
      data: entry.toFirestore(),
    );
  }

  Stream<List<FirstAidEntry>> streamFirstAidLog() {
    return _firstAidRef
        .where('siteId', isEqualTo: _tenantId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => FirstAidEntry.fromFirestore(d.data(), d.id)).toList());
  }

  /// Routes through FirestoreService.createDocument (not a direct write) to preserve
  /// HygieneForm's original offline-queue + audit-log behavior.
  Future<void> createHygieneSurvey(HygieneSurvey survey) async {
    await _firestoreService.createDocument(
      tenantId: _tenantId,
      collection: 'hygiene_surveys',
      data: survey.toFirestore(),
    );
  }

  Stream<List<HygieneSurvey>> streamHygieneSurveys() {
    return _hygieneRef
        .where('siteId', isEqualTo: _tenantId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => HygieneSurvey.fromFirestore(d.data(), d.id)).toList());
  }

  /// Routes through FirestoreService.createDocument (not a direct write) to preserve
  /// MedicalForm's original offline-queue + audit-log behavior.
  Future<void> createMedicalRecord(MedicalRecord record) async {
    await _firestoreService.createDocument(
      tenantId: _tenantId,
      collection: 'medical_records',
      data: record.toFirestore(),
    );
  }

  Stream<List<MedicalRecord>> streamMedicalRecords() {
    return _medicalRef
        .where('siteId', isEqualTo: _tenantId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => MedicalRecord.fromFirestore(d.data(), d.id)).toList());
  }
}
