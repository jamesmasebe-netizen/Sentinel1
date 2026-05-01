import 'package:cloud_firestore/cloud_firestore.dart';

/// Incident model — mirrors the Firestore `incidents` collection
class Incident {
  final String? id;
  final String siteId;
  final String title;
  final String description;
  final String type; // injury, near_miss, property_damage, environmental, fire, chemical
  final String severity; // critical, major, moderate, minor, negligible
  final String status; // open, investigating, resolved, closed
  final String? location;
  final String? area;
  final DateTime? dateOfIncident;
  final String? reportedBy;
  final String? reportedByName;
  final String? assignedTo;
  final String? assignedToName;
  final List<String> attachments;
  final List<String> witnesses;
  final String? rootCause;
  final String? immediateAction;
  final String? correctiveAction;
  final bool lostTimeInjury;
  final int? daysLost;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Incident({
    this.id,
    required this.siteId,
    required this.title,
    required this.description,
    required this.type,
    this.severity = 'minor',
    this.status = 'open',
    this.location,
    this.area,
    this.dateOfIncident,
    this.reportedBy,
    this.reportedByName,
    this.assignedTo,
    this.assignedToName,
    this.attachments = const [],
    this.witnesses = const [],
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
      siteId: data['siteId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? 'near_miss',
      severity: data['severity'] ?? 'minor',
      status: data['status'] ?? 'open',
      location: data['location'],
      area: data['area'],
      dateOfIncident: (data['dateOfIncident'] as Timestamp?)?.toDate(),
      reportedBy: data['reportedBy'],
      reportedByName: data['reportedByName'],
      assignedTo: data['assignedTo'],
      assignedToName: data['assignedToName'],
      attachments: List<String>.from(data['attachments'] ?? []),
      witnesses: List<String>.from(data['witnesses'] ?? []),
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
    'siteId': siteId,
    'title': title,
    'description': description,
    'type': type,
    'severity': severity,
    'status': status,
    'location': location,
    'area': area,
    'dateOfIncident': dateOfIncident != null ? Timestamp.fromDate(dateOfIncident!) : null,
    'reportedBy': reportedBy,
    'reportedByName': reportedByName,
    'assignedTo': assignedTo,
    'assignedToName': assignedToName,
    'attachments': attachments,
    'witnesses': witnesses,
    'rootCause': rootCause,
    'immediateAction': immediateAction,
    'correctiveAction': correctiveAction,
    'lostTimeInjury': lostTimeInjury,
    'daysLost': daysLost,
    'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
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
    String? assignedTo,
    String? assignedToName,
    List<String>? attachments,
    List<String>? witnesses,
    String? rootCause,
    String? immediateAction,
    String? correctiveAction,
    bool? lostTimeInjury,
    int? daysLost,
  }) => Incident(
    id: id,
    siteId: siteId,
    title: title ?? this.title,
    description: description ?? this.description,
    type: type ?? this.type,
    severity: severity ?? this.severity,
    status: status ?? this.status,
    location: location ?? this.location,
    area: area ?? this.area,
    dateOfIncident: dateOfIncident ?? this.dateOfIncident,
    reportedBy: reportedBy,
    reportedByName: reportedByName,
    assignedTo: assignedTo ?? this.assignedTo,
    assignedToName: assignedToName ?? this.assignedToName,
    attachments: attachments ?? this.attachments,
    witnesses: witnesses ?? this.witnesses,
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
  final String siteId;
  final String? incidentId;
  final String title;
  final String description;
  final String type; // corrective, preventive
  final String status; // open, in_progress, completed, overdue, closed
  final String priority; // high, medium, low
  final String? assignedTo;
  final String? assignedToName;
  final DateTime? dueDate;
  final DateTime? completedDate;
  final String? completionNotes;
  final String? createdBy;
  final DateTime? createdAt;

  const CAPA({
    this.id,
    required this.siteId,
    this.incidentId,
    required this.title,
    required this.description,
    required this.type,
    this.status = 'open',
    this.priority = 'medium',
    this.assignedTo,
    this.assignedToName,
    this.dueDate,
    this.completedDate,
    this.completionNotes,
    this.createdBy,
    this.createdAt,
  });

  factory CAPA.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CAPA(
      id: doc.id,
      siteId: data['siteId'] ?? '',
      incidentId: data['incidentId'],
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? 'corrective',
      status: data['status'] ?? 'open',
      priority: data['priority'] ?? 'medium',
      assignedTo: data['assignedTo'],
      assignedToName: data['assignedToName'],
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      completedDate: (data['completedDate'] as Timestamp?)?.toDate(),
      completionNotes: data['completionNotes'],
      createdBy: data['createdBy'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'siteId': siteId,
    'incidentId': incidentId,
    'title': title,
    'description': description,
    'type': type,
    'status': status,
    'priority': priority,
    'assignedTo': assignedTo,
    'assignedToName': assignedToName,
    'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
    'completedDate': completedDate != null ? Timestamp.fromDate(completedDate!) : null,
    'completionNotes': completionNotes,
    'createdBy': createdBy,
    'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
  };
}
