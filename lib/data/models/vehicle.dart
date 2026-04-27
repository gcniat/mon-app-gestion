class Vehicle {
  final int? id;
  final String name;
  final String brand;
  final String model;
  final String licensePlate;
  final String createdAt;

  const Vehicle({
    this.id,
    required this.name,
    required this.brand,
    required this.model,
    required this.licensePlate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'brand': brand,
        'model': model,
        'license_plate': licensePlate,
        'created_at': createdAt,
      };

  factory Vehicle.fromMap(Map<String, dynamic> map) => Vehicle(
        id: map['id'] as int?,
        name: map['name'] as String,
        brand: map['brand'] as String,
        model: map['model'] as String,
        licensePlate: map['license_plate'] as String,
        createdAt: map['created_at'] as String,
      );

  Vehicle copyWith({
    int? id,
    String? name,
    String? brand,
    String? model,
    String? licensePlate,
    String? createdAt,
  }) =>
      Vehicle(
        id: id ?? this.id,
        name: name ?? this.name,
        brand: brand ?? this.brand,
        model: model ?? this.model,
        licensePlate: licensePlate ?? this.licensePlate,
        createdAt: createdAt ?? this.createdAt,
      );
}
