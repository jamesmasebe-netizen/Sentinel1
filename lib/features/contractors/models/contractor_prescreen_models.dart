import 'package:cloud_firestore/cloud_firestore.dart';

enum PreScreenStatus { pending, processing, completed, failed }

class PrescreenFlag {
  final String field;
  final String issue;
  final String severity; // 'critical', 'warning', 'info'
  final String? detectedValue;
  final String? expectedValue;

  PrescreenFlag({
    required this.field,
    required this.issue,
    required this.severity,
    this.detectedValue,
    this.expectedValue,
  });

  factory PrescreenFlag.fromMap(Map<String, dynamic> map) {
    return PrescreenFlag(
      field: map['field'] ?? '',
      issue: map['issue'] ?? '',
      severity: map['severity'] ?? 'info',
      detectedValue: map['detectedValue'],
      expectedValue: map['expectedValue'],
    );
  }

  Map<String, dynamic> toMap() => {
    'field': field,
    'issue': issue,
    'severity': severity,
    'detectedValue': detectedValue,
    'expectedValue': expectedValue,
  };
}

class ContractorPrescreenResult {
  final String id;
  final String documentId;
  final String submissionId;
  final PreScreenStatus status;
  final List<PrescreenFlag> flags;
  final double confidenceScore;
  final Map<String, String> extractedDates; // e.g. {'medicalCertExpiry': '2026-12-01'}
  final Map<String, String> extractedCertifications; // e.g. {'firstAid': 'Level 2'}
  final DateTime processedAt;
  final String? errorMessage;

  ContractorPrescreenResult({
    required this.id,
    required this.documentId,
    required this.submissionId,
    required this.status,
    required this.flags,
    required this.confidenceScore,
    required this.extractedDates,
    required this.extractedCertifications,
    required this.processedAt,
    this.errorMessage,
  });

  factory ContractorPrescreenResult.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ContractorPrescreenResult(
      id: doc.id,
      documentId: data['documentId'] ?? '',
      submissionId: data['submissionId'] ?? '',
      status: PreScreenStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => PreScreenStatus.pending,
      ),
      flags: (data['flags'] as List<dynamic>? ?? [])
          .map((f) => PrescreenFlag.fromMap(f as Map<String, dynamic>))
          .toList(),
      confidenceScore: (data['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      extractedDates: Map<String, String>.from(data['extractedDates'] ?? {}),
      extractedCertifications: Map<String, String>.from(data['extractedCertifications'] ?? {}),
      processedAt: (data['processedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      errorMessage: data['errorMessage'],
    );
  }

  Map<String, dynamic> toMap() => {
    'documentId': documentId,
    'submissionId': submissionId,
    'status': status.name,
    'flags': flags.map((f) => f.toMap()).toList(),
    'confidenceScore': confidenceScore,
    'extractedDates': extractedDates,
    'extractedCertifications': extractedCertifications,
    'processedAt': Timestamp.fromDate(processedAt),
    'errorMessage': errorMessage,
  };

  bool get hasCriticalFlags => flags.any((f) => f.severity == 'critical');
  bool get hasWarnings => flags.any((f) => f.severity == 'warning');
  int get criticalCount => flags.where((f) => f.severity == 'critical').length;
  int get warningCount => flags.where((f) => f.severity == 'warning').length;
}
