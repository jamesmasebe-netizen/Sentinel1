import 'package:cloud_firestore/cloud_firestore.dart';

class BomLine {
  final String itemId;
  final double quantityRequired;
  final String unitOfMeasure;
  final String notes;

  BomLine({
    required this.itemId,
    required this.quantityRequired,
    required this.unitOfMeasure,
    this.notes = '',
  });

  factory BomLine.fromJson(Map<String, dynamic> json) {
    return BomLine(
      itemId: json['item_id'] ?? '',
      quantityRequired: (json['quantity_required'] ?? 0).toDouble(),
      unitOfMeasure: json['unit_of_measure'] ?? '',
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'quantity_required': quantityRequired,
      'unit_of_measure': unitOfMeasure,
      'notes': notes,
    };
  }
}

class BillOfMaterials {
  final String id;
  final String finishedGoodItemId;
  final String name;
  final String description;
  final List<BomLine> lines;
  final bool isActive;

  BillOfMaterials({
    required this.id,
    required this.finishedGoodItemId,
    required this.name,
    this.description = '',
    required this.lines,
    this.isActive = true,
  });

  factory BillOfMaterials.fromJson(Map<String, dynamic> json, String id) {
    final List<dynamic> linesData = json['lines'] ?? [];
    return BillOfMaterials(
      id: id,
      finishedGoodItemId: json['finished_good_item_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      isActive: json['is_active'] ?? true,
      lines: linesData.map((e) => BomLine.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'finished_good_item_id': finishedGoodItemId,
      'name': name,
      'description': description,
      'is_active': isActive,
      'lines': lines.map((e) => e.toJson()).toList(),
    };
  }
}
