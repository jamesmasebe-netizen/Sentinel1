import 'package:cloud_firestore/cloud_firestore.dart';

/// Canonical WorkOrder.status values — see docs/schema_field_service.md.
const kWorkOrderStatuses = [
  'DRAFT',
  'SCHEDULED',
  'DISPATCHED',
  'TRAVELING',
  'IN_PROGRESS',
  'ON_HOLD',
  'COMPLETED',
  'CANCELED',
];

/// Canonical WorkOrder.priority values — see docs/schema_field_service.md.
const kWorkOrderPriorities = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];

class WorkOrder {
  final String id;
  final String workOrderNumber;
  final String status;
  final String? substatusId;
  final String priority;
  final String? incidentTypeId;
  final String? serviceTypeId;
  final String customerId;
  final String? billingAccountId;
  final String? agreementId;
  final String? assetId;
  final GeoPoint? location;
  final Map<String, dynamic>? address;
  final Map<String, dynamic>? scheduling;
  final String? assignedTechnicianId;
  final String? dispatcherId;
  final String? territoryId;
  final String? description;
  final String? resolutionNotes;
  final Map<String, dynamic>? safetyRequirements;
  final Map<String, dynamic>? iotContext;
  final Map<String, dynamic>? financials;
  final bool isMobileOfflineSynced;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WorkOrder({
    required this.id,
    required this.workOrderNumber,
    required this.status,
    this.substatusId,
    required this.priority,
    this.incidentTypeId,
    this.serviceTypeId,
    required this.customerId,
    this.billingAccountId,
    this.agreementId,
    this.assetId,
    this.location,
    this.address,
    this.scheduling,
    this.assignedTechnicianId,
    this.dispatcherId,
    this.territoryId,
    this.description,
    this.resolutionNotes,
    this.safetyRequirements,
    this.iotContext,
    this.financials,
    this.isMobileOfflineSynced = false,
    this.createdAt,
    this.updatedAt,
  });

