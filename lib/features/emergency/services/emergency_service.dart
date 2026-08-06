import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/tenant_firestore_extension.dart';
import '../models/emergency_drill.dart';
import '../models/emergency_equipment.dart';
import '../models/emergency_contact.dart';

final emergencyServiceProvider = Provider<EmergencyService>((ref) {
  return EmergencyService(
    ref.watch(firestoreProvider),
    ref.watch(firestoreServiceProvider),
    ref.watch(currentTenantIdProvider) ?? '',
  );
});

/// Live-streams every `emergency_drills` document for the current tenant, newest first,
/// mirroring `EmergencyDrillsTab`'s previous inline query exactly.
final emergencyDrillsProvider = StreamProvider.autoDispose<List<EmergencyDrill>>((ref) {
  return ref.watch(emergencyServiceProvider).streamDrills();
});

/// Live-streams every `emergency_equipment` document for the current tenant, newest first,
/// mirroring `EmergencyEquipmentTab`'s previous inline query exactly.
final emergencyEquipmentProvider =
    StreamProvider.autoDispose<List<EmergencyEquipment>>((ref) {
  return ref.watch(emergencyServiceProvider).streamEquipment();
});

/// Live-streams `emergency_contacts` for the current tenant (filtered by `siteId`), oldest first,
/// mirroring `EmergencyContactsTab`'s previous inline query exactly.
final emergencyContactsProvider =
    StreamProvider.autoDispose<List<EmergencyContact>>((ref) {
  return ref.watch(emergencyServiceProvider).streamContacts();
});

/// Covers all 3 of the emergency module's tenant-scoped collections
/// (`emergency_drills`, `emergency_equipment`, `emergency_contacts`).
///
/// Note the inconsistency inherited from the pre-extraction inline queries, preserved as-is:
/// `emergency_drills`/`emergency_equipment` have no `siteId` field at all (they rely purely on
/// the tenant-scoped Firestore path, which is safe), while `emergency_contacts` does carry and
/// filter on one. Retroactively adding `siteId` to the first two would be an unrequested schema
/// change to live data, so each collection's methods match its own actual existing shape.
///
/// This module's Broadcast tab does not touch Firestore at all — it calls a Cloud Function via
/// `NotificationService.sendEmergencyBroadcast`, which is unrelated to this service and untouched
/// by this extraction.
class EmergencyService {
  final FirebaseFirestore _db;
  final FirestoreService _firestoreService;
  final String _tenantId;

  EmergencyService(this._db, this._firestoreService, this._tenantId);

  CollectionReference<Map<String, dynamic>> get _drillsRef =>
      _db.tenantCollection(_tenantId, 'emergency_drills');

  CollectionReference<Map<String, dynamic>> get _equipmentRef =>
      _db.tenantCollection(_tenantId, 'emergency_equipment');

  CollectionReference<Map<String, dynamic>> get _contactsRef =>
      _db.tenantCollection(_tenantId, 'emergency_contacts');

  // ─── Drills ───

  /// Routes through FirestoreService.createDocument (not a direct write) to preserve
  /// DrillFormCard's original offline-queue + audit-log behavior.
  Future<void> createDrill(EmergencyDrill drill) async {
    await _firestoreService.createDocument(
      tenantId: _tenantId,
      collection: 'emergency_drills',
      data: drill.toFirestore(),
    );
  }

  Stream<List<EmergencyDrill>> streamDrills() {
    return _drillsRef
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => EmergencyDrill.fromFirestore(d.data(), d.id)).toList());
  }

  // ─── Equipment ───

  /// Routes through FirestoreService.createDocument (not a direct write) to preserve
  /// EquipmentFormCard's original offline-queue + audit-log behavior.
  Future<void> createEquipment(EmergencyEquipment equipment) async {
    await _firestoreService.createDocument(
      tenantId: _tenantId,
      collection: 'emergency_equipment',
      data: equipment.toFirestore(),
    );
  }

  Stream<List<EmergencyEquipment>> streamEquipment() {
    return _equipmentRef
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => EmergencyEquipment.fromFirestore(d.data(), d.id))
            .toList());
  }

  // ─── Contacts ───

  /// Routes through FirestoreService.createDocument (not a direct write) to preserve
  /// EmergencyContactFormCard's original offline-queue + audit-log behavior.
  Future<void> createContact(EmergencyContact contact) async {
    await _firestoreService.createDocument(
      tenantId: _tenantId,
      collection: 'emergency_contacts',
      data: contact.toFirestore(),
    );
  }

  Stream<List<EmergencyContact>> streamContacts() {
    return _contactsRef
        .where('siteId', isEqualTo: _tenantId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => EmergencyContact.fromFirestore(d.data(), d.id))
            .toList());
  }

  /// The 4 default emergency numbers `EmergencyContactsTab` offers to seed when a tenant has no
  /// contacts recorded yet. Kept here as the single source of truth for the (name, number) pairs
  /// actually written — the widget layer keeps its own copy augmented with icon/color for display
  /// only, matched back to these by `name`.
  static const List<Map<String, String>> defaultContacts = [
    {'name': 'Fire Department', 'number': '10111'},
    {'name': 'Ambulance / EMS', 'number': '10177'},
    {'name': 'Police / SAPS', 'number': '10111'},
    {'name': 'Poison Information', 'number': '0800 111 990'},
  ];

  /// Writes all 4 [defaultContacts] for the current tenant, authored by [authorId].
  Future<void> seedDefaultContacts({required String authorId}) async {
    for (final c in defaultContacts) {
      await createContact(EmergencyContact(
        id: '',
        name: c['name']!,
        number: c['number']!,
        authorId: authorId,
        siteId: _tenantId,
        createdAt: DateTime.now(),
      ));
    }
  }
}
