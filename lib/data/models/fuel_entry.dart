class FuelEntry {
  final int? id;
  final int vehicleId;
  final String date;
  final double liters;
  final double pricePerLiter;
  final double totalCost;
  final int? odometer;
  final String? notes;
  final String createdAt;

  const FuelEntry({
    this.id,
    required this.vehicleId,
    required this.date,
    required this.liters,
    required this.pricePerLiter,
    required this.totalCost,
    this.odometer,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'vehicle_id': vehicleId,
        'date': date,
        'liters': liters,
        'price_per_liter': pricePerLiter,
        'total_cost': totalCost,
        'odometer': odometer,
        'notes': notes,
        'created_at': createdAt,
      };

  factory FuelEntry.fromMap(Map<String, dynamic> map) => FuelEntry(
        id: map['id'] as int?,
        vehicleId: map['vehicle_id'] as int,
        date: map['date'] as String,
        liters: (map['liters'] as num).toDouble(),
        pricePerLiter: (map['price_per_liter'] as num).toDouble(),
        totalCost: (map['total_cost'] as num).toDouble(),
        odometer: map['odometer'] as int?,
        notes: map['notes'] as String?,
        createdAt: map['created_at'] as String,
      );

  FuelEntry copyWith({
    int? id,
    int? vehicleId,
    String? date,
    double? liters,
    double? pricePerLiter,
    double? totalCost,
    int? odometer,
    String? notes,
    String? createdAt,
  }) =>
      FuelEntry(
        id: id ?? this.id,
        vehicleId: vehicleId ?? this.vehicleId,
        date: date ?? this.date,
        liters: liters ?? this.liters,
        pricePerLiter: pricePerLiter ?? this.pricePerLiter,
        totalCost: totalCost ?? this.totalCost,
        odometer: odometer ?? this.odometer,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
      );
}
