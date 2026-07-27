import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../models/property_models.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

final propertiesProvider = StreamProvider<List<Property>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final siteId = ref.watch(currentTenantIdProvider);

  if (siteId == null) return Stream.value([]);

  return firestore
      .tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'properties')
      .where('siteId', isEqualTo: siteId)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => Property.fromFirestore(doc)).toList(),
      );
});

final propertyProjectsProvider =
    StreamProvider.family<List<PropertyProject>, String>((ref, propertyId) {
      final firestore = ref.watch(firestoreProvider);
      return firestore
          .tenantCollection(
            ref.watch(currentTenantIdProvider) ?? "",
            'property_projects',
          )
          .where('propertyId', isEqualTo: propertyId)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map((doc) => PropertyProject.fromFirestore(doc))
                    .toList(),
          );
    });

final propertyUtilitiesProvider =
    StreamProvider.family<List<UtilityUsage>, String>((ref, propertyId) {
      final firestore = ref.watch(firestoreProvider);
      return firestore
          .tenantCollection(
            ref.watch(currentTenantIdProvider) ?? "",
            'property_utilities',
          )
          .where('propertyId', isEqualTo: propertyId)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map((doc) => UtilityUsage.fromFirestore(doc))
                    .toList(),
          );
    });

final propertyAppointmentsProvider =
    StreamProvider.family<List<LegalAppointment>, String>((ref, propertyId) {
      final firestore = ref.watch(firestoreProvider);
      return firestore
          .tenantCollection(
            ref.watch(currentTenantIdProvider) ?? "",
            'legal_appointments',
          )
          .where('propertyId', isEqualTo: propertyId)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map((doc) => LegalAppointment.fromFirestore(doc))
                    .toList(),
          );
    });

final propertyLeasesProvider = StreamProvider.family<List<LeaseInfo>, String>((
  ref,
  propertyId,
) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .tenantCollection(
        ref.watch(currentTenantIdProvider) ?? "",
        'property_leases',
      )
      .where('propertyId', isEqualTo: propertyId)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => LeaseInfo.fromFirestore(doc)).toList(),
      );
});

final propertyAssetsProvider = StreamProvider.family<List<AssetInfo>, String>((
  ref,
  propertyId,
) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .tenantCollection(
        ref.watch(currentTenantIdProvider) ?? "",
        'property_assets',
      )
      .where('propertyId', isEqualTo: propertyId)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => AssetInfo.fromFirestore(doc)).toList(),
      );
});
