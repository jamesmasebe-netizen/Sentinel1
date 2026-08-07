import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/tenant_firestore_extension.dart';
import '../models/environment_models.dart';

final environmentServiceProvider = Provider<EnvironmentService>((ref) {
  return EnvironmentService(
    ref.watch(firestoreProvider),
    ref.watch(firestoreServiceProvider),
    ref.watch(currentTenantIdProvider) ?? '',
  );
});

final environmentalSpillsProvider = StreamProvider.autoDispose<List<EnvironmentalSpill>>((ref) {
  return ref.watch(environmentServiceProvider).streamSpills();
});

final wasteManifestsProvider = StreamProvider.autoDispose<List<WasteManifest>>((ref) {
  return ref.watch(environmentServiceProvider).streamWasteManifests();
});

final esgMetricsProvider = StreamProvider.autoDispose<List<EsgMetric>>((ref) {
  return ref.watch(environmentServiceProvider).streamEsgMetrics();
});

// Uncapped variants for environmental_analytics_tab.dart's aggregate KPIs/percentages — the
// list-view providers above cap at 50 (matching each tab's original query), which would
// silently understate analytics totals for any tenant with more than 50 records.
final allEnvironmentalSpillsProvider = StreamProvider.autoDispose<List<EnvironmentalSpill>>((ref) {
  return ref.watch(environmentServiceProvider).streamAllSpills();
});

final allWasteManifestsProvider = StreamProvider.autoDispose<List<WasteManifest>>((ref) {
  return ref.watch(environmentServiceProvider).streamAllWasteManifests();
});

final allEsgMetricsProvider = StreamProvider.autoDispose<List<EsgMetric>>((ref) {
  return ref.watch(environmentServiceProvider).streamAllEsgMetrics();
});

/// Service layer for the environment module (spills, waste manifests, ESG metrics). Routes
/// creates through FirestoreService (not a direct write) so this preserves the offline-queue +
/// audit-log behavior every create call in this module already had inline — mirrors
/// ComplianceService, the Wave 2b reference pattern.
class EnvironmentService {
  final FirebaseFirestore _db;
  final FirestoreService _firestoreService;
  final String _tenantId;

  EnvironmentService(this._db, this._firestoreService, this._tenantId);

  // --- Environmental Spills ---

  Future<void> createSpill(EnvironmentalSpill spill) async {
    await _firestoreService.createDocument(
      tenantId: _tenantId,
      collection: 'environmental_spills',
      data: spill.toFirestore(),
    );
  }

  Stream<List<EnvironmentalSpill>> streamSpills() {
    return _db
        .tenantCollection(_tenantId, 'environmental_spills')
        .where('siteId', isEqualTo: _tenantId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) => EnvironmentalSpill.fromFirestore(d)).toList());
  }

  // --- Waste Manifests ---

  Future<void> createWasteManifest(WasteManifest manifest) async {
    await _firestoreService.createDocument(
      tenantId: _tenantId,
      collection: 'waste_manifests',
      data: manifest.toFirestore(),
    );
  }

  Stream<List<WasteManifest>> streamWasteManifests() {
    return _db
        .tenantCollection(_tenantId, 'waste_manifests')
        .where('siteId', isEqualTo: _tenantId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) => WasteManifest.fromFirestore(d)).toList());
  }

  // --- ESG Metrics ---

  Future<void> createEsgMetric(EsgMetric metric) async {
    await _firestoreService.createDocument(
      tenantId: _tenantId,
      collection: 'esg_metrics',
      data: metric.toFirestore(),
    );
  }

  Stream<List<EsgMetric>> streamEsgMetrics() {
    return _db
        .tenantCollection(_tenantId, 'esg_metrics')
        .where('siteId', isEqualTo: _tenantId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) => EsgMetric.fromFirestore(d)).toList());
  }

  // --- Uncapped variants for analytics aggregation (see allXProvider comments above) ---

  Stream<List<EnvironmentalSpill>> streamAllSpills() {
    return _db
        .tenantCollection(_tenantId, 'environmental_spills')
        .where('siteId', isEqualTo: _tenantId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => EnvironmentalSpill.fromFirestore(d)).toList());
  }

  Stream<List<WasteManifest>> streamAllWasteManifests() {
    return _db
        .tenantCollection(_tenantId, 'waste_manifests')
        .where('siteId', isEqualTo: _tenantId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => WasteManifest.fromFirestore(d)).toList());
  }

  Stream<List<EsgMetric>> streamAllEsgMetrics() {
    return _db
        .tenantCollection(_tenantId, 'esg_metrics')
        .where('siteId', isEqualTo: _tenantId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => EsgMetric.fromFirestore(d)).toList());
  }
}
