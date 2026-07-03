class JournalEntry {
  final String id;
  final String accountId;
  final double amount;
  final DateTime date;
  final String description;

  JournalEntry({
    required this.id,
    required this.accountId,
    required this.amount,
    required this.date,
    required this.description,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String,
      accountId: json['accountId'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountId': accountId,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
    };
  }
}
