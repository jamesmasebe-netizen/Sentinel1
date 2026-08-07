import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

class EnvironmentalSpill {
  final String id;
  final String siteId;
  final String substance;
  final String volume;
  final String location;
  final bool contained;
  final bool reportedToAuthorities;
  final String authorId;
  final DateTime? dateOfSpill;
  final DateTime? createdAt;

  EnvironmentalSpill({
    required this.id,
    required this.siteId,
    required this.substance,
    this.volume = '',
    this.location = '',
    this.contained = false,
    this.reportedToAuthorities = false,
    this.authorId = '',
    this.dateOfSpill,
    this.createdAt,
  });

  factory EnvironmentalSpill.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return EnvironmentalSpill(
      id: doc.id,
      siteId: data['siteId'] ?? '',
      substance: data['substance'] ?? '',
      volume: data['volume'] ?? '',
      location: data['location'] ?? '',
      contained: data['contained'] ?? false,
      reportedToAuthorities: data['reportedToAuthorities'] ?? false,
      authorId: data['authorId'] ?? '',
      dateOfSpill: _parseDate(data['dateOfSpill']),
      createdAt: _parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'siteId': siteId,
      'substance': substance,
      'volume': volume,
      'location': location,
      'contained': contained,
      'reportedToAuthorities': reportedToAuthorities,
      'authorId': authorId,
      'dateOfSpill': (dateOfSpill ?? DateTime.now()).toIso8601String(),
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }
}

class WasteManifest {
  final String id;
  final String siteId;
  final String wasteType;
  final double quantity;
  final String unit;
  final String transporterName;
  final String disposalFacility;
  final String status;
  final String authorId;
  final DateTime? createdAt;

  WasteManifest({
    required this.id,
    required this.siteId,
    required this.wasteType,
    this.quantity = 0,
    this.unit = 'kg',
    this.transporterName = '',
    this.disposalFacility = '',
    this.status = 'Pending Pickup',
    this.authorId = '',
    this.createdAt,
  });

  factory WasteManifest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return WasteManifest(
      id: doc.id,
      siteId: data['siteId'] ?? '',
      wasteType: data['wasteType'] ?? '',
      quantity: (data['quantity'] as num?)?.toDouble() ?? 0,
      unit: data['unit'] ?? 'kg',
      transporterName: data['transporterName'] ?? '',
      disposalFacility: data['disposalFacility'] ?? '',
      status: data['status'] ?? 'Pending Pickup',
      authorId: data['authorId'] ?? '',
      createdAt: _parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'siteId': siteId,
      'wasteType': wasteType,
      'quantity': quantity,
      'unit': unit,
      'transporterName': transporterName,
      'disposalFacility': disposalFacility,
      'status': status,
      'authorId': authorId,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }
}

class EsgMetric {
  final String id;
  final String siteId;
  final String category;
  final double value;
  final String unit;
  final String period;
  final String authorId;
  final DateTime? createdAt;

  EsgMetric({
    required this.id,
    required this.siteId,
    required this.category,
    this.value = 0,
    this.unit = '',
    this.period = '',
    this.authorId = '',
    this.createdAt,
  });

  factory EsgMetric.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return EsgMetric(
      id: doc.id,
      siteId: data['siteId'] ?? '',
      category: data['category'] ?? '',
      value: (data['value'] as num?)?.toDouble() ?? 0,
      unit: data['unit'] ?? '',
      period: data['period'] ?? '',
      authorId: data['authorId'] ?? '',
      createdAt: _parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'siteId': siteId,
      'category': category,
      'value': value,
      'unit': unit,
      'period': period,
      'authorId': authorId,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }
}
