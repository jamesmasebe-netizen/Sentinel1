import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a Project Task displayed on the Gantt Chart.
class ProjectTask {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final double progress; // 0.0 to 1.0
  final List<String> dependencies; // IDs of tasks that must finish before this starts
  final String assignedTo; // Employee or Contractor ID
  final String riskLevel; // 'Low', 'Medium', 'High', 'Critical'
  final bool isMilestone;

  ProjectTask({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    this.progress = 0.0,
    this.dependencies = const [],
    this.assignedTo = '',
    this.riskLevel = 'Medium',
    this.isMilestone = false,
  });

  ProjectTask copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    double? progress,
    List<String>? dependencies,
    String? assignedTo,
    String? riskLevel,
    bool? isMilestone,
  }) {
    return ProjectTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      progress: progress ?? this.progress,
      dependencies: dependencies ?? this.dependencies,
      assignedTo: assignedTo ?? this.assignedTo,
      riskLevel: riskLevel ?? this.riskLevel,
      isMilestone: isMilestone ?? this.isMilestone,
    );
  }

  factory ProjectTask.fromMap(Map<String, dynamic> map, String taskId) {
    return ProjectTask(
      id: taskId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      dependencies: List<String>.from(map['dependencies'] ?? []),
      assignedTo: map['assignedTo'] ?? '',
      riskLevel: map['riskLevel'] ?? 'Medium',
      isMilestone: map['isMilestone'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'progress': progress,
      'dependencies': dependencies,
      'assignedTo': assignedTo,
      'riskLevel': riskLevel,
      'isMilestone': isMilestone,
    };
  }
}

/// Represents a Stage in the PRINCE2 methodology for a Project.
class ProjectStage {
  final String id;
  final String stageName; // e.g., 'Starting up a Project', 'Initiating a Project'
  final int order;
  final String status; // 'Pending', 'In Progress', 'Completed', 'Blocked'
  final String? approvedBy; // User ID of the approver
  final DateTime? approvedAt;
  final bool requiresSafetyClearance; // Hard lock for compliance

  ProjectStage({
    required this.id,
    required this.stageName,
    required this.order,
    this.status = 'Pending',
    this.approvedBy,
    this.approvedAt,
    this.requiresSafetyClearance = false,
  });

  factory ProjectStage.fromMap(Map<String, dynamic> map, String stageId) {
    return ProjectStage(
      id: stageId,
      stageName: map['stageName'] ?? '',
      order: map['order'] ?? 0,
      status: map['status'] ?? 'Pending',
      approvedBy: map['approvedBy'],
      approvedAt: (map['approvedAt'] as Timestamp?)?.toDate(),
      requiresSafetyClearance: map['requiresSafetyClearance'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stageName': stageName,
      'order': order,
      'status': status,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'requiresSafetyClearance': requiresSafetyClearance,
    };
  }
}

/// Represents an overarching Project entity integrating operations and SHEQ.
class Project {
  final String id; // Traceable ID like PRJ-2024-0001
  final String siteId; // Organization Site ID
  final String propertyId; // Linked Property
  final String name;
  final String description;
  final String category; // 'Maintenance', 'Opex', 'Renovation', 'Emergency'
  final DateTime startDate;
  final DateTime targetEndDate;
  final double budget;

  // Linked Entities
  final List<String> contractorIds; // Linked Contractors executing the project
  final List<String> riskAssessmentIds; // Linked HIRAs / DRAs

  // Calculated & Aggregated Safety Fields
  final String overallRiskLevel; // Auto-calculated based on tasks/NCRs/Safety File
  final double safetyFileScore; // 0.0 to 100.0, acts as compliance lock
  final int totalNcrs; // Number of Non-Conformance Reports linked

  // Status and Progression
  final String status; // 'Draft', 'Active', 'On Hold', 'Completed'
  final List<ProjectStage> stages;
  final List<ProjectTask> tasks;

  final DateTime? createdAt;
  final String? createdBy;

  Project({
    required this.id,
    required this.siteId,
    required this.propertyId,
    required this.name,
    required this.description,
    required this.category,
    required this.startDate,
    required this.targetEndDate,
    this.budget = 0.0,
    this.contractorIds = const [],
    this.riskAssessmentIds = const [],
    this.overallRiskLevel = 'Medium',
    this.safetyFileScore = 0.0,
    this.totalNcrs = 0,
    this.status = 'Draft',
    this.stages = const [],
    this.tasks = const [],
    this.createdAt,
    this.createdBy,
  });

