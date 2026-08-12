/// A completion/qualification record (`training_records`) — distinct from [Enrollment]'s
/// in-progress tracking. Added 2026-08-12 as a real typed model for a collection that already had
/// one consistent shape across its 2 real writers (CoursePlayerScreen's auto-generated
/// certificate on course completion, and RecordFormSheet's manually-logged external
/// qualification) but no model class — both wrote raw maps directly.
class TrainingCertificate {
  final String id;
  final String employeeId;
  final String employeeName;
  final String idNumber;
  final String courseName;
  final DateTime dateCompleted;
  final DateTime expiryDate;
  final String status; // Active, Expired
  final String authorId;
  final String siteId;
  final DateTime createdAt;

  TrainingCertificate({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    this.idNumber = '',
    required this.courseName,
    required this.dateCompleted,
    required this.expiryDate,
    required this.status,
    required this.authorId,
    required this.siteId,
    required this.createdAt,
  });

  factory TrainingCertificate.fromFirestore(Map<String, dynamic> json, String id) {
    return TrainingCertificate(
      id: id,
      employeeId: json['employeeId'] ?? '',
      employeeName: json['employeeName'] ?? 'Unknown Employee',
      idNumber: json['idNumber'] ?? '',
      courseName: json['courseName'] ?? '',
      dateCompleted:
          DateTime.tryParse(json['dateCompleted']?.toString() ?? '') ?? DateTime.now(),
      expiryDate: DateTime.tryParse(json['expiryDate']?.toString() ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'Active',
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
      'courseName': courseName,
      'dateCompleted': dateCompleted.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'status': status,
      'authorId': authorId,
      'siteId': siteId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
