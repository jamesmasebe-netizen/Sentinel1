import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a Project Task displayed on the Gantt Chart.
class ProjectTask {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final double progress; // 0.0 to 1.0
  final String assignedTo; // Employee or Contractor ID
  final String riskLevel; // 'Low', 'Medium', 'High', 'Critical'
  final bool isMilestone;

  // Enhancements
  final String assignedToName;
  final String? assignedToAvatar;
  final DateTime? baselineStart;
  final DateTime? baselineEnd;
  final String parentId; // ID of the parent task/process
  final String taskType; // 'process', 'task', 'subtask'

  ProjectTask({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    this.progress = 0.0,
    this.assignedTo = '',
    this.riskLevel = 'Medium',
    this.isMilestone = false,
    this.assignedToName = '',
    this.assignedToAvatar,
    this.baselineStart,
    this.baselineEnd,
    this.parentId = '',
    this.taskType = 'task',
  });

  ProjectTask copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    double? progress,
    String? assignedTo,
    String? riskLevel,
    bool? isMilestone,
    String? assignedToName,
    String? assignedToAvatar,
    DateTime? baselineStart,
    DateTime? baselineEnd,
    String? parentId,
    String? taskType,
  }) {
    return ProjectTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      progress: progress ?? this.progress,
      assignedTo: assignedTo ?? this.assignedTo,
      riskLevel: riskLevel ?? this.riskLevel,
      isMilestone: isMilestone ?? this.isMilestone,
      assignedToName: assignedToName ?? this.assignedToName,
      assignedToAvatar: assignedToAvatar ?? this.assignedToAvatar,
      baselineStart: baselineStart ?? this.baselineStart,
      baselineEnd: baselineEnd ?? this.baselineEnd,
      parentId: parentId ?? this.parentId,
      taskType: taskType ?? this.taskType,
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
      assignedTo: map['assignedTo'] ?? '',
      riskLevel: map['riskLevel'] ?? 'Medium',
      isMilestone: map['isMilestone'] ?? false,
      assignedToName: map['assignedToName'] ?? '',
      assignedToAvatar: map['assignedToAvatar'],
      baselineStart: (map['baselineStart'] as Timestamp?)?.toDate(),
      baselineEnd: (map['baselineEnd'] as Timestamp?)?.toDate(),
      parentId: map['parentId'] ?? '',
      taskType: map['taskType'] ?? 'task',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'progress': progress,
      'assignedTo': assignedTo,
      'riskLevel': riskLevel,
      'isMilestone': isMilestone,
      'assignedToName': assignedToName,
      'assignedToAvatar': assignedToAvatar,
      'baselineStart':
          baselineStart != null ? Timestamp.fromDate(baselineStart!) : null,
      'baselineEnd':
          baselineEnd != null ? Timestamp.fromDate(baselineEnd!) : null,
      'parentId': parentId,
      'taskType': taskType,
    };
  }
}

/// Represents a Stage in the PRINCE2 methodology for a Project.
class ProjectStage {
  final String id;
  final String
  stageName; // e.g., 'Starting up a Project', 'Initiating a Project'
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
  final String tenantId; // Organization Site ID
  final String propertyId; // Linked Property
  final String name;
  final String description;
  final String category; // 'Maintenance', 'Opex', 'Renovation', 'Emergency'
  final DateTime startDate;
  final DateTime targetEndDate;
  final double budget;
  final double actualSpend;
  final double estimatedCostAtCompletion;

  // Project Lead / Contacts
  final String projectLead;
  final String projectLeadContact;
  final String fallbackContact;
  final String fallbackContactContact;

  // Linked Entities
  final List<String> allocatedEmployeeIds;
  final List<String> allocatedContractorIds;
  final List<String> allocatedAssetIds;

