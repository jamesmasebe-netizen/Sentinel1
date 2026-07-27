import 'package:cloud_firestore/cloud_firestore.dart';

class EquipmentModel {
  final String? id;
  final String equipmentName;
  final String assetTag;
  final String location;
  final String manufacturer;
  final String category;
  final String status;
  final String? assignedToId;
  final DateTime nextInspectionDate;
  final int daysUntilInspection;
  final String authorId;
  final DateTime createdAt;
  final String tenantId;

  EquipmentModel({
    this.id,
    required this.equipmentName,
    required this.assetTag,
    required this.location,
    required this.manufacturer,
    required this.category,
    required this.status,
    this.assignedToId,
    required this.nextInspectionDate,
    required this.daysUntilInspection,
    required this.authorId,
    required this.createdAt,
    required this.tenantId,
  });

  factory EquipmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return EquipmentModel(
      id: doc.id,
      equipmentName: data['equipmentName'] ?? '',
      assetTag: data['assetTag'] ?? '',
      location: data['location'] ?? '',
      manufacturer: data['manufacturer'] ?? '',
      category: data['category'] ?? '',
      status: data['status'] ?? 'Operational',
      assignedToId: data['assignedToId'],
      nextInspectionDate: data['nextInspectionDate'] != null 
          ? DateTime.tryParse(data['nextInspectionDate']) ?? DateTime.now()
          : DateTime.now(),
      daysUntilInspection: data['daysUntilInspection'] ?? 0,
      authorId: data['authorId'] ?? '',
      createdAt: data['createdAt'] != null 
          ? DateTime.tryParse(data['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      tenantId: data['tenantId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'equipmentName': equipmentName,
      'assetTag': assetTag,
      'location': location,
      'manufacturer': manufacturer,
      'category': category,
      'status': status,
      'assignedToId': assignedToId,
      'nextInspectionDate': nextInspectionDate.toIso8601String(),
      'daysUntilInspection': daysUntilInspection,
      'authorId': authorId,
      'createdAt': createdAt.toIso8601String(),
      'tenantId': tenantId,
    };
  }
}
