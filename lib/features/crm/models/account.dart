class Account {
  final String id;
  final String name;
  final String industry;
  final String website;

  Account({
    required this.id,
    required this.name,
    required this.industry,
    required this.website,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      name: json['name'] as String,
      industry: json['industry'] as String,
      website: json['website'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'industry': industry, 'website': website};
  }
}
