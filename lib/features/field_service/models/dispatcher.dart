class Dispatcher {
  final String id;
  final String name;
  final String region;
  final String contactNumber;

  Dispatcher({
    required this.id,
    required this.name,
    required this.region,
    required this.contactNumber,
  });

  factory Dispatcher.fromJson(Map<String, dynamic> json) {
    return Dispatcher(
      id: json['id'] as String,
      name: json['name'] as String,
      region: json['region'] as String,
      contactNumber: json['contactNumber'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'region': region,
      'contactNumber': contactNumber,
    };
  }
}
