import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return null;
}

class Deal {
  final String id;
  final String title;
  final String customerName;
  final double value;
  final DealStage stage;
  final DateTime createdAt;

  Deal({
    required this.id,
    required this.title,
    required this.customerName,
    required this.value,
    required this.stage,
    required this.createdAt,
  });

  Deal copyWith({
    String? id,
    String? title,
    String? customerName,
    double? value,
    DealStage? stage,
    DateTime? createdAt,
  }) {
    return Deal(
      id: id ?? this.id,
      title: title ?? this.title,
      customerName: customerName ?? this.customerName,
      value: value ?? this.value,
      stage: stage ?? this.stage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Deal.fromJson(Map<String, dynamic> json, String id) {
    return Deal(
      id: id,
      title: json['title'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      stage: DealStage.values.firstWhere(
        (e) => e.name == json['stage'],
        orElse: () => DealStage.lead,
      ),
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'customerName': customerName,
      'value': value,
      'stage': stage.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

enum DealStage { lead, qualified, proposal, negotiation, closedWon, closedLost }

class Account {
  final String id;
  final String name;
  final String industry;
  final String website;
  final double annualRevenue;
  final int employeeCount;
  final Map<String, dynamic>? billingAddress;
  final Map<String, dynamic>? shippingAddress;
  final String ownerId;
  final String? territoryId;
  final String? parentAccountId;
  final String status;
  final String relationshipHealth;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Account({
    required this.id,
    required this.name,
    required this.industry,
    required this.website,
    required this.annualRevenue,
    required this.employeeCount,
    this.billingAddress,
    this.shippingAddress,
    required this.ownerId,
    this.territoryId,
    this.parentAccountId,
    required this.status,
    required this.relationshipHealth,
    this.createdAt,
    this.updatedAt,
  });

  factory Account.fromJson(Map<String, dynamic> json, String id) {
    return Account(
      id: id,
      name: json['name'] as String? ?? '',
      industry: json['industry'] as String? ?? '',
      website: json['website'] as String? ?? '',
      annualRevenue: (json['annualRevenue'] as num?)?.toDouble() ?? 0.0,
      employeeCount: json['employeeCount'] as int? ?? 0,
      billingAddress: json['billingAddress'] as Map<String, dynamic>?,
      shippingAddress: json['shippingAddress'] as Map<String, dynamic>?,
      ownerId: json['ownerId'] as String? ?? '',
      territoryId: json['territoryId'] as String?,
      parentAccountId: json['parentAccountId'] as String?,
      status: json['status'] as String? ?? 'Prospect',
      relationshipHealth: json['relationshipHealth'] as String? ?? 'Yellow',
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'industry': industry,
      'website': website,
      'annualRevenue': annualRevenue,
      'employeeCount': employeeCount,
      if (billingAddress != null) 'billingAddress': billingAddress,
      if (shippingAddress != null) 'shippingAddress': shippingAddress,
      'ownerId': ownerId,
      if (territoryId != null) 'territoryId': territoryId,
      if (parentAccountId != null) 'parentAccountId': parentAccountId,
      'status': status,
      'relationshipHealth': relationshipHealth,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }
}

class Contact {
  final String id;
  final String accountId;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String mobile;
  final String jobTitle;
  final String department;
  final String leadSource;
  final bool isPrimary;
  final String ownerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Contact({
    required this.id,
    required this.accountId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.mobile,
    required this.jobTitle,
    required this.department,
    required this.leadSource,
    required this.isPrimary,
    required this.ownerId,
    this.createdAt,
    this.updatedAt,
  });

  factory Contact.fromJson(Map<String, dynamic> json, String id) {
    return Contact(
      id: id,
      accountId: json['accountId'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      mobile: json['mobile'] as String? ?? '',
      jobTitle: json['jobTitle'] as String? ?? '',
      department: json['department'] as String? ?? '',
      leadSource: json['leadSource'] as String? ?? '',
      isPrimary: json['isPrimary'] as bool? ?? false,
      ownerId: json['ownerId'] as String? ?? '',
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accountId': accountId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'mobile': mobile,
      'jobTitle': jobTitle,
      'department': department,
      'leadSource': leadSource,
      'isPrimary': isPrimary,
      'ownerId': ownerId,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }
}

class Lead {
  final String id;
  final String firstName;
  final String lastName;
  final String company;
  final String email;
  final String phone;
  final String leadSource;
  final String status;
  final String rating;
  final double aiLeadScore;
  final String? sequenceId;
  final String ownerId;
  final bool isConverted;
  final String? convertedAccountId;
  final String? convertedContactId;
  final String? convertedOpportunityId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Lead({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.company,
    required this.email,
    required this.phone,
    required this.leadSource,
    required this.status,
    required this.rating,
    required this.aiLeadScore,
    this.sequenceId,
    required this.ownerId,
    required this.isConverted,
    this.convertedAccountId,
    this.convertedContactId,
    this.convertedOpportunityId,
    this.createdAt,
    this.updatedAt,
  });

  factory Lead.fromJson(Map<String, dynamic> json, String id) {
    return Lead(
      id: id,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      company: json['company'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      leadSource: json['leadSource'] as String? ?? '',
      status: json['status'] as String? ?? 'New',
      rating: json['rating'] as String? ?? 'Cold',
      aiLeadScore: (json['aiLeadScore'] as num?)?.toDouble() ?? 0.0,
      sequenceId: json['sequenceId'] as String?,
      ownerId: json['ownerId'] as String? ?? '',
      isConverted: json['isConverted'] as bool? ?? false,
      convertedAccountId: json['convertedAccountId'] as String?,
      convertedContactId: json['convertedContactId'] as String?,
      convertedOpportunityId: json['convertedOpportunityId'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'company': company,
      'email': email,
      'phone': phone,
      'leadSource': leadSource,
      'status': status,
      'rating': rating,
      'aiLeadScore': aiLeadScore,
      if (sequenceId != null) 'sequenceId': sequenceId,
      'ownerId': ownerId,
      'isConverted': isConverted,
      if (convertedAccountId != null) 'convertedAccountId': convertedAccountId,
      if (convertedContactId != null) 'convertedContactId': convertedContactId,
      if (convertedOpportunityId != null)
        'convertedOpportunityId': convertedOpportunityId,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }
}

class Opportunity {
  final String id;
  final String name;
  final String accountId;
  final String primaryContactId;
  final String stage;
  final double amount;
  final double probability;
  final DateTime? expectedCloseDate;
  final String forecastCategory;
  final String leadSource;
  final String nextStep;
  final String ownerId;
  final String? lossReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Opportunity({
    required this.id,
    required this.name,
    required this.accountId,
    required this.primaryContactId,
    required this.stage,
    required this.amount,
    required this.probability,
    this.expectedCloseDate,
    required this.forecastCategory,
    required this.leadSource,
    required this.nextStep,
    required this.ownerId,
    this.lossReason,
    this.createdAt,
    this.updatedAt,
  });

  factory Opportunity.fromJson(Map<String, dynamic> json, String id) {
    return Opportunity(
      id: id,
      name: json['name'] as String? ?? '',
      accountId: json['accountId'] as String? ?? '',
      primaryContactId: json['primaryContactId'] as String? ?? '',
      stage: json['stage'] as String? ?? 'Prospecting',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      probability: (json['probability'] as num?)?.toDouble() ?? 0.0,
      expectedCloseDate: _parseDateTime(json['expectedCloseDate']),
      forecastCategory: json['forecastCategory'] as String? ?? 'Pipeline',
      leadSource: json['leadSource'] as String? ?? '',
      nextStep: json['nextStep'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      lossReason: json['lossReason'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'accountId': accountId,
      'primaryContactId': primaryContactId,
      'stage': stage,
      'amount': amount,
      'probability': probability,
      if (expectedCloseDate != null)
        'expectedCloseDate': Timestamp.fromDate(expectedCloseDate!),
      'forecastCategory': forecastCategory,
      'leadSource': leadSource,
      'nextStep': nextStep,
      'ownerId': ownerId,
      if (lossReason != null) 'lossReason': lossReason,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }
}

class Quote {
  final String id;
  final String opportunityId;
  final String accountId;
  final String quoteNumber;
  final String status;
  final DateTime? expirationDate;
  final double subtotal;
  final double discount;
  final double tax;
  final double grandTotal;
  final Map<String, dynamic>? billingAddress;
  final Map<String, dynamic>? shippingAddress;
  final String termsAndConditions;
  final bool isSyncing;
  final String ownerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Quote({
    required this.id,
    required this.opportunityId,
    required this.accountId,
    required this.quoteNumber,
    required this.status,
    this.expirationDate,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.grandTotal,
    this.billingAddress,
    this.shippingAddress,
    required this.termsAndConditions,
    required this.isSyncing,
    required this.ownerId,
    this.createdAt,
    this.updatedAt,
  });

  factory Quote.fromJson(Map<String, dynamic> json, String id) {
    return Quote(
      id: id,
      opportunityId: json['opportunityId'] as String? ?? '',
      accountId: json['accountId'] as String? ?? '',
      quoteNumber: json['quoteNumber'] as String? ?? '',
      status: json['status'] as String? ?? 'Draft',
      expirationDate: _parseDateTime(json['expirationDate']),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0.0,
      billingAddress: json['billingAddress'] as Map<String, dynamic>?,
      shippingAddress: json['shippingAddress'] as Map<String, dynamic>?,
      termsAndConditions: json['termsAndConditions'] as String? ?? '',
      isSyncing: json['isSyncing'] as bool? ?? false,
      ownerId: json['ownerId'] as String? ?? '',
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'opportunityId': opportunityId,
      'accountId': accountId,
      'quoteNumber': quoteNumber,
      'status': status,
      if (expirationDate != null)
        'expirationDate': Timestamp.fromDate(expirationDate!),
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'grandTotal': grandTotal,
      if (billingAddress != null) 'billingAddress': billingAddress,
      if (shippingAddress != null) 'shippingAddress': shippingAddress,
      'termsAndConditions': termsAndConditions,
      'isSyncing': isSyncing,
      'ownerId': ownerId,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }
}

class Campaign {
  final String id;
  final String name;
  final String type;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final double budget;
  final double actualSpend;
  final String targetAudience;
  final double expectedRevenue;
  final double actualRevenue;
  final String ownerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Campaign({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    this.startDate,
    this.endDate,
    required this.budget,
    required this.actualSpend,
    required this.targetAudience,
    required this.expectedRevenue,
    required this.actualRevenue,
    required this.ownerId,
    this.createdAt,
    this.updatedAt,
  });

  factory Campaign.fromJson(Map<String, dynamic> json, String id) {
    return Campaign(
      id: id,
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      status: json['status'] ?? '',
      startDate:
          json['startDate'] != null
              ? (json['startDate'] as Timestamp).toDate()
              : null,
      endDate:
          json['endDate'] != null
              ? (json['endDate'] as Timestamp).toDate()
              : null,
      budget: (json['budget'] ?? 0.0).toDouble(),
      actualSpend: (json['actualSpend'] ?? 0.0).toDouble(),
      targetAudience: json['targetAudience'] ?? '',
      expectedRevenue: (json['expectedRevenue'] ?? 0.0).toDouble(),
      actualRevenue: (json['actualRevenue'] ?? 0.0).toDouble(),
      ownerId: json['ownerId'] ?? '',
      createdAt:
          json['createdAt'] != null
              ? (json['createdAt'] as Timestamp).toDate()
              : null,
      updatedAt:
          json['updatedAt'] != null
              ? (json['updatedAt'] as Timestamp).toDate()
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'status': status,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'budget': budget,
      'actualSpend': actualSpend,
      'targetAudience': targetAudience,
      'expectedRevenue': expectedRevenue,
      'actualRevenue': actualRevenue,
      'ownerId': ownerId,
      'createdAt':
          createdAt != null
              ? Timestamp.fromDate(createdAt!)
              : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class CustomerJourney {
  final String id;
  final String? leadId;
  final String? contactId;
  final String? campaignId;
  final List<Map<String, dynamic>> touchpoints;
  final String currentStage;
  final double totalScore;
  final bool isConverted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CustomerJourney({
    required this.id,
    this.leadId,
    this.contactId,
    this.campaignId,
    required this.touchpoints,
    required this.currentStage,
    required this.totalScore,
    required this.isConverted,
    this.createdAt,
    this.updatedAt,
  });

  factory CustomerJourney.fromJson(Map<String, dynamic> json, String id) {
    return CustomerJourney(
      id: id,
      leadId: json['leadId'],
      contactId: json['contactId'],
      campaignId: json['campaignId'],
      touchpoints: List<Map<String, dynamic>>.from(json['touchpoints'] ?? []),
      currentStage: json['currentStage'] ?? '',
      totalScore: (json['totalScore'] ?? 0.0).toDouble(),
      isConverted: json['isConverted'] ?? false,
      createdAt:
          json['createdAt'] != null
              ? (json['createdAt'] as Timestamp).toDate()
              : null,
      updatedAt:
          json['updatedAt'] != null
              ? (json['updatedAt'] as Timestamp).toDate()
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'leadId': leadId,
      'contactId': contactId,
      'campaignId': campaignId,
      'touchpoints': touchpoints,
      'currentStage': currentStage,
      'totalScore': totalScore,
      'isConverted': isConverted,
      'createdAt':
          createdAt != null
              ? Timestamp.fromDate(createdAt!)
              : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class Activity {
  final String id;
  final String type;
  final String subject;
  final String description;
  final String regardingType;
  final String regardingId;
  final String ownerId;
  final DateTime? dueDate;
  final String status;
  final DateTime? completedAt;
  final DateTime? createdAt;

  Activity({
    required this.id,
    required this.type,
    required this.subject,
    required this.description,
    required this.regardingType,
    required this.regardingId,
    required this.ownerId,
    this.dueDate,
    required this.status,
    this.completedAt,
    this.createdAt,
  });

  factory Activity.fromJson(Map<String, dynamic> json, String id) {
    return Activity(
      id: id,
      type: json['type'] ?? '',
      subject: json['subject'] ?? '',
      description: json['description'] ?? '',
      regardingType: json['regardingType'] ?? '',
      regardingId: json['regardingId'] ?? '',
      ownerId: json['ownerId'] ?? '',
      dueDate:
          json['dueDate'] != null
              ? (json['dueDate'] as Timestamp).toDate()
              : null,
      status: json['status'] ?? '',
      completedAt:
          json['completedAt'] != null
              ? (json['completedAt'] as Timestamp).toDate()
              : null,
      createdAt:
          json['createdAt'] != null
              ? (json['createdAt'] as Timestamp).toDate()
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'subject': subject,
      'description': description,
      'regardingType': regardingType,
      'regardingId': regardingId,
      'ownerId': ownerId,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'status': status,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'createdAt':
          createdAt != null
              ? Timestamp.fromDate(createdAt!)
              : FieldValue.serverTimestamp(),
    };
  }
}
