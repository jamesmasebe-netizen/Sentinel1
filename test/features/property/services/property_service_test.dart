// Tests for PropertyService (lib/features/property/services/property_service.dart) — the service
// layer extracted from the `property` module's previously-inline Firestore calls, following the
// ComplianceService reference pattern (test/features/compliance/services/compliance_service_test.dart).
//
// FIXED 2026-08-07 (real, live gap): every form in this module (property_form_sheet.dart,
// property_project_form.dart, property_utility_form.dart, legal_appointment_form.dart,
// property_lease_form.dart, property_asset_form.dart) previously wrote directly to Firestore
// (`firestore.tenantCollection(...).add(...)`), bypassing FirestoreService entirely — unlike
// every other business module in the app, a form submitted here while offline had no queue/retry
// safety net and was silently lost, with no audit trail either. All 6 now route through
// PropertyService, which uses FirestoreService.createDocument/updateDocument like everything else.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sentinel1/core/providers/app_providers.dart';
import 'package:sentinel1/core/services/offline_sync_service.dart';
import 'package:sentinel1/features/property/models/property_models.dart';
import 'package:sentinel1/features/property/services/property_service.dart';

class MockOfflineSyncService extends Mock implements OfflineSyncService {}

const _tenantId = 'test-tenant';

Property _buildProperty({String id = ''}) {
  return Property(
    id: id,
    name: 'HQ Tower',
    type: 'Office',
    address: '1 Main St',
    lat: -26.2,
    lng: 28.0,
    totalArea: '5000sqm',
    floors: 10,
    occupancy: 120,
    capacity: 200,
    status: 'Optimal',
    constructionDate: DateTime(2010, 1, 1),
    managerId: 'mgr-1',
    complianceScore: 88.5,
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
  late PropertyService service;

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
    service = container.read(propertyServiceProvider);
  });

  List<dynamic> capturedQueueArgs() {
    return verify(() => offlineSync.queueOperation(
          operation: captureAny(named: 'operation'),
          collection: captureAny(named: 'collection'),
          data: captureAny(named: 'data'),
          documentId: captureAny(named: 'documentId'),
        )).captured;
  }

  group('saveProperty', () {
    test('an empty id creates a new document via the offline-first path', () async {
      await service.saveProperty(_buildProperty());

      final args = capturedQueueArgs();
      expect(args[0], OfflineOperation.create);
      expect(args[1], 'tenants/$_tenantId/properties');
      expect(args[3], isNull); // no documentId on create
      final data = args[2] as Map<String, dynamic>;
      expect(data['name'], 'HQ Tower');
      expect(data['siteId'], _tenantId);
      expect(data['manager'], 'mgr-1');
    });

    test('a non-empty id updates the existing document via the offline-first path', () async {
      await service.saveProperty(_buildProperty(id: 'prop-1'));

      final args = capturedQueueArgs();
      expect(args[0], OfflineOperation.update);
      expect(args[1], 'tenants/$_tenantId/properties');
      expect(args[3], 'prop-1');
    });

    test('also writes a real audit-log entry', () async {
      await service.saveProperty(_buildProperty());

      final snap = await db
          .collection('tenants')
          .doc(_tenantId)
          .collection('audit_logs')
          .where('action', isEqualTo: 'CREATE')
          .get();
      expect(snap.docs, hasLength(1));
    });
  });

  group('createProject', () {
    test('queues the create with the field shape property_facility_tab.dart reads', () async {
      await service.createProject(PropertyProject(
        id: '',
        propertyId: 'prop-1',
        title: 'Roof repair',
        type: 'Repair',
        description: 'Fix leak',
        status: 'Planned',
        assigneeId: 'emp-1',
        dueDate: DateTime(2026, 3, 1),
        progress: 0,
      ));

      final args = capturedQueueArgs();
      expect(args[1], 'tenants/$_tenantId/property_projects');
      final data = args[2] as Map<String, dynamic>;
      expect(data['propertyId'], 'prop-1');
      expect(data['assignedTo'], 'emp-1'); // PropertyProject.assigneeId -> 'assignedTo' on disk
    });
  });

  group('createUtilityUsage', () {
    test('queues the create with the correct collection and numeric fields', () async {
      await service.createUtilityUsage(UtilityUsage(
        id: '',
        propertyId: 'prop-1',
        month: 'Jan 2026',
        electricity: 1200.5,
        water: 300.0,
        waste: 50.0,
        carbon: 4.2,
      ));

      final args = capturedQueueArgs();
      expect(args[1], 'tenants/$_tenantId/property_utilities');
      final data = args[2] as Map<String, dynamic>;
      expect(data['electricity'], 1200.5);
      expect(data['carbon'], 4.2);
    });
  });

  group('createLegalAppointment', () {
    test('queues the create, storing personId under the on-disk personName field', () async {
      await service.createLegalAppointment(LegalAppointment(
        id: '',
        propertyId: 'prop-1',
        role: 'Fire Marshal',
        personId: 'emp-42',
        status: 'Appointed',
        expiry: DateTime(2027, 1, 1),
      ));

      final args = capturedQueueArgs();
      expect(args[1], 'tenants/$_tenantId/legal_appointments');
      final data = args[2] as Map<String, dynamic>;
      expect(data['role'], 'Fire Marshal');
      // Preserves the pre-existing (flagged, not fixed) on-disk shape: 'personName' actually
      // holds the employee id, not a display name — see property_facility_tab.dart / T3-PROPERTY.
      expect(data['personName'], 'emp-42');
    });
  });

  group('createLease', () {
    test('queues the create with tenantId stored under the on-disk tenantName field', () async {
      await service.createLease(LeaseInfo(
        id: '',
        propertyId: 'prop-1',
        tenantId: 'Acme Retail',
        monthlyRent: 45000,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2027, 1, 1),
        status: 'Active',
      ));

      final args = capturedQueueArgs();
      expect(args[1], 'tenants/$_tenantId/property_leases');
      final data = args[2] as Map<String, dynamic>;
      expect(data['tenantName'], 'Acme Retail');
      expect(data['monthlyRent'], 45000);
    });
  });

  group('createAsset', () {
    test('queues the create with the correct collection', () async {
      await service.createAsset(AssetInfo(
        id: '',
        propertyId: 'prop-1',
        name: 'Rooftop HVAC Unit 2',
        category: 'HVAC',
        condition: 'Good',
        lastInspected: DateTime(2026, 1, 15),
      ));

      final args = capturedQueueArgs();
      expect(args[1], 'tenants/$_tenantId/property_assets');
      final data = args[2] as Map<String, dynamic>;
      expect(data['name'], 'Rooftop HVAC Unit 2');
      expect(data['category'], 'HVAC');
    });
  });
}
