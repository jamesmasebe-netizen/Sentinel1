class Invoice {
  final String id;
  final String customerId;
  final double totalAmount;
  final String status;
  final DateTime dueDate;

  Invoice({
    required this.id,
    required this.customerId,
    required this.totalAmount,
    required this.status,
    required this.dueDate,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: json['status'] as String,
      dueDate: DateTime.parse(json['dueDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'totalAmount': totalAmount,
      'status': status,
      'dueDate': dueDate.toIso8601String(),
    };
  }
}
