import 'package:cloud_firestore/cloud_firestore.dart';

enum FindingStatus { open, addressed, verifiedClosed, cancelled }

enum FindingType { majorNc, minorNc, observation, commendation }

enum SubmissionStatus { pending, underReview, requiresRevision, finalized }

class Finding {
  final String findingId;
  final String submissionId;
  final String documentId;
  final int requirementId;
  final FindingStatus status;
  final FindingType type;
  final String description;
  final String contractorAction;
  final String reviewerUid;
  final String reviewerName;
  final DateTime createdAt;
  final String modifiedBy;
  final DateTime modifiedAt;
  final List<Map<String, dynamic>> statusHistory;

  Finding({
    required this.findingId,
    required this.submissionId,
    required this.documentId,
    required this.requirementId,
    required this.status,
    required this.type,
    required this.description,
    required this.contractorAction,
    required this.reviewerUid,
    required this.reviewerName,
    required this.createdAt,
    required this.modifiedBy,
    required this.modifiedAt,
    required this.statusHistory,
  });

  factory Finding.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Finding(
      findingId: doc.id,
      submissionId: data['submissionId'] ?? '',
      documentId: data['documentId'] ?? '',
      requirementId: data['requirementId'] ?? 0,
      status: FindingStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => FindingStatus.open,
      ),
      type: FindingType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => FindingType.observation,
      ),
      description: data['description'] ?? '',
      contractorAction: data['contractorAction'] ?? '',
      reviewerUid: data['reviewerUid'] ?? '',
      reviewerName: data['reviewerName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      modifiedBy: data['modifiedBy'] ?? '',
      modifiedAt: (data['modifiedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      statusHistory: List<Map<String, dynamic>>.from(data['statusHistory'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'submissionId': submissionId,
      'documentId': documentId,
      'requirementId': requirementId,
      'status': status.name,
      'type': type.name,
      'description': description,
      'contractorAction': contractorAction,
      'reviewerUid': reviewerUid,
      'reviewerName': reviewerName,
      'createdAt': createdAt,
      'modifiedBy': modifiedBy,
      'modifiedAt': modifiedAt,
      'statusHistory': statusHistory,
    };
  }
}

class SafetyFileSubmission {
  final String id;
  final String contractorId;
  final String projectId;
  final String siteId;
  final SubmissionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double score;

  SafetyFileSubmission({
    required this.id,
    required this.contractorId,
    required this.projectId,
    required this.siteId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.score = 0.0,
  });

  factory SafetyFileSubmission.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SafetyFileSubmission(
      id: doc.id,
      contractorId: data['contractorId'] ?? '',
      projectId: data['projectId'] ?? '',
      siteId: data['siteId'] ?? '',
      status: SubmissionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => SubmissionStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      score: (data['score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contractorId': contractorId,
      'projectId': projectId,
      'siteId': siteId,
      'status': status.name,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'score': score,
    };
  }
}