import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/tenant_firestore_extension.dart';
import '../models/bowtie_analysis.dart';

final bowtieServiceProvider = Provider<BowtieService>((ref) {
  return BowtieService(
    ref.watch(firestoreProvider),
    ref.watch(firestoreServiceProvider),
    ref.watch(currentTenantIdProvider) ?? '',
  );
});

/// Live-streams this tenant's bow-tie register, newest first, limit 30 — mirrors
/// `BowtieScreen`'s previous inline query.
final bowtieAnalysesProvider =
    StreamProvider.autoDispose<List<BowtieAnalysis>>((ref) {
      return ref.watch(bowtieServiceProvider).streamAnalyses();
    });

class BowtieService {
  final FirebaseFirestore _db;
  final FirestoreService _firestoreService;
  final String _tenantId;

  BowtieService(this._db, this._firestoreService, this._tenantId);

  CollectionReference<Map<String, dynamic>> get _bowtieRef =>
      _db.tenantCollection(_tenantId, 'bowtie_analyses');

  /// Routes through FirestoreService.createDocument (not a direct write) so this preserves
  /// bowtie_form.dart's original offline-queue + audit-log behavior — see ComplianceService's
  /// matching fix (this module's reference pattern).
  Future<void> createAnalysis(BowtieAnalysis analysis) async {
    await _firestoreService.createDocument(
      tenantId: _tenantId,
      collection: 'bowtie_analyses',
      data: analysis.toFirestore(),
    );
  }

  Stream<List<BowtieAnalysis>> streamAnalyses() {
    return _bowtieRef
        .where('siteId', isEqualTo: _tenantId)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map((d) => BowtieAnalysis.fromFirestore(d.data(), d.id))
                  .toList(),
        );
  }
}
