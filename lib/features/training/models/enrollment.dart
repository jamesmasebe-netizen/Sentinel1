/// Unified 2026-08-12 — this collection ('enrollments') previously had a twin,
/// 'training_enrollments', holding the identical underlying concept (an employee's progress
/// against a course) with only the trigger differing: self-enrolled (via CoursePlayerScreen) vs.
/// manager-assigned (via AllocateCourseForm). [source] is the discriminator that replaced the
/// separate collection. employeeName/courseName/dueDate/assignedAt/authorId/siteId were
/// previously training_enrollments-only fields — nullable here since a self-paced enrollment
/// may not set them.
class Enrollment {
  final String id;
  final String courseId;
  final String employeeId;
  final double progressPercentage;
  final String status; // Not Started, In Progress, Assigned, Completed
  final DateTime enrollmentDate;
  final String source; // 'self_paced' | 'manager_assigned'
  final String? employeeName;
  final String? courseName;
  final DateTime? dueDate;
  final DateTime? assignedAt;
  final String? authorId;
  final String? siteId;

  Enrollment({
    required this.id,
    required this.courseId,
    required this.employeeId,
    this.progressPercentage = 0.0,
    this.status = 'Not Started',
    required this.enrollmentDate,
    this.source = 'self_paced',
    this.employeeName,
    this.courseName,
    this.dueDate,
    this.assignedAt,
    this.authorId,
    this.siteId,
  });

  Enrollment copyWith({
    String? id,
    String? courseId,
    String? employeeId,
    double? progressPercentage,
    String? status,
    DateTime? enrollmentDate,
  }) {
    return Enrollment(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      employeeId: employeeId ?? this.employeeId,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      status: status ?? this.status,
      enrollmentDate: enrollmentDate ?? this.enrollmentDate,
      source: source,
      employeeName: employeeName,
      courseName: courseName,
      dueDate: dueDate,
      assignedAt: assignedAt,
      authorId: authorId,
      siteId: siteId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'employeeId': employeeId,
      'progressPercentage': progressPercentage,
      'status': status,
      'enrollmentDate': enrollmentDate.toIso8601String(),
      'source': source,
      if (employeeName != null) 'employeeName': employeeName,
      if (courseName != null) 'courseName': courseName,
      if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
      if (assignedAt != null) 'assignedAt': assignedAt!.toIso8601String(),
      if (authorId != null) 'authorId': authorId,
      if (siteId != null) 'siteId': siteId,
    };
  }

  factory Enrollment.fromMap(Map<String, dynamic> map, String docId) {
    return Enrollment(
      id: docId,
      courseId: map['courseId'] ?? '',
      employeeId: map['employeeId'] ?? '',
      progressPercentage: (map['progressPercentage'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'Not Started',
      enrollmentDate:
          map['enrollmentDate'] != null
              ? DateTime.parse(map['enrollmentDate'])
              : DateTime.now(),
      source: map['source'] ?? 'self_paced',
      employeeName: map['employeeName'],
      courseName: map['courseName'],
      dueDate: map['dueDate'] != null ? DateTime.tryParse(map['dueDate']) : null,
      assignedAt: map['assignedAt'] != null ? DateTime.tryParse(map['assignedAt']) : null,
      authorId: map['authorId'],
      siteId: map['siteId'],
    );
  }
}
