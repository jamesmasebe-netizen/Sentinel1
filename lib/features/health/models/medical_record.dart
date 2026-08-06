/// An occupational medical surveillance record (`medical_records`).
///
/// Dates are stored as ISO8601 strings, not Firestore `Timestamp`s — matching the shape every
/// existing `medical_records` document already has on disk (see `HealthService`) and the
/// compliance module's identical convention (`ComplianceDocument`).
class MedicalRecord {
  final String id;
  final String employeeId;
  final String employeeName;
  final String idNumber;
  final String medicalType;
  final String status;
  final String restrictions;
  final String practitionerName;
  final String facility;
  final DateTime dateConducted;
  final DateTime nextDueDate;
  final String authorId;
  final String siteId;
  final DateTime createdAt;

  MedicalRecord({
    required this.id,
    required this.employeeId,
    this.employeeName = 'Unknown Employee',
    this.idNumber = '',
    this.medicalType = 'Exam',
    this.status = 'Unknown',
    this.restrictions = '',
    this.practitionerName = '',
    this.facility = '',
    required this.dateConducted,
    required this.nextDueDate,
    required this.authorId,
    required this.siteId,
    required this.createdAt,
  });

  factory MedicalRecord.fromFirestore(Map<String, dynamic> json, String id) {
    return MedicalRecord(
      id: id,
      employeeId: json['employeeId'] ?? '',
      employeeName: json['employeeName'] ?? 'Unknown Employee',
      idNumber: json['idNumber'] ?? '',
      medicalType: json['medicalType'] ?? 'Exam',
      status: json['status'] ?? 'Unknown',
      restrictions: json['restrictions'] ?? '',
      practitionerName: json['practitionerName'] ?? '',
      facility: json['facility'] ?? '',
      dateConducted:
          DateTime.tryParse(json['dateConducted']?.toString() ?? '') ?? DateTime.now(),
      nextDueDate: DateTime.tryParse(json['nextDueDate']?.toString() ?? '') ?? DateTime.now(),
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
      'medicalType': medicalType,
      'status': status,
      'restrictions': restrictions,
      'practitionerName': practitionerName,
      'facility': facility,
      'dateConducted': dateConducted.toIso8601String(),
      'nextDueDate': nextDueDate.toIso8601String(),
      'authorId': authorId,
      'siteId': siteId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
