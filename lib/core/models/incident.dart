import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_incident.dart';

/// Incident model — mirrors the Firestore `incidents` collection.
///
/// `type`/`severity`/`status` are capitalized display strings ('Injury',
/// 'Minor', 'Open', etc.), not lowercase snake_case — this matches what
/// `incident_report_form.dart` actually writes and every reading screen
/// (`incident_card.dart`, `incidents_register_screen.dart`,
/// `incident_detail_sheet.dart`, `safety_analytics_screen.dart`,
/// dashboard KPIs) already consistently expects and filters on. An earlier
/// draft of this model assumed lowercase snake_case values; normalizing the
/// model to the convention already live everywhere else avoids breaking a
/// working register screen — see F-101 in docs/fixes/FIX_LIST.md.
class Incident extends BaseIncident {
  final String title;
  final String type; // Injury, Near Miss, Property Damage, Environmental, Hazard Observation
  final String? contractorId;
  final String? assigneeId;
  final String? rootCause;
  final String? immediateAction;
  final String? correctiveAction;
  final bool lostTimeInjury;
  final int? daysLost;
  final String? photoUrl;
  final bool isAnonymous;
  final double directCosts;
  final double indirectCosts;
  final double totalCost;
  final Map<String, dynamic>? injuryDetails;
  final Map<String, dynamic>? environmentalDetails;
  final Map<String, dynamic>? propertyDamageDetails;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Incident({
    super.id,
    required super.tenantId,
    required this.title,
    required super.description,
    required this.type,
    super.severity = 'Minor',
    super.status = 'Open',
    super.location,
    super.dateOfIncident,
    super.reporterId,
    super.reporterName,
    this.contractorId,
    this.assigneeId,
    this.rootCause,
    this.immediateAction,
    this.correctiveAction,
    this.lostTimeInjury = false,
    this.daysLost,
    this.photoUrl,
    this.isAnonymous = false,
    this.directCosts = 0,
    this.indirectCosts = 0,
    this.totalCost = 0,
    this.injuryDetails,
    this.environmentalDetails,
    this.propertyDamageDetails,
    this.createdAt,
    this.updatedAt,
  });

