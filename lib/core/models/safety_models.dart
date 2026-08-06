import 'package:cloud_firestore/cloud_firestore.dart';

/// Permit to Work model — mirrors Firestore `permits` collection
class Permit {
  final String? id;
  final String tenantId;
  final String permitNumber;
  final String
  type; // hot_work, confined_space, excavation, electrical, working_at_height, general
  final String title;
  final String description;
  final String
  status; // draft, pending_approval, approved, active, completed, cancelled, expired
  final String? location;
  final String? area;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? requesterId;
  final String? approverId;
  final DateTime? approvedAt;
  final List<Map<String, dynamic>> workers;
  final String? riskAssessmentId;
  final String? closureNotes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Permit({
    this.id,
    required this.tenantId,
    this.permitNumber = '',
    required this.type,
    required this.title,
    required this.description,
    this.status = 'draft',
    this.location,
    this.area,
    this.startDate,
    this.endDate,
    this.requesterId,
    this.approverId,
    this.approvedAt,
    this.workers = const [],
    this.riskAssessmentId,
    this.closureNotes,
    this.createdAt,
    this.updatedAt,
  });

  factory Permit.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Permit(
      id: doc.id,
      tenantId: data['tenantId'] ?? '',
      permitNumber: data['permitNumber'] ?? '',
      type: data['type'] ?? 'general',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'draft',
      location: data['location'],
      area: data['area'],
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      requesterId: data['requestedBy'],
      approverId: data['approvedBy'],
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      workers: List<Map<String, dynamic>>.from(data['workers'] ?? []),
      riskAssessmentId: data['riskAssessmentId'],
      closureNotes: data['closureNotes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'tenantId': tenantId,
    'permitNumber': permitNumber,
    'type': type,
    'title': title,
    'description': description,
    'status': status,
    'location': location,
    'area': area,
    'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
    'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
    'requesterId': requesterId,
    'approverId': approverId,
    'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
    'workers': workers,
    'riskAssessmentId': riskAssessmentId,
    'closureNotes': closureNotes,
    'createdAt':
        createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

/// Risk Assessment — backs the Risk module's HIRA (`type: 'hira'`) sub-feature, stored in the
/// tenant-scoped `risk_assessments` collection (see `HiraService`,
/// `lib/features/risk/services/hira_service.dart`). Was previously a dead/unused class (zero
/// references anywhere outside this file) whose field mapping didn't actually match what
/// `hira_form.dart` writes: `approverId`/`assessorId` were read from the wrong raw keys
/// (`approvedBy`/would-be `assessorId` instead of the real `approverId`/`assessedBy`),
/// `reviewDate` was force-cast to `Timestamp` even though it's written as an ISO8601 string (a
/// real on-disk read would have thrown), and several fields the writer actually populates —
/// `hazard`, `consequence`, `controlMeasure`, `residualRiskLevel`, `teamMembers` — were missing
/// entirely while unused ones (`area`, `activity`, `assessmentDate`, `expiryDate`,
/// `residualRiskScore`) were present. Corrected in place (Wave 2b, 2026-08-06) to match the real
/// on-disk shape exactly, safe to do since nothing else referenced this class yet (confirmed via
/// repo-wide grep). `createdAt` is a real Firestore `Timestamp` (`FieldValue.serverTimestamp()`);
/// `reviewDate` is an ISO8601 string — `_parseDate` below handles both shapes defensively so a
/// legacy/differently-shaped document can never throw on read.
class RiskAssessment {
  final String? id;
  final String siteId;
  final String
  type; // hira (DRA uses its own DynamicRiskAssessment model — see dra_service.dart)
  final String title;
  final String description;
  final String hazard;
  final String consequence;
  final String likelihood;
  final String severity;
  final int? inherentRiskScore;
  final String? riskRating; // Extreme, High, Medium, Low
  final String? controlMeasure;
  final String? residualRiskLevel;
  final List<String> teamMembers;
  final String? approverId;
  final DateTime? reviewDate;
  final String status; // active, draft, review, expired
  final String? assessorId;
  final String? reviewerId;
  final DateTime? createdAt;

  const RiskAssessment({
    this.id,
    required this.siteId,
    this.type = 'hira',
    required this.title,
    this.description = '',
    this.hazard = '',
    this.consequence = '',
    this.likelihood = '',
    this.severity = '',
    this.inherentRiskScore,
    this.riskRating,
    this.controlMeasure,
    this.residualRiskLevel,
    this.teamMembers = const [],
    this.approverId,
    this.reviewDate,
    this.status = 'active',
    this.assessorId,
    this.reviewerId,
    this.createdAt,
  });

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  factory RiskAssessment.fromFirestore(Map<String, dynamic> json, String id) {
    return RiskAssessment(
      id: id,
      siteId: json['siteId'] ?? '',
      type: json['type'] ?? 'hira',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      hazard: json['hazard'] ?? '',
      consequence: json['consequence'] ?? '',
      likelihood: json['likelihood'] ?? '',
      severity: json['severity'] ?? '',
      inherentRiskScore: json['inherentRiskScore'],
      riskRating: json['riskRating'],
      controlMeasure: json['controlMeasure'],
      residualRiskLevel: json['residualRiskLevel'],
      teamMembers: List<String>.from(json['teamMembers'] ?? []),
      approverId: json['approverId'],
      reviewDate: _parseDate(json['reviewDate']),
      status: json['status'] ?? 'active',
      assessorId: json['assessedBy'],
      reviewerId: json['reviewedBy'],
      createdAt: _parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'siteId': siteId,
    'type': type,
    'title': title,
    'description': description,
    'hazard': hazard,
    'consequence': consequence,
    'likelihood': likelihood,
    'severity': severity,
    'inherentRiskScore': inherentRiskScore,
    'riskRating': riskRating,
    'controlMeasure': controlMeasure,
    'residualRiskLevel': residualRiskLevel,
    'teamMembers': teamMembers,
    'approverId': approverId,
    'reviewDate': reviewDate?.toIso8601String(),
    'status': status,
    'assessedBy': assessorId,
    if (reviewerId != null) 'reviewedBy': reviewerId,
    'createdAt':
        createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
  };
}

/// Contractor model
class Contractor {
  final String? id;
  final String tenantId;
  final String companyName;
  final String contactPersonId;
  final String email;
  final String? phone;
  final String status; // active, suspended, blacklisted, expired
  final String? complianceStatus; // compliant, non_compliant, pending
  final String? companyRegistrationNumber;
  final String? scopeOfWork;
  final String? riskRating;
  final DateTime? contractStart;
  final DateTime? contractEnd;
  final List<Map<String, dynamic>> workers;
  final double? safetyRating;
  final DateTime? createdAt;

  const Contractor({
    this.id,
    required this.tenantId,
    required this.companyName,
    required this.contactPersonId,
    required this.email,
    this.phone,
    this.status = 'active',
    this.complianceStatus = 'pending',
    this.companyRegistrationNumber,
    this.scopeOfWork,
    this.riskRating,
    this.contractStart,
    this.contractEnd,
    this.workers = const [],
    this.safetyRating,
    this.createdAt,
  });

  factory Contractor.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Contractor(
      id: doc.id,
      tenantId: data['tenantId'] ?? '',
      companyName: data['companyName'] ?? '',
      contactPersonId: data['contactPerson'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      status: data['status'] ?? 'active',
      complianceStatus: data['complianceStatus'] ?? 'pending',
      companyRegistrationNumber: data['companyRegistrationNumber'] ?? data['registrationNumber'],
      scopeOfWork: data['scopeOfWork'],
      riskRating: data['riskRating'],
      contractStart: (data['contractStart'] as Timestamp?)?.toDate(),
      contractEnd: (data['contractEnd'] as Timestamp?)?.toDate(),
      workers: List<Map<String, dynamic>>.from(data['workers'] ?? []),
      safetyRating: (data['safetyRating'] as num?)?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'tenantId': tenantId,
    'companyName': companyName,
    'contactPersonId': contactPersonId,
    'email': email,
    'phone': phone,
    'status': status,
    'complianceStatus': complianceStatus,
    'companyRegistrationNumber': companyRegistrationNumber,
    'scopeOfWork': scopeOfWork,
    'riskRating': riskRating,
    'contractStart':
        contractStart != null ? Timestamp.fromDate(contractStart!) : null,
    'contractEnd':
        contractEnd != null ? Timestamp.fromDate(contractEnd!) : null,
    'workers': workers,
    'safetyRating': safetyRating,
    'createdAt':
        createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
  };
}

/// Action Item
class ActionItem {
  final String? id;
  final String tenantId;
  final String title;
  final String description;
  final String status; // open, in_progress, completed, overdue
  final String priority; // critical, high, medium, low
  final String? source; // incident, audit, inspection, risk_assessment, meeting
  final String? sourceId;
  final String? assigneeId;
  final String? creatorId;
  final DateTime? dueDate;
  final DateTime? completedDate;
  final String? completionNotes;
  final DateTime? createdAt;

  const ActionItem({
    this.id,
    required this.tenantId,
    required this.title,
    required this.description,
    this.status = 'open',
    this.priority = 'medium',
    this.source,
    this.sourceId,
    this.assigneeId,
    this.creatorId,
    this.dueDate,
    this.completedDate,
    this.completionNotes,
    this.createdAt,
  });

  factory ActionItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ActionItem(
      id: doc.id,
      tenantId: data['tenantId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'open',
      priority: data['priority'] ?? 'medium',
      source: data['source'],
      sourceId: data['sourceId'],
      assigneeId: data['assignedTo'],
      creatorId: data['createdBy'],
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      completedDate: (data['completedDate'] as Timestamp?)?.toDate(),
      completionNotes: data['completionNotes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'tenantId': tenantId,
    'title': title,
    'description': description,
    'status': status,
    'priority': priority,
    'source': source,
    'sourceId': sourceId,
    'assigneeId': assigneeId,
    'creatorId': creatorId,
    'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
    'completedDate':
        completedDate != null ? Timestamp.fromDate(completedDate!) : null,
    'completionNotes': completionNotes,
    'createdAt':
        createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
  };
}
