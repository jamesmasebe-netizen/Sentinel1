class Employee {
  final String id;
  final String? authUserId;
  final String fullName;
  final String email;
  final String department;
  final String jobTitle;
  final String? managerId;
  final double leaveBalance;
  final String status; // Active, Suspended

  Employee({
    required this.id,
    this.authUserId,
    required this.fullName,
    required this.email,
    required this.department,
    required this.jobTitle,
    this.managerId,
    required this.leaveBalance,
    required this.status,
  });

  Employee copyWith({
    String? id,
    String? authUserId,
    String? fullName,
    String? email,
    String? department,
    String? jobTitle,
    String? managerId,
    double? leaveBalance,
    String? status,
  }) {
    return Employee(
      id: id ?? this.id,
      authUserId: authUserId ?? this.authUserId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      department: department ?? this.department,
      jobTitle: jobTitle ?? this.jobTitle,
      managerId: managerId ?? this.managerId,
      leaveBalance: leaveBalance ?? this.leaveBalance,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'authUserId': authUserId,
      'fullName': fullName,
      'email': email,
      'department': department,
      'jobTitle': jobTitle,
      'managerId': managerId,
      'leaveBalance': leaveBalance,
      'status': status,
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map, String documentId) {
    return Employee(
      id: documentId,
      authUserId: map['authUserId'],
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      department: map['department'] ?? '',
      jobTitle: map['jobTitle'] ?? '',
      managerId: map['managerId'],
      leaveBalance: (map['leaveBalance'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'Active',
    );
  }
}
