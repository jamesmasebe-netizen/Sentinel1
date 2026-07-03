class ChartOfAccounts {
  final String id;
  final String name;
  final String code;
  final String type;

  ChartOfAccounts({
    required this.id,
    required this.name,
    required this.code,
    required this.type,
  });

  factory ChartOfAccounts.fromJson(Map<String, dynamic> json) {
    return ChartOfAccounts(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'code': code, 'type': type};
  }
}
