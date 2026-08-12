/// A logged emergency drill (fire, medical, evacuation, spill, security, etc).
///
/// `createdAt` is stored as an ISO8601 string, matching every other feature module's on-disk
/// convention. `dateConducted` is a plain freeform string, not a parsed `DateTime` — it mirrors
/// what `DrillFormCard` already writes (bound to a text controller with no date picker attached,
/// so it may legitimately be an empty string). This collection has no `siteId` field — every
/// document already lives at the tenant-scoped `tenants/{tenantId}/emergency_drills` path, so no
/// additional per-document tenant field or query filter is needed (see `EmergencyService`).
///
/// `propertyId`/`propertyName` (added 2026-08-12): a genuine multi-site reference to a `property`
/// module `Property` record, nullable — a drill with no property set applies tenant-wide.
class EmergencyDrill {
  final String id;
  final String drillType;
  final String dateConducted;
  final int durationMinutes;
  final String evaluatorName;
  final String scenarioDescription;
  final String areasForImprovement;
  final String authorId;
  final String? propertyId;
  final String? propertyName;
  final DateTime createdAt;

  EmergencyDrill({
    required this.id,
    required this.drillType,
    this.dateConducted = '',
    this.durationMinutes = 0,
    this.evaluatorName = '',
    this.scenarioDescription = '',
    this.areasForImprovement = '',
    required this.authorId,
    this.propertyId,
    this.propertyName,
    required this.createdAt,
  });

  factory EmergencyDrill.fromFirestore(Map<String, dynamic> json, String id) {
    return EmergencyDrill(
      id: id,
      drillType: json['drillType'] ?? '',
      dateConducted: json['dateConducted'] ?? '',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      evaluatorName: json['evaluatorName'] ?? '',
      scenarioDescription: json['scenarioDescription'] ?? '',
      areasForImprovement: json['areasForImprovement'] ?? '',
      authorId: json['authorId'] ?? '',
      propertyId: json['propertyId'],
      propertyName: json['propertyName'],
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'drillType': drillType,
      'dateConducted': dateConducted,
      'durationMinutes': durationMinutes,
      'evaluatorName': evaluatorName,
      'scenarioDescription': scenarioDescription,
      'areasForImprovement': areasForImprovement,
      'authorId': authorId,
      if (propertyId != null) 'propertyId': propertyId,
      if (propertyName != null) 'propertyName': propertyName,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
