class Quote {
  final String id;
  final String opportunityId;
  final double totalAmount;
  final DateTime expirationDate;

  Quote({
    required this.id,
    required this.opportunityId,
    required this.totalAmount,
    required this.expirationDate,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'] as String,
      opportunityId: json['opportunityId'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      expirationDate: DateTime.parse(json['expirationDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'opportunityId': opportunityId,
      'totalAmount': totalAmount,
      'expirationDate': expirationDate.toIso8601String(),
    };
  }
}
