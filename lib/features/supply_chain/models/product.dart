class Product {
  final String id;
  final String name;
  final String sku;
  final double price;
  final int stockQuantity;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.price,
    required this.stockQuantity,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      sku: json['sku'] as String,
      price: (json['price'] as num).toDouble(),
      stockQuantity: json['stockQuantity'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'price': price,
      'stockQuantity': stockQuantity,
    };
  }
}
