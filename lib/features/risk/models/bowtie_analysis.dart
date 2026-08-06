/// A Bow-Tie threat/barrier/consequence analysis, stored in the tenant-scoped
/// `bowtie_analyses` collection (see `BowtieService`).
///
/// `createdAt` is stored as an ISO8601 string — `bowtie_form.dart` writes
/// `DateTime.now().toIso8601String()`, not a Firestore `Timestamp` — matching every existing
/// on-disk document.
class BowtieAnalysis {
  final String id;
  final String title;
  final String topEvent;
  final String threats;
  final String consequences;
  final String preventiveBarriers;
  final String mitigationBarriers;
  final String status;
  final String authorId;
  final String siteId;
  final DateTime createdAt;

  BowtieAnalysis({
    required this.id,
    required this.title,
    required this.topEvent,
    this.threats = '',
    this.consequences = '',
    this.preventiveBarriers = '',
    this.mitigationBarriers = '',
    this.status = 'Draft',
    required this.authorId,
    required this.siteId,
    required this.createdAt,
  });

  factory BowtieAnalysis.fromFirestore(Map<String, dynamic> json, String id) {
    return BowtieAnalysis(
      id: id,
      title: json['title'] ?? 'Untitled Analysis',
      topEvent: json['topEvent'] ?? '',
      threats: json['threats'] ?? '',
      consequences: json['consequences'] ?? '',
      preventiveBarriers: json['preventiveBarriers'] ?? '',
      mitigationBarriers: json['mitigationBarriers'] ?? '',
      status: json['status'] ?? 'Draft',
      authorId: json['authorId'] ?? '',
      siteId: json['siteId'] ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title': title,
    'topEvent': topEvent,
    'threats': threats,
    'consequences': consequences,
    'preventiveBarriers': preventiveBarriers,
    'mitigationBarriers': mitigationBarriers,
    'status': status,
    'authorId': authorId,
    'siteId': siteId,
    'createdAt': createdAt.toIso8601String(),
  };
}
