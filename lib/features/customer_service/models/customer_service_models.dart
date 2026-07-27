import 'package:cloud_firestore/cloud_firestore.dart';

// Helper to handle Firestore Timestamp to DateTime conversion
DateTime? _timestampToDateTime(dynamic timestamp) {
  if (timestamp == null) return null;
  if (timestamp is Timestamp) return timestamp.toDate();
  if (timestamp is DateTime) return timestamp;
  if (timestamp is String) return DateTime.tryParse(timestamp);
  return null;
}

dynamic _dateTimeToTimestamp(DateTime? date) {
  if (date == null) return null;
  return Timestamp.fromDate(date);
}

class Ticket {
  final String id; // Represents Document ID
  final String ticketId; // Human-readable identifier
  final String? customerId;
  final String? contactId;
  final String? parentTicketId;
  final String? assetId;
  final String title;
  final String? description;
  final String status;
  final String? resolutionType;
  final String priority;
  final String severity;
  final String channel;
  final String? assignedTo;
  final String? workstreamId;
  final String? queueId;
  final String? entitlementId;
  final bool isEscalated;
  final int escalationLevel;
  final String? slaStatus;
  final Map<String, dynamic>? slaTimers;
  final List<String> tags;
  final Map<String, dynamic> customFields;
  final String? copilotSummary;
  final double? sentimentTrend;
  final DateTime? firstResponseAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final DateTime? closedAt;

