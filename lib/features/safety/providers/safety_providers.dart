import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

// Placeholder models or direct Firestore data
class SafetyIncident {
  final String id;
  final String title;
  final String status;
  final DateTime date;

  SafetyIncident({
    required this.id,
    required this.title,
    required this.status,
    required this.date,
  });

  factory SafetyIncident.fromFirestore(Map<String, dynamic> data, String id) {
    return SafetyIncident(
      id: id,
      title: data['title'] ?? 'Unknown Incident',
      status: data['status'] ?? 'Open',
      date: (data['timestamp'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }
}

class WorkPermit {
  final String id;
  final String type;
  final String status;

  WorkPermit({required this.id, required this.type, required this.status});

  factory WorkPermit.fromFirestore(Map<String, dynamic> data, String id) {
    return WorkPermit(
      id: id,
      type: data['type'] ?? 'General',
      status: data['status'] ?? 'Draft',
    );
  }
}

final propertyIncidentsProvider = StreamProvider.family<
  List<SafetyIncident>,
  String
>((ref, propertyId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'incidents')
      .where('propertyId', isEqualTo: propertyId)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs
                .map((doc) => SafetyIncident.fromFirestore(doc.data(), doc.id))
                .toList(),
      );
});

final propertyPermitsProvider = StreamProvider.family<List<WorkPermit>, String>(
  (ref, propertyId) {
    final firestore = ref.watch(firestoreProvider);
    return firestore
        .tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'permits')
        .where('propertyId', isEqualTo: propertyId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => WorkPermit.fromFirestore(doc.data(), doc.id))
                  .toList(),
        );
  },
);

/// Incident Attachments
final incidentAttachmentsProvider = StreamProvider.family<List<String>, String>(
  (ref, incidentId) {
    final firestore = ref.watch(firestoreProvider);
    return firestore
        .tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'incidents')
        .doc(incidentId)
        .collection('attachments')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => d.id).toList());
  },
);

/// Incident Witnesses
final incidentWitnessesProvider = StreamProvider.family<List<String>, String>((
  ref,
  incidentId,
) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'incidents')
      .doc(incidentId)
      .collection('witnesses')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((d) => d.id).toList());
});

/// Permit Hazards
final permitHazardsProvider = StreamProvider.family<List<String>, String>((
  ref,
  permitId,
) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'permits')
      .doc(permitId)
      .collection('hazards')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((d) => d.id).toList());
});

/// Permit Control Measures
final permitControlMeasuresProvider =
    StreamProvider.family<List<String>, String>((ref, permitId) {
      final firestore = ref.watch(firestoreProvider);
      return firestore
          .tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'permits')
          .doc(permitId)
          .collection('controlMeasures')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((d) => d.id).toList());
    });

/// Permit PPE Required
final permitPpeRequiredProvider = StreamProvider.family<List<String>, String>((
  ref,
  permitId,
) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'permits')
      .doc(permitId)
      .collection('ppeRequired')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((d) => d.id).toList());
});

/// Permit Attachments
final permitAttachmentsProvider = StreamProvider.family<List<String>, String>((
  ref,
  permitId,
) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'permits')
      .doc(permitId)
      .collection('attachments')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((d) => d.id).toList());
});

/// Risk Assessment Hazards
final riskAssessmentHazardsProvider =
    StreamProvider.family<List<String>, String>((ref, riskAssessmentId) {
      final firestore = ref.watch(firestoreProvider);
      return firestore
          .tenantCollection(
            ref.watch(currentTenantIdProvider) ?? "",
            'riskAssessments',
          )
          .doc(riskAssessmentId)
          .collection('hazards')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((d) => d.id).toList());
    });

/// Contractor Certifications
final contractorCertificationsProvider =
    StreamProvider.family<List<String>, String>((ref, contractorId) {
      final firestore = ref.watch(firestoreProvider);
      return firestore
          .tenantCollection(
            ref.watch(currentTenantIdProvider) ?? "",
            'contractors',
          )
          .doc(contractorId)
          .collection('certifications')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((d) => d.id).toList());
    });

/// Action Item Attachments
final actionItemAttachmentsProvider =
    StreamProvider.family<List<String>, String>((ref, actionItemId) {
      final firestore = ref.watch(firestoreProvider);
      return firestore
          .tenantCollection(
            ref.watch(currentTenantIdProvider) ?? "",
            'actionItems',
          )
          .doc(actionItemId)
          .collection('attachments')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((d) => d.id).toList());
    });
