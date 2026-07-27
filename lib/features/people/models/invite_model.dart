import 'package:cloud_firestore/cloud_firestore.dart';

class InviteModel {
  final String id;
  final String email;
  final String role;
  final String status;
  final DateTime? createdAt;
  final String? tenantId;

  InviteModel({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
    this.createdAt,
    this.tenantId,
  });

  factory InviteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data was null');
    }

    return InviteModel(
      id: doc.id,
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? 'user',
      status: data['status'] as String? ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      tenantId: data['tenantId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'role': role,
      'status': status,
      'createdAt':
          createdAt != null
              ? Timestamp.fromDate(createdAt!)
              : FieldValue.serverTimestamp(),
      'tenantId': tenantId,
    };
  }
}