  Ticket({
    required this.id,
    required this.ticketId,
    this.customerId,
    this.contactId,
    this.parentTicketId,
    this.assetId,
    required this.title,
    this.description,
    this.status = 'New',
    this.resolutionType,
    this.priority = 'Medium',
    this.severity = '3',
    this.channel = 'Email',
    this.assignedTo,
    this.workstreamId,
    this.queueId,
    this.entitlementId,
    this.isEscalated = false,
    this.escalationLevel = 0,
    this.slaStatus,
    this.slaTimers,
    this.tags = const [],
    this.customFields = const {},
    this.copilotSummary,
    this.sentimentTrend,
    this.firstResponseAt,
    this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.closedAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> json, String documentId) {
    return Ticket(
      id: documentId,
      ticketId: json['id'] as String? ?? '',
      customerId: json['customerId'] as String?,
      contactId: json['contactId'] as String?,
      parentTicketId: json['parentTicketId'] as String?,
      assetId: json['assetId'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'New',
      resolutionType: json['resolutionType'] as String?,
      priority: json['priority'] as String? ?? 'Medium',
      severity: json['severity'] as String? ?? '3',
      channel: json['channel'] as String? ?? 'Email',
      assignedTo: json['assignedTo'] as String?,
      workstreamId: json['workstreamId'] as String?,
      queueId: json['queueId'] as String?,
      entitlementId: json['entitlementId'] as String?,
      isEscalated: json['isEscalated'] as bool? ?? false,
      escalationLevel: json['escalationLevel'] as int? ?? 0,
      slaStatus: json['slaStatus'] as String?,
      slaTimers: json['slaTimers'] as Map<String, dynamic>?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
      customFields: json['customFields'] as Map<String, dynamic>? ?? {},
      copilotSummary: json['copilotSummary'] as String?,
      sentimentTrend: (json['sentimentTrend'] as num?)?.toDouble(),
      firstResponseAt: _timestampToDateTime(json['firstResponseAt']),
      createdAt: _timestampToDateTime(json['createdAt']),
      updatedAt: _timestampToDateTime(json['updatedAt']),
      resolvedAt: _timestampToDateTime(json['resolvedAt']),
      closedAt: _timestampToDateTime(json['closedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': ticketId,
      if (customerId != null) 'customerId': customerId,
      if (contactId != null) 'contactId': contactId,
      if (parentTicketId != null) 'parentTicketId': parentTicketId,
      if (assetId != null) 'assetId': assetId,
      'title': title,
      if (description != null) 'description': description,
      'status': status,
      if (resolutionType != null) 'resolutionType': resolutionType,
      'priority': priority,
      'severity': severity,
      'channel': channel,
      if (assignedTo != null) 'assignedTo': assignedTo,
      if (workstreamId != null) 'workstreamId': workstreamId,
      if (queueId != null) 'queueId': queueId,
      if (entitlementId != null) 'entitlementId': entitlementId,
      'isEscalated': isEscalated,
      'escalationLevel': escalationLevel,
      if (slaStatus != null) 'slaStatus': slaStatus,
      if (slaTimers != null) 'slaTimers': slaTimers,
      'tags': tags,
      'customFields': customFields,
      if (copilotSummary != null) 'copilotSummary': copilotSummary,
      if (sentimentTrend != null) 'sentimentTrend': sentimentTrend,
      if (firstResponseAt != null)
        'firstResponseAt': _dateTimeToTimestamp(firstResponseAt),
      if (createdAt != null) 'createdAt': _dateTimeToTimestamp(createdAt),
      if (updatedAt != null) 'updatedAt': _dateTimeToTimestamp(updatedAt),
      if (resolvedAt != null) 'resolvedAt': _dateTimeToTimestamp(resolvedAt),
      if (closedAt != null) 'closedAt': _dateTimeToTimestamp(closedAt),
    };
  }
}

class TicketMessage {
  final String id;
  final String? senderId;
  final String senderType;
  final String channel;
  final String? content;
  final double? sentimentScore;
  final List<String> aiSuggestions;
  final String? copilotDraft;
  final List<Map<String, dynamic>> attachments;
  final bool isInternal;
  final Map<String, dynamic> readReceipts;
  final DateTime? timestamp;

  TicketMessage({
    required this.id,
    this.senderId,
    this.senderType = 'Agent',
    this.channel = 'Email',
    this.content,
    this.sentimentScore,
    this.aiSuggestions = const [],
    this.copilotDraft,
    this.attachments = const [],
    this.isInternal = false,
    this.readReceipts = const {},
    this.timestamp,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json, String documentId) {
    return TicketMessage(
      id: documentId,
      senderId: json['senderId'] as String?,
      senderType: json['senderType'] as String? ?? 'Agent',
      channel: json['channel'] as String? ?? 'Email',
      content: json['content'] as String?,
      sentimentScore: (json['sentimentScore'] as num?)?.toDouble(),
      aiSuggestions:
          (json['aiSuggestions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      copilotDraft: json['copilotDraft'] as String?,
      attachments:
          (json['attachments'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      isInternal: json['isInternal'] as bool? ?? false,
      readReceipts: json['readReceipts'] as Map<String, dynamic>? ?? {},
      timestamp: _timestampToDateTime(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (senderId != null) 'senderId': senderId,
      'senderType': senderType,
      'channel': channel,
      if (content != null) 'content': content,
      if (sentimentScore != null) 'sentimentScore': sentimentScore,
      'aiSuggestions': aiSuggestions,
      if (copilotDraft != null) 'copilotDraft': copilotDraft,
      'attachments': attachments,
      'isInternal': isInternal,
      'readReceipts': readReceipts,
      if (timestamp != null) 'timestamp': _dateTimeToTimestamp(timestamp),
    };
  }
}

class KnowledgeArticle {
  final String id;
  final String articleNumber;
  final String title;
  final String? content;
  final String? summary;
  final String? language;
  final List<String> categories;
  final List<String> tags;
  final String status;
  final String approvalStatus;
  final String? authorId;
  final String? reviewerId;
  final String visibility;
  final List<String> relatedProducts;
  final DateTime? expirationDate;
  final Map<String, dynamic> metrics;
  final int version;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  KnowledgeArticle({
    required this.id,
    required this.articleNumber,
    required this.title,
    this.content,
    this.summary,
    this.language,
    this.categories = const [],
    this.tags = const [],
    this.status = 'Draft',
    this.approvalStatus = 'Pending',
    this.authorId,
    this.reviewerId,
    this.visibility = 'Internal',
    this.relatedProducts = const [],
    this.expirationDate,
    this.metrics = const {},
    this.version = 1,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory KnowledgeArticle.fromJson(
    Map<String, dynamic> json,
    String documentId,
  ) {
    return KnowledgeArticle(
      id: documentId,
      articleNumber: json['articleNumber'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String?,
      summary: json['summary'] as String?,
      language: json['language'] as String?,
      categories:
          (json['categories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
      status: json['status'] as String? ?? 'Draft',
      approvalStatus: json['approvalStatus'] as String? ?? 'Pending',
      authorId: json['authorId'] as String?,
      reviewerId: json['reviewerId'] as String?,
      visibility: json['visibility'] as String? ?? 'Internal',
      relatedProducts:
          (json['relatedProducts'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      expirationDate: _timestampToDateTime(json['expirationDate']),
      metrics: json['metrics'] as Map<String, dynamic>? ?? {},
      version: json['version'] as int? ?? 1,
      publishedAt: _timestampToDateTime(json['publishedAt']),
      createdAt: _timestampToDateTime(json['createdAt']),
      updatedAt: _timestampToDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'articleNumber': articleNumber,
      'title': title,
      if (content != null) 'content': content,
      if (summary != null) 'summary': summary,
      if (language != null) 'language': language,
      'categories': categories,
      'tags': tags,
      'status': status,
      'approvalStatus': approvalStatus,
      if (authorId != null) 'authorId': authorId,
      if (reviewerId != null) 'reviewerId': reviewerId,
      'visibility': visibility,
      'relatedProducts': relatedProducts,
      if (expirationDate != null)
        'expirationDate': _dateTimeToTimestamp(expirationDate),
      'metrics': metrics,
      'version': version,
      if (publishedAt != null) 'publishedAt': _dateTimeToTimestamp(publishedAt),
      if (createdAt != null) 'createdAt': _dateTimeToTimestamp(createdAt),
      if (updatedAt != null) 'updatedAt': _dateTimeToTimestamp(updatedAt),
    };
  }
}

class SlaInstance {
  final String id;
  final String kpiType;
  final String status;
  final DateTime? failureTime;
  final DateTime? warningTime;
  final DateTime? succeededOn;
  final int? elapsedTime;

  SlaInstance({
    required this.id,
    required this.kpiType,
    this.status = 'In Progress',
    this.failureTime,
    this.warningTime,
    this.succeededOn,
    this.elapsedTime,
  });

  factory SlaInstance.fromJson(Map<String, dynamic> json, String documentId) {
    return SlaInstance(
      id: documentId,
      kpiType: json['kpiType'] as String? ?? '',
      status: json['status'] as String? ?? 'In Progress',
      failureTime: _timestampToDateTime(json['failureTime']),
      warningTime: _timestampToDateTime(json['warningTime']),
      succeededOn: _timestampToDateTime(json['succeededOn']),
      elapsedTime: json['elapsedTime'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kpiType': kpiType,
      'status': status,
      if (failureTime != null) 'failureTime': _dateTimeToTimestamp(failureTime),
      if (warningTime != null) 'warningTime': _dateTimeToTimestamp(warningTime),
      if (succeededOn != null) 'succeededOn': _dateTimeToTimestamp(succeededOn),
      if (elapsedTime != null) 'elapsedTime': elapsedTime,
    };
  }
}

class CsAsset {
  final String id;
  final String name;
  final String? customerId;
  final String? serialNumber;
  final String? productModel;
  final DateTime? purchaseDate;
  final DateTime? warrantyExpiry;
  final String status;
  final bool iotEnabled;
  final DateTime? lastHeartbeat;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CsAsset({
    required this.id,
    required this.name,
    this.customerId,
    this.serialNumber,
    this.productModel,
    this.purchaseDate,
    this.warrantyExpiry,
    this.status = 'Active',
    this.iotEnabled = false,
    this.lastHeartbeat,
    this.createdAt,
    this.updatedAt,
  });

  factory CsAsset.fromJson(Map<String, dynamic> json, String documentId) {
    return CsAsset(
      id: documentId,
      name: json['name'] as String? ?? '',
      customerId: json['customerId'] as String?,
      serialNumber: json['serialNumber'] as String?,
      productModel: json['productModel'] as String?,
      purchaseDate: _timestampToDateTime(json['purchaseDate']),
      warrantyExpiry: _timestampToDateTime(json['warrantyExpiry']),
      status: json['status'] as String? ?? 'Active',
      iotEnabled: json['iotEnabled'] as bool? ?? false,
      lastHeartbeat: _timestampToDateTime(json['lastHeartbeat']),
      createdAt: _timestampToDateTime(json['createdAt']),
      updatedAt: _timestampToDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (customerId != null) 'customerId': customerId,
      if (serialNumber != null) 'serialNumber': serialNumber,
      if (productModel != null) 'productModel': productModel,
      if (purchaseDate != null)
        'purchaseDate': _dateTimeToTimestamp(purchaseDate),
      if (warrantyExpiry != null)
        'warrantyExpiry': _dateTimeToTimestamp(warrantyExpiry),
      'status': status,
      'iotEnabled': iotEnabled,
      if (lastHeartbeat != null)
        'lastHeartbeat': _dateTimeToTimestamp(lastHeartbeat),
      if (createdAt != null) 'createdAt': _dateTimeToTimestamp(createdAt),
      if (updatedAt != null) 'updatedAt': _dateTimeToTimestamp(updatedAt),
    };
  }
}
