/// A COIDA claim logged against an employee's workplace incident.
///
/// Dates are stored as ISO8601 strings, not Firestore `Timestamp`s — matching the shape every
/// existing `coida_claims` document already has on disk (`ClaimsTab`'s previous inline write did
/// `_incidentDate.toIso8601String()`/`DateTime.now().toIso8601String()`) and how `ClaimsTab`/
/// `RtwTab` previously read `incidentDate`/`createdAt` back as plain strings.
class WorkersCompClaim {
  final String id;
  final String employeeId;
  final String employeeName;
  final String idNumber;
  final String claimNumber;
  final DateTime incidentDate;
  final int lostDays;
  final String status;
  final String rtwStatus;
  final String authorId;
  final String siteId;
  final DateTime createdAt;

  WorkersCompClaim({
    required this.id,
    required this.employeeId,
    this.employeeName = 'Unknown Employee',
    this.idNumber = '',
    this.claimNumber = '',
    required this.incidentDate,
    this.lostDays = 0,
    this.status = 'Submitted',
    this.rtwStatus = 'Off Sick',
    required this.authorId,
    required this.siteId,
    required this.createdAt,
  });

  factory WorkersCompClaim.fromFirestore(Map<String, dynamic> json, String id) {
    return WorkersCompClaim(
      id: id,
      employeeId: json['employeeId'] ?? '',
      employeeName: json['employeeName'] ?? 'Unknown Employee',
      idNumber: json['idNumber'] ?? '',
      claimNumber: json['claimNumber'] ?? '',
      incidentDate: DateTime.tryParse(json['incidentDate']?.toString() ?? '') ?? DateTime.now(),
      lostDays: (json['lostDays'] as num?)?.toInt() ?? 0,
      status: json['status'] ?? 'Submitted',
      rtwStatus: json['rtwStatus'] ?? 'Off Sick',
      authorId: json['authorId'] ?? '',
      siteId: json['siteId'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'idNumber': idNumber,
      'claimNumber': claimNumber,
      'incidentDate': incidentDate.toIso8601String(),
      'lostDays': lostDays,
      'status': status,
      'rtwStatus': rtwStatus,
      'authorId': authorId,
      'siteId': siteId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
