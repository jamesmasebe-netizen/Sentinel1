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

/// Risk Assessment (HIRA / DRA)
class RiskAssessment {
  final String? id;
  final String tenantId;
  final String type; // hira, dra
  final String title;
  final String description;
  final String status; // draft, review, approved, expired
  final String? area;
  final String? activity;
  final int? inherentRiskScore;
  final int? residualRiskScore;
  final String? riskRating; // extreme, high, medium, low
  final String? assessorId;
  final String? reviewerId;
  final String? approverId;
  final DateTime? assessmentDate;
  final DateTime? reviewDate;
  final DateTime? expiryDate;
  final DateTime? createdAt;

  const RiskAssessment({
    this.id,
    required this.tenantId,
    required this.type,
    required this.title,
    required this.description,
    this.status = 'draft',
    this.area,
    this.activity,
    this.inherentRiskScore,
    this.residualRiskScore,
    this.riskRating,
    this.assessorId,
    this.reviewerId,
    this.approverId,
    this.assessmentDate,
    this.reviewDate,
    this.expiryDate,
    this.createdAt,
  });

  factory RiskAssessment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return RiskAssessment(
      id: doc.id,
      tenantId: data['tenantId'] ?? '',
      type: data['type'] ?? 'hira',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'draft',
      area: data['area'],
      activity: data['activity'],
      inherentRiskScore: data['inherentRiskScore'],
      residualRiskScore: data['residualRiskScore'],
      riskRating: data['riskRating'],
      assessorId: data['assessedBy'],
      reviewerId: data['reviewedBy'],
      approverId: data['approvedBy'],
      assessmentDate: (data['assessmentDate'] as Timestamp?)?.toDate(),
      reviewDate: (data['reviewDate'] as Timestamp?)?.toDate(),
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'tenantId': tenantId,
    'type': type,
    'title': title,
    'description': description,
    'status': status,
    'area': area,
    'activity': activity,
    'inherentRiskScore': inherentRiskScore,
    'residualRiskScore': residualRiskScore,
    'riskRating': riskRating,
    'assessorId': assessorId,
    'reviewerId': reviewerId,
    'approverId': approverId,
    'assessmentDate':
        assessmentDate != null ? Timestamp.fromDate(assessmentDate!) : null,
    'reviewDate': reviewDate != null ? Timestamp.fromDate(reviewDate!) : null,
    'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
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