  Project copyWith({
    String? id,
    String? siteId,
    String? propertyId,
    String? name,
    String? description,
    String? category,
    DateTime? startDate,
    DateTime? targetEndDate,
    double? budget,
    List<String>? contractorIds,
    List<String>? riskAssessmentIds,
    String? overallRiskLevel,
    double? safetyFileScore,
    int? totalNcrs,
    String? status,
    List<ProjectStage>? stages,
    List<ProjectTask>? tasks,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return Project(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      propertyId: propertyId ?? this.propertyId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      startDate: startDate ?? this.startDate,
      targetEndDate: targetEndDate ?? this.targetEndDate,
      budget: budget ?? this.budget,
      contractorIds: contractorIds ?? this.contractorIds,
      riskAssessmentIds: riskAssessmentIds ?? this.riskAssessmentIds,
      overallRiskLevel: overallRiskLevel ?? this.overallRiskLevel,
      safetyFileScore: safetyFileScore ?? this.safetyFileScore,
      totalNcrs: totalNcrs ?? this.totalNcrs,
      status: status ?? this.status,
      stages: stages ?? this.stages,
      tasks: tasks ?? this.tasks,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  factory Project.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Parse Stages
    final stagesList = (data['stages'] as List<dynamic>?) ?? [];
    final parsedStages = stagesList.asMap().entries.map((entry) {
      return ProjectStage.fromMap(entry.value as Map<String, dynamic>, 'stage_${entry.key}');
    }).toList();

    // Parse Tasks
    final tasksList = (data['tasks'] as List<dynamic>?) ?? [];
    final parsedTasks = tasksList.asMap().entries.map((entry) {
      return ProjectTask.fromMap(entry.value as Map<String, dynamic>, 'task_${entry.key}');
    }).toList();

    return Project(
      id: doc.id,
      siteId: data['siteId'] ?? '',
      propertyId: data['propertyId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'Maintenance',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      targetEndDate: (data['targetEndDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      budget: (data['budget'] as num?)?.toDouble() ?? 0.0,
      contractorIds: List<String>.from(data['contractorIds'] ?? []),
      riskAssessmentIds: List<String>.from(data['riskAssessmentIds'] ?? []),
      overallRiskLevel: data['overallRiskLevel'] ?? 'Medium',
      safetyFileScore: (data['safetyFileScore'] as num?)?.toDouble() ?? 0.0,
      totalNcrs: data['totalNcrs'] ?? 0,
      status: data['status'] ?? 'Draft',
      stages: parsedStages,
      tasks: parsedTasks,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'siteId': siteId,
      'propertyId': propertyId,
      'name': name,
      'description': description,
      'category': category,
      'startDate': Timestamp.fromDate(startDate),
      'targetEndDate': Timestamp.fromDate(targetEndDate),
      'budget': budget,
      'contractorIds': contractorIds,
      'riskAssessmentIds': riskAssessmentIds,
      'overallRiskLevel': overallRiskLevel,
      'safetyFileScore': safetyFileScore,
      'totalNcrs': totalNcrs,
      'status': status,
      'stages': stages.map((s) => s.toMap()).toList(),
      'tasks': tasks.map((t) => t.toMap()).toList(),
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    };
  }

  /// Helper to get project progress percentage based on task completion
  double get overallProgress {
    if (tasks.isEmpty) return 0.0;
    final totalProgress = tasks.fold(0.0, (acc, task) => acc + task.progress);
    return totalProgress / tasks.length;
  }
}

/// Specialized subset Model for NCRs connected to a Project
class ProjectNCR {
  final String id;
  final String projectId;
  final String siteId;
  final String description;
  final String severity; // 'Minor', 'Major', 'Critical'
  final String status; // 'Open', 'Resolved'
  final DateTime reportedDate;
  final String? reportedBy;

  ProjectNCR({
    required this.id,
    required this.projectId,
    required this.siteId,
    required this.description,
    required this.severity,
    this.status = 'Open',
    required this.reportedDate,
    this.reportedBy,
  });

  factory ProjectNCR.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ProjectNCR(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      siteId: data['siteId'] ?? '',
      description: data['description'] ?? '',
      severity: data['severity'] ?? 'Major',
      status: data['status'] ?? 'Open',
      reportedDate: (data['reportedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reportedBy: data['reportedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'projectId': projectId,
      'siteId': siteId,
      'description': description,
      'severity': severity,
      'status': status,
      'reportedDate': Timestamp.fromDate(reportedDate),
      'reportedBy': reportedBy,
    };
  }
}
