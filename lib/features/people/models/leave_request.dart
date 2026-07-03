class LeaveRequest {
  final String id;
  final String employeeId;
  final DateTime startDate;
  final DateTime endDate;
  final String type; // Annual, Sick, Maternity, Family Responsibility
  final String status; // Pending, Approved, Rejected
  final String reason;

  LeaveRequest({
    required this.id,
    required this.employeeId,
    required this.startDate,
    required this.endDate,
    required this.type,
    required this.status,
    required this.reason,
  });

  LeaveRequest copyWith({
    String? id,
    String? employeeId,
    DateTime? startDate,
    DateTime? endDate,
    String? type,
    String? status,
    String? reason,
  }) {
    return LeaveRequest(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      type: type ?? this.type,
      status: status ?? this.status,
      reason: reason ?? this.reason,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'type': type,
      'status': status,
      'reason': reason,
    };
  }

  factory LeaveRequest.fromMap(Map<String, dynamic> map, String documentId) {
    return LeaveRequest(
      id: documentId,
      employeeId: map['employeeId'] ?? '',
      startDate:
          map['startDate'] != null
              ? DateTime.parse(map['startDate'])
              : DateTime.now(),
      endDate:
          map['endDate'] != null
              ? DateTime.parse(map['endDate'])
              : DateTime.now(),
      type: map['type'] ?? 'Annual',
      status: map['status'] ?? 'Pending',
      reason: map['reason'] ?? '',
    );
  }
}
