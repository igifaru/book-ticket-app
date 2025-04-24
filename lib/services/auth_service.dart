import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bus_ticket_booking/utils/database_helper.dart';
import 'package:bus_ticket_booking/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  final DatabaseHelper _databaseHelper;
  final _storage = const FlutterSecureStorage();
  User? _currentUser;
  bool _initialized = false;
  bool _initializing = false;
  final List<VoidCallback> _listeners = [];
  final SharedPreferences _prefs;

  AuthService({required DatabaseHelper databaseHelper, required SharedPreferences prefs})
    : _databaseHelper = databaseHelper,
      _prefs = prefs {
    debugPrint('AuthService: Created');
  }

  User? get currentUser => _currentUser;
  bool get isInitialized => _initialized;
  bool get isAuthenticated => _prefs.getBool('isAuthenticated') ?? false;

  Future<void> initialize() async {
    if (_initialized || _initializing) {
      debugPrint('AuthService: Already initialized or initializing');
      return;
    }

    _initializing = true;
    try {
      debugPrint('AuthService: Starting initialization...');

      // Ensure database is ready
      debugPrint('AuthService: Waiting for database...');
      final db = await _databaseHelper.database;
      debugPrint('AuthService: Database is ready');

      // Check stored credentials
      debugPrint('AuthService: Checking stored credentials...');
      final userId = await _storage.read(key: 'user_id');

      if (userId != null) {
        debugPrint('AuthService: Found stored user ID: $userId');
        try {
          final results = await _databaseHelper.query(
            'users',
            where: 'id = ?',
            whereArgs: [int.parse(userId)],
          );

          if (results.isNotEmpty) {
            _currentUser = User.fromMap(results.first);
            debugPrint('AuthService: Loaded user: ${_currentUser?.email}');
          } else {
            debugPrint('AuthService: No user found for stored ID');
            await _storage.delete(key: 'user_id');
            await _storage.delete(key: 'user_role');
            _currentUser = null;
          }
        } catch (e) {
          debugPrint('AuthService: Error loading user: $e');
          await _storage.delete(key: 'user_id');
          await _storage.delete(key: 'user_role');
          _currentUser = null;
        }
      } else {
        debugPrint('AuthService: No stored credentials found');
        _currentUser = null;
      }

      _initialized = true;
      debugPrint('AuthService: Initialization complete');
      notifyListeners();
    } catch (e) {
      debugPrint('AuthService: Error during initialization: $e');
      _currentUser = null;
      _initialized = false;
      rethrow;
    } finally {
      _initializing = false;
    }
  }

  Future<void> reinitialize() async {
    debugPrint('AuthService: Forcing reinitialization...');
    _initialized = false;
    _initializing = false;
    _currentUser = null;
    notifyListeners();

    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('AuthService: Error clearing storage: $e');
    }

    await initialize();
  }

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
    super.removeListener(listener);
  }

  @override
  void dispose() {
    _listeners.clear();
    super.dispose();
  }

  Future<User> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    String role = 'user',
    String? username,
  }) async {
    try {
      // Check if user already exists
      final existingUser = await _databaseHelper.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );

      if (existingUser.isNotEmpty) {
        throw Exception('User with this email already exists');
      }

      final user = User(
        name: name,
        email: email,
        phone: phone,
        password: password,
        role: role,
        username: username ?? email.split('@')[0],
        createdAt: DateTime.now(),
      );

      final id = await _databaseHelper.insert('users', user.toMap());
      final newUser = user.copyWith(id: id);
      _currentUser = newUser;
      notifyListeners();
      return newUser;
    } catch (e) {
      debugPrint('AuthService: Registration error: $e');
      throw Exception('Failed to register user: $e');
    }
  }

  Future<User> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('AuthService: Attempting login with email: $email');

      final results = await _databaseHelper.query(
        'users',
        where: 'email = ? AND password = ?',
        whereArgs: [email, password],
      );

      debugPrint('AuthService: Login query results: $results');

      if (results.isEmpty) {
        final userWithEmail = await _databaseHelper.query(
          'users',
          where: 'email = ?',
          whereArgs: [email],
        );

        if (userWithEmail.isEmpty) {
          throw Exception('No user found with this email');
        } else {
          throw Exception('Invalid password');
        }
      }

      _currentUser = User.fromMap(results.first);
      debugPrint(
        'AuthService: User logged in successfully: ${_currentUser?.email} with role: ${_currentUser?.role}',
      );

      await _storage.write(key: 'user_id', value: _currentUser!.id.toString());
      await _storage.write(key: 'user_role', value: _currentUser!.role);

      notifyListeners();
      return _currentUser!;
    } catch (e) {
      debugPrint('AuthService: Login error: $e');
      throw Exception('Failed to login: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _storage.delete(key: 'user_id');
      await _storage.delete(key: 'user_role');
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      debugPrint('AuthService: Logout error: $e');
      throw Exception('Failed to logout: $e');
    }
  }

  Future<bool> isAdmin() async {
    try {
      final role = await _storage.read(key: 'user_role');
      return role == 'admin';
    } catch (e) {
      debugPrint('AuthService: Error checking admin status: $e');
      return false;
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      final userId = await _storage.read(key: 'user_id');
      return userId != null;
    } catch (e) {
      debugPrint('AuthService: Error checking login status: $e');
      return false;
    }
  }

  Future<User?> getUserById(int id) async {
    try {
      final results = await _databaseHelper.query(
        'users',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (results.isEmpty) return null;
      return User.fromMap(results.first);
    } catch (e) {
      debugPrint('AuthService: Error getting user by id: $e');
      return null;
    }
  }

  Future<User?> getCurrentUser() async {
    if (_currentUser != null) {
      return _currentUser;
    }

    try {
      final userId = await _storage.read(key: 'user_id');
      if (userId != null) {
        final id = int.parse(userId);
        final user = await getUserById(id);
        _currentUser = user;
        notifyListeners();
        return user;
      }
      return null;
    } catch (e) {
      debugPrint('AuthService: Error getting current user: $e');
      return null;
    }
  }

  Future<List<User>> getAllUsers() async {
    try {
      final List<Map<String, dynamic>> maps = await _databaseHelper.query('users');
      return maps.map((map) => User.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error getting all users: $e');
      throw Exception('Failed to get users: $e');
    }
  }

  Future<void> updateUserStatus(int userId, String status) async {
    try {
      final user = await getUserById(userId);
      if (user == null) throw Exception('User not found');

      final updatedUser = user.copyWith(status: status);
      await _databaseHelper.update(
        'users',
        updatedUser.toMap(),
        where: 'id = ?',
        whereArgs: [userId],
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user status: $e');
      throw Exception('Failed to update user status: $e');
    }
  }

  Future<void> deleteUser(int userId) async {
    try {
      // First check if user exists
      final user = await getUserById(userId);
      if (user == null) throw Exception('User not found');

      // Check if user has any active bookings
      final bookings = await _databaseHelper.query(
        'bookings',
        where: 'userId = ? AND status != ?',
        whereArgs: [userId, 'cancelled'],
      );

      if (bookings.isNotEmpty) {
        throw Exception('Cannot delete user with active bookings');
      }

      // Delete user's bookings
      await _databaseHelper.delete(
        'bookings',
        where: 'userId = ?',
        whereArgs: [userId],
      );

      // Delete user's notifications
      await _databaseHelper.delete(
        'notifications',
        where: 'userId = ?',
        whereArgs: [userId],
      );

      // Finally delete the user
      await _databaseHelper.delete(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting user: $e');
      throw Exception('Failed to delete user: $e');
    }
  }

  Future<void> signIn(String username, String password) async {
    if (!_initialized) await initialize();
    
    // TODO: Implement actual authentication logic
    await _prefs.setBool('isAuthenticated', true);
    await _prefs.setString('currentUser', username);
    notifyListeners();
  }
  
  Future<void> signOut() async {
    if (!_initialized) await initialize();
    
    await _prefs.setBool('isAuthenticated', false);
    await _prefs.remove('currentUser');
    notifyListeners();
  }
}
