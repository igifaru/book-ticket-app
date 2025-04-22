import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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

  Future<Database> get database async {
    debugPrint('DatabaseHelper: Getting database instance');
    if (_database != null) {
      debugPrint('DatabaseHelper: Returning existing database instance');
      return _database!;
    }
    
    // Wait if initialization is in progress
    while (_isInitializing) {
      debugPrint('DatabaseHelper: Waiting for initialization to complete...');
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    _isInitializing = true;
    try {
      debugPrint('DatabaseHelper: Initializing new database instance');
      _database = await init();
      debugPrint('DatabaseHelper: Database initialization successful');
      return _database!;
    } catch (e) {
      debugPrint('DatabaseHelper: Error initializing database: $e');
      _isInitializing = false;
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  Future<Database> init() async {
    debugPrint('DatabaseHelper: Starting database initialization');
    
    try {
      // Get the database path
      String databasesPath;
      if (Platform.isAndroid) {
        debugPrint('DatabaseHelper: Getting Android documents directory');
        final documentsDirectory = await getApplicationDocumentsDirectory();
        databasesPath = documentsDirectory.path;
      } else {
        debugPrint('DatabaseHelper: Getting default database path');
        databasesPath = await getDatabasesPath();
      }
      
      final path = join(databasesPath, 'bus_booking.db');
      debugPrint('DatabaseHelper: Database path: $path');

      // Make sure the directory exists
      try {
        debugPrint('DatabaseHelper: Creating database directory');
        await Directory(dirname(path)).create(recursive: true);
      } catch (e) {
        debugPrint('DatabaseHelper: Error creating directory: $e');
      }

      // Open the database
      debugPrint('DatabaseHelper: Opening database');
      final db = await openDatabase(
        path,
        version: 2,
        onCreate: (Database db, int version) async {
          debugPrint('DatabaseHelper: Creating tables...');
          await _createTables(db);
          await _createDefaultAdmin(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          debugPrint('DatabaseHelper: Upgrading database from $oldVersion to $newVersion');
          
          // Drop and recreate the buses table
          await db.execute('DROP TABLE IF EXISTS buses');
          
          // Create buses table with correct schema
          await db.execute('''
            CREATE TABLE buses (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              busNumber TEXT NOT NULL,
              capacity INTEGER NOT NULL,
              type TEXT NOT NULL,
              isActive INTEGER DEFAULT 1,
              busName TEXT NOT NULL,
              routeId INTEGER NOT NULL,
              departureTime TEXT NOT NULL,
              arrivalTime TEXT NOT NULL,
              totalSeats INTEGER NOT NULL,
              availableSeats INTEGER NOT NULL,
              price REAL NOT NULL,
              fromLocation TEXT NOT NULL,
              toLocation TEXT NOT NULL,
              status TEXT DEFAULT 'active',
              createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
              travelDate TEXT NOT NULL,
              FOREIGN KEY (routeId) REFERENCES routes (id)
            )
          ''');
        },
      );

      debugPrint('DatabaseHelper: Database opened successfully');
      return db;
    } catch (e) {
      debugPrint('DatabaseHelper: Error in init: $e');
      rethrow;
    }
  }

  Future<void> _createTables(Database db) async {
    debugPrint('DatabaseHelper: Creating tables');
    try {
      // Create users table
      await db.execute('''
        CREATE TABLE $tableUsers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          email TEXT UNIQUE NOT NULL,
          phone TEXT NOT NULL,
          password TEXT NOT NULL,
          role TEXT NOT NULL DEFAULT 'user',
          username TEXT,
          createdAt TEXT NOT NULL
        )
      ''');

      // Create routes table
      await db.execute('''
        CREATE TABLE $tableRoutes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          startLocation TEXT NOT NULL,
          endLocation TEXT NOT NULL,
          viaLocations TEXT,
          description TEXT,
          distance REAL NOT NULL,
          estimatedDuration INTEGER NOT NULL,
          isActive INTEGER NOT NULL DEFAULT 1
        )
      ''');

      // Create buses table with correct schema
      await db.execute('''
        CREATE TABLE buses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          busNumber TEXT NOT NULL,
          capacity INTEGER NOT NULL,
          type TEXT NOT NULL,
          isActive INTEGER DEFAULT 1,
          busName TEXT NOT NULL,
          routeId INTEGER NOT NULL,
          departureTime TEXT NOT NULL,
          arrivalTime TEXT NOT NULL,
          totalSeats INTEGER NOT NULL,
          availableSeats INTEGER NOT NULL,
          price REAL NOT NULL,
          fromLocation TEXT NOT NULL,
          toLocation TEXT NOT NULL,
          status TEXT DEFAULT 'active',
          createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
          travelDate TEXT NOT NULL,
          FOREIGN KEY (routeId) REFERENCES routes (id)
        )
      ''');

      // Create bookings table
      await db.execute('''
        CREATE TABLE $tableBookings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER NOT NULL,
          busId INTEGER NOT NULL,
          numberOfSeats INTEGER NOT NULL,
          totalAmount REAL NOT NULL,
          status TEXT NOT NULL DEFAULT 'pending',
          paymentStatus TEXT NOT NULL DEFAULT 'pending',
          fromLocation TEXT NOT NULL,
          toLocation TEXT NOT NULL,
          bookingDate TEXT NOT NULL,
          journeyDate TEXT NOT NULL,
          seatNumber TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          confirmedBy INTEGER,
          confirmedAt TEXT,
          FOREIGN KEY (userId) REFERENCES $tableUsers (id),
          FOREIGN KEY (busId) REFERENCES $tableBuses (id),
          FOREIGN KEY (confirmedBy) REFERENCES $tableUsers (id)
        )
      ''');

      // Create payments table
      await db.execute('''
        CREATE TABLE $tablePayments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          bookingId INTEGER NOT NULL,
          amount REAL NOT NULL,
          paymentMethod TEXT NOT NULL,
          transactionId TEXT NOT NULL,
          paymentDate TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'pending',
          FOREIGN KEY (bookingId) REFERENCES $tableBookings (id)
        )
      ''');

      // Create notifications table
      await db.execute('''
        CREATE TABLE $tableNotifications (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER,
          message TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          isRead INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (userId) REFERENCES $tableUsers (id)
        )
      ''');

      debugPrint('DatabaseHelper: Tables created successfully');
    } catch (e) {
      debugPrint('DatabaseHelper: Error creating tables: $e');
      rethrow;
    }
  }

  Future<void> _createDefaultAdmin(Database db) async {
    debugPrint('DatabaseHelper: Creating default admin user');
    try {
      await db.insert(tableUsers, {
        'name': 'System Administrator',
        'email': 'admin@gmail.com',
        'phone': '1234567890',
        'password': 'admin123',
        'role': 'admin',
        'username': 'admin',
        'createdAt': DateTime.now().toIso8601String()
      });
      debugPrint('DatabaseHelper: Default admin user created successfully');
    } catch (e) {
      debugPrint('DatabaseHelper: Error creating default admin: $e');
      rethrow;
    }
  }

  Future<void> ensureAdminExists() async {
    debugPrint('DatabaseHelper: Ensuring admin user exists');
    try {
      final db = _database;
      if (db == null) {
        debugPrint('DatabaseHelper: Database not initialized');
        return;
      }

      final List<Map<String, dynamic>> users = await db.query(
        tableUsers,
        where: 'email = ?',
        whereArgs: ['admin@gmail.com'],
      );

      if (users.isEmpty) {
        debugPrint('DatabaseHelper: Creating default admin user');
        await _createDefaultAdmin(db);
      }
    } catch (e) {
      debugPrint('DatabaseHelper: Error ensuring admin exists: $e');
      rethrow;
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

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<List<Map<String, dynamic>>> getAllRoutes() async {
    return await query(tableRoutes);
  }

  Future<Map<String, dynamic>?> getRouteById(int id) async {
    final results = await query(
      tableRoutes,
      where: 'id = ?',
      whereArgs: [id],
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
    return await insert(tableRoutes, route);
  }

  Future<int> updateRoute(int id, Map<String, dynamic> route) async {
    return await update(
      tableRoutes,
      route,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteRoute(int id) async {
    return await delete(
      tableRoutes,
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