import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return null;
}

class AmountModel {
  final double value;
  final String currency;

  AmountModel({required this.value, required this.currency});

  factory AmountModel.fromJson(Map<String, dynamic> json) {
    return AmountModel(
      value: (json['value'] ?? json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
    );
  }

  Map<String, dynamic> toJson() {
    return {'value': value, 'currency': currency};
  }
}

class BudgetModel {
  final double totalBudgetAmount;
  final String currency;
  final double consumedBudget;

  BudgetModel({
    required this.totalBudgetAmount,
    required this.currency,
    required this.consumedBudget,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      totalBudgetAmount: (json['totalBudgetAmount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
      consumedBudget: (json['consumedBudget'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalBudgetAmount': totalBudgetAmount,
      'currency': currency,
      'consumedBudget': consumedBudget,
    };
  }
}

class EffortModel {
  final double estimatedHours;
  final double actualHours;
  final double remainingHours;

  EffortModel({
    required this.estimatedHours,
    required this.actualHours,
    required this.remainingHours,
  });

  factory EffortModel.fromJson(Map<String, dynamic> json) {
    return EffortModel(
      estimatedHours: (json['estimatedHours'] ?? 0).toDouble(),
      actualHours: (json['actualHours'] ?? 0).toDouble(),
      remainingHours: (json['remainingHours'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'estimatedHours': estimatedHours,
      'actualHours': actualHours,
      'remainingHours': remainingHours,
    };
  }
}

class Project {
  final String projectId;
  final String clientId;
  final String contractId;
  final String name;
  final String description;
  final String status;
  final String projectManagerId;
  final DateTime? startDate;
  final DateTime? endDate;
  final BudgetModel? budget;
  final String revenueRecognitionMethod;
  final List<String> allocatedEmployeeIds;
  final List<String> allocatedContractorIds;
  final List<String> allocatedAssetIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Project({
    required this.projectId,
    required this.clientId,
    required this.contractId,
    required this.name,
    required this.description,
    required this.status,
    required this.projectManagerId,
    this.startDate,
    this.endDate,
    this.budget,
    required this.revenueRecognitionMethod,
    this.allocatedEmployeeIds = const [],
    this.allocatedContractorIds = const [],
    this.allocatedAssetIds = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Project.fromJson(Map<String, dynamic> json, String id) {
    return Project(
      projectId: id,
      clientId: json['clientId'] ?? '',
      contractId: json['contractId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'Draft',
      projectManagerId: json['projectManagerId'] ?? '',
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      budget:
          json['budget'] != null
              ? BudgetModel.fromJson(Map<String, dynamic>.from(json['budget']))
              : null,
      revenueRecognitionMethod: json['revenueRecognitionMethod'] ?? '',
      allocatedEmployeeIds: List<String>.from(json['allocatedEmployeeIds'] ?? []),
      allocatedContractorIds: List<String>.from(json['allocatedContractorIds'] ?? []),
      allocatedAssetIds: List<String>.from(json['allocatedAssetIds'] ?? []),
      createdAt: _parseDate(json['timestamps']?['createdAt']),
      updatedAt: _parseDate(json['timestamps']?['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'contractId': contractId,
      'name': name,
      'description': description,
      'status': status,
      'projectManagerId': projectManagerId,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'budget': budget?.toJson(),
      'revenueRecognitionMethod': revenueRecognitionMethod,
      'allocatedEmployeeIds': allocatedEmployeeIds,
      'allocatedContractorIds': allocatedContractorIds,
      'allocatedAssetIds': allocatedAssetIds,
      'timestamps': {
        'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      },
    };
  }
}

class WbsTask {
  final String taskId;
  final String? parentTaskId;
  final String name;
  final String description;
  final String taskType;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final EffortModel? effort;
  final double percentComplete;
  final List<String> assignedResourceIds;
  final List<String> dependencies;
  final bool isBillable;

  WbsTask({
    required this.taskId,
    this.parentTaskId,
    required this.name,
    required this.description,
    required this.taskType,
    required this.status,
    this.startDate,
    this.endDate,
    this.effort,
    required this.percentComplete,
    required this.assignedResourceIds,
    required this.dependencies,
    required this.isBillable,
  });

  factory WbsTask.fromJson(Map<String, dynamic> json, String id) {
    return WbsTask(
      taskId: id,
      parentTaskId: json['parentTaskId'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      taskType: json['taskType'] ?? 'Task',
      status: json['status'] ?? 'NotStarted',
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      effort:
          json['effort'] != null
              ? EffortModel.fromJson(Map<String, dynamic>.from(json['effort']))
              : null,
      percentComplete: (json['percentComplete'] ?? 0).toDouble(),
      assignedResourceIds: List<String>.from(json['assignedResourceIds'] ?? []),
      dependencies: List<String>.from(json['dependencies'] ?? []),
      isBillable: json['isBillable'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parentTaskId': parentTaskId,
      'name': name,
      'description': description,
      'taskType': taskType,
      'status': status,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'effort': effort?.toJson(),
      'percentComplete': percentComplete,
      'assignedResourceIds': assignedResourceIds,
      'dependencies': dependencies,
      'isBillable': isBillable,
    };
  }
}

class TimeEntry {
  final String entryId;
  final String resourceId;
  final String projectId;
  final String taskId;
  final DateTime? date;
  final double hours;
  final String description;
  final bool isBillable;
  final String billingStatus;
  final String approvalStatus;
  final String? approverId;
  final String? rejectionReason;
  final String? invoiceId;

  TimeEntry({
    required this.entryId,
    required this.resourceId,
    required this.projectId,
    required this.taskId,
    this.date,
    required this.hours,
    required this.description,
    required this.isBillable,
    required this.billingStatus,
    required this.approvalStatus,
    this.approverId,
    this.rejectionReason,
    this.invoiceId,
  });

  factory TimeEntry.fromJson(Map<String, dynamic> json, String id) {
    return TimeEntry(
      entryId: id,
      resourceId: json['resourceId'] ?? '',
      projectId: json['projectId'] ?? '',
      taskId: json['taskId'] ?? '',
      date: _parseDate(json['date']),
      hours: (json['hours'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      isBillable: json['isBillable'] ?? true,
      billingStatus: json['billingStatus'] ?? 'Unbilled',
      approvalStatus: json['approvalStatus'] ?? 'Draft',
      approverId: json['approverId'],
      rejectionReason: json['rejectionReason'],
      invoiceId: json['invoiceId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'resourceId': resourceId,
      'projectId': projectId,
      'taskId': taskId,
      'date': date != null ? Timestamp.fromDate(date!) : null,
      'hours': hours,
      'description': description,
      'isBillable': isBillable,
      'billingStatus': billingStatus,
      'approvalStatus': approvalStatus,
      'approverId': approverId,
      'rejectionReason': rejectionReason,
      'invoiceId': invoiceId,
    };
  }
}

class Expense {
  final String expenseId;
  final String resourceId;
  final String projectId;
  final String? taskId;
  final String category;
  final DateTime? incurredDate;
  final AmountModel? amount;
  final String? receiptUrl;
  final bool isBillable;
  final String approvalStatus;
  final String reimbursementStatus;
  final String billingStatus;
  final String? invoiceId;

  Expense({
    required this.expenseId,
    required this.resourceId,
    required this.projectId,
    this.taskId,
    required this.category,
    this.incurredDate,
    this.amount,
    this.receiptUrl,
    required this.isBillable,
    required this.approvalStatus,
    required this.reimbursementStatus,
    required this.billingStatus,
    this.invoiceId,
  });

  factory Expense.fromJson(Map<String, dynamic> json, String id) {
    return Expense(
      expenseId: id,
      resourceId: json['resourceId'] ?? '',
      projectId: json['projectId'] ?? '',
      taskId: json['taskId'],
      category: json['category'] ?? '',
      incurredDate: _parseDate(json['incurredDate']),
      amount:
          json['amount'] != null
              ? AmountModel.fromJson(Map<String, dynamic>.from(json['amount']))
              : null,
      receiptUrl: json['receiptUrl'],
      isBillable: json['isBillable'] ?? true,
      approvalStatus: json['approvalStatus'] ?? 'Draft',
      reimbursementStatus: json['reimbursementStatus'] ?? 'Pending',
      billingStatus: json['billingStatus'] ?? 'Unbilled',
      invoiceId: json['invoiceId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'resourceId': resourceId,
      'projectId': projectId,
      'taskId': taskId,
      'category': category,
      'incurredDate':
          incurredDate != null ? Timestamp.fromDate(incurredDate!) : null,
      'amount': amount?.toJson(),
      'receiptUrl': receiptUrl,
      'isBillable': isBillable,
      'approvalStatus': approvalStatus,
      'reimbursementStatus': reimbursementStatus,
      'billingStatus': billingStatus,
      'invoiceId': invoiceId,
    };
  }
}

class Actual {
  final String actualId;
  final String projectId;
  final String transactionClass;
  final String transactionType;
  final DateTime? documentDate;
  final AmountModel? amount;
  final double quantity;
  final AmountModel? unitPrice;
  final String? resourceId;
  final String? taskId;
  final String sourceDocumentType;
  final String sourceDocumentId;
  final String billingStatus;

  Actual({
    required this.actualId,
    required this.projectId,
    required this.transactionClass,
    required this.transactionType,
    this.documentDate,
    this.amount,
    required this.quantity,
    this.unitPrice,
    this.resourceId,
    this.taskId,
    required this.sourceDocumentType,
    required this.sourceDocumentId,
    required this.billingStatus,
  });

  factory Actual.fromJson(Map<String, dynamic> json, String id) {
    return Actual(
      actualId: id,
      projectId: json['projectId'] ?? '',
      transactionClass: json['transactionClass'] ?? '',
      transactionType: json['transactionType'] ?? '',
      documentDate: _parseDate(json['documentDate']),
      amount:
          json['amount'] != null
              ? AmountModel.fromJson(Map<String, dynamic>.from(json['amount']))
              : null,
      quantity: (json['quantity'] ?? 0).toDouble(),
      unitPrice:
          json['unitPrice'] != null
              ? AmountModel.fromJson(
                Map<String, dynamic>.from(json['unitPrice']),
              )
              : null,
      resourceId: json['resourceId'],
      taskId: json['taskId'],
      sourceDocumentType: json['sourceDocumentType'] ?? '',
      sourceDocumentId: json['sourceDocumentId'] ?? '',
      billingStatus: json['billingStatus'] ?? 'ReadyToInvoice',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'transactionClass': transactionClass,
      'transactionType': transactionType,
      'documentDate':
          documentDate != null ? Timestamp.fromDate(documentDate!) : null,
      'amount': amount?.toJson(),
      'quantity': quantity,
      'unitPrice': unitPrice?.toJson(),
      'resourceId': resourceId,
      'taskId': taskId,
      'sourceDocumentType': sourceDocumentType,
      'sourceDocumentId': sourceDocumentId,
      'billingStatus': billingStatus,
    };
  }
}
