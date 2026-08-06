/// A corporate-level strategic risk, stored in the tenant-scoped `strategic_risks` collection
/// (see `StrategicRiskService`).
///
/// `createdAt` is stored as an ISO8601 string — `strategic_risk_form.dart` writes
/// `DateTime.now().toIso8601String()`, not a Firestore `Timestamp` — matching every existing
/// on-disk document.
class StrategicRisk {
  final String id;
  final String title;
  final String description;
  final String category;
  final String owner;
  final String likelihood;
  final String impact;
  final int riskScore;
  final String riskRating;
  final String mitigation;
  final String status;
  final String authorId;
  final String siteId;
  final DateTime createdAt;

  StrategicRisk({
    required this.id,
    required this.title,
    this.description = '',
    this.category = 'Operational',
    this.owner = '',
    this.likelihood = '',
    this.impact = '',
    this.riskScore = 0,
    this.riskRating = 'Low',
    this.mitigation = '',
    this.status = 'Open',
    required this.authorId,
    required this.siteId,
    required this.createdAt,
  });

  factory StrategicRisk.fromFirestore(Map<String, dynamic> json, String id) {
    return StrategicRisk(
      id: id,
      title: json['title'] ?? 'Untitled Risk',
      description: json['description'] ?? '',
      category: json['category'] ?? 'Operational',
      owner: json['owner'] ?? '',
      likelihood: json['likelihood'] ?? '',
      impact: json['impact'] ?? '',
      riskScore: (json['riskScore'] as num?)?.toInt() ?? 0,
      riskRating: json['riskRating'] ?? 'Low',
      mitigation: json['mitigation'] ?? '',
      status: json['status'] ?? 'Open',
      authorId: json['authorId'] ?? '',
      siteId: json['siteId'] ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title': title,
    'description': description,
    'category': category,
    'owner': owner,
    'likelihood': likelihood,
    'impact': impact,
    'riskScore': riskScore,
    'riskRating': riskRating,
    'mitigation': mitigation,
    'status': status,
    'authorId': authorId,
    'siteId': siteId,
    'createdAt': createdAt.toIso8601String(),
  };
}
