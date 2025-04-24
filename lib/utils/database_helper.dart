import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  static const String tableUsers = 'users';
  static const String tableBuses = 'buses';
  static const String tableBookings = 'bookings';
  static const String tablePayments = 'payments';
  static const String tableRoutes = 'routes';
  static const String tableNotifications = 'notifications';

  factory DatabaseHelper() {
    debugPrint('DatabaseHelper: Creating instance');
    return _instance;
  }

  DatabaseHelper._internal();

  bool _isInitializing = false;
  final Completer<void> _initCompleter = Completer<void>();

  Future<Database> get database async {
    debugPrint('DatabaseHelper: Getting database instance');
    if (_database != null) {
      debugPrint('DatabaseHelper: Returning existing database instance');
      return _database!;
    }

    if (_isInitializing) {
      debugPrint('DatabaseHelper: Waiting for initialization to complete');
      await _initCompleter.future;
      return _database!;
    }

    await _initializeDatabase();
    return _database!;
  }

  Future<void> _initializeDatabase() async {
    if (_isInitializing) {
      await _initCompleter.future;
      return;
    }

    _isInitializing = true;
    try {
      debugPrint('DatabaseHelper: Starting database initialization');
      
      // Get database path
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, 'bus_booking.db');
      debugPrint('DatabaseHelper: Database path: $path');

      // Make sure the directory exists
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (e) {
        debugPrint('DatabaseHelper: Error creating directory: $e');
      }

      // Open database
      _database = await openDatabase(
        path,
        version: 1,
        onCreate: (Database db, int version) async {
          debugPrint('DatabaseHelper: Creating database tables');
          await _createTables(db);
          await _createDefaultAdmin(db);
        },
        onOpen: (Database db) async {
          debugPrint('DatabaseHelper: Database opened, checking tables');
          await _ensureTablesExist(db);
        },
      );

      debugPrint('DatabaseHelper: Database initialization successful');
      _initCompleter.complete();
    } catch (e, stackTrace) {
      debugPrint('DatabaseHelper: Error initializing database: $e\n$stackTrace');
      _initCompleter.completeError(e);
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableUsers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'user'
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableRoutes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        fromLocation TEXT NOT NULL,
        toLocation TEXT NOT NULL,
        distance REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableBuses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        busNumber TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        capacity INTEGER NOT NULL,
        type TEXT NOT NULL,
        price REAL NOT NULL,
        routeId INTEGER,
        departureTime TEXT NOT NULL,
        arrivalTime TEXT NOT NULL,
        travelDate TEXT NOT NULL,
        FOREIGN KEY (routeId) REFERENCES $tableRoutes (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableBookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        busId INTEGER NOT NULL,
        seats INTEGER NOT NULL,
        totalAmount REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        createdAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES $tableUsers (id),
        FOREIGN KEY (busId) REFERENCES $tableBuses (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableNotifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        message TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        isRead INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (userId) REFERENCES $tableUsers (id)
      )
    ''');
  }

  Future<void> _ensureTablesExist(Database db) async {
    final tables = [tableUsers, tableRoutes, tableBuses, tableBookings, tableNotifications];
    for (final table in tables) {
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM sqlite_master WHERE type="table" AND name=?', [table])
      );
      if (count == 0) {
        debugPrint('DatabaseHelper: Table $table not found, creating tables');
        await _createTables(db);
        break;
      }
    }
    await _ensureAdminExists(db);
  }

  Future<void> _createDefaultAdmin(Database db) async {
    debugPrint('DatabaseHelper: Creating default admin user');
    try {
      await db.insert(tableUsers, {
        'name': 'System Administrator',
        'email': 'admin@gmail.com',
        'password': 'admin123',
        'role': 'admin'
      });
      debugPrint('DatabaseHelper: Default admin user created successfully');
    } catch (e) {
      debugPrint('DatabaseHelper: Error creating default admin: $e');
    }
  }

  Future<void> _ensureAdminExists(Database db) async {
    final adminCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableUsers WHERE role = ?', ['admin'])
    );
    if (adminCount == 0) {
      await _createDefaultAdmin(db);
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await database;
    return await db.insert(table, values);
  }

  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<List<Map<String, dynamic>>> getAllRoutes() async {
    final db = await database;
    return await db.query('routes');
  }

  Future<Map<String, dynamic>?> getRouteById(int id) async {
    final db = await database;
    final results = await db.query(
      'routes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    return await query(tableUsers);
  }

  Future<List<Map<String, dynamic>>> getAllBuses() async {
    return await query(tableBuses);
  }

  Future<Map<String, dynamic>?> getBusById(int id) async {
    final results = await query(
      tableBuses,
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getAllBookings() async {
    return await query(tableBookings);
  }

  Future<Map<String, dynamic>?> getBookingById(int id) async {
    final results = await query(
      tableBookings,
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getAllPayments() async {
    final db = await database;
    return await db.query(tablePayments);
  }

  Future<List<Map<String, dynamic>>> getPaymentsByDateRange(String startDate, String endDate) async {
    final db = await database;
    return await db.query(
      tablePayments,
      where: 'paymentDate BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
    );
  }

  Future<Map<String, dynamic>?> getPaymentById(int id) async {
    final results = await query(
      tablePayments,
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> insertNotification(Map<String, dynamic> notification) async {
    return await insert(tableNotifications, notification);
  }

  Future<List<Map<String, dynamic>>> getNotificationsForUser(int userId) async {
    return await query(
      tableNotifications,
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  Future<int> updateNotification(int id, Map<String, dynamic> notification) async {
    return await update(
      tableNotifications,
      notification,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteNotification(int id) async {
    return await delete(
      tableNotifications,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getBookingsByUserId(int userId) async {
    final db = await database;
    return await db.query(
      'bookings',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  Future<List<Map<String, dynamic>>> getBookingsByBusId(int busId) async {
    final db = await database;
    return await db.query(
      'bookings',
      where: 'busId = ?',
      whereArgs: [busId],
    );
  }

  Future<List<Map<String, dynamic>>> getUserBookings(int userId) async {
    final db = await database;
    return await db.query(
      'bookings',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  Future<List<Map<String, dynamic>>> getBusBookings(int busId) async {
    final db = await database;
    return await db.query(
      'bookings',
      where: 'busId = ?',
      whereArgs: [busId],
    );
  }

  Future<List<Map<String, dynamic>>> searchBookings({
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    final db = await database;
    return await db.query(
      'bookings',
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    final results = await query(
      tableUsers,
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> insertRoute(Map<String, dynamic> route) async {
    final db = await database;
    return await db.insert('routes', route);
  }

  Future<int> updateRoute(Map<String, dynamic> route) async {
    final db = await database;
    return await db.update(
      'routes',
      route,
      where: 'id = ?',
      whereArgs: [route['id']],
    );
  }

  Future<int> deleteRoute(int id) async {
    final db = await database;
    return await db.delete(
      'routes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertBus(Map<String, dynamic> bus) async {
    return await insert(tableBuses, bus);
  }

  Future<int> updateBus(int id, Map<String, dynamic> bus) async {
    return await update(
      tableBuses,
      bus,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteBus(int id) async {
    return await delete(
      tableBuses,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertBooking(Map<String, dynamic> booking) async {
    return await insert(tableBookings, booking);
  }

  Future<int> updateBooking(int id, Map<String, dynamic> booking) async {
    return await update(
      tableBookings,
      booking,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteBooking(int id) async {
    return await delete(
      tableBookings,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertPayment(Map<String, dynamic> payment) async {
    return await insert(tablePayments, payment);
  }

  Future<int> updatePayment(int id, Map<String, dynamic> payment) async {
    return await update(
      tablePayments,
      payment,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletePayment(int id) async {
    return await delete(
      tablePayments,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}