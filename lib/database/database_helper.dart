import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' ;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'bus_booking.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        phone TEXT,
        role TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Buses table
    await db.execute('''
      CREATE TABLE buses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bus_number TEXT NOT NULL,
        bus_name TEXT NOT NULL,
        total_seats INTEGER NOT NULL,
        available_seats INTEGER NOT NULL,
        route TEXT NOT NULL,
        departure_time TEXT NOT NULL,
        arrival_time TEXT NOT NULL,
        price REAL NOT NULL,
        status TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Bookings table
    await db.execute('''
      CREATE TABLE bookings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        bus_id INTEGER NOT NULL,
        seat_number TEXT NOT NULL,
        booking_date TEXT NOT NULL,
        journey_date TEXT NOT NULL,
        total_amount REAL NOT NULL,
        payment_status TEXT NOT NULL,
        payment_method TEXT,
        transaction_id TEXT,
        status TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (bus_id) REFERENCES buses (id)
      )
    ''');

    // Payments table
    await db.execute('''
      CREATE TABLE payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        booking_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_method TEXT NOT NULL,
        transaction_id TEXT,
        status TEXT NOT NULL,
        payment_date TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (booking_id) REFERENCES bookings (id)
      )
    ''');
  }

  // Helper methods for database operations
  Future<int> insert(String table, Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> query(String table) async {
    Database db = await database;
    return await db.query(table);
  }

  Future<List<Map<String, dynamic>>> queryWithWhere(
      String table, String where, List<dynamic> whereArgs) async {
    Database db = await database;
    return await db.query(table, where: where, whereArgs: whereArgs);
  }

  Future<int> update(String table, Map<String, dynamic> row, String where,
      List<dynamic> whereArgs) async {
    Database db = await database;
    return await db.update(table, row, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
      String table, String where, List<dynamic> whereArgs) async {
    Database db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }
}