  factory WorkOrder.fromJson(Map<String, dynamic> json, String documentId) {
    return WorkOrder(
      id: documentId,
      workOrderNumber: json['work_order_number'] ?? '',
      status: json['status'] ?? 'DRAFT',
      substatusId: json['substatus_id'],
      priority: json['priority'] ?? 'LOW',
      incidentTypeId: json['incident_type_id'],
      serviceTypeId: json['service_type_id'],
      customerId: json['customer_id'] ?? '',
      billingAccountId: json['billing_account_id'],
      agreementId: json['agreement_id'],
      assetId: json['asset_id'],
      location: json['location'],
      address: json['address'],
      scheduling: json['scheduling'],
      assignedTechnicianId: json['assigned_technician_id'],
      dispatcherId: json['dispatcher_id'],
      territoryId: json['territory_id'],
      description: json['description'],
      resolutionNotes: json['resolution_notes'],
      safetyRequirements: json['safety_requirements'],
      iotContext: json['iot_context'],
      financials: json['financials'],
      isMobileOfflineSynced: json['is_mobile_offline_synced'] ?? false,
      createdAt: (json['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (json['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'work_order_number': workOrderNumber,
      'status': status,
      if (substatusId != null) 'substatus_id': substatusId,
      'priority': priority,
      if (incidentTypeId != null) 'incident_type_id': incidentTypeId,
      if (serviceTypeId != null) 'service_type_id': serviceTypeId,
      'customer_id': customerId,
      if (billingAccountId != null) 'billing_account_id': billingAccountId,
      if (agreementId != null) 'agreement_id': agreementId,
      if (assetId != null) 'asset_id': assetId,
      if (location != null) 'location': location,
      if (address != null) 'address': address,
      if (scheduling != null) 'scheduling': scheduling,
      if (assignedTechnicianId != null)
        'assigned_technician_id': assignedTechnicianId,
      if (dispatcherId != null) 'dispatcher_id': dispatcherId,
      if (territoryId != null) 'territory_id': territoryId,
      if (description != null) 'description': description,
      if (resolutionNotes != null) 'resolution_notes': resolutionNotes,
      if (safetyRequirements != null) 'safety_requirements': safetyRequirements,
      if (iotContext != null) 'iot_context': iotContext,
      if (financials != null) 'financials': financials,
      'is_mobile_offline_synced': isMobileOfflineSynced,
      if (createdAt != null) 'created_at': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updated_at': Timestamp.fromDate(updatedAt!),
    };
  }
}

class WorkOrderTask {
  final String id;
  final String taskName;
  final String? description;
  final String? inspectionTemplateId;
  final bool isMandatory;
  final int? estimatedDurationMins;
  final int? actualDurationMins;
  final double? percentComplete;
  final String status;
  final DateTime? completedAt;
  final String? completedBy;
  final int sequenceOrder;

  WorkOrderTask({
    required this.id,
    required this.taskName,
    this.description,
    this.inspectionTemplateId,
    this.isMandatory = false,
    this.estimatedDurationMins,
    this.actualDurationMins,
    this.percentComplete,
    required this.status,
    this.completedAt,
    this.completedBy,
    required this.sequenceOrder,
  });

  factory WorkOrderTask.fromJson(Map<String, dynamic> json, String documentId) {
    return WorkOrderTask(
      id: documentId,
      taskName: json['task_name'] ?? '',
      description: json['description'],
      inspectionTemplateId: json['inspection_template_id'],
      isMandatory: json['is_mandatory'] ?? false,
      estimatedDurationMins: json['estimated_duration_mins']?.toInt(),
      actualDurationMins: json['actual_duration_mins']?.toInt(),
      percentComplete: json['percent_complete']?.toDouble(),
      status: json['status'] ?? 'PENDING',
      completedAt: (json['completed_at'] as Timestamp?)?.toDate(),
      completedBy: json['completed_by'],
      sequenceOrder: json['sequence_order']?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'task_name': taskName,
      if (description != null) 'description': description,
      if (inspectionTemplateId != null)
        'inspection_template_id': inspectionTemplateId,
      'is_mandatory': isMandatory,
      if (estimatedDurationMins != null)
        'estimated_duration_mins': estimatedDurationMins,
      if (actualDurationMins != null)
        'actual_duration_mins': actualDurationMins,
      if (percentComplete != null) 'percent_complete': percentComplete,
      'status': status,
      if (completedAt != null) 'completed_at': Timestamp.fromDate(completedAt!),
      if (completedBy != null) 'completed_by': completedBy,
      'sequence_order': sequenceOrder,
    };
  }
}

class DispatcherRoute {
  final String id;
  final String technicianId;
  final DateTime? date;
  final String status;
  final GeoPoint? startLocation;
  final GeoPoint? endLocation;
  final Map<String, dynamic>? metrics;
  final String? generatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DispatcherRoute({
    required this.id,
    required this.technicianId,
    this.date,
    required this.status,
    this.startLocation,
    this.endLocation,
    this.metrics,
    this.generatedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory DispatcherRoute.fromJson(
    Map<String, dynamic> json,
    String documentId,
  ) {
    return DispatcherRoute(
      id: documentId,
      technicianId: json['technician_id'] ?? '',
      date: (json['date'] as Timestamp?)?.toDate(),
      status: json['status'] ?? 'DRAFT',
      startLocation: json['start_location'],
      endLocation: json['end_location'],
      metrics: json['metrics'],
      generatedBy: json['generated_by'],
      createdAt: (json['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (json['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'technician_id': technicianId,
      if (date != null) 'date': Timestamp.fromDate(date!),
      'status': status,
      if (startLocation != null) 'start_location': startLocation,
      if (endLocation != null) 'end_location': endLocation,
      if (metrics != null) 'metrics': metrics,
      if (generatedBy != null) 'generated_by': generatedBy,
      if (createdAt != null) 'created_at': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updated_at': Timestamp.fromDate(updatedAt!),
    };
  }
}

class CustomerAsset {
  final String id;
  final String assetName;
  final String? categoryId;
  final String customerId;
  final String? parentAssetId;
  final String status;
  final DateTime? installationDate;
  final DateTime? warrantyStartDate;
  final DateTime? warrantyEndDate;
  final GeoPoint? location;
  final String? iotDeviceId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? parentId;
  final DateTime? lastTelemetryDate;

  CustomerAsset({
    required this.id,
    required this.assetName,
    this.categoryId,
    required this.customerId,
    this.parentAssetId,
    required this.status,
    this.installationDate,
    this.warrantyStartDate,
    this.warrantyEndDate,
    this.location,
    this.iotDeviceId,
    this.createdAt,
    this.updatedAt,
    this.parentId,
    this.lastTelemetryDate,
  });

  factory CustomerAsset.fromJson(Map<String, dynamic> json, String documentId) {
    return CustomerAsset(
      id: documentId,
      assetName: json['asset_name'] ?? '',
      categoryId: json['category_id'],
      customerId: json['customer_id'] ?? '',
      parentAssetId: json['parent_asset_id'],
      status: json['status'] ?? 'ACTIVE',
      installationDate: (json['installation_date'] as Timestamp?)?.toDate(),
      warrantyStartDate: (json['warranty_start_date'] as Timestamp?)?.toDate(),
      warrantyEndDate: (json['warranty_end_date'] as Timestamp?)?.toDate(),
      location: json['location'],
      iotDeviceId: json['iot_device_id'],
      createdAt: (json['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (json['updated_at'] as Timestamp?)?.toDate(),
      parentId: json['parent_id'],
      lastTelemetryDate: (json['last_telemetry_date'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'asset_name': assetName,
      if (categoryId != null) 'category_id': categoryId,
      'customer_id': customerId,
      if (parentAssetId != null) 'parent_asset_id': parentAssetId,
      'status': status,
      if (installationDate != null)
        'installation_date': Timestamp.fromDate(installationDate!),
      if (warrantyStartDate != null)
        'warranty_start_date': Timestamp.fromDate(warrantyStartDate!),
      if (warrantyEndDate != null)
        'warranty_end_date': Timestamp.fromDate(warrantyEndDate!),
      if (location != null) 'location': location,
      if (iotDeviceId != null) 'iot_device_id': iotDeviceId,
      if (createdAt != null) 'created_at': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updated_at': Timestamp.fromDate(updatedAt!),
      if (parentId != null) 'parent_id': parentId,
      if (lastTelemetryDate != null)
        'last_telemetry_date': Timestamp.fromDate(lastTelemetryDate!),
    };
  }
}

class IotDevice {
  final String id;
  final String? assetId;
  final String? customerId;
  final String deviceType;
  final String? providerInstanceId;
  final GeoPoint? location;
  final String status;
  final DateTime? lastPingAt;
  final String? firmwareVersion;
  final Map<String, dynamic>? telemetryThresholds;

  IotDevice({
    required this.id,
    this.assetId,
    this.customerId,
    required this.deviceType,
    this.providerInstanceId,
    this.location,
    required this.status,
    this.lastPingAt,
    this.firmwareVersion,
    this.telemetryThresholds,
  });

  factory IotDevice.fromJson(Map<String, dynamic> json, String documentId) {
    return IotDevice(
      id: documentId,
      assetId: json['asset_id'],
      customerId: json['customer_id'],
      deviceType: json['device_type'] ?? 'UNKNOWN',
      providerInstanceId: json['provider_instance_id'],
      location: json['location'],
      status: json['status'] ?? 'OFFLINE',
      lastPingAt: (json['last_ping_at'] as Timestamp?)?.toDate(),
      firmwareVersion: json['firmware_version'],
      telemetryThresholds: json['telemetry_thresholds'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (assetId != null) 'asset_id': assetId,
      if (customerId != null) 'customer_id': customerId,
      'device_type': deviceType,
      if (providerInstanceId != null)
        'provider_instance_id': providerInstanceId,
      if (location != null) 'location': location,
      'status': status,
      if (lastPingAt != null) 'last_ping_at': Timestamp.fromDate(lastPingAt!),
      if (firmwareVersion != null) 'firmware_version': firmwareVersion,
      if (telemetryThresholds != null)
        'telemetry_thresholds': telemetryThresholds,
    };
  }
}

// Lightweight lookup models for Field Service
class Territory {
  final String id;
  final String name;
  Territory({required this.id, required this.name});
  factory Territory.fromJson(Map<String, dynamic> json, String id) => Territory(id: id, name: json['name'] ?? '');
  Map<String, dynamic> toJson() => {'name': name};
}

class IncidentType {
  final String id;
  final String name;
  IncidentType({required this.id, required this.name});
  factory IncidentType.fromJson(Map<String, dynamic> json, String id) => IncidentType(id: id, name: json['name'] ?? '');
  Map<String, dynamic> toJson() => {'name': name};
}

class ServiceType {
  final String id;
  final String name;
  ServiceType({required this.id, required this.name});
  factory ServiceType.fromJson(Map<String, dynamic> json, String id) => ServiceType(id: id, name: json['name'] ?? '');
  Map<String, dynamic> toJson() => {'name': name};
}

class WorkOrderSubstatus {
  final String id;
  final String name;
  WorkOrderSubstatus({required this.id, required this.name});
  factory WorkOrderSubstatus.fromJson(Map<String, dynamic> json, String id) => WorkOrderSubstatus(id: id, name: json['name'] ?? '');
  Map<String, dynamic> toJson() => {'name': name};
}

class Agreement {
  final String id;
  final String title;
  Agreement({required this.id, required this.title});
  factory Agreement.fromJson(Map<String, dynamic> json, String id) => Agreement(id: id, title: json['title'] ?? '');
  Map<String, dynamic> toJson() => {'title': title};
}
