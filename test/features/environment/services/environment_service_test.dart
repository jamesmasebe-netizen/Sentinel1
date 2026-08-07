// Tests for EnvironmentService (lib/features/environment/services/environment_service.dart) —
// the service layer extracted from the environment module's previously-inline Firestore calls
// (spills/waste manifests/ESG metrics), following the ComplianceService reference pattern
// (test/features/compliance/services/compliance_service_test.dart): creates route through
// FirestoreService (mocked OfflineSyncService + real fake_cloud_firestore-backed audit log),
// stream reads go directly against fake_cloud_firestore.
//
// Also regression-covers the dashboardWasteProvider fix
// (lib/features/dashboard/providers/dashboard_providers.dart): that provider previously read
// data['type'] and parsed a unit-embedded quantity string, but the real writer (this service,
// formerly waste_form.dart directly) has always written a separate 'wasteType' string field and
// a bare numeric 'quantity' field with its own 'unit' field — meaning the dashboard's
// categorization never matched a real document. The 'createWasteManifest persists the exact
// field shape...' test below pins the shape the fixed provider now depends on.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sentinel1/core/providers/app_providers.dart';
import 'package:sentinel1/core/services/offline_sync_service.dart';
import 'package:sentinel1/features/environment/models/environment_models.dart';
import 'package:sentinel1/features/environment/services/environment_service.dart';

class MockOfflineSyncService extends Mock implements OfflineSyncService {}

const _tenantId = 'test-tenant';
const _otherTenantId = 'other-tenant';

EnvironmentalSpill _buildSpill({
  String id = '',
  String substance = 'Diesel',
  String volume = '20L',
  String location = 'Loading Bay',
  bool contained = true,
  bool reportedToAuthorities = false,
  String siteId = _tenantId,
  DateTime? createdAt,
}) {
  return EnvironmentalSpill(
    id: id,
    siteId: siteId,
    substance: substance,
    volume: volume,
    location: location,
    contained: contained,
    reportedToAuthorities: reportedToAuthorities,
    authorId: 'author-1',
    dateOfSpill: DateTime.now(),
    createdAt: createdAt ?? DateTime.now(),
  );
}

WasteManifest _buildWaste({
  String id = '',
  String wasteType = 'Recyclable',
  double quantity = 12.5,
  String unit = 'kg',
  String siteId = _tenantId,
  DateTime? createdAt,
}) {
  return WasteManifest(
    id: id,
    siteId: siteId,
    wasteType: wasteType,
    quantity: quantity,
    unit: unit,
    transporterName: 'Acme Waste Co',
    disposalFacility: 'Regional Landfill',
    status: 'Pending Pickup',
    authorId: 'author-1',
    createdAt: createdAt ?? DateTime.now(),
  );
}

