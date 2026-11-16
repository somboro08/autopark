import 'dart:math';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/app_user.dart';
import '../models/parking_center.dart';
import '../models/vehicle.dart';
import '../models/parking_session.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  /// Version 2 : ajout des profils utilisateurs (propriétaire / agent),
  /// de la propriété des véhicules et de la préparation du jeton de garde.
  static const int _dbVersion = 2;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final path = join(documentsDir.path, 'autopark_mvp.db');
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
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
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        role TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await _createVehiclesTable(db);

    await db.execute('''
      CREATE TABLE parking_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER NOT NULL,
        center_id INTEGER NOT NULL,
        entry_time TEXT NOT NULL,
        exit_time TEXT,
        status INTEGER DEFAULT 0,
        notes TEXT,
        retrieval_token TEXT,
        FOREIGN KEY (vehicle_id) REFERENCES vehicles (id),
        FOREIGN KEY (center_id) REFERENCES parking_centers (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE center_vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        center_id INTEGER NOT NULL,
        vehicle_id INTEGER NOT NULL,
        registered_at TEXT NOT NULL,
        UNIQUE (center_id, vehicle_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  Future<void> _createVehiclesTable(Database db) async {
    await db.execute('''
      CREATE TABLE vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plate TEXT NOT NULL,
        owner_name TEXT NOT NULL,
        owner_phone TEXT,
        center_id INTEGER,
        owner_id INTEGER,
        model TEXT,
        qr_code TEXT,
        numeric_code TEXT,
        photo_path TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (center_id) REFERENCES parking_centers (id),
        FOREIGN KEY (owner_id) REFERENCES users (id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          role TEXT NOT NULL,
          name TEXT NOT NULL,
          phone TEXT,
          created_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE center_vehicles (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          center_id INTEGER NOT NULL,
          vehicle_id INTEGER NOT NULL,
          registered_at TEXT NOT NULL,
          UNIQUE (center_id, vehicle_id)
        )
      ''');

      await db.execute('''
        CREATE TABLE app_settings (
          key TEXT PRIMARY KEY,
          value TEXT
        )
      ''');

      // Reconstruction de la table vehicles : center_id devient nullable et on
      // ajoute owner_id + model (SQLite ne sait pas modifier une contrainte).
      await db.execute('ALTER TABLE vehicles RENAME TO vehicles_v1');
      await _createVehiclesTable(db);
      await db.execute('''
        INSERT INTO vehicles
          (id, plate, owner_name, owner_phone, center_id, owner_id, model,
           qr_code, numeric_code, photo_path, created_at)
        SELECT
          id, plate, owner_name, owner_phone, center_id, NULL, NULL,
          qr_code, numeric_code, photo_path, created_at
        FROM vehicles_v1
      ''');
      await db.execute('DROP TABLE vehicles_v1');

      await db.execute(
        'ALTER TABLE parking_sessions ADD COLUMN retrieval_token TEXT',
      );
    }
  }

  // ---------- Paramètres applicatifs ----------

  Future<String?> getSetting(String key) async {
    final database = await db;
    final rows = await database.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setSetting(String key, String? value) async {
    final database = await db;
    await database.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ---------- Utilisateurs ----------

  Future<int> insertUser(AppUser user) async {
    final database = await db;
    return await database.insert('users', user.toMap());
  }

  Future<List<AppUser>> getUsers() async {
    final database = await db;
    final maps = await database.query('users', orderBy: 'created_at ASC');
    return maps.map((m) => AppUser.fromMap(m)).toList();
  }

  Future<AppUser?> getUserById(int id) async {
    final database = await db;
    final maps = await database.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return AppUser.fromMap(maps.first);
  }

  Future<int> updateUser(AppUser user) async {
    final database = await db;
    return await database.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    final database = await db;
    return await database.delete('users', where: 'id = ?', whereArgs: [id]);
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

  /// Véhicules enregistrés dans le profil d'un propriétaire.
  Future<List<Vehicle>> getVehiclesByOwner(int ownerId) async {
    final database = await db;
    final maps = await database.query(
      'vehicles',
      where: 'owner_id = ?',
      whereArgs: [ownerId],
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

  /// Le véhicule est-il déjà connu de ce centre ?
  Future<bool> isVehicleKnownByCenter(int centerId, int vehicleId) async {
    final database = await db;
    final maps = await database.query(
      'center_vehicles',
      where: 'center_id = ? AND vehicle_id = ?',
      whereArgs: [centerId, vehicleId],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  /// Rattache un véhicule partagé à un centre (idempotent).
  Future<void> registerVehicleForCenter(int centerId, int vehicleId) async {
    final database = await db;
    await database.insert(
      'center_vehicles',
      {
        'center_id': centerId,
        'vehicle_id': vehicleId,
        'registered_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Nombre de centres distincts où le véhicule a déjà été gardé.
  Future<int> countCentersForVehicle(int vehicleId) async {
    final database = await db;
    final rows = await database.rawQuery(
      'SELECT COUNT(DISTINCT center_id) AS c FROM parking_sessions WHERE vehicle_id = ?',
      [vehicleId],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
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
      where: 'center_id = ? AND entry_time >= ? AND entry_time < ?',
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

  /// Historique complet d'un véhicule, tous centres confondus.
  Future<List<ParkingSession>> getSessionsByVehicle(int vehicleId) async {
    final database = await db;
    final maps = await database.query(
      'parking_sessions',
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'entry_time DESC',
    );
    return maps.map((m) => ParkingSession.fromMap(m)).toList();
  }

  /// Historique de toutes les motos d'un propriétaire, tous centres confondus.
  Future<List<ParkingSession>> getSessionsByOwner(int ownerId) async {
    final database = await db;
    final maps = await database.rawQuery('''
      SELECT s.*
      FROM parking_sessions s
      INNER JOIN vehicles v ON v.id = s.vehicle_id
      WHERE v.owner_id = ?
      ORDER BY s.entry_time DESC
    ''', [ownerId]);
    return maps.map((m) => ParkingSession.fromMap(m)).toList();
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

  // ---------- Données de démonstration ----------

  final Random _random = Random.secure();

  /// Génère un code véhicule unique du type `AUTOPARK-8F3K2`.
  String generateVehicleQrCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final buffer = StringBuffer('AUTOPARK-');
    for (var i = 0; i < 5; i++) {
      buffer.write(alphabet[_random.nextInt(alphabet.length)]);
    }
    return buffer.toString();
  }

  /// Génère un code numérique à 6 chiffres.
  String generateNumericCode() {
    return (100000 + _random.nextInt(900000)).toString();
  }

  /// Seeds demo data (profils, centre, véhicules, sessions) at first launch.
  Future<void> seedDemoDataIfEmpty() async {
    final database = await db;
    final count = Sqflite.firstIntValue(
      await database.rawQuery('SELECT COUNT(*) FROM parking_centers'),
    );
    if (count != null && count > 0) return;

    final now = DateTime.now();

    // --- Profils de démonstration ---
    final agentId = await insertUser(AppUser(
      role: AppRole.agent,
      name: 'Awa Dossou',
      phone: '+229 97 00 00 01',
    ));

    final jeanId = await insertUser(AppUser(
      role: AppRole.owner,
      name: 'Jean Houngbo',
      phone: '+229 97 00 11 22',
    ));

    final aichaId = await insertUser(AppUser(
      role: AppRole.owner,
      name: 'Aïcha Sossou',
      phone: '+229 96 33 44 55',
    ));

    // Le profil agent est sélectionné par défaut sur une base neuve.
    await setSetting('active_user_id', agentId.toString());

    // --- Centre de démonstration ---
    final centerId = await insertCenter(ParkingCenter(
      name: 'Parking Central Cotonou',
      address: 'Avenue Steinmetz, Cotonou',
      maxHoursDelay: 24,
    ));

    // --- Véhicules appartenant aux propriétaires ---
    final demoVehicles = [
      {
        'plate': 'AB-123-CD',
        'owner': 'Jean Houngbo',
        'phone': '+229 97 00 11 22',
        'owner_id': jeanId,
        'model': 'Yamaha Crypton',
        'code': '1001',
      },
      {
        'plate': 'EF-456-GH',
        'owner': 'Aïcha Sossou',
        'phone': '+229 96 33 44 55',
        'owner_id': aichaId,
        'model': 'Haojue HJ110',
        'code': '1002',
      },
      {
        'plate': 'IJ-789-KL',
        'owner': 'Marcel Dossou',
        'phone': '+229 95 66 77 88',
        'owner_id': null,
        'model': 'Bajaj Boxer',
        'code': '1003',
      },
      {
        'plate': 'MN-012-OP',
        'owner': 'Grâce Kponou',
        'phone': '+229 94 12 34 56',
        'owner_id': null,
        'model': 'SanLG SL110',
        'code': '1004',
      },
    ];

    for (var i = 0; i < demoVehicles.length; i++) {
      final v = demoVehicles[i];
      final vehicleId = await insertVehicle(Vehicle(
        plate: v['plate'] as String,
        ownerName: v['owner'] as String,
        ownerPhone: v['phone'] as String,
        ownerId: v['owner_id'] as int?,
        model: v['model'] as String?,
        centerId: centerId,
        qrCode: 'AUTOPARK-${v['code']}',
        numericCode: v['code'] as String,
      ));

      await registerVehicleForCenter(centerId, vehicleId);

      // i=0: en cours, i=1: récupéré, i=2: non récupéré, i=3: en cours.
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

    // Moto appartenant à Jean, pas encore partagée avec un centre : démontre
    // le parcours « j'enregistre ma moto dans mon profil, puis je la partage ».
    await insertVehicle(Vehicle(
      plate: 'QR-456-TU',
      ownerName: 'Jean Houngbo',
      ownerPhone: '+229 97 00 11 22',
      ownerId: jeanId,
      model: 'TVS HLX 125',
      qrCode: 'AUTOPARK-9001',
      numericCode: '9001',
    ));
  }

  Future<void> clearAllData() async {
    final database = await db;
    await database.delete('parking_sessions');
    await database.delete('center_vehicles');
    await database.delete('vehicles');
    await database.delete('parking_centers');
    await database.delete('users');
    await database.delete('app_settings');
  }

  Future<void> close() async {
    final database = await db;
    await database.close();
    _db = null;
  }
}
