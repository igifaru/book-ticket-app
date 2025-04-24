import 'package:flutter/foundation.dart';
import '../models/route.dart';
import '../utils/database_helper.dart';

class RouteService extends ChangeNotifier {
  final DatabaseHelper _databaseHelper;
  bool _isInitialized = false;
  bool _loading = false;
  List<BusRoute> _routes = [];

  RouteService({required DatabaseHelper databaseHelper}) : _databaseHelper = databaseHelper;

  bool get isInitialized => _isInitialized;
  bool get loading => _loading;
  List<BusRoute> get routes => List.unmodifiable(_routes);

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _loading = true;
      notifyListeners();
      await _loadRoutes();
      _isInitialized = true;
    } catch (e) {
      debugPrint('RouteService: Error initializing service: $e');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadRoutes() async {
    final routeMaps = await _databaseHelper.getAllRoutes();
    _routes = routeMaps.map((map) => BusRoute.fromMap(map)).toList();
  }

  Future<List<BusRoute>> getAllRoutes() async {
    if (!_isInitialized) await initialize();
    return _routes;
  }

  Future<BusRoute?> getRouteById(int id) async {
    if (!_isInitialized) await initialize();
    return _routes.firstWhere((route) => route.id == id);
  }

  Future<BusRoute> addRoute(BusRoute route) async {
    if (!_isInitialized) await initialize();

    final id = await _databaseHelper.insertRoute(route.toMap());
    final newRoute = route.copyWith(id: id);
    _routes.add(newRoute);
    notifyListeners();
    return newRoute;
  }

  Future<void> updateRoute(BusRoute route) async {
    if (!_isInitialized) await initialize();

    await _databaseHelper.updateRoute(route.toMap());
    final index = _routes.indexWhere((r) => r.id == route.id);
    if (index != -1) {
      _routes[index] = route;
      notifyListeners();
    }
  }

  Future<void> deleteRoute(int id) async {
    if (!_isInitialized) await initialize();

    await _databaseHelper.deleteRoute(id);
    _routes.removeWhere((route) => route.id == id);
    notifyListeners();
  }

  Future<List<BusRoute>> searchRoutes(String query) async {
    if (!_isInitialized) await initialize();

    final lowercaseQuery = query.toLowerCase();
    return _routes.where((route) {
      return route.fromLocation.toLowerCase().contains(lowercaseQuery) ||
             route.toLocation.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  Future<List<BusRoute>> getPopularRoutes({int limit = 5}) async {
    if (!_isInitialized) await initialize();
    
    // TODO: Implement actual popularity calculation based on bookings
    // For now, return the first 5 routes
    return _routes.take(limit).toList();
  }

  void dispose() {
    _isInitialized = false;
    _routes.clear();
    super.dispose();
  }
}