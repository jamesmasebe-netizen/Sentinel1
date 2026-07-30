import 'package:cloud_firestore/cloud_firestore.dart';

// Helper to convert Firestore Timestamp to DateTime
DateTime? _timestampToDateTime(dynamic timestamp) {
  if (timestamp == null) return null;
  if (timestamp is Timestamp) return timestamp.toDate();
  if (timestamp is String) return DateTime.tryParse(timestamp);
  return null;
}

dynamic _dateTimeToTimestamp(DateTime? date) {
  if (date == null) return null;
  return Timestamp.fromDate(date);
}

class Department {
  final String id;
  final String name;
  final String? description;
  final String? managerId;
  final String siteId;

  Department({
    this.id = '',
    this.name = '',
    this.description,
    this.managerId,
    this.siteId = '',
  });

  factory Department.fromJson(Map<String, dynamic> json, String id) {
    return Department(
      id: id,
      name: json['name'] ?? '',
      description: json['description'],
      managerId: json['managerId'],
      siteId: json['siteId'] ?? '',
    );
  }

  factory Department.fromFirestore(DocumentSnapshot doc) {
    return Department.fromJson(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      if (description != null) 'description': description,
      if (managerId != null) 'managerId': managerId,
      'siteId': siteId,
    };
  }
}

class JobRole {
  final String id;
  final String title;
  final String? departmentId;
  final String? description;
  final bool isLegalAppointment;
  final String siteId;

  JobRole({
    this.id = '',
    this.title = '',
    this.departmentId,
    this.description,
    this.isLegalAppointment = false,
    this.siteId = '',
  });

  factory JobRole.fromJson(Map<String, dynamic> json, String id) {
    return JobRole(
      id: id,
      title: json['title'] ?? '',
      departmentId: json['departmentId'],
      description: json['description'],
      isLegalAppointment: json['isLegalAppointment'] ?? false,
      siteId: json['siteId'] ?? '',
    );
  }

  factory JobRole.fromFirestore(DocumentSnapshot doc) {
    return JobRole.fromJson(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      if (departmentId != null) 'departmentId': departmentId,
      if (description != null) 'description': description,
      'isLegalAppointment': isLegalAppointment,
      'siteId': siteId,
    };
  }
}

class OhsRole {
  final String id;
  final String title;
  final String? description;
  final String siteId;

  OhsRole({
    this.id = '',
    this.title = '',
    this.description,
    this.siteId = '',
  });

  factory OhsRole.fromJson(Map<String, dynamic> json, String id) {
    return OhsRole(
      id: id,
      title: json['title'] ?? '',
      description: json['description'],
      siteId: json['siteId'] ?? '',
    );
  }

  factory OhsRole.fromFirestore(DocumentSnapshot doc) {
    return OhsRole.fromJson(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      if (description != null) 'description': description,
      'siteId': siteId,
    };
  }
}

class EmployeeProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String? preferredName;
  final String workEmail;
  final String personalEmail;
  final String phoneNumber;
  final DateTime? hireDate;
  final DateTime? terminationDate;
  final String employmentStatus;
  final String positionId; // HR Role
  final List<String> ohsRoleIds; // OHS Act appointments
  final String departmentId;
  final String managerEmployeeId;
  final bool missingMandatorySafetyTraining;

  EmployeeProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.preferredName,
    required this.workEmail,
    required this.personalEmail,
    required this.phoneNumber,
    this.hireDate,
    this.terminationDate,
    required this.employmentStatus,
    required this.positionId,
    this.ohsRoleIds = const [],
    required this.departmentId,
    required this.managerEmployeeId,
    this.missingMandatorySafetyTraining = false,
  });

  factory EmployeeProfile.fromJson(Map<String, dynamic> json, String id) {
    return EmployeeProfile(
      id: id,
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      preferredName: json['preferredName'],
      workEmail: json['workEmail'] ?? '',
      personalEmail: json['personalEmail'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      hireDate: _timestampToDateTime(json['hireDate']),
      terminationDate: _timestampToDateTime(json['terminationDate']),
      employmentStatus: json['employmentStatus'] ?? '',
      positionId: json['positionId'] ?? '',
      ohsRoleIds: List<String>.from(json['ohsRoleIds'] ?? []),
      departmentId: json['departmentId'] ?? '',
      managerEmployeeId: json['managerEmployeeId'] ?? '',
      missingMandatorySafetyTraining:
          json['missingMandatorySafetyTraining'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      if (preferredName != null) 'preferredName': preferredName,
      'workEmail': workEmail,
      'personalEmail': personalEmail,
      'phoneNumber': phoneNumber,
      if (hireDate != null) 'hireDate': _dateTimeToTimestamp(hireDate),
      if (terminationDate != null)
        'terminationDate': _dateTimeToTimestamp(terminationDate),
      'employmentStatus': employmentStatus,
      'positionId': positionId,
      'ohsRoleIds': ohsRoleIds,
      'departmentId': departmentId,
      'managerEmployeeId': managerEmployeeId,
      'missingMandatorySafetyTraining': missingMandatorySafetyTraining,
    };
  }
}

class LeaveRequest {
  final String id;
  final String leaveTypeId;
  final DateTime startDate;
  final DateTime endDate;
  final double totalHoursRequested;
  final String status;
  final String approverId;
  final String reason;
  final String? medicalCertificateUrl;
  final String employeeId;
  final String employeeName;
  final String leaveType;
  final String managerId;
  final String siteId;

  LeaveRequest({
    required this.id,
    this.leaveTypeId = '',
    DateTime? startDate,
    DateTime? endDate,
    this.totalHoursRequested = 0.0,
    required this.status,
    this.approverId = '',
    required this.reason,
    this.medicalCertificateUrl,
    this.employeeId = '',
    this.employeeName = '',
    this.leaveType = '',
    this.managerId = '',
    this.siteId = '',
  }) : startDate = startDate ?? DateTime.now(),
       endDate = endDate ?? DateTime.now();

  factory LeaveRequest.fromJson(Map<String, dynamic> json, String id) {
    return LeaveRequest(
      id: id,
      leaveTypeId: json['leaveTypeId'],
      startDate: _timestampToDateTime(json['startDate']),
      endDate: _timestampToDateTime(json['endDate']),
      totalHoursRequested: (json['totalHoursRequested'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      approverId: json['approverId'],
      reason: json['reason'] ?? '',
      medicalCertificateUrl: json['medicalCertificateUrl'],
      employeeId: json['employeeId'],
      employeeName: json['employeeName'],
      leaveType: json['leaveType'],
      managerId: json['managerId'],
      siteId: json['siteId'],
    );
  }

  factory LeaveRequest.fromFirestore(DocumentSnapshot doc) {
    return LeaveRequest.fromJson(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toJson() {
    return toFirestore();
  }

  Map<String, dynamic> toFirestore() {
    return {
      'leaveTypeId': leaveTypeId,
      'startDate': _dateTimeToTimestamp(startDate),
      'endDate': _dateTimeToTimestamp(endDate),
      'totalHoursRequested': totalHoursRequested,
      'status': status,
      'approverId': approverId,
      'reason': reason,
      if (medicalCertificateUrl != null)
        'medicalCertificateUrl': medicalCertificateUrl,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'leaveType': leaveType,
      'managerId': managerId,
      'siteId': siteId,
    };
  }
}

class CompensationPlan {
  final String id;
  final String name;
  final String type;
  final Map<String, dynamic> eligibilityRules;
  final double targetPercentage;
  final String? vestingScheduleId;

  CompensationPlan({
    required this.id,
    required this.name,
    required this.type,
    required this.eligibilityRules,
    required this.targetPercentage,
    this.vestingScheduleId,
  });

  factory CompensationPlan.fromJson(Map<String, dynamic> json, String id) {
    return CompensationPlan(
      id: id,
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      eligibilityRules: Map<String, dynamic>.from(
        json['eligibilityRules'] ?? {},
      ),
      targetPercentage: (json['targetPercentage'] ?? 0).toDouble(),
      vestingScheduleId: json['vestingScheduleId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'eligibilityRules': eligibilityRules,
      'targetPercentage': targetPercentage,
      if (vestingScheduleId != null) 'vestingScheduleId': vestingScheduleId,
    };
  }
}

class BenefitEnrollment {
  final String id;
  final String planId;
  final String planType;
  final String coverageTier;
  final String status;
  final DateTime? effectiveDate;
  final List<String> dependentsCovered;
  final double employeeContribution;
  final double employerContribution;

  BenefitEnrollment({
    required this.id,
    required this.planId,
    required this.planType,
    required this.coverageTier,
    required this.status,
    this.effectiveDate,
    required this.dependentsCovered,
    required this.employeeContribution,
    required this.employerContribution,
  });

  factory BenefitEnrollment.fromJson(Map<String, dynamic> json, String id) {
    return BenefitEnrollment(
      id: id,
      planId: json['planId'] ?? '',
      planType: json['planType'] ?? '',
      coverageTier: json['coverageTier'] ?? '',
      status: json['status'] ?? '',
      effectiveDate: _timestampToDateTime(json['effectiveDate']),
      dependentsCovered: List<String>.from(json['dependentsCovered'] ?? []),
      employeeContribution: (json['employeeContribution'] ?? 0).toDouble(),
      employerContribution: (json['employerContribution'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'planId': planId,
      'planType': planType,
      'coverageTier': coverageTier,
      'status': status,
      if (effectiveDate != null)
        'effectiveDate': _dateTimeToTimestamp(effectiveDate),
      'dependentsCovered': dependentsCovered,
      'employeeContribution': employeeContribution,
      'employerContribution': employerContribution,
    };
  }
}

class PerformanceReview {
  final String id;
  final String cycleId;
  final String managerId;
  final Map<String, dynamic> selfEvaluation;
  final Map<String, dynamic> managerEvaluation;
  final List<dynamic> peerFeedback;
  final dynamic overallRating;
  final String status;
  final String employeeId;
  final String reviewerId;
  final String reviewPeriod;
  final double score;
  final String feedback;
  final DateTime completedDate;
  final String siteId;

  PerformanceReview({
    required this.id,
    this.cycleId = '',
    this.managerId = '',
    Map<String, dynamic>? selfEvaluation,
    Map<String, dynamic>? managerEvaluation,
    List<dynamic>? peerFeedback,
    this.overallRating,
    this.status = '',
    this.employeeId = '',
    this.reviewerId = '',
    this.reviewPeriod = '',
    this.score = 0.0,
    this.feedback = '',
    DateTime? completedDate,
    this.siteId = '',
  }) : completedDate = completedDate ?? DateTime.now(),
       selfEvaluation = selfEvaluation ?? {},
       managerEvaluation = managerEvaluation ?? {},
       peerFeedback = peerFeedback ?? [];

  factory PerformanceReview.fromJson(Map<String, dynamic> json, String id) {
    return PerformanceReview(
      id: id,
      cycleId: json['cycleId'],
      managerId: json['managerId'],
      selfEvaluation:
          json['selfEvaluation'] != null
              ? Map<String, dynamic>.from(json['selfEvaluation'])
              : null,
      managerEvaluation:
          json['managerEvaluation'] != null
              ? Map<String, dynamic>.from(json['managerEvaluation'])
              : null,
      peerFeedback:
          json['peerFeedback'] != null
              ? List<dynamic>.from(json['peerFeedback'])
              : null,
      overallRating: json['overallRating'],
      status: json['status'],
      employeeId: json['employeeId'],
      reviewerId: json['reviewerId'],
      reviewPeriod: json['reviewPeriod'],
      score: json['score']?.toDouble(),
      feedback: json['feedback'],
      completedDate: _timestampToDateTime(json['completedDate']),
      siteId: json['siteId'],
    );
  }

  factory PerformanceReview.fromFirestore(DocumentSnapshot doc) {
    return PerformanceReview.fromJson(
      doc.data() as Map<String, dynamic>,
      doc.id,
    );
  }

  Map<String, dynamic> toJson() {
    return toFirestore();
  }

  Map<String, dynamic> toFirestore() {
    return {
      'cycleId': cycleId,
      'managerId': managerId,
      'selfEvaluation': selfEvaluation,
      'managerEvaluation': managerEvaluation,
      'peerFeedback': peerFeedback,
      if (overallRating != null) 'overallRating': overallRating,
      'status': status,
      'employeeId': employeeId,
      'reviewerId': reviewerId,
      'reviewPeriod': reviewPeriod,
      'score': score,
      'feedback': feedback,
      'completedDate': _dateTimeToTimestamp(completedDate),
      'siteId': siteId,
    };
  }
}

class Candidate {
  final String id;
  final String requisitionId;
  final String name;
  final String title;
  final String email;
  final String department;
  final String stage;
  final String resumeUrl;
  final DateTime appliedDate;

  Candidate({
    this.id = '',
    this.requisitionId = '',
    this.name = '',
    this.title = '',
    this.email = '',
    this.department = '',
    this.stage = '',
    this.resumeUrl = '',
    DateTime? appliedDate,
  }) : appliedDate = appliedDate ?? DateTime.now();

  factory Candidate.fromJson(Map<String, dynamic> json, String id) {
    return Candidate(
      id: id,
      requisitionId: json['requisitionId'] ?? '',
      name: json['name'] ?? '',
      title: json['title'] ?? '',
      email: json['email'] ?? '',
      department: json['department'] ?? '',
      stage: json['stage'] ?? '',
      resumeUrl: json['resumeUrl'] ?? '',
      appliedDate: _timestampToDateTime(json['appliedDate']),
    );
  }

  factory Candidate.fromFirestore(DocumentSnapshot doc) {
    return Candidate.fromJson(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toFirestore() {
    return {
      'requisitionId': requisitionId,
      'name': name,
      'title': title,
      'email': email,
      'department': department,
      'stage': stage,
      'resumeUrl': resumeUrl,
      'appliedDate': _dateTimeToTimestamp(appliedDate),
    };
  }
}

class JobRequisition {
  final String id;
  final String title;
  final String department;
  final String description;
  final String status;
  final DateTime postedDate;
  final String siteId;

  JobRequisition({
    this.id = '',
    this.title = '',
    this.department = '',
    this.description = '',
    this.status = '',
    DateTime? postedDate,
    this.siteId = '',
  }) : postedDate = postedDate ?? DateTime.now();

  factory JobRequisition.fromJson(Map<String, dynamic> json, String id) {
    return JobRequisition(
      id: id,
      title: json['title'] ?? '',
      department: json['department'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? '',
      postedDate: _timestampToDateTime(json['postedDate']),
      siteId: json['siteId'] ?? '',
    );
  }

  factory JobRequisition.fromFirestore(DocumentSnapshot doc) {
    return JobRequisition.fromJson(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'department': department,
      'description': description,
      'status': status,
      'postedDate': _dateTimeToTimestamp(postedDate),
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
  final double deductions;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String status;
  final String siteId;

  double get netPay => baseSalary + bonuses - deductions;

  PayrollLedger({
    this.id = '',
    this.employeeId = '',
    this.employeeName = '',
    this.baseSalary = 0.0,
    this.bonuses = 0.0,
    this.deductions = 0.0,
    DateTime? periodStart,
    DateTime? periodEnd,
    this.status = '',
    this.siteId = '',
  }) : periodStart = periodStart ?? DateTime.now(),
       periodEnd = periodEnd ?? DateTime.now();

  factory PayrollLedger.fromJson(Map<String, dynamic> json, String id) {
    return PayrollLedger(
      id: id,
      employeeId: json['employeeId'],
      employeeName: json['employeeName'],
      baseSalary: json['baseSalary']?.toDouble(),
      bonuses: json['bonuses']?.toDouble(),
      deductions: json['deductions']?.toDouble(),
      periodStart: _timestampToDateTime(json['periodStart']),
      periodEnd: _timestampToDateTime(json['periodEnd']),
      status: json['status'],
      siteId: json['siteId'],
    );
  }

  factory PayrollLedger.fromFirestore(DocumentSnapshot doc) {
    return PayrollLedger.fromJson(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toFirestore() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'baseSalary': baseSalary,
      'bonuses': bonuses,
      'deductions': deductions,
      'periodStart': _dateTimeToTimestamp(periodStart),
      'periodEnd': _dateTimeToTimestamp(periodEnd),
      'status': status,
      'siteId': siteId,
    };
  }
}

class OHSAppointment {
  final String id;
  final String appointeeId;
  final String appointeeName;
  final String statutoryReference;
  final DateTime appointedDate;
  final String status;
  final String siteId;

  OHSAppointment({
    this.id = '',
    this.appointeeId = '',
    this.appointeeName = '',
    this.statutoryReference = '',
    DateTime? appointedDate,
    this.status = '',
    this.siteId = '',
  }) : appointedDate = appointedDate ?? DateTime.now();

  factory OHSAppointment.fromJson(Map<String, dynamic> json, String id) {
    return OHSAppointment(
      id: id,
      appointeeId: json['appointeeId'] ?? '',
      appointeeName: json['appointeeName'] ?? '',
      statutoryReference: json['statutoryReference'] ?? '',
      appointedDate: _timestampToDateTime(json['appointedDate']),
      status: json['status'] ?? '',
      siteId: json['siteId'] ?? '',
    );
  }

  factory OHSAppointment.fromFirestore(DocumentSnapshot doc) {
    return OHSAppointment.fromJson(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toFirestore() {
    return {
      'appointeeId': appointeeId,
      'appointeeName': appointeeName,
      'statutoryReference': statutoryReference,
      'appointedDate': _dateTimeToTimestamp(appointedDate),
      'status': status,
      'siteId': siteId,
    };
  }
}
