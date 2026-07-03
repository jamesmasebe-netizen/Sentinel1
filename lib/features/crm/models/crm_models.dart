import 'package:cloud_firestore/cloud_firestore.dart';

enum DealStage {
  lead,
  qualified,
  proposal,
  negotiation,
  closedWon,
  closedLost
}

class Deal {
  final String id;
  final String title;
  final String customerName;
  final double value;
  final DealStage stage;
  final DateTime createdAt;
  final String? assignedTo;

  Deal({
    required this.id,
    required this.title,
    required this.customerName,
    required this.value,
    required this.stage,
    required this.createdAt,
    this.assignedTo,
  });

  factory Deal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Parse stage safely
    DealStage parsedStage = DealStage.lead;
    final stageString = data['stage'] as String?;
    if (stageString != null) {
      for (final s in DealStage.values) {
        if (s.name == stageString) {
          parsedStage = s;
          break;
        }
      }
    }

    return Deal(
      id: doc.id,
      title: data['title'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      value: (data['value'] as num?)?.toDouble() ?? 0.0,
      stage: parsedStage,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      assignedTo: data['assignedTo'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'customerName': customerName,
      'value': value,
      'stage': stage.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'assignedTo': assignedTo,
    };
  }

  Deal copyWith({
    String? id,
    String? title,
    String? customerName,
    double? value,
    DealStage? stage,
    DateTime? createdAt,
    String? assignedTo,
  }) {
    return Deal(
      id: id ?? this.id,
      title: title ?? this.title,
      customerName: customerName ?? this.customerName,
      value: value ?? this.value,
      stage: stage ?? this.stage,
      createdAt: createdAt ?? this.createdAt,
      assignedTo: assignedTo ?? this.assignedTo,
    );
  }
}
