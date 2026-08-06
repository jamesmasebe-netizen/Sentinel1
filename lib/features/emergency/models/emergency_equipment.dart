/// A tracked piece of emergency/safety equipment (extinguisher, first aid kit, AED, spill kit).
///
/// `createdAt` is stored as an ISO8601 string. `nextInspectionDate` is a plain freeform string
/// (the form hints `YYYY-MM-DD` but has no date picker enforcing it), matching what
/// `EquipmentFormCard` already writes. This collection has no `siteId` field — every document
/// already lives at the tenant-scoped `tenants/{tenantId}/emergency_equipment` path (see
/// `EmergencyService`).
class EmergencyEquipment {
  final String id;
  final String equipmentType;
  final String location;
  final String nextInspectionDate;
  final String status;
  final String authorId;
  final DateTime createdAt;

  EmergencyEquipment({
    required this.id,
    required this.equipmentType,
    this.location = '',
    this.nextInspectionDate = '',
    required this.status,
    required this.authorId,
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
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
