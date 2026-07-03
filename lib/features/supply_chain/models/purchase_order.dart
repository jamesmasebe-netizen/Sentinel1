class PurchaseOrder {
  final String id;
  final String supplierId;
  final DateTime orderDate;
  final String status;
  final double totalAmount;

  PurchaseOrder({
    required this.id,
    required this.supplierId,
    required this.orderDate,
    required this.status,
    required this.totalAmount,
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    return PurchaseOrder(
      id: json['id'] as String,
      supplierId: json['supplierId'] as String,
      orderDate: DateTime.parse(json['orderDate'] as String),
      status: json['status'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'supplierId': supplierId,
      'orderDate': orderDate.toIso8601String(),
      'status': status,
      'totalAmount': totalAmount,
    };
  }
}