  // Calculated & Aggregated Safety Fields
  final String
  overallRiskLevel; // Auto-calculated based on tasks/NCRs/Safety File
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
    required this.tenantId,
    required this.propertyId,
    required this.name,
    required this.description,
    required this.category,
    required this.startDate,
    required this.targetEndDate,
    this.budget = 0.0,
    this.actualSpend = 0.0,
    this.estimatedCostAtCompletion = 0.0,
    this.projectLead = '',
    this.projectLeadContact = '',
    this.fallbackContact = '',
    this.fallbackContactContact = '',
    this.allocatedEmployeeIds = const [],
    this.allocatedContractorIds = const [],
    this.allocatedAssetIds = const [],
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
    double? actualSpend,
    double? estimatedCostAtCompletion,
    String? projectLead,
    String? projectLeadContact,
    String? fallbackContact,
    String? fallbackContactContact,
    List<String>? allocatedEmployeeIds,
    List<String>? allocatedContractorIds,
    List<String>? allocatedAssetIds,
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
      tenantId: siteId ?? tenantId,
      propertyId: propertyId ?? this.propertyId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      startDate: startDate ?? this.startDate,
      targetEndDate: targetEndDate ?? this.targetEndDate,
      budget: budget ?? this.budget,
      actualSpend: actualSpend ?? this.actualSpend,
      estimatedCostAtCompletion:
          estimatedCostAtCompletion ?? this.estimatedCostAtCompletion,
      projectLead: projectLead ?? this.projectLead,
      projectLeadContact: projectLeadContact ?? this.projectLeadContact,
      fallbackContact: fallbackContact ?? this.fallbackContact,
      fallbackContactContact:
          fallbackContactContact ?? this.fallbackContactContact,
      allocatedEmployeeIds: allocatedEmployeeIds ?? this.allocatedEmployeeIds,
      allocatedContractorIds: allocatedContractorIds ?? this.allocatedContractorIds,
      allocatedAssetIds: allocatedAssetIds ?? this.allocatedAssetIds,
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
    final parsedStages =
        stagesList.asMap().entries.map((entry) {
          return ProjectStage.fromMap(
            entry.value as Map<String, dynamic>,
            'stage_${entry.key}',
          );
        }).toList();

    // Parse Tasks
    final tasksList = (data['tasks'] as List<dynamic>?) ?? [];
    final parsedTasks =
        tasksList.asMap().entries.map((entry) {
          return ProjectTask.fromMap(
            entry.value as Map<String, dynamic>,
            'task_${entry.key}',
          );
        }).toList();

