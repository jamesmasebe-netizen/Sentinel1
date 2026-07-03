class Opportunity {
  final String id;
  final String accountId;
  final String name;
  final double amount;
  final String stage;

  Opportunity({
    required this.id,
    required this.accountId,
    required this.name,
    required this.amount,
    required this.stage,
  });

  factory Opportunity.fromJson(Map<String, dynamic> json) {
    return Opportunity(
      id: json['id'] as String,
      accountId: json['accountId'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      stage: json['stage'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountId': accountId,
      'name': name,
      'amount': amount,
      'stage': stage,
    };
  }
}
