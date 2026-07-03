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
  ActionItem copyWith({String? status}) => ActionItem(
    id: id,
    collectionName: collectionName,
    type: type,
    title: title,
    status: status ?? this.status,
    dueDate: dueDate,
    assignee: assignee,
  );
}