    return Project(
      id: doc.id,
      tenantId: data['siteId'] ?? '',
      propertyId: data['propertyId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'Maintenance',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      targetEndDate:
          (data['targetEndDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      budget: (data['budget'] as num?)?.toDouble() ?? 0.0,
      actualSpend: (data['actualSpend'] as num?)?.toDouble() ?? 0.0,
      estimatedCostAtCompletion:
          (data['estimatedCostAtCompletion'] as num?)?.toDouble() ?? 0.0,
      projectLead: data['projectLead'] ?? '',
      projectLeadContact: data['projectLeadContact'] ?? '',
      fallbackContact: data['fallbackContact'] ?? '',
      fallbackContactContact: data['fallbackContactContact'] ?? '',
      allocatedEmployeeIds: List<String>.from(data['allocatedEmployeeIds'] ?? []),
      allocatedContractorIds: List<String>.from(data['allocatedContractorIds'] ?? []),
      allocatedAssetIds: List<String>.from(data['allocatedAssetIds'] ?? []),
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
      'tenantId': tenantId,
      'propertyId': propertyId,
      'name': name,
      'description': description,
      'category': category,
      'startDate': Timestamp.fromDate(startDate),
      'targetEndDate': Timestamp.fromDate(targetEndDate),
      'budget': budget,
      'actualSpend': actualSpend,
      'estimatedCostAtCompletion': estimatedCostAtCompletion,
      'projectLead': projectLead,
      'projectLeadContact': projectLeadContact,
      'fallbackContact': fallbackContact,
      'fallbackContactContact': fallbackContactContact,
      'allocatedEmployeeIds': allocatedEmployeeIds,
      'allocatedContractorIds': allocatedContractorIds,
      'allocatedAssetIds': allocatedAssetIds,
      'overallRiskLevel': overallRiskLevel,
      'safetyFileScore': safetyFileScore,
      'totalNcrs': totalNcrs,
      'status': status,
      'stages': stages.map((s) => s.toMap()).toList(),
      'tasks': tasks.map((t) => t.toMap()).toList(),
      'createdAt':
          createdAt != null
              ? Timestamp.fromDate(createdAt!)
              : FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    };
  }

  /// Helper to get project progress percentage based on task completion
  double get overallProgress {
    if (tasks.isEmpty) return 0.0;
    final totalProgress = tasks.fold(0.0, (acc, task) => acc + task.progress);
    return totalProgress / tasks.length;
  }

  /// Cost Performance Index (CPI)
  /// CPI > 1.0 means under budget. CPI < 1.0 means over budget.
  double get costPerformanceIndex {
    if (actualSpend == 0.0) return 1.0;
    // Earned Value = budget * overallProgress
    final earnedValue = budget * overallProgress;
    return earnedValue / actualSpend;
  }

  /// Schedule Performance Index (SPI)
  /// SPI > 1.0 means ahead of schedule. SPI < 1.0 means behind schedule.
  double get schedulePerformanceIndex {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 1.0; // Hasn't started
    final totalDuration = targetEndDate.difference(startDate).inDays;
    final elapsedDuration = now.difference(startDate).inDays;
    if (totalDuration <= 0) return 1.0;

    final plannedProgress = (elapsedDuration / totalDuration).clamp(0.0, 1.0);
    if (plannedProgress == 0.0) return 1.0;

    // SPI = Earned Value / Planned Value
    // We can simplify this to: overallProgress / plannedProgress
    return overallProgress / plannedProgress;
  }
}

/// Specialized subset Model for NCRs connected to a Project
class ProjectNCR {
  final String id;
  final String projectId;
  final String tenantId;
  final String description;
  final String severity; // 'Minor', 'Major', 'Critical'
  final String status; // 'Open', 'Resolved'
  final DateTime reportedDate;
  final String? reportedBy;

  ProjectNCR({
    required this.id,
    required this.projectId,
    required this.tenantId,
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
      tenantId: data['siteId'] ?? '',
      description: data['description'] ?? '',
      severity: data['severity'] ?? 'Major',
      status: data['status'] ?? 'Open',
      reportedDate:
          (data['reportedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reportedBy: data['reportedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'projectId': projectId,
      'tenantId': tenantId,
      'description': description,
      'severity': severity,
      'status': status,
      'reportedDate': Timestamp.fromDate(reportedDate),
      'reportedBy': reportedBy,
    };
  }
}

/// Specialized subset Model for Expenses connected to a Project
class ProjectExpense {
  final String id;
  final String projectId;
  final String tenantId;
  final String description;
  final double amount;
  final String category; // 'Labor', 'Materials', 'Subcontractor', 'Other'
  final DateTime loggedAt;
  final String? loggedBy;

  ProjectExpense({
    required this.id,
    required this.projectId,
    required this.tenantId,
    required this.description,
    required this.amount,
    required this.category,
    required this.loggedAt,
    this.loggedBy,
  });

  factory ProjectExpense.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ProjectExpense(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      tenantId: data['siteId'] ?? '',
      description: data['description'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      category: data['category'] ?? 'Other',
      loggedAt: (data['loggedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      loggedBy: data['loggedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'projectId': projectId,
      'tenantId': tenantId,
      'description': description,
      'amount': amount,
      'category': category,
      'loggedAt': Timestamp.fromDate(loggedAt),
      'loggedBy': loggedBy,
    };
  }
}
