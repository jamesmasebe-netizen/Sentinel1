class WorkOrder {
  final String id;
  final String title;
  final String description;
  final String status;
  final String? permitId;
  final String? riskAssessmentId;
  final String? contractorId;
  final String? actionItemId;
  final DateTime scheduledDate;

  WorkOrder({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.permitId,
    this.riskAssessmentId,
    this.contractorId,
    this.actionItemId,
    required this.scheduledDate,
  });

  factory WorkOrder.fromJson(Map<String, dynamic> json) {
    return WorkOrder(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      permitId: json['permitId'] as String?,
      riskAssessmentId: json['riskAssessmentId'] as String?,
      contractorId: json['contractorId'] as String?,
      actionItemId: json['actionItemId'] as String?,
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'permitId': permitId,
      'riskAssessmentId': riskAssessmentId,
      'contractorId': contractorId,
      'actionItemId': actionItemId,
      'scheduledDate': scheduledDate.toIso8601String(),
    };
  }
}
