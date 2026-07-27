class CollSource {
  final String name, type;
  const CollSource(this.name, this.type);
}

class ActionItem {
  final String id, collectionName, type, title, status, dueDate, assignee;
  const ActionItem({
    required this.id,
    required this.collectionName,
    required this.type,
    required this.title,
    required this.status,
    required this.dueDate,
    required this.assignee,
  });

  factory ActionItem.fromJson(Map<String, dynamic> json, String id) {
    return ActionItem(
      id: id,
      collectionName: json['collectionName'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      status: json['status'] ?? 'Pending',
      dueDate: json['dueDate'] ?? '',
      assignee: json['assignee'] ?? 'Unassigned',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'collectionName': collectionName,
      'type': type,
      'title': title,
      'status': status,
      'dueDate': dueDate,
      'assignee': assignee,
    };
  }

  ActionItem copyWith({
    String? id,
    String? collectionName,
    String? type,
    String? title,
    String? status,
    String? dueDate,
    String? assignee,
  }) => ActionItem(
    id: id ?? this.id,
    collectionName: collectionName ?? this.collectionName,
    type: type ?? this.type,
    title: title ?? this.title,
    status: status ?? this.status,
    dueDate: dueDate ?? this.dueDate,
    assignee: assignee ?? this.assignee,
  );
}
