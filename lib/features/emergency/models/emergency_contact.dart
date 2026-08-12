/// An emergency contact number (fire department, ambulance, poison control, etc), either
/// user-added via `EmergencyContactFormCard` or one of the 4 defaults seeded by
/// `EmergencyService.seedDefaultContacts`.
///
/// `createdAt` is stored as an ISO8601 string. Unlike `emergency_drills`/`emergency_equipment`,
/// this collection DOES carry a `siteId` field (set to the author's `tenantId`) and
/// `streamContacts()` filters on it in addition to the tenant-scoped path — preserved exactly as
/// the previous inline query did, even though it's redundant with the tenant-scoped path itself.
///
/// `propertyId`/`propertyName` (added 2026-08-12) is a genuine multi-site reference — a tenant
/// with several `property` module `Property` records can scope a contact to one of them, distinct
/// from `siteId` (which is really just the tenant, not a site). Nullable: a contact with no
/// property set applies tenant-wide.
class EmergencyContact {
  final String id;
  final String name;
  final String number;
  final String authorId;
  final String siteId;
  final String? propertyId;
  final String? propertyName;
  final DateTime createdAt;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.number,
    required this.authorId,
    required this.siteId,
    this.propertyId,
    this.propertyName,
    required this.createdAt,
  });

  factory EmergencyContact.fromFirestore(Map<String, dynamic> json, String id) {
    return EmergencyContact(
      id: id,
      name: json['name'] ?? 'Unknown',
      number: json['number'] ?? '',
      authorId: json['authorId'] ?? '',
      siteId: json['siteId'] ?? '',
      propertyId: json['propertyId'],
      propertyName: json['propertyName'],
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'number': number,
      'authorId': authorId,
      'siteId': siteId,
      if (propertyId != null) 'propertyId': propertyId,
      if (propertyName != null) 'propertyName': propertyName,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
