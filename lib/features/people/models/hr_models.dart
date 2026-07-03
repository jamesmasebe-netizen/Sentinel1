import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveRequest {
  final String id;
  final String employeeId;
  final String employeeName;
  final String leaveType; // Annual, Sick, Maternity, OHS Mandatory
  final DateTime startDate;
  final DateTime endDate;
  final String status; // Pending, Approved, Rejected
  final String? managerId;
  final String? reason;
  final String siteId;

  LeaveRequest({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.managerId,
    this.reason,
    required this.siteId,
  });

  factory LeaveRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LeaveRequest(
      id: doc.id,
      employeeId: data['employeeId'] ?? '',
      employeeName: data['employeeName'] ?? '',
      leaveType: data['leaveType'] ?? 'Annual',
      startDate: DateTime.parse(data['startDate']),
      endDate: DateTime.parse(data['endDate']),
      status: data['status'] ?? 'Pending',
      managerId: data['managerId'],
      reason: data['reason'],
      siteId: data['siteId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'leaveType': leaveType,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status,
      'managerId': managerId,
      'reason': reason,
      'siteId': siteId,
    };
  }
}

class PayrollLedger {
  final String id;
  final String employeeId;
  final String employeeName;
  final double baseSalary;
  final double bonuses;
  final double deductions; // Tax, UI, etc.
  final DateTime periodStart;
  final DateTime periodEnd;
  final String status; // Draft, Processed, Paid
  final String siteId;

  PayrollLedger({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.baseSalary,
    required this.bonuses,
    required this.deductions,
    required this.periodStart,
    required this.periodEnd,
    required this.status,
    required this.siteId,
  });

  double get netPay => baseSalary + bonuses - deductions;

  factory PayrollLedger.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PayrollLedger(
      id: doc.id,
      employeeId: data['employeeId'] ?? '',
      employeeName: data['employeeName'] ?? '',
      baseSalary: (data['baseSalary'] ?? 0.0).toDouble(),
      bonuses: (data['bonuses'] ?? 0.0).toDouble(),
      deductions: (data['deductions'] ?? 0.0).toDouble(),
      periodStart: DateTime.parse(data['periodStart']),
      periodEnd: DateTime.parse(data['periodEnd']),
      status: data['status'] ?? 'Draft',
      siteId: data['siteId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'baseSalary': baseSalary,
      'bonuses': bonuses,
      'deductions': deductions,
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'status': status,
      'siteId': siteId,
    };
  }
}

class JobRequisition {
  final String id;
  final String title;
  final String department;
  final String description;
  final String status; // Open, Closed, Draft
  final DateTime postedDate;
  final String siteId;

  JobRequisition({
    required this.id,
    required this.title,
    required this.department,
    required this.description,
    required this.status,
    required this.postedDate,
    required this.siteId,
  });

  factory JobRequisition.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JobRequisition(
      id: doc.id,
      title: data['title'] ?? '',
      department: data['department'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'Open',
      postedDate: DateTime.parse(data['postedDate']),
      siteId: data['siteId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'department': department,
      'description': description,
      'status': status,
      'postedDate': postedDate.toIso8601String(),
      'siteId': siteId,
    };
  }
}

class Candidate {
  final String id;
  final String requisitionId;
  final String name;
  final String email;
  final String resumeUrl;
  final String stage; // Applied, Screening, Interview, Offer, Hired, Rejected
  final DateTime appliedDate;

  Candidate({
    required this.id,
    required this.requisitionId,
    required this.name,
    required this.email,
    required this.resumeUrl,
    required this.stage,
    required this.appliedDate,
  });

  factory Candidate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Candidate(
      id: doc.id,
      requisitionId: data['requisitionId'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      resumeUrl: data['resumeUrl'] ?? '',
      stage: data['stage'] ?? 'Applied',
      appliedDate: DateTime.parse(data['appliedDate']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'requisitionId': requisitionId,
      'name': name,
      'email': email,
      'resumeUrl': resumeUrl,
      'stage': stage,
      'appliedDate': appliedDate.toIso8601String(),
    };
  }
}

class PerformanceReview {
  final String id;
  final String employeeId;
  final String reviewerId;
  final String reviewPeriod; // e.g., "Q3 2026"
  final double score; // 1.0 to 5.0
  final String feedback;
  final DateTime completedDate;
  final String siteId;

  PerformanceReview({
    required this.id,
    required this.employeeId,
    required this.reviewerId,
    required this.reviewPeriod,
    required this.score,
    required this.feedback,
    required this.completedDate,
    required this.siteId,
  });

  factory PerformanceReview.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PerformanceReview(
      id: doc.id,
      employeeId: data['employeeId'] ?? '',
      reviewerId: data['reviewerId'] ?? '',
      reviewPeriod: data['reviewPeriod'] ?? '',
      score: (data['score'] ?? 0.0).toDouble(),
      feedback: data['feedback'] ?? '',
      completedDate: DateTime.parse(data['completedDate']),
      siteId: data['siteId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'employeeId': employeeId,
      'reviewerId': reviewerId,
      'reviewPeriod': reviewPeriod,
      'score': score,
      'feedback': feedback,
      'completedDate': completedDate.toIso8601String(),
      'siteId': siteId,
    };
  }
}

class OHSAppointment {
  final String id;
  final String appointeeId;
  final String appointeeName;
  final String statutoryReference; // e.g., "OHS Act 16.2 Assignee"
  final DateTime appointedDate;
  final String status; // Active, Revoked
  final String siteId;

  OHSAppointment({
    required this.id,
    required this.appointeeId,
    required this.appointeeName,
    required this.statutoryReference,
    required this.appointedDate,
    required this.status,
    required this.siteId,
  });

  factory OHSAppointment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OHSAppointment(
      id: doc.id,
      appointeeId: data['appointeeId'] ?? '',
      appointeeName: data['appointeeName'] ?? '',
      statutoryReference: data['statutoryReference'] ?? '',
      appointedDate: DateTime.parse(data['appointedDate']),
      status: data['status'] ?? 'Active',
      siteId: data['siteId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'appointeeId': appointeeId,
      'appointeeName': appointeeName,
      'statutoryReference': statutoryReference,
      'appointedDate': appointedDate.toIso8601String(),
      'status': status,
      'siteId': siteId,
    };
  }
}