EsgMetric _buildMetric({
  String id = '',
  String category = 'Scope 1',
  double value = 42,
  String unit = 'tCO2e',
  String siteId = _tenantId,
  DateTime? createdAt,
}) {
  return EsgMetric(
    id: id,
    siteId: siteId,
    category: category,
    value: value,
    unit: unit,
    period: '2026',
    authorId: 'author-1',
    createdAt: createdAt ?? DateTime.now(),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(OfflineOperation.create);
    registerFallbackValue(<String, dynamic>{});
  });

  late FakeFirebaseFirestore db;
  late MockOfflineSyncService offlineSync;
  late ProviderContainer container;
  late EnvironmentService service;

  setUp(() {
    db = FakeFirebaseFirestore();
    offlineSync = MockOfflineSyncService();
    when(() => offlineSync.queueOperation(
          operation: any(named: 'operation'),
          collection: any(named: 'collection'),
          data: any(named: 'data'),
          documentId: any(named: 'documentId'),
        )).thenAnswer((_) async => 'queued-op-1');

    container = ProviderContainer(overrides: [
      firestoreProvider.overrideWithValue(db),
      offlineSyncServiceProvider.overrideWithValue(offlineSync),
      currentTenantIdProvider.overrideWithValue(_tenantId),
    ]);
    addTearDown(container.dispose);
    service = container.read(environmentServiceProvider);
  });

  List<dynamic> capturedQueueArgs() {
    return verify(() => offlineSync.queueOperation(
          operation: captureAny(named: 'operation'),
          collection: captureAny(named: 'collection'),
          data: captureAny(named: 'data'),
          documentId: captureAny(named: 'documentId'),
        )).captured;
  }

  Future<void> seedRawSpill(EnvironmentalSpill spill, {String tenantId = _tenantId}) async {
    await db
        .collection('tenants')
        .doc(tenantId)
        .collection('environmental_spills')
        .add(spill.toFirestore());
  }

  Future<void> seedRawWaste(WasteManifest manifest, {String tenantId = _tenantId}) async {
    await db
        .collection('tenants')
        .doc(tenantId)
        .collection('waste_manifests')
        .add(manifest.toFirestore());
  }

  Future<void> seedRawMetric(EsgMetric metric, {String tenantId = _tenantId}) async {
    await db
        .collection('tenants')
        .doc(tenantId)
        .collection('esg_metrics')
        .add(metric.toFirestore());
  }

  group('createSpill', () {
    test('queues the create via the offline-first path with the correct collection path', () async {
      await service.createSpill(_buildSpill(substance: 'Hydraulic Oil'));

      final args = capturedQueueArgs();
      expect(args[0], OfflineOperation.create);
      expect(args[1], 'tenants/$_tenantId/environmental_spills');
      final data = args[2] as Map<String, dynamic>;
      expect(data['substance'], 'Hydraulic Oil');
      expect(data['siteId'], _tenantId);
    });

    test('also writes a real CREATE audit-log entry', () async {
      await service.createSpill(_buildSpill());

      final snap = await db
          .collection('tenants')
          .doc(_tenantId)
          .collection('audit_logs')
          .where('action', isEqualTo: 'CREATE')
          .get();
      expect(snap.docs, hasLength(1));
      final metadata = snap.docs.single.data()['metadata'] as Map<String, dynamic>;
      expect(metadata['collection'], 'tenants/$_tenantId/environmental_spills');
    });
  });

  group('streamSpills', () {
    test('returns only this tenant\'s spills, newest first', () async {
      await seedRawSpill(_buildSpill(
        substance: 'Older Spill',
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      ));
      await seedRawSpill(_buildSpill(substance: 'Newer Spill'));
      await seedRawSpill(
        _buildSpill(substance: 'Other Tenant Spill', siteId: _otherTenantId),
        tenantId: _otherTenantId,
      );

      final result = await service.streamSpills().first;

      expect(result.map((s) => s.substance), ['Newer Spill', 'Older Spill']);
    });
  });

  group('createWasteManifest', () {
    test(
        'persists the exact field shape the dashboard waste provider now depends on '
        '(separate wasteType/quantity/unit, not a combined string)', () async {
      await service.createWasteManifest(
        _buildWaste(wasteType: 'Hazardous', quantity: 3.2, unit: 'kg'),
      );

      final args = capturedQueueArgs();
      expect(args[1], 'tenants/$_tenantId/waste_manifests');
      final data = args[2] as Map<String, dynamic>;
      expect(data['wasteType'], 'Hazardous');
      expect(data['quantity'], 3.2);
      expect(data['unit'], 'kg');
    });
  });

  group('streamWasteManifests', () {
    test('returns only this tenant\'s manifests, newest first', () async {
      await seedRawWaste(_buildWaste(
        wasteType: 'General',
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      ));
      await seedRawWaste(_buildWaste(wasteType: 'Recyclable'));
      await seedRawWaste(
        _buildWaste(wasteType: 'Other Tenant', siteId: _otherTenantId),
        tenantId: _otherTenantId,
      );

      final result = await service.streamWasteManifests().first;

      expect(result.map((m) => m.wasteType), ['Recyclable', 'General']);
    });
  });

  group('createEsgMetric', () {
    test('queues the create via the offline-first path', () async {
      await service.createEsgMetric(_buildMetric(category: 'Water', value: 5.5));

      final args = capturedQueueArgs();
      expect(args[1], 'tenants/$_tenantId/esg_metrics');
      final data = args[2] as Map<String, dynamic>;
      expect(data['category'], 'Water');
      expect(data['value'], 5.5);
    });
  });

  group('streamEsgMetrics', () {
    test('returns only this tenant\'s metrics, newest first', () async {
      await seedRawMetric(_buildMetric(
        category: 'Older Metric',
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      ));
      await seedRawMetric(_buildMetric(category: 'Newer Metric'));

      final result = await service.streamEsgMetrics().first;

      expect(result.map((m) => m.category), ['Newer Metric', 'Older Metric']);
    });
  });

  group('uncapped analytics variants', () {
    test('streamAllSpills returns all of this tenant\'s spills regardless of order', () async {
      for (var i = 0; i < 3; i++) {
        await seedRawSpill(_buildSpill(substance: 'Spill $i'));
      }
      await seedRawSpill(_buildSpill(substance: 'Other Tenant', siteId: _otherTenantId),
          tenantId: _otherTenantId);

      final result = await service.streamAllSpills().first;

      expect(result, hasLength(3));
    });

    test('streamAllWasteManifests returns all of this tenant\'s manifests', () async {
      for (var i = 0; i < 3; i++) {
        await seedRawWaste(_buildWaste(wasteType: 'Type $i'));
      }

      final result = await service.streamAllWasteManifests().first;

      expect(result, hasLength(3));
    });

    test('streamAllEsgMetrics returns all of this tenant\'s metrics', () async {
      for (var i = 0; i < 3; i++) {
        await seedRawMetric(_buildMetric(category: 'Cat $i'));
      }

      final result = await service.streamAllEsgMetrics().first;

      expect(result, hasLength(3));
    });
  });
}
