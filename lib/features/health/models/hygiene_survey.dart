/// An occupational hygiene monitoring survey (`hygiene_surveys`).
///
/// Dates are stored as ISO8601 strings, not Firestore `Timestamp`s — matching the shape every
/// existing `hygiene_surveys` document already has on disk (see `HealthService`) and the
/// compliance module's identical convention (`ComplianceDocument`). `readingValue`/`legalLimit`
/// stay `String` (not `num`) — `HygieneForm` has always written them as raw trimmed text, and
/// `HygieneListItem` already `double.tryParse()`s them defensively; converting the stored type
/// is a migration out of scope for this extraction. `legalLimit` defaults to `'100'` (not `'0'`)
/// when missing, preserving `HygieneListItem`'s previous fallback so a legacy doc without the
/// field doesn't get falsely flagged as over-threshold.
class HygieneSurvey {
  final String id;
  final String zoneName;
  final String location;
  final String hazardType;
  final String readingValue;
  final String legalLimit;
  final int samplesTaken;
  final bool requiresMedicalSurveillance;
  final DateTime dateConducted;
  final String authorId;
  final String siteId;
  final DateTime createdAt;

  HygieneSurvey({
    required this.id,
    this.zoneName = 'Unknown Zone',
    this.location = '',
    this.hazardType = 'Unknown Hazard',
    this.readingValue = '0',
    this.legalLimit = '100',
    this.samplesTaken = 0,
    this.requiresMedicalSurveillance = false,
    required this.dateConducted,
    required this.authorId,
    required this.siteId,
    required this.createdAt,
  });

  factory HygieneSurvey.fromFirestore(Map<String, dynamic> json, String id) {
    return HygieneSurvey(
      id: id,
      zoneName: json['zoneName'] ?? 'Unknown Zone',
      location: json['location'] ?? '',
      hazardType: json['hazardType'] ?? 'Unknown Hazard',
      readingValue: json['readingValue']?.toString() ?? '0',
      legalLimit: json['legalLimit']?.toString() ?? '100',
      samplesTaken: (json['samplesTaken'] as num?)?.toInt() ?? 0,
      requiresMedicalSurveillance: json['requiresMedicalSurveillance'] == true,
      dateConducted:
          DateTime.tryParse(json['dateConducted']?.toString() ?? '') ?? DateTime.now(),
      authorId: json['authorId'] ?? '',
      siteId: json['siteId'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'zoneName': zoneName,
      'location': location,
      'hazardType': hazardType,
      'readingValue': readingValue,
      'legalLimit': legalLimit,
      'samplesTaken': samplesTaken,
      'requiresMedicalSurveillance': requiresMedicalSurveillance,
      'dateConducted': dateConducted.toIso8601String(),
      'authorId': authorId,
      'siteId': siteId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
