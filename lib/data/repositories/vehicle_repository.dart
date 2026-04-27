import 'package:sqflite/sqflite.dart';
import '../../core/constants.dart';
import '../database/database_helper.dart';
import '../models/vehicle.dart';

class VehicleRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<int> insert(Vehicle vehicle) async {
    final db = await _db.database;
    return db.insert(AppConstants.tableVehicles, vehicle.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Vehicle>> getAll() async {
    final db = await _db.database;
    final maps = await db.query(AppConstants.tableVehicles, orderBy: 'name ASC');
    return maps.map(Vehicle.fromMap).toList();
  }

  Future<Vehicle?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query(AppConstants.tableVehicles,
        where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Vehicle.fromMap(maps.first);
  }

  Future<int> update(Vehicle vehicle) async {
    final db = await _db.database;
    return db.update(AppConstants.tableVehicles, vehicle.toMap(),
        where: 'id = ?', whereArgs: [vehicle.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return db.delete(AppConstants.tableVehicles, where: 'id = ?', whereArgs: [id]);
  }
}
