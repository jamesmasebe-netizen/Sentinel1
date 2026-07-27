import 'package:cloud_firestore/cloud_firestore.dart';

class BpfStageDefinition {
  final String id;
  final String title;
  final String description;
  final String expectedRecordType; // e.g. 'lead', 'project'

  const BpfStageDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.expectedRecordType,
  });
}

class BpfDefinition {
  final String id;
  final String title;
  final List<BpfStageDefinition> stages;

  const BpfDefinition({
    required this.id,
    required this.title,
    required this.stages,
  });
}

class BpfInstance {
  final String id;
  final String bpfTypeId; // e.g., 'lead_to_cash'
  final String currentStageId;
  final String status; // 'in_progress', 'completed', 'abandoned'
  final Map<String, String> linkedRecordIds; // e.g. {'leadId': 'abc', 'projectId': 'xyz'}
  final DateTime startedAt;
  final DateTime stageStartedAt;

  BpfInstance({
    required this.id,
    required this.bpfTypeId,
    required this.currentStageId,
    required this.status,
    required this.linkedRecordIds,
    required this.startedAt,
    required this.stageStartedAt,
  });

  factory BpfInstance.fromMap(Map<String, dynamic> data, String id) {
    return BpfInstance(
      id: id,
      bpfTypeId: data['bpfTypeId'] ?? '',
      currentStageId: data['currentStageId'] ?? '',
      status: data['status'] ?? 'in_progress',
      linkedRecordIds: Map<String, String>.from(data['linkedRecordIds'] ?? {}),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      stageStartedAt: (data['stageStartedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bpfTypeId': bpfTypeId,
      'currentStageId': currentStageId,
      'status': status,
      'linkedRecordIds': linkedRecordIds,
      'startedAt': Timestamp.fromDate(startedAt),
      'stageStartedAt': Timestamp.fromDate(stageStartedAt),
    };
  }

  BpfInstance copyWith({
    String? currentStageId,
    String? status,
    Map<String, String>? linkedRecordIds,
    DateTime? stageStartedAt,
  }) {
    return BpfInstance(
      id: id,
      bpfTypeId: bpfTypeId,
      currentStageId: currentStageId ?? this.currentStageId,
      status: status ?? this.status,
      linkedRecordIds: linkedRecordIds ?? this.linkedRecordIds,
      startedAt: startedAt,
      stageStartedAt: stageStartedAt ?? this.stageStartedAt,
    );
  }
}
