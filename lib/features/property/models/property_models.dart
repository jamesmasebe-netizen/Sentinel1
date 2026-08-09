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
  final String managerId;
  // Manual entry — no live compliance-scoring source exists yet (see F-211).
  final double complianceScore;

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
    required this.managerId,
    this.complianceScore = 0.0,
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
      managerId: data['manager'] ?? '',
      complianceScore: (data['complianceScore'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toFirestore(String siteId) {
    return {
      'siteId': siteId,
      'name': name,
      'type': type,
      'address': address,
      'lat': lat,
      'lng': lng,
      'totalArea': totalArea,
      'floors': floors,
      'occupancy': occupancy,
      'capacity': capacity,
      'status': status,
      'constructionDate': constructionDate.toIso8601String(),
      'manager': managerId,
      'complianceScore': complianceScore,
    };
  }
}

class PropertyProject {
  final String id;
  final String propertyId;
  final String title;
  final String type;
  final String description;
  final String status;
  final String assigneeId;
  final DateTime dueDate;
  final int progress;

  PropertyProject({
    required this.id,
    required this.propertyId,
    required this.title,
    required this.type,
    required this.description,
    required this.status,
    required this.assigneeId,
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
      assigneeId: data['assignedTo'] ?? '',
      dueDate: DateTime.parse(
        data['dueDate'] ?? DateTime.now().toIso8601String(),
      ),
      progress: data['progress'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'propertyId': propertyId,
      'title': title,
      'type': type,
      'description': description,
      'status': status,
      'assignedTo': assigneeId,
      'dueDate': dueDate.toIso8601String(),
      'progress': progress,
    };
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

  Map<String, dynamic> toFirestore() {
    return {
      'propertyId': propertyId,
      'month': month,
      'electricity': electricity,
      'water': water,
      'waste': waste,
      'carbon': carbon,
    };
  }
}

class LegalAppointment {
  final String id;
  final String propertyId;
  final String role;
  final String personId;
  final String personName;
  final String status;
  final DateTime? expiry;

  LegalAppointment({
    required this.id,
    required this.propertyId,
    required this.role,
    required this.personId,
    this.personName = '',
    required this.status,
    this.expiry,
  });

  // FIXED 2026 (this pass): the on-disk field named 'personName' had always actually stored the
  // appointed person's employee id, not a display name (see property_facility_tab.dart, which
  // rendered `appointment.personId` as raw text — a real UX gap tracked in T3-PROPERTY). Going
  // forward the id and a denormalized display name (resolved from employeesProvider at save time,
  // see legal_appointment_form.dart) are stored under separate keys. `data['personName']` is kept
  // as a fallback source for `personId` so appointments written before this fix still parse; those
  // records simply have no `personDisplayName` yet, so the UI falls back to showing the id for
  // them exactly as it did before (see property_facility_tab.dart) rather than blanking out.
  factory LegalAppointment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LegalAppointment(
      id: doc.id,
      propertyId: data['propertyId'] ?? '',
      role: data['role'] ?? '',
      personId: data['personId'] ?? data['personName'] ?? '',
      personName: data['personDisplayName'] ?? '',
      status: data['status'] ?? '',
      expiry: data['expiry'] != null ? DateTime.parse(data['expiry']) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'propertyId': propertyId,
      'role': role,
      'personId': personId,
      'personDisplayName': personName,
      'status': status,
      'expiry': expiry?.toIso8601String(),
    };
  }
}

class LeaseInfo {
  final String id;
  final String propertyId;
  final String tenantId;
  final double monthlyRent;
  final DateTime startDate;
  final DateTime endDate;
  final String status;

  LeaseInfo({
    required this.id,
    required this.propertyId,
    required this.tenantId,
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
      tenantId: data['tenantName'] ?? '',
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

  Map<String, dynamic> toFirestore() {
    return {
      'propertyId': propertyId,
      'tenantName': tenantId,
      'monthlyRent': monthlyRent,
      'status': status,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
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

  Map<String, dynamic> toFirestore() {
    return {
      'propertyId': propertyId,
      'name': name,
      'category': category,
      'condition': condition,
      'lastInspected': lastInspected.toIso8601String(),
    };
  }
}
