import 'package:cloud_firestore/cloud_firestore.dart';

/// Dynamic Risk Assessment (DRA) — on-the-spot task risk evaluation, stored in the tenant-scoped
/// `dynamic_risk_assessments` collection (see `DraService`).
///
/// `taskDescription`/`location`/`task` are the canonical fields `dra_card.dart` and
/// `risk_command_center_screen.dart` actually read; `activity`/`area` are legacy duplicate keys
/// `dra_form.dart` still dual-writes per `docs/fixes/FIX_LIST.md` F-306's fix (`toFirestore()`
/// preserves that dual-write exactly — not cleaned up here). `fromFirestore` falls back to the
/// legacy keys so an older, pre-F-306 document still parses correctly instead of showing blank.
///
/// `reviewDate` is an ISO8601 string; `createdAt` is a real Firestore `Timestamp`
/// (`FieldValue.serverTimestamp()`). `status == 'Approved'` (and the derived [approved] getter)
/// reflects real on-disk data: no write path anywhere in this app ever sets `status` to
/// `'Approved'` today — a known, unresolved F-306 gap, preserved as-is rather than fixed as part
/// of this extraction.
class DynamicRiskAssessment {
  final String? id;
  final String siteId;
  final String type;
  final String title;
  final String description;
  final String taskDescription;
  final String location;
  final String likelihood;
  final String severity;
  final String? riskLevel;
  final String status;
  final List<String> hazardsIdentified;
  final List<String> controlsApplied;
  final List<String> teamMembers;
  final String? approverId;
  final DateTime? reviewDate;
  final bool isSafeToProceed;
  final String? assessedBy;
  final String? authorName;
  final DateTime? createdAt;

  const DynamicRiskAssessment({
    this.id,
    required this.siteId,
    this.type = 'dra',
    required this.title,
    this.description = '',
    required this.taskDescription,
    this.location = '',
    this.likelihood = '',
    this.severity = '',
    this.riskLevel,
    this.status = 'Pending',
    this.hazardsIdentified = const [],
    this.controlsApplied = const [],
    this.teamMembers = const [],
    this.approverId,
    this.reviewDate,
    this.isSafeToProceed = false,
    this.assessedBy,
    this.authorName,
    this.createdAt,
  });

  /// No write path sets `status` to `'Approved'` anywhere in this app today (F-306, unresolved)
  /// — always `false` against real data. Modeled rather than hidden, so callers see reality.
  bool get approved => status == 'Approved';

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  factory DynamicRiskAssessment.fromFirestore(
    Map<String, dynamic> json,
    String id,
  ) {
    return DynamicRiskAssessment(
      id: id,
      siteId: json['siteId'] ?? '',
      type: json['type'] ?? 'dra',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      taskDescription:
          json['taskDescription'] ?? json['task'] ?? json['activity'] ?? '',
      location: json['location'] ?? json['area'] ?? '',
      likelihood: json['likelihood'] ?? '',
      severity: json['severity'] ?? '',
      riskLevel: json['riskLevel'],
      status: json['status'] ?? 'Pending',
      hazardsIdentified: List<String>.from(json['hazardsIdentified'] ?? []),
      controlsApplied: List<String>.from(json['controlsApplied'] ?? []),
      teamMembers: List<String>.from(json['teamMembers'] ?? []),
      approverId: json['approverId'],
      reviewDate: _parseDate(json['reviewDate']),
      isSafeToProceed: json['isSafeToProceed'] == true,
      assessedBy: json['assessedBy'],
      authorName: json['authorName'],
      createdAt: _parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'type': type,
    'title': title,
    'description': description,
    // activity/area are legacy duplicate keys — see class doc comment / FIX_LIST.md F-306.
    'activity': taskDescription,
    'area': location,
    'taskDescription': taskDescription,
    'location': location,
    'task': taskDescription,
    'likelihood': likelihood,
    'severity': severity,
    'riskLevel': riskLevel,
    'status': status,
    'hazardsIdentified': hazardsIdentified,
    'controlsApplied': controlsApplied,
    'teamMembers': teamMembers,
    'approverId': approverId,
    'reviewDate': reviewDate?.toIso8601String(),
    'isSafeToProceed': isSafeToProceed,
    'assessedBy': assessedBy,
    'authorName': authorName,
    'siteId': siteId,
    'createdAt':
        createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
  };
}
