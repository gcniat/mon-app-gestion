import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);
    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tableVehicles} (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        name         TEXT    NOT NULL,
        brand        TEXT    NOT NULL,
        model        TEXT    NOT NULL,
        license_plate TEXT   NOT NULL,
        created_at   TEXT    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableFuelEntries} (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id      INTEGER NOT NULL,
        date            TEXT    NOT NULL,
        liters          REAL    NOT NULL,
        price_per_liter REAL    NOT NULL,
        total_cost      REAL    NOT NULL,
        odometer        INTEGER,
        notes           TEXT,
        created_at      TEXT    NOT NULL,
        FOREIGN KEY (vehicle_id) REFERENCES ${AppConstants.tableVehicles}(id)
          ON DELETE CASCADE
      )
    ''');
  }
}
