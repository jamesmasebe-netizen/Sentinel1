import 'package:cloud_firestore/cloud_firestore.dart';

/// Permit to Work model — mirrors Firestore `permits` collection
class Permit {
  final String? id;
  final String siteId;
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
  final String? requestedBy;
  final String? requestedByName;
  final String? approvedBy;
  final String? approvedByName;
  final DateTime? approvedAt;
  final List<String> hazards;
  final List<String> controlMeasures;
  final List<String> ppeRequired;
  final List<Map<String, dynamic>> workers;
  final String? riskAssessmentId;
  final List<String> attachments;
  final String? closureNotes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Permit({
    this.id,
    required this.siteId,
    this.permitNumber = '',
    required this.type,
    required this.title,
    required this.description,
    this.status = 'draft',
    this.location,
    this.area,
    this.startDate,
    this.endDate,
    this.requestedBy,
    this.requestedByName,
    this.approvedBy,
    this.approvedByName,
    this.approvedAt,
    this.hazards = const [],
    this.controlMeasures = const [],
    this.ppeRequired = const [],
    this.workers = const [],
    this.riskAssessmentId,
    this.attachments = const [],
    this.closureNotes,
    this.createdAt,
    this.updatedAt,
  });

  factory Permit.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Permit(
      id: doc.id,
      siteId: data['siteId'] ?? '',
      permitNumber: data['permitNumber'] ?? '',
      type: data['type'] ?? 'general',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'draft',
      location: data['location'],
      area: data['area'],
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      requestedBy: data['requestedBy'],
      requestedByName: data['requestedByName'],
      approvedBy: data['approvedBy'],
      approvedByName: data['approvedByName'],
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      hazards: List<String>.from(data['hazards'] ?? []),
      controlMeasures: List<String>.from(data['controlMeasures'] ?? []),
      ppeRequired: List<String>.from(data['ppeRequired'] ?? []),
      workers: List<Map<String, dynamic>>.from(data['workers'] ?? []),
      riskAssessmentId: data['riskAssessmentId'],
      attachments: List<String>.from(data['attachments'] ?? []),
      closureNotes: data['closureNotes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'siteId': siteId,
    'permitNumber': permitNumber,
    'type': type,
    'title': title,
    'description': description,
    'status': status,
    'location': location,
    'area': area,
    'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
    'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
    'requestedBy': requestedBy,
    'requestedByName': requestedByName,
    'approvedBy': approvedBy,
    'approvedByName': approvedByName,
    'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
    'hazards': hazards,
    'controlMeasures': controlMeasures,
    'ppeRequired': ppeRequired,
    'workers': workers,
    'riskAssessmentId': riskAssessmentId,
    'attachments': attachments,
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
  final String siteId;
  final String type; // hira, dra
  final String title;
  final String description;
  final String status; // draft, review, approved, expired
  final String? area;
  final String? activity;
  final List<Map<String, dynamic>> hazards;
  final int? inherentRiskScore;
  final int? residualRiskScore;
  final String? riskRating; // extreme, high, medium, low
  final String? assessedBy;
  final String? reviewedBy;
  final String? approvedBy;
  final DateTime? assessmentDate;
  final DateTime? reviewDate;
  final DateTime? expiryDate;
  final DateTime? createdAt;

  const RiskAssessment({
    this.id,
    required this.siteId,
    required this.type,
    required this.title,
    required this.description,
    this.status = 'draft',
    this.area,
    this.activity,
    this.hazards = const [],
    this.inherentRiskScore,
    this.residualRiskScore,
    this.riskRating,
    this.assessedBy,
    this.reviewedBy,
    this.approvedBy,
    this.assessmentDate,
    this.reviewDate,
    this.expiryDate,
    this.createdAt,
  });

  factory RiskAssessment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return RiskAssessment(
      id: doc.id,
      siteId: data['siteId'] ?? '',
      type: data['type'] ?? 'hira',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'draft',
      area: data['area'],
      activity: data['activity'],
      hazards: List<Map<String, dynamic>>.from(data['hazards'] ?? []),
      inherentRiskScore: data['inherentRiskScore'],
      residualRiskScore: data['residualRiskScore'],
      riskRating: data['riskRating'],
      assessedBy: data['assessedBy'],
      reviewedBy: data['reviewedBy'],
      approvedBy: data['approvedBy'],
      assessmentDate: (data['assessmentDate'] as Timestamp?)?.toDate(),
      reviewDate: (data['reviewDate'] as Timestamp?)?.toDate(),
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'siteId': siteId,
    'type': type,
    'title': title,
    'description': description,
    'status': status,
    'area': area,
    'activity': activity,
    'hazards': hazards,
    'inherentRiskScore': inherentRiskScore,
    'residualRiskScore': residualRiskScore,
    'riskRating': riskRating,
    'assessedBy': assessedBy,
    'reviewedBy': reviewedBy,
    'approvedBy': approvedBy,
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
  final String siteId;
  final String companyName;
  final String contactPerson;
  final String email;
  final String? phone;
  final String status; // active, suspended, blacklisted, expired
  final String? complianceStatus; // compliant, non_compliant, pending
  final DateTime? contractStart;
  final DateTime? contractEnd;
  final List<String> certifications;
  final List<Map<String, dynamic>> workers;
  final double? safetyRating;
  final DateTime? createdAt;

  const Contractor({
    this.id,
    required this.siteId,
    required this.companyName,
    required this.contactPerson,
    required this.email,
    this.phone,
    this.status = 'active',
    this.complianceStatus = 'pending',
    this.contractStart,
    this.contractEnd,
    this.certifications = const [],
    this.workers = const [],
    this.safetyRating,
    this.createdAt,
  });

  factory Contractor.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Contractor(
      id: doc.id,
      siteId: data['siteId'] ?? '',
      companyName: data['companyName'] ?? '',
      contactPerson: data['contactPerson'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      status: data['status'] ?? 'active',
      complianceStatus: data['complianceStatus'] ?? 'pending',
      contractStart: (data['contractStart'] as Timestamp?)?.toDate(),
      contractEnd: (data['contractEnd'] as Timestamp?)?.toDate(),
      certifications: List<String>.from(data['certifications'] ?? []),
      workers: List<Map<String, dynamic>>.from(data['workers'] ?? []),
      safetyRating: (data['safetyRating'] as num?)?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'siteId': siteId,
    'companyName': companyName,
    'contactPerson': contactPerson,
    'email': email,
    'phone': phone,
    'status': status,
    'complianceStatus': complianceStatus,
    'contractStart':
        contractStart != null ? Timestamp.fromDate(contractStart!) : null,
    'contractEnd':
        contractEnd != null ? Timestamp.fromDate(contractEnd!) : null,
    'certifications': certifications,
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
  final String siteId;
  final String title;
  final String description;
  final String status; // open, in_progress, completed, overdue
  final String priority; // critical, high, medium, low
  final String? source; // incident, audit, inspection, risk_assessment, meeting
  final String? sourceId;
  final String? assignedTo;
  final String? assignedToName;
  final String? createdBy;
  final DateTime? dueDate;
  final DateTime? completedDate;
  final String? completionNotes;
  final List<String> attachments;
  final DateTime? createdAt;

  const ActionItem({
    this.id,
    required this.siteId,
    required this.title,
    required this.description,
    this.status = 'open',
    this.priority = 'medium',
    this.source,
    this.sourceId,
    this.assignedTo,
    this.assignedToName,
    this.createdBy,
    this.dueDate,
    this.completedDate,
    this.completionNotes,
    this.attachments = const [],
    this.createdAt,
  });

  factory ActionItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ActionItem(
      id: doc.id,
      siteId: data['siteId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'open',
      priority: data['priority'] ?? 'medium',
      source: data['source'],
      sourceId: data['sourceId'],
      assignedTo: data['assignedTo'],
      assignedToName: data['assignedToName'],
      createdBy: data['createdBy'],
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      completedDate: (data['completedDate'] as Timestamp?)?.toDate(),
      completionNotes: data['completionNotes'],
      attachments: List<String>.from(data['attachments'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'siteId': siteId,
    'title': title,
    'description': description,
    'status': status,
    'priority': priority,
    'source': source,
    'sourceId': sourceId,
    'assignedTo': assignedTo,
    'assignedToName': assignedToName,
    'createdBy': createdBy,
    'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
    'completedDate':
        completedDate != null ? Timestamp.fromDate(completedDate!) : null,
    'completionNotes': completionNotes,
    'attachments': attachments,
    'createdAt':
        createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
  };
}
