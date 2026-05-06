import 'package:cloud_firestore/cloud_firestore.dart';

class Property {
  final String id;
  final String name;
  final String type;
  final String address;
  final double lat;
  final double lng;
  final String totalArea;
  final int floors;
  final int occupancy;
  final int capacity;
  final String status;
  final DateTime constructionDate;
  final String manager;
  final double complianceScore; // Added for traceability
  final int totalAssets; // Added for traceability

  Property({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.lat,
    required this.lng,
    required this.totalArea,
    required this.floors,
    required this.occupancy,
    required this.capacity,
    required this.status,
    required this.constructionDate,
    required this.manager,
    this.complianceScore = 0.0,
    this.totalAssets = 0,
  });

  factory Property.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Property(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      address: data['address'] ?? '',
      lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0.0,
      totalArea: data['totalArea'] ?? '',
      floors: data['floors'] ?? 0,
      occupancy: data['occupancy'] ?? 0,
      capacity: data['capacity'] ?? 0,
      status: data['status'] ?? 'Unknown',
      constructionDate: DateTime.parse(
        data['constructionDate'] ?? DateTime.now().toIso8601String(),
      ),
      manager: data['manager'] ?? '',
      complianceScore: (data['complianceScore'] as num?)?.toDouble() ?? 0.0,
      totalAssets: data['totalAssets'] ?? 0,
    );
  }
}

class PropertyProject {
  final String id;
  final String propertyId;
  final String title;
  final String type;
  final String description;
  final String status;
  final String assignedTo;
  final DateTime dueDate;
  final int progress;

  PropertyProject({
    required this.id,
    required this.propertyId,
    required this.title,
    required this.type,
    required this.description,
    required this.status,
    required this.assignedTo,
    required this.dueDate,
    required this.progress,
  });

  factory PropertyProject.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PropertyProject(
      id: doc.id,
      propertyId: data['propertyId'] ?? '',
      title: data['title'] ?? '',
      type: data['type'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? '',
      assignedTo: data['assignedTo'] ?? '',
      dueDate: DateTime.parse(
        data['dueDate'] ?? DateTime.now().toIso8601String(),
      ),
      progress: data['progress'] ?? 0,
    );
  }
}

class UtilityUsage {
  final String id;
  final String propertyId;
  final String month;
  final double electricity;
  final double water;
  final double waste;
  final double carbon;

  UtilityUsage({
    required this.id,
    required this.propertyId,
    required this.month,
    required this.electricity,
    required this.water,
    required this.waste,
    required this.carbon,
  });

  factory UtilityUsage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UtilityUsage(
      id: doc.id,
      propertyId: data['propertyId'] ?? '',
      month: data['month'] ?? '',
      electricity: (data['electricity'] as num?)?.toDouble() ?? 0.0,
      water: (data['water'] as num?)?.toDouble() ?? 0.0,
      waste: (data['waste'] as num?)?.toDouble() ?? 0.0,
      carbon: (data['carbon'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class LegalAppointment {
  final String id;
  final String propertyId;
  final String role;
  final String personName;
  final String status;
  final DateTime? expiry;

  LegalAppointment({
    required this.id,
    required this.propertyId,
    required this.role,
    required this.personName,
    required this.status,
    this.expiry,
  });

  factory LegalAppointment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LegalAppointment(
      id: doc.id,
      propertyId: data['propertyId'] ?? '',
      role: data['role'] ?? '',
      personName: data['personName'] ?? '',
      status: data['status'] ?? '',
      expiry: data['expiry'] != null ? DateTime.parse(data['expiry']) : null,
    );
  }
}

class LeaseInfo {
  final String id;
  final String propertyId;
  final String tenantName;
  final double monthlyRent;
  final DateTime startDate;
  final DateTime endDate;
  final String status;

  LeaseInfo({
    required this.id,
    required this.propertyId,
    required this.tenantName,
    required this.monthlyRent,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory LeaseInfo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LeaseInfo(
      id: doc.id,
      propertyId: data['propertyId'] ?? '',
      tenantName: data['tenantName'] ?? '',
      monthlyRent: (data['monthlyRent'] as num?)?.toDouble() ?? 0.0,
      startDate: DateTime.parse(
        data['startDate'] ?? DateTime.now().toIso8601String(),
      ),
      endDate: DateTime.parse(
        data['endDate'] ?? DateTime.now().toIso8601String(),
      ),
      status: data['status'] ?? 'Active',
    );
  }
}

class AssetInfo {
  final String id;
  final String propertyId;
  final String name;
  final String category;
  final String condition;
  final DateTime lastInspected;

  AssetInfo({
    required this.id,
    required this.propertyId,
    required this.name,
    required this.category,
    required this.condition,
    required this.lastInspected,
  });

  factory AssetInfo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AssetInfo(
      id: doc.id,
      propertyId: data['propertyId'] ?? '',
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      condition: data['condition'] ?? 'Good',
      lastInspected: DateTime.parse(
        data['lastInspected'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
