/// An emergency contact number (fire department, ambulance, poison control, etc), either
/// user-added via `EmergencyContactFormCard` or one of the 4 defaults seeded by
/// `EmergencyService.seedDefaultContacts`.
///
/// `createdAt` is stored as an ISO8601 string. Unlike `emergency_drills`/`emergency_equipment`,
/// this collection DOES carry a `siteId` field (set to the author's `tenantId`) and
/// `streamContacts()` filters on it in addition to the tenant-scoped path — preserved exactly as
/// the previous inline query did, even though it's redundant with the tenant-scoped path itself.
class EmergencyContact {
  final String id;
  final String name;
  final String number;
  final String authorId;
  final String siteId;
  final DateTime createdAt;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.number,
    required this.authorId,
    required this.siteId,
    required this.createdAt,
  });

  factory EmergencyContact.fromFirestore(Map<String, dynamic> json, String id) {
    return EmergencyContact(
      id: id,
      name: json['name'] ?? 'Unknown',
      number: json['number'] ?? '',
      authorId: json['authorId'] ?? '',
      siteId: json['siteId'] ?? '',
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
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
