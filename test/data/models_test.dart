import 'package:flutter_test/flutter_test.dart';
import 'package:mon_app_gestion/data/models/fuel_entry.dart';
import 'package:mon_app_gestion/data/models/vehicle.dart';

void main() {
  group('Vehicle', () {
    const vehicle = Vehicle(
      id: 1,
      name: 'Ma voiture',
      brand: 'Toyota',
      model: 'Corolla',
      licensePlate: 'ABC-123',
      createdAt: '2024-01-01',
    );

    test('toMap contient tous les champs', () {
      final map = vehicle.toMap();
      expect(map['id'], 1);
      expect(map['name'], 'Ma voiture');
      expect(map['brand'], 'Toyota');
      expect(map['model'], 'Corolla');
      expect(map['license_plate'], 'ABC-123');
      expect(map['created_at'], '2024-01-01');
    });

    test('fromMap reconstruit correctement', () {
      final restored = Vehicle.fromMap(vehicle.toMap());
      expect(restored.id, vehicle.id);
      expect(restored.name, vehicle.name);
      expect(restored.brand, vehicle.brand);
      expect(restored.model, vehicle.model);
      expect(restored.licensePlate, vehicle.licensePlate);
      expect(restored.createdAt, vehicle.createdAt);
    });

    test('copyWith modifie seulement les champs spécifiés', () {
      final updated = vehicle.copyWith(name: 'Nouveau nom');
      expect(updated.name, 'Nouveau nom');
      expect(updated.brand, vehicle.brand);
      expect(updated.id, vehicle.id);
    });

    test('copyWith sans argument retourne les mêmes valeurs', () {
      final copy = vehicle.copyWith();
      expect(copy.name, vehicle.name);
      expect(copy.licensePlate, vehicle.licensePlate);
    });
  });

  group('FuelEntry', () {
    const entry = FuelEntry(
      id: 10,
      vehicleId: 1,
      date: '2024-06-15',
      liters: 45.5,
      pricePerLiter: 1.65,
      totalCost: 75.075,
      odometer: 15000,
      notes: 'Station Esso',
      createdAt: '2024-06-15',
    );

    test('toMap contient tous les champs', () {
      final map = entry.toMap();
      expect(map['vehicle_id'], 1);
      expect(map['date'], '2024-06-15');
      expect(map['liters'], 45.5);
      expect(map['price_per_liter'], 1.65);
      expect(map['total_cost'], 75.075);
      expect(map['odometer'], 15000);
      expect(map['notes'], 'Station Esso');
    });

    test('fromMap reconstruit correctement', () {
      final restored = FuelEntry.fromMap(entry.toMap());
      expect(restored.vehicleId, entry.vehicleId);
      expect(restored.liters, entry.liters);
      expect(restored.pricePerLiter, entry.pricePerLiter);
      expect(restored.totalCost, entry.totalCost);
      expect(restored.odometer, entry.odometer);
      expect(restored.notes, entry.notes);
    });

    test('fromMap gère les champs optionnels null', () {
      final map = entry.toMap()..['odometer'] = null..['notes'] = null;
      final restored = FuelEntry.fromMap(map);
      expect(restored.odometer, isNull);
      expect(restored.notes, isNull);
    });

    test('copyWith modifie seulement les champs spécifiés', () {
      final updated = entry.copyWith(liters: 50.0, notes: 'Modifié');
      expect(updated.liters, 50.0);
      expect(updated.notes, 'Modifié');
      expect(updated.vehicleId, entry.vehicleId);
      expect(updated.date, entry.date);
    });
  });
}
