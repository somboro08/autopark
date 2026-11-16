import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/parking_center.dart';
import '../models/vehicle.dart';
import '../models/parking_session.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final path = join(documentsDir.path, 'autopark_mvp.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE parking_centers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        max_hours_delay INTEGER DEFAULT 24,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plate TEXT NOT NULL,
        owner_name TEXT NOT NULL,
        owner_phone TEXT,
        center_id INTEGER NOT NULL,
        qr_code TEXT,
        numeric_code TEXT,
        photo_path TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (center_id) REFERENCES parking_centers (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE parking_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER NOT NULL,
        center_id INTEGER NOT NULL,
        entry_time TEXT NOT NULL,
        exit_time TEXT,
        status INTEGER DEFAULT 0,
        notes TEXT,
        FOREIGN KEY (vehicle_id) REFERENCES vehicles (id),
        FOREIGN KEY (center_id) REFERENCES parking_centers (id)
      )
    ''');
  }

  // ---------- Parking Centers ----------

  Future<int> insertCenter(ParkingCenter center) async {
    final database = await db;
    return await database.insert('parking_centers', center.toMap());
  }

  Future<List<ParkingCenter>> getCenters() async {
    final database = await db;
    final maps = await database.query('parking_centers', orderBy: 'name ASC');
    return maps.map((m) => ParkingCenter.fromMap(m)).toList();
  }

  Future<ParkingCenter?> getCenterById(int id) async {
    final database = await db;
    final maps = await database.query(
      'parking_centers',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return ParkingCenter.fromMap(maps.first);
  }

  Future<int> updateCenter(ParkingCenter center) async {
    final database = await db;
    return await database.update(
      'parking_centers',
      center.toMap(),
      where: 'id = ?',
      whereArgs: [center.id],
    );
  }

  Future<int> deleteCenter(int id) async {
    final database = await db;
    return await database.delete('parking_centers', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- Vehicles ----------

  Future<int> insertVehicle(Vehicle vehicle) async {
    final database = await db;
    return await database.insert('vehicles', vehicle.toMap());
  }

  Future<List<Vehicle>> getVehiclesByCenter(int centerId) async {
    final database = await db;
    final maps = await database.query(
      'vehicles',
      where: 'center_id = ?',
      whereArgs: [centerId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Vehicle.fromMap(m)).toList();
  }

  Future<Vehicle?> getVehicleById(int id) async {
    final database = await db;
    final maps = await database.query(
      'vehicles',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Vehicle.fromMap(maps.first);
  }

  Future<List<Vehicle>> searchVehicles(String query) async {
    final database = await db;
    final maps = await database.query(
      'vehicles',
      where: 'plate LIKE ? OR owner_name LIKE ? OR numeric_code LIKE ? OR qr_code LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Vehicle.fromMap(m)).toList();
  }

  Future<Vehicle?> getVehicleByPlate(String plate) async {
    final database = await db;
    final maps = await database.query(
      'vehicles',
      where: 'plate = ?',
      whereArgs: [plate],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Vehicle.fromMap(maps.first);
  }

  Future<Vehicle?> getVehicleByQrCode(String qrCode) async {
    final database = await db;
    final maps = await database.query(
      'vehicles',
      where: 'qr_code = ?',
      whereArgs: [qrCode],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Vehicle.fromMap(maps.first);
  }

  Future<Vehicle?> getVehicleByNumericCode(String code) async {
    final database = await db;
    final maps = await database.query(
      'vehicles',
      where: 'numeric_code = ?',
      whereArgs: [code],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Vehicle.fromMap(maps.first);
  }

  Future<int> updateVehicle(Vehicle vehicle) async {
    final database = await db;
    return await database.update(
      'vehicles',
      vehicle.toMap(),
      where: 'id = ?',
      whereArgs: [vehicle.id],
    );
  }

  Future<int> deleteVehicle(int id) async {
    final database = await db;
    return await database.delete('vehicles', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- Parking Sessions ----------

  Future<int> insertSession(ParkingSession session) async {
    final database = await db;
    return await database.insert('parking_sessions', session.toMap());
  }

  Future<List<ParkingSession>> getSessionsByCenterAndDate(
    int centerId,
    DateTime date,
  ) async {
    final database = await db;
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final maps = await database.query(
      'parking_sessions',
      where:
          'center_id = ? AND entry_time >= ? AND entry_time < ?',
      whereArgs: [centerId, start.toIso8601String(), end.toIso8601String()],
      orderBy: 'entry_time DESC',
    );
    return maps.map((m) => ParkingSession.fromMap(m)).toList();
  }

  Future<List<ParkingSession>> getActiveSessionsByCenter(int centerId) async {
    final database = await db;
    final maps = await database.query(
      'parking_sessions',
      where: 'center_id = ? AND status = ?',
      whereArgs: [centerId, SessionStatus.active.index],
      orderBy: 'entry_time DESC',
    );
    return maps.map((m) => ParkingSession.fromMap(m)).toList();
  }

  Future<ParkingSession?> getActiveSessionForVehicle(int vehicleId) async {
    final database = await db;
    final maps = await database.query(
      'parking_sessions',
      where: 'vehicle_id = ? AND status = ?',
      whereArgs: [vehicleId, SessionStatus.active.index],
      orderBy: 'entry_time DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ParkingSession.fromMap(maps.first);
  }

  Future<int> updateSession(ParkingSession session) async {
    final database = await db;
    return await database.update(
      'parking_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<int> deleteSession(int id) async {
    final database = await db;
    return await database.delete('parking_sessions', where: 'id = ?', whereArgs: [id]);
  }

  /// Seeds a demo center with a few vehicles and sessions so the MVP is
  /// immediately explorable. Only runs when the database is empty.
  Future<void> seedDemoDataIfEmpty() async {
    final database = await db;
    final count = Sqflite.firstIntValue(
      await database.rawQuery('SELECT COUNT(*) FROM parking_centers'),
    );
    if (count != null && count > 0) return;

    final now = DateTime.now();

    final centerId = await insertCenter(ParkingCenter(
      name: 'Parking Central Cotonou',
      address: 'Avenue Steinmetz, Cotonou',
      maxHoursDelay: 24,
    ));

    final demoVehicles = [
      {
        'plate': 'AB-123-CD',
        'owner': 'Jean Houngbo',
        'phone': '+229 97 00 11 22',
        'code': '1001',
      },
      {
        'plate': 'EF-456-GH',
        'owner': 'Aïcha Sossou',
        'phone': '+229 96 33 44 55',
        'code': '1002',
      },
      {
        'plate': 'IJ-789-KL',
        'owner': 'Marcel Dossou',
        'phone': '+229 95 66 77 88',
        'code': '1003',
      },
      {
        'plate': 'MN-012-OP',
        'owner': 'Grâce Kponou',
        'phone': '+229 94 12 34 56',
        'code': '1004',
      },
    ];

    for (var i = 0; i < demoVehicles.length; i++) {
      final v = demoVehicles[i];
      final vehicleId = await insertVehicle(Vehicle(
        plate: v['plate'] as String,
        ownerName: v['owner'] as String,
        ownerPhone: v['phone'] as String,
        centerId: centerId,
        qrCode: 'AUTOPARK-${v['code']}',
        numericCode: v['code'] as String,
      ));

      // i=0: active (in progress), i=1: retrieved, i=2: expired (not retrieved),
      // i=3: active.
      final entry = now.subtract(Duration(hours: 2 + i * 3, minutes: 15));
      DateTime? exit;
      var status = SessionStatus.active;
      if (i == 1) {
        status = SessionStatus.retrieved;
        exit = entry.add(const Duration(hours: 5));
      } else if (i == 2) {
        status = SessionStatus.notRetrieved;
      }
      await insertSession(ParkingSession(
        vehicleId: vehicleId,
        centerId: centerId,
        entryTime: entry,
        exitTime: exit,
        status: status,
      ));
    }
  }

  Future<void> clearAllData() async {
    final database = await db;
    await database.delete('parking_sessions');
    await database.delete('vehicles');
    await database.delete('parking_centers');
  }

  Future<void> close() async {
    final database = await db;
    await database.close();
    _db = null;
  }
}
