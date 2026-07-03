class Enrollment {
  final String id;
  final String courseId;
  final String employeeId;
  final double progressPercentage;
  final String status; // Not Started, In Progress, Completed
  final DateTime enrollmentDate;

  Enrollment({
    required this.id,
    required this.courseId,
    required this.employeeId,
    this.progressPercentage = 0.0,
    this.status = 'Not Started',
    required this.enrollmentDate,
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
    };
  }

  factory Enrollment.fromMap(Map<String, dynamic> map, String docId) {
    return Enrollment(
      id: docId,
      courseId: map['courseId'] ?? '',
      employeeId: map['employeeId'] ?? '',
      progressPercentage: (map['progressPercentage'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'Not Started',
      enrollmentDate: map['enrollmentDate'] != null 
          ? DateTime.parse(map['enrollmentDate']) 
          : DateTime.now(),
    );
  }
}
