import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/firestore_service.dart';
import '../models/property_models.dart';

final propertyServiceProvider = Provider<PropertyService>((ref) {
  return PropertyService(
    ref.watch(firestoreServiceProvider),
    ref.watch(currentTenantIdProvider) ?? '',
  );
});

/// Service layer for the `property` module (properties, projects, utility usage, legal
/// appointments, leases, assets). Every create previously wrote directly to Firestore from its
/// form widget (`firestore.tenantCollection(...).add(...)`), bypassing FirestoreService entirely —
/// unlike every other business module in the app, a form submitted while offline here had no
/// queue/retry safety net and was silently lost. Routes all writes through
/// FirestoreService.createDocument/updateDocument instead, mirroring ComplianceService (the Wave
/// 2b reference pattern).
class PropertyService {
  final FirestoreService _firestoreService;
  final String _tenantId;

  PropertyService(this._firestoreService, this._tenantId);

  Future<void> saveProperty(Property property) async {
    final data = property.toFirestore(_tenantId);
    if (property.id.isEmpty) {
      await _firestoreService.createDocument(
        tenantId: _tenantId,
        collection: 'properties',
        data: data,
      );
    } else {
      await _firestoreService.updateDocument(
        tenantId: _tenantId,
        collection: 'properties',
        documentId: property.id,
        data: data,
      );
    }
  }

  Future<void> createProject(PropertyProject project) async {
    await _firestoreService.createDocument(
      tenantId: _tenantId,
      collection: 'property_projects',
      data: project.toFirestore(),
    );
  }

  Future<void> createUtilityUsage(UtilityUsage usage) async {
    await _firestoreService.createDocument(
      tenantId: _tenantId,
      collection: 'property_utilities',
      data: usage.toFirestore(),
    );
  }

  Future<void> createLegalAppointment(LegalAppointment appointment) async {
    await _firestoreService.createDocument(
      tenantId: _tenantId,
      collection: 'legal_appointments',
      data: appointment.toFirestore(),
    );
  }

  Future<void> createLease(LeaseInfo lease) async {
    await _firestoreService.createDocument(
      tenantId: _tenantId,
      collection: 'property_leases',
      data: lease.toFirestore(),
    );
  }

  Future<void> createAsset(AssetInfo asset) async {
    await _firestoreService.createDocument(
      tenantId: _tenantId,
      collection: 'property_assets',
      data: asset.toFirestore(),
    );
  }
}
