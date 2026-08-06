/// A first-aid treatment log entry (`first_aid_logs`).
///
/// Dates are stored as ISO8601 strings, not Firestore `Timestamp`s — matching the shape every
/// existing `first_aid_logs` document already has on disk (see `HealthService`) and the
/// compliance module's identical convention (`ComplianceDocument`).
///
/// `employeeName` is the patient's display name, captured at write time from the
/// `EmployeeSelector` already used to pick `patientId` — fixes a real bug where
/// `FirstAidListItem` read `data['employeeName']` but `FirstAidForm` never wrote it, so every
/// entry showed "Unknown" regardless of who the patient was.
class FirstAidEntry {
  final String id;
  final String patientId;
  final String employeeName;
  final String firstAiderId;
  final String description;
  final String treatment;
  final String actionTaken;
  final bool referredToMedical;
  final DateTime date;
  final String authorId;
  final String siteId;
  final DateTime createdAt;

  FirstAidEntry({
    required this.id,
    required this.patientId,
    this.employeeName = 'Unknown',
    required this.firstAiderId,
    this.description = '',
    this.treatment = '',
    this.actionTaken = '',
    this.referredToMedical = false,
    required this.date,
    required this.authorId,
    required this.siteId,
    required this.createdAt,
  });

  factory FirstAidEntry.fromFirestore(Map<String, dynamic> json, String id) {
    return FirstAidEntry(
      id: id,
      patientId: json['patientId'] ?? '',
      employeeName: json['employeeName'] ?? 'Unknown',
      firstAiderId: json['firstAiderId'] ?? '',
      description: json['description'] ?? '',
      treatment: json['treatment'] ?? '',
      actionTaken: json['actionTaken'] ?? '',
      referredToMedical: json['referredToMedical'] == true,
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      authorId: json['authorId'] ?? '',
      siteId: json['siteId'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'employeeName': employeeName,
      'firstAiderId': firstAiderId,
      'description': description,
      'treatment': treatment,
      'actionTaken': actionTaken,
      'referredToMedical': referredToMedical,
      'date': date.toIso8601String(),
      'authorId': authorId,
      'siteId': siteId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
