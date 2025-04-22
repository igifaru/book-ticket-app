import 'package:flutter/foundation.dart';
import '../models/route.dart';
import '../utils/database_helper.dart';

class RouteService extends ChangeNotifier {
  final DatabaseHelper _databaseHelper;
  List<Route> _routes = [];
  bool _loading = false;
  bool _initialized = false;

  RouteService({
    required DatabaseHelper databaseHelper,
  }) : _databaseHelper = databaseHelper;

  List<Route> get routes => _routes;
  bool get loading => _loading;
  bool get initialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    
    _loading = true;
    notifyListeners();
    try {
      await loadRoutes();
      _initialized = true;
      _loading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('RouteService: Error during initialization: $e');
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadRoutes() async {
    try {
      final List<Map<String, dynamic>> maps = await _databaseHelper.getAllRoutes();
      _routes = maps.map((map) => Route.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error loading routes: $e');
      _routes = [];
    }
  }

  Future<List<Route>> getAllRoutes() async {
    if (!_initialized) {
      await initialize();
    }
    return _routes;
  }

  Future<Route?> getRouteById(int id) async {
    try {
      final map = await _databaseHelper.getRouteById(id);
      return map != null ? Route.fromMap(map) : null;
    } catch (e) {
      debugPrint('Error getting route by id: $e');
      return null;
    }
  }

  Future<Route> createRoute(Route route) async {
    try {
      final id = await _databaseHelper.insertRoute(route.toMap());
      final newRoute = route.copyWith(id: id);
      _routes.add(newRoute);
      notifyListeners();
      return newRoute;
    } catch (e) {
      debugPrint('Error creating route: $e');
      rethrow;
    }
  }

  Future<Route> updateRoute(Route route) async {
    try {
      if (route.id == null) throw Exception('Route ID is required for update');
      await _databaseHelper.updateRoute(route.id!, route.toMap());
      final index = _routes.indexWhere((r) => r.id == route.id);
      if (index != -1) {
        _routes[index] = route;
        notifyListeners();
      }
      return route;
    } catch (e) {
      debugPrint('Error updating route: $e');
      rethrow;
    }
  }

  Future<void> deleteRoute(int id) async {
    try {
      await _databaseHelper.deleteRoute(id);
      _routes.removeWhere((r) => r.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting route: $e');
      rethrow;
    }
  }

  Future<List<Route>> searchRoutes(String query) async {
    try {
      final List<Map<String, dynamic>> results = await _databaseHelper.query(
        'routes',
        where: 'startLocation LIKE ? OR endLocation LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
      );
      return results.map((map) => Route.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to search routes: $e');
    }
  }

  List<Route> get activeRoutes => _routes.where((route) => route.isActive).toList();

  Future<void> toggleRouteStatus(int id) async {
    final route = _routes.firstWhere((r) => r.id == id);
    final updatedRoute = route.copyWith(isActive: !route.isActive);
    await updateRoute(updatedRoute);
  }

  List<String> getAllLocations() {
    final Set<String> locations = {};
    for (final route in _routes) {
      locations.add(route.startLocation);
      locations.add(route.endLocation);
      if (route.viaLocations.isNotEmpty) {
        locations.add(route.viaLocations);
      }
    }
    return locations.toList()..sort();
  }
}