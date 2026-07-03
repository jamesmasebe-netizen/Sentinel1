import 'package:cloud_firestore/cloud_firestore.dart';

/// Incident model — mirrors the Firestore `incidents` collection
class Incident {
  final String? id;
  final String tenantId;
  final String title;
  final String description;
  final String
  type; // injury, near_miss, property_damage, environmental, fire, chemical
  final String severity; // critical, major, moderate, minor, negligible
  final String status; // open, investigating, resolved, closed
  final String? location;
  final String? area;
  final DateTime? dateOfIncident;
  final String? reporterId;
  final String? assigneeId;
  final String? rootCause;
  final String? immediateAction;
  final String? correctiveAction;
  final bool lostTimeInjury;
  final int? daysLost;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Incident({
    this.id,
    required this.tenantId,
    required this.title,
    required this.description,
    required this.type,
    this.severity = 'minor',
    this.status = 'open',
    this.location,
    this.area,
    this.dateOfIncident,
    this.reporterId,
    this.assigneeId,
    this.rootCause,
    this.immediateAction,
    this.correctiveAction,
    this.lostTimeInjury = false,
    this.daysLost,
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
      type: data['type'] ?? 'near_miss',
      severity: data['severity'] ?? 'minor',
      status: data['status'] ?? 'open',
      location: data['location'],
      area: data['area'],
      dateOfIncident: (data['dateOfIncident'] as Timestamp?)?.toDate(),
      reporterId: data['reportedBy'],
      assigneeId: data['assignedTo'],
      rootCause: data['rootCause'],
      immediateAction: data['immediateAction'],
      correctiveAction: data['correctiveAction'],
      lostTimeInjury: data['lostTimeInjury'] ?? false,
      daysLost: data['daysLost'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
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
    'area': area,
    'dateOfIncident':
        dateOfIncident != null ? Timestamp.fromDate(dateOfIncident!) : null,
    'reporterId': reporterId,
    'assigneeId': assigneeId,
    'rootCause': rootCause,
    'immediateAction': immediateAction,
    'correctiveAction': correctiveAction,
    'lostTimeInjury': lostTimeInjury,
    'daysLost': daysLost,
    'createdAt':
        createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  Incident copyWith({
    String? title,
    String? description,
    String? type,
    String? severity,
    String? status,
    String? location,
    String? area,
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
    area: area ?? this.area,
    dateOfIncident: dateOfIncident ?? this.dateOfIncident,
    reporterId: reporterId,
    assigneeId: assigneeId ?? this.assigneeId,
    rootCause: rootCause ?? this.rootCause,
    immediateAction: immediateAction ?? this.immediateAction,
    correctiveAction: correctiveAction ?? this.correctiveAction,
    lostTimeInjury: lostTimeInjury ?? this.lostTimeInjury,
    daysLost: daysLost ?? this.daysLost,
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
