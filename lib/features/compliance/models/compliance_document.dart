/// A registered compliance document (licence, certificate, permit, policy, etc).
///
/// Dates are stored as ISO8601 strings, not Firestore `Timestamp`s — matching the shape every
/// existing `compliance_docs` document already has on disk (see `ComplianceService`) and the
/// range-query in `streamExpiringDocuments()`, which compares against a string bound.
class ComplianceDocument {
  final String id;
  final String title;
  final String referenceNumber;
  final String documentType;
  final String status;
  final String? ownerId;
  final DateTime expiryDate;
  final DateTime reviewDate;
  final String authorId;
  final String siteId;
  final DateTime createdAt;

  ComplianceDocument({
    required this.id,
    required this.title,
    this.referenceNumber = '',
    required this.documentType,
    required this.status,
    this.ownerId,
    required this.expiryDate,
    required this.reviewDate,
    required this.authorId,
    required this.siteId,
    required this.createdAt,
  });

  factory ComplianceDocument.fromFirestore(Map<String, dynamic> json, String id) {
    return ComplianceDocument(
      id: id,
      title: json['title'] ?? 'Untitled Doc',
      referenceNumber: json['referenceNumber'] ?? '',
      documentType: json['documentType'] ?? '',
      status: json['status'] ?? '',
      ownerId: json['ownerId'],
      expiryDate: DateTime.tryParse(json['expiryDate']?.toString() ?? '') ?? DateTime.now(),
      reviewDate: DateTime.tryParse(json['reviewDate']?.toString() ?? '') ?? DateTime.now(),
      authorId: json['authorId'] ?? '',
      siteId: json['siteId'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'referenceNumber': referenceNumber,
      'documentType': documentType,
      'status': status,
      if (ownerId != null) 'ownerId': ownerId,
      'expiryDate': expiryDate.toIso8601String(),
      'reviewDate': reviewDate.toIso8601String(),
      'authorId': authorId,
      'siteId': siteId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
