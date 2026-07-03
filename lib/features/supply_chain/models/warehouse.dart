class Warehouse {
  final String id;
  final String name;
  final String location;
  final int capacity;

  Warehouse({
    required this.id,
    required this.name,
    required this.location,
    required this.capacity,
  });

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
      capacity: json['capacity'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'location': location, 'capacity': capacity};
  }
}
