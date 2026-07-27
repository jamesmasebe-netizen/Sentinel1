import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _parseDate(dynamic date) {
  if (date == null) return null;
  if (date is Timestamp) return date.toDate();
  if (date is String) return DateTime.tryParse(date);
  return null;
}

dynamic _formatDate(DateTime? date) {
  if (date == null) return null;
  return Timestamp.fromDate(date);
}

class InventoryItem {
  final String id;
  final String sku;
  final String name;
  final String description;
  final String itemType;
  final String unitOfMeasure;
  final Map<String, dynamic>? weight;
  final Map<String, dynamic>? dimensions;
  final String valuationMethod;
  final Map<String, dynamic>? standardCost;
  final int leadTimeDays;
  final double safetyStock;
  final double reorderPoint;
  final bool isConfigurable;
  final bool isActive;
  final String lifecycleStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double stockLevel;
  final String? warehouseId;
  final String? aisle;
  final String? rack;
  final String? bin;

  InventoryItem({
    required this.id,
    required this.sku,
    required this.name,
    this.description = '',
    required this.itemType,
    required this.unitOfMeasure,
    this.weight,
    this.dimensions,
    required this.valuationMethod,
    this.standardCost,
    this.leadTimeDays = 0,
    this.safetyStock = 0.0,
    this.reorderPoint = 0.0,
    this.isConfigurable = false,
    this.isActive = true,
    required this.lifecycleStatus,
    this.createdAt,
    this.updatedAt,
    this.stockLevel = 0.0,
    this.warehouseId,
    this.aisle,
    this.rack,
    this.bin,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json, String id) {
    return InventoryItem(
      id: id,
      sku: json['sku'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      itemType: json['item_type'] ?? '',
      unitOfMeasure: json['unit_of_measure'] ?? '',
      weight:
          json['weight'] != null
              ? Map<String, dynamic>.from(json['weight'])
              : null,
      dimensions:
          json['dimensions'] != null
              ? Map<String, dynamic>.from(json['dimensions'])
              : null,
      valuationMethod: json['valuation_method'] ?? '',
      standardCost:
          json['standard_cost'] != null
              ? Map<String, dynamic>.from(json['standard_cost'])
              : null,
      leadTimeDays: json['lead_time_days']?.toInt() ?? 0,
      safetyStock: (json['safety_stock'] ?? 0).toDouble(),
      reorderPoint: (json['reorder_point'] ?? 0).toDouble(),
      isConfigurable: json['is_configurable'] ?? false,
      isActive: json['is_active'] ?? true,
      lifecycleStatus: json['lifecycle_status'] ?? '',
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      stockLevel: (json['stock_level'] ?? 0).toDouble(),
      warehouseId: json['warehouse_id'] as String?,
      aisle: json['aisle'] as String?,
      rack: json['rack'] as String?,
      bin: json['bin'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sku': sku,
      'name': name,
      'description': description,
      'item_type': itemType,
      'unit_of_measure': unitOfMeasure,
      if (weight != null) 'weight': weight,
      if (dimensions != null) 'dimensions': dimensions,
      'valuation_method': valuationMethod,
      if (standardCost != null) 'standard_cost': standardCost,
      'lead_time_days': leadTimeDays,
      'safety_stock': safetyStock,
      'reorder_point': reorderPoint,
      'is_configurable': isConfigurable,
      'is_active': isActive,
      'lifecycle_status': lifecycleStatus,
      'created_at': _formatDate(createdAt),
      'updated_at': _formatDate(updatedAt),
      'stock_level': stockLevel,
      'warehouse_id': warehouseId,
      'aisle': aisle,
      'rack': rack,
      'bin': bin,
    };
  }
}

class Warehouse {
  final String id;
  final String name;
  final String code;
  final String type;
  final Map<String, dynamic>? address;
  final String? managerId;
  final String status;

  Warehouse({
    required this.id,
    required this.name,
    required this.code,
    required this.type,
    this.address,
    this.managerId,
    required this.status,
  });

  factory Warehouse.fromJson(Map<String, dynamic> json, String id) {
    return Warehouse(
      id: id,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      type: json['type'] ?? '',
      address:
          json['address'] != null
              ? Map<String, dynamic>.from(json['address'])
              : null,
      managerId: json['manager_id'],
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'type': type,
      if (address != null) 'address': address,
      if (managerId != null) 'manager_id': managerId,
      'status': status,
    };
  }
}

class PurchaseOrder {
  final String id;
  final String poNumber;
  final String? vendorId;
  final String? warehouseId;
  final String status;
  final DateTime? orderDate;
  final DateTime? expectedDeliveryDate;
  final String currency;
  final double totalAmount;

  PurchaseOrder({
    required this.id,
    required this.poNumber,
    this.vendorId,
    this.warehouseId,
    required this.status,
    this.orderDate,
    this.expectedDeliveryDate,
    this.currency = 'USD',
    this.totalAmount = 0.0,
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json, String id) {
    return PurchaseOrder(
      id: id,
      poNumber: json['po_number'] ?? '',
      vendorId: json['vendor_id'],
      warehouseId: json['warehouse_id'],
      status: json['status'] ?? '',
      orderDate: _parseDate(json['order_date']),
      expectedDeliveryDate: _parseDate(json['expected_delivery_date']),
      currency: json['currency'] ?? 'USD',
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'po_number': poNumber,
      if (vendorId != null) 'vendor_id': vendorId,
      if (warehouseId != null) 'warehouse_id': warehouseId,
      'status': status,
      'order_date': _formatDate(orderDate),
      'expected_delivery_date': _formatDate(expectedDeliveryDate),
      'currency': currency,
      'total_amount': totalAmount,
    };
  }
}

class PurchaseOrderLine {
  final String id;
  final String? itemId;
  final double quantityOrdered;
  final double quantityReceived;
  final double unitPrice;

  PurchaseOrderLine({
    required this.id,
    this.itemId,
    this.quantityOrdered = 0.0,
    this.quantityReceived = 0.0,
    this.unitPrice = 0.0,
  });

  factory PurchaseOrderLine.fromJson(Map<String, dynamic> json, String id) {
    return PurchaseOrderLine(
      id: id,
      itemId: json['item_id'],
      quantityOrdered: (json['quantity_ordered'] ?? 0).toDouble(),
      quantityReceived: (json['quantity_received'] ?? 0).toDouble(),
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (itemId != null) 'item_id': itemId,
      'quantity_ordered': quantityOrdered,
      'quantity_received': quantityReceived,
      'unit_price': unitPrice,
    };
  }
}

class Asset {
  final String id;
  final String assetTag;
  final String name;
  final String category;
  final String serialNumber;
  final String manufacturer;
  final String model;
  final String status;
  final String? warehouseId;
  final String? locationId;
  final Map<String, dynamic>? financials;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Asset({
    required this.id,
    required this.assetTag,
    required this.name,
    required this.category,
    this.serialNumber = '',
    this.manufacturer = '',
    this.model = '',
    required this.status,
    this.warehouseId,
    this.locationId,
    this.financials,
    this.createdAt,
    this.updatedAt,
  });

  factory Asset.fromJson(Map<String, dynamic> json, String id) {
    return Asset(
      id: id,
      assetTag: json['asset_tag'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      serialNumber: json['serial_number'] ?? '',
      manufacturer: json['manufacturer'] ?? '',
      model: json['model'] ?? '',
      status: json['status'] ?? '',
      warehouseId: json['warehouse_id'],
      locationId: json['location_id'],
      financials:
          json['financials'] != null
              ? Map<String, dynamic>.from(json['financials'])
              : null,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'asset_tag': assetTag,
      'name': name,
      'category': category,
      'serial_number': serialNumber,
      'manufacturer': manufacturer,
      'model': model,
      'status': status,
      if (warehouseId != null) 'warehouse_id': warehouseId,
      if (locationId != null) 'location_id': locationId,
      if (financials != null) 'financials': financials,
      'created_at': _formatDate(createdAt),
      'updated_at': _formatDate(updatedAt),
    };
  }
}

class SalesOrder {
  final String id;
  final String orderNumber;
  final String accountId;
  final String status;
  final DateTime? orderDate;
  final double totalAmount;

  SalesOrder({
    required this.id,
    required this.orderNumber,
    required this.accountId,
    required this.status,
    this.orderDate,
    this.totalAmount = 0.0,
  });

  factory SalesOrder.fromJson(Map<String, dynamic> json, String id) {
    return SalesOrder(
      id: id,
      orderNumber: json['order_number'] ?? '',
      accountId: json['account_id'] ?? '',
      status: json['status'] ?? '',
      orderDate: _parseDate(json['order_date']),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_number': orderNumber,
      'account_id': accountId,
      'status': status,
      'order_date': _formatDate(orderDate),
      'total_amount': totalAmount,
    };
  }
}

class TransferOrder {
  final String id;
  final String orderNumber;
  final String sourceLocation;
  final String destinationLocation;
  final String status;
  final DateTime? orderDate;

  TransferOrder({
    required this.id,
    required this.orderNumber,
    required this.sourceLocation,
    required this.destinationLocation,
    required this.status,
    this.orderDate,
  });

  factory TransferOrder.fromJson(Map<String, dynamic> json, String id) {
    return TransferOrder(
      id: id,
      orderNumber: json['order_number'] ?? '',
      sourceLocation: json['source_location'] ?? '',
      destinationLocation: json['destination_location'] ?? '',
      status: json['status'] ?? '',
      orderDate: _parseDate(json['order_date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_number': orderNumber,
      'source_location': sourceLocation,
      'destination_location': destinationLocation,
      'status': status,
      'order_date': _formatDate(orderDate),
    };
  }
}

class WarehouseBinLocation {
  final String id;
  final String warehouseId;
  final String binCode;
  final String aisle;
  final String rack;
  final String level;
  final String zone;
  final String? itemId;
  final double currentQuantity;
  final double maxCapacity;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WarehouseBinLocation({
    required this.id,
    required this.warehouseId,
    required this.binCode,
    this.aisle = '',
    this.rack = '',
    this.level = '',
    this.zone = '',
    this.itemId,
    this.currentQuantity = 0.0,
    this.maxCapacity = 0.0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory WarehouseBinLocation.fromJson(Map<String, dynamic> json, String id) {
    return WarehouseBinLocation(
      id: id,
      warehouseId: json['warehouse_id'] ?? '',
      binCode: json['bin_code'] ?? '',
      aisle: json['aisle'] ?? '',
      rack: json['rack'] ?? '',
      level: json['level'] ?? '',
      zone: json['zone'] ?? '',
      itemId: json['item_id'],
      currentQuantity: (json['current_quantity'] ?? 0).toDouble(),
      maxCapacity: (json['max_capacity'] ?? 0).toDouble(),
      isActive: json['is_active'] ?? true,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'warehouse_id': warehouseId,
      'bin_code': binCode,
      'aisle': aisle,
      'rack': rack,
      'level': level,
      'zone': zone,
      if (itemId != null) 'item_id': itemId,
      'current_quantity': currentQuantity,
      'max_capacity': maxCapacity,
      'is_active': isActive,
      'created_at': _formatDate(createdAt),
      'updated_at': _formatDate(updatedAt),
    };
  }
}

class VendorPerformanceMetric {
  final String id;
  final String vendorId;
  final String vendorName;
  final String period;
  final double onTimeDeliveryRate;
  final double qualityRejectionRate;
  final double avgLeadTimeDays;
  final double totalSpend;
  final String rating;
  final DateTime? evaluatedAt;
  final DateTime? createdAt;

  VendorPerformanceMetric({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    this.period = '',
    this.onTimeDeliveryRate = 0.0,
    this.qualityRejectionRate = 0.0,
    this.avgLeadTimeDays = 0.0,
    this.totalSpend = 0.0,
    this.rating = 'Average',
    this.evaluatedAt,
    this.createdAt,
  });

  factory VendorPerformanceMetric.fromJson(
    Map<String, dynamic> json,
    String id,
  ) {
    return VendorPerformanceMetric(
      id: id,
      vendorId: json['vendor_id'] ?? '',
      vendorName: json['vendor_name'] ?? '',
      period: json['period'] ?? '',
      onTimeDeliveryRate: (json['on_time_delivery_rate'] ?? 0).toDouble(),
      qualityRejectionRate: (json['quality_rejection_rate'] ?? 0).toDouble(),
      avgLeadTimeDays: (json['avg_lead_time_days'] ?? 0).toDouble(),
      totalSpend: (json['total_spend'] ?? 0).toDouble(),
      rating: json['rating'] ?? 'Average',
      evaluatedAt: _parseDate(json['evaluated_at']),
      createdAt: _parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vendor_id': vendorId,
      'vendor_name': vendorName,
      'period': period,
      'on_time_delivery_rate': onTimeDeliveryRate,
      'quality_rejection_rate': qualityRejectionRate,
      'avg_lead_time_days': avgLeadTimeDays,
      'total_spend': totalSpend,
      'rating': rating,
      'evaluated_at': _formatDate(evaluatedAt),
      'created_at': _formatDate(createdAt),
    };
  }
}

class MrpSuggestion {
  final String id;
  final String itemId;
  final int suggestedQuantity;
  final String type;
  final String status;
  final String reason;

  MrpSuggestion({
    required this.id,
    required this.itemId,
    required this.suggestedQuantity,
    required this.type,
    required this.status,
    required this.reason,
  });

  factory MrpSuggestion.fromJson(Map<String, dynamic> json, String id) {
    return MrpSuggestion(
      id: id,
      itemId: json['itemId'] as String? ?? '',
      suggestedQuantity: (json['suggestedQuantity'] as num?)?.toInt() ?? 0,
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
    );
  }
}
