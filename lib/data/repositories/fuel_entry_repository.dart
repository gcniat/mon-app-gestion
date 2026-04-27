import 'package:sqflite/sqflite.dart';
import '../../core/constants.dart';
import '../database/database_helper.dart';
import '../models/fuel_entry.dart';

class FuelEntryRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<int> insert(FuelEntry entry) async {
    final db = await _db.database;
    return db.insert(AppConstants.tableFuelEntries, entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<FuelEntry>> getByVehicle(int vehicleId) async {
    final db = await _db.database;
    final maps = await db.query(
      AppConstants.tableFuelEntries,
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'date DESC',
    );
    return maps.map(FuelEntry.fromMap).toList();
  }

  Future<List<FuelEntry>> getAll() async {
    final db = await _db.database;
    final maps = await db.query(AppConstants.tableFuelEntries, orderBy: 'date DESC');
    return maps.map(FuelEntry.fromMap).toList();
  }

  Future<int> update(FuelEntry entry) async {
    final db = await _db.database;
    return db.update(AppConstants.tableFuelEntries, entry.toMap(),
        where: 'id = ?', whereArgs: [entry.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return db.delete(AppConstants.tableFuelEntries,
        where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalCostByVehicle(int vehicleId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT SUM(total_cost) as total FROM ${AppConstants.tableFuelEntries} WHERE vehicle_id = ?',
      [vehicleId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
