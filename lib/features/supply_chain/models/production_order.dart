import 'package:cloud_firestore/cloud_firestore.dart';

class ProductionOrder {
  final String id;
  final String bomId;
  final String finishedGoodItemId;
  final int quantityToProduce;
  final int quantityProduced;
  final String status; // PLANNED, IN_PROGRESS, COMPLETED, CANCELLED
  final DateTime? startDate;
  final DateTime? completionDate;
  final String assignedToUserId;
  final String warehouseId;

  ProductionOrder({
    required this.id,
    required this.bomId,
    required this.finishedGoodItemId,
    required this.quantityToProduce,
    this.quantityProduced = 0,
    required this.status,
    this.startDate,
    this.completionDate,
    this.assignedToUserId = '',
    this.warehouseId = '',
  });

  factory ProductionOrder.fromJson(Map<String, dynamic> json, String id) {
    return ProductionOrder(
      id: id,
      bomId: json['bom_id'] ?? '',
      finishedGoodItemId: json['finished_good_item_id'] ?? '',
      quantityToProduce: (json['quantity_to_produce'] ?? 0).toInt(),
      quantityProduced: (json['quantity_produced'] ?? 0).toInt(),
      status: json['status'] ?? 'PLANNED',
      startDate: json['start_date'] != null ? (json['start_date'] as Timestamp).toDate() : null,
      completionDate: json['completion_date'] != null ? (json['completion_date'] as Timestamp).toDate() : null,
      assignedToUserId: json['assigned_to_user_id'] ?? '',
      warehouseId: json['warehouse_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bom_id': bomId,
      'finished_good_item_id': finishedGoodItemId,
      'quantity_to_produce': quantityToProduce,
      'quantity_produced': quantityProduced,
      'status': status,
      'start_date': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'completion_date': completionDate != null ? Timestamp.fromDate(completionDate!) : null,
      'assigned_to_user_id': assignedToUserId,
      'warehouse_id': warehouseId,
    };
  }
}
