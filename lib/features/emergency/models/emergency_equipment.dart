/// A tracked piece of emergency/safety equipment (extinguisher, first aid kit, AED, spill kit).
///
/// `createdAt` is stored as an ISO8601 string. `nextInspectionDate` is a plain freeform string
/// (the form hints `YYYY-MM-DD` but has no date picker enforcing it), matching what
/// `EquipmentFormCard` already writes. This collection has no `siteId` field — every document
/// already lives at the tenant-scoped `tenants/{tenantId}/emergency_equipment` path (see
/// `EmergencyService`).
///
/// `propertyId`/`propertyName` (added 2026-08-12): a genuine multi-site reference to a `property`
/// module `Property` record, nullable. `location` stays as free text for finer-than-property detail
/// (e.g. "3rd floor kitchen") — it's a supplement to `propertyId`, not superseded by it.
class EmergencyEquipment {
  final String id;
  final String equipmentType;
  final String location;
  final String nextInspectionDate;
  final String status;
  final String authorId;
  final String? propertyId;
  final String? propertyName;
  final DateTime createdAt;

  EmergencyEquipment({
    required this.id,
    required this.equipmentType,
    this.location = '',
    this.nextInspectionDate = '',
    required this.status,
    required this.authorId,
    this.propertyId,
    this.propertyName,
    required this.createdAt,
  });

  factory EmergencyEquipment.fromFirestore(Map<String, dynamic> json, String id) {
    return EmergencyEquipment(
      id: id,
      equipmentType: json['equipmentType'] ?? '',
      location: json['location'] ?? '',
      nextInspectionDate: json['nextInspectionDate'] ?? '',
      status: json['status'] ?? '',
      authorId: json['authorId'] ?? '',
      propertyId: json['propertyId'],
      propertyName: json['propertyName'],
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'equipmentType': equipmentType,
      'location': location,
      'nextInspectionDate': nextInspectionDate,
      'status': status,
      'authorId': authorId,
      if (propertyId != null) 'propertyId': propertyId,
      if (propertyName != null) 'propertyName': propertyName,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
