import 'package:cloud_firestore/cloud_firestore.dart';

/// InventoryItem model for Supply Chain & Operations
class InventoryItem {
  final String? id;
  final String tenantId;
  final String name;
  final String sku;
  final String category;
  final int quantity;
  final String unit;
  final String? locationId;
  final int? reorderLevel;
  final double? cost;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const InventoryItem({
    this.id,
    required this.tenantId,
    required this.name,
    required this.sku,
    required this.category,
    required this.quantity,
    required this.unit,
    this.locationId,
    this.reorderLevel,
    this.cost,
    this.createdAt,
    this.updatedAt,
  });

  factory InventoryItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return InventoryItem(
      id: doc.id,
      tenantId: data['tenantId'] ?? '',
      name: data['name'] ?? '',
      sku: data['sku'] ?? '',
      category: data['category'] ?? '',
      quantity: data['quantity'] ?? 0,
      unit: data['unit'] ?? '',
      locationId: data['locationId'],
      reorderLevel: data['reorderLevel'],
      cost: (data['cost'] as num?)?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'tenantId': tenantId,
        'name': name,
        'sku': sku,
        'category': category,
        'quantity': quantity,
        'unit': unit,
        if (locationId != null) 'locationId': locationId,
        if (reorderLevel != null) 'reorderLevel': reorderLevel,
        if (cost != null) 'cost': cost,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  InventoryItem copyWith({
    String? id,
    String? tenantId,
    String? name,
    String? sku,
    String? category,
    int? quantity,
    String? unit,
    String? locationId,
    int? reorderLevel,
    double? cost,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      locationId: locationId ?? this.locationId,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      cost: cost ?? this.cost,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Warehouse model for Supply Chain & Operations
class Warehouse {
  final String? id;
  final String tenantId;
  final String name;
  final String location;
  final String? managerId;
  final double? capacity;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Warehouse({
    this.id,
    required this.tenantId,
    required this.name,
    required this.location,
    this.managerId,
    this.capacity,
    this.createdAt,
    this.updatedAt,
  });

  factory Warehouse.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Warehouse(
      id: doc.id,
      tenantId: data['tenantId'] ?? '',
      name: data['name'] ?? '',
      location: data['location'] ?? '',
      managerId: data['managerId'],
      capacity: (data['capacity'] as num?)?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'tenantId': tenantId,
        'name': name,
        'location': location,
        if (managerId != null) 'managerId': managerId,
        if (capacity != null) 'capacity': capacity,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