  factory Incident.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Incident(
      id: doc.id,
      tenantId: data['tenantId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? 'Near Miss',
      severity: data['severity'] ?? 'Minor',
      status: data['status'] ?? 'Open',
      location: data['location'],
      dateOfIncident: BaseIncident.parseFlexibleDate(data['dateOfIncident']),
      reporterId: data['reportedBy'],
      reporterName: data['reporterName'],
      contractorId: data['contractorId'],
      assigneeId: data['assignedTo'],
      rootCause: data['rootCause'],
      immediateAction: data['immediateAction'],
      correctiveAction: data['correctiveAction'],
      lostTimeInjury: data['lostTimeInjury'] ?? false,
      daysLost: data['daysLost'],
      photoUrl: data['photoUrl'],
      isAnonymous: data['isAnonymous'] ?? false,
      directCosts: (data['directCosts'] as num?)?.toDouble() ?? 0,
      indirectCosts: (data['indirectCosts'] as num?)?.toDouble() ?? 0,
      totalCost: (data['totalCost'] as num?)?.toDouble() ?? 0,
      injuryDetails: data['injuryDetails'] as Map<String, dynamic>?,
      environmentalDetails: data['environmentalDetails'] as Map<String, dynamic>?,
      propertyDamageDetails: data['propertyDamageDetails'] as Map<String, dynamic>?,
      createdAt: BaseIncident.parseFlexibleDate(data['createdAt']),
      updatedAt: BaseIncident.parseFlexibleDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'tenantId': tenantId,
    'title': title,
    'description': description,
    'type': type,
    'severity': severity,
    'status': status,
    'location': location,
    'dateOfIncident': dateOfIncident?.toIso8601String(),
    'reportedBy': reporterId,
    'reporterName': reporterName,
    'contractorId': contractorId,
    'assignedTo': assigneeId,
    'rootCause': rootCause,
    'immediateAction': immediateAction,
    'correctiveAction': correctiveAction,
    'lostTimeInjury': lostTimeInjury,
    'daysLost': daysLost,
    'photoUrl': photoUrl,
    'isAnonymous': isAnonymous,
    'directCosts': directCosts,
    'indirectCosts': indirectCosts,
    'totalCost': totalCost,
    if (injuryDetails != null) 'injuryDetails': injuryDetails,
    if (environmentalDetails != null) 'environmentalDetails': environmentalDetails,
    if (propertyDamageDetails != null) 'propertyDamageDetails': propertyDamageDetails,
    'createdAt': createdAt != null ? createdAt!.toIso8601String() : DateTime.now().toIso8601String(),
    'updatedAt': DateTime.now().toIso8601String(),
  };

  Incident copyWith({
    String? title,
    String? description,
    String? type,
    String? severity,
    String? status,
    String? location,
    DateTime? dateOfIncident,
    String? assigneeId,
    String? rootCause,
    String? immediateAction,
    String? correctiveAction,
    bool? lostTimeInjury,
    int? daysLost,
  }) => Incident(
    id: id,
    tenantId: tenantId,
    title: title ?? this.title,
    description: description ?? this.description,
    type: type ?? this.type,
    severity: severity ?? this.severity,
    status: status ?? this.status,
    location: location ?? this.location,
    dateOfIncident: dateOfIncident ?? this.dateOfIncident,
    reporterId: reporterId,
    reporterName: reporterName,
    contractorId: contractorId,
    assigneeId: assigneeId ?? this.assigneeId,
    rootCause: rootCause ?? this.rootCause,
    immediateAction: immediateAction ?? this.immediateAction,
    correctiveAction: correctiveAction ?? this.correctiveAction,
    lostTimeInjury: lostTimeInjury ?? this.lostTimeInjury,
    daysLost: daysLost ?? this.daysLost,
    photoUrl: photoUrl,
    isAnonymous: isAnonymous,
    directCosts: directCosts,
    indirectCosts: indirectCosts,
    totalCost: totalCost,
    injuryDetails: injuryDetails,
    environmentalDetails: environmentalDetails,
    propertyDamageDetails: propertyDamageDetails,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

/// CAPA (Corrective and Preventive Action)
class CAPA {
  final String? id;
  final String tenantId;
  final String? incidentId;
  final String title;
  final String description;
  final String type; // corrective, preventive
  final String status; // open, in_progress, completed, overdue, closed
  final String priority; // high, medium, low
  final String? assigneeId;
  final DateTime? dueDate;
  final DateTime? completedDate;
  final String? completionNotes;
  final String? creatorId;
  final DateTime? createdAt;

  const CAPA({
    this.id,
    required this.tenantId,
    this.incidentId,
    required this.title,
    required this.description,
    required this.type,
    this.status = 'open',
    this.priority = 'medium',
    this.assigneeId,
    this.dueDate,
    this.completedDate,
    this.completionNotes,
    this.creatorId,
    this.createdAt,
  });

  factory CAPA.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CAPA(
      id: doc.id,
      tenantId: data['tenantId'] ?? '',
      incidentId: data['incidentId'],
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? 'corrective',
      status: data['status'] ?? 'open',
      priority: data['priority'] ?? 'medium',
      assigneeId: data['assignedTo'],
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      completedDate: (data['completedDate'] as Timestamp?)?.toDate(),
      completionNotes: data['completionNotes'],
      creatorId: data['createdBy'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'tenantId': tenantId,
    'incidentId': incidentId,
    'title': title,
    'description': description,
    'type': type,
    'status': status,
    'priority': priority,
    'assigneeId': assigneeId,
    'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
    'completedDate':
        completedDate != null ? Timestamp.fromDate(completedDate!) : null,
    'completionNotes': completionNotes,
    'creatorId': creatorId,
    'createdAt':
        createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
  };
}
