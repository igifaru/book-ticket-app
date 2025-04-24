import 'package:flutter/foundation.dart';
import '../models/bus.dart';
import '../utils/database_helper.dart';
import 'package:intl/intl.dart';

class BusService extends ChangeNotifier {
  final DatabaseHelper _databaseHelper;
  List<Bus> _buses = [];
  bool _loading = false;
  bool _isInitialized = false;
  bool _initializing = false;

  BusService({
    required DatabaseHelper databaseHelper,
  }) : _databaseHelper = databaseHelper {
    // Initialize in constructor
    initialize().catchError((e) {
      debugPrint('BusService: Error during initialization: $e');
    });
  }

  List<Bus> get buses => List.unmodifiable(_buses);
  bool get loading => _loading;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized || _initializing) return;

    _initializing = true;
    _loading = true;
    
    try {
      debugPrint('BusService: Starting initialization...');
      await _databaseHelper.database;
      
      // Load buses in a microtask to avoid blocking the UI
      await Future.microtask(() async {
        final buses = await _loadBuses();
        _buses = buses;
        _isInitialized = true;
        debugPrint('BusService: Initialization complete with ${buses.length} buses');
      });
    } catch (e, stackTrace) {
      debugPrint('BusService: Error during initialization: $e');
      debugPrint('BusService: Stack trace: $stackTrace');
      _isInitialized = false;
      _buses = [];
    } finally {
      _loading = false;
      _initializing = false;
      notifyListeners();
    }
  }

  Future<List<Bus>> _loadBuses() async {
    try {
      debugPrint('BusService: Loading all buses...');
      final List<Map<String, dynamic>> maps = await _databaseHelper.getAllBuses();
      return maps.map((map) => Bus.fromMap(map)).toList();
    } catch (e) {
      debugPrint('BusService: Error loading buses: $e');
      return [];
    }
  }

  Future<List<Bus>> getAllBuses() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _buses;
  }

  Future<Bus?> getBusById(int id) async {
    try {
      final map = await _databaseHelper.getBusById(id);
      return map != null ? Bus.fromMap(map) : null;
    } catch (e) {
      debugPrint('Error getting bus by id: $e');
      return null;
    }
  }

  Future<Bus> createBus(Bus bus) async {
    try {
      final id = await _databaseHelper.insertBus(bus.toMap());
      final newBus = bus.copyWith(id: id);
      _buses = [..._buses, newBus];
      notifyListeners();
      return newBus;
    } catch (e) {
      debugPrint('Error creating bus: $e');
      rethrow;
    }
  }

  Future<Bus> updateBus(Bus bus) async {
    try {
      if (bus.id == null) throw Exception('Bus ID is required for update');
      await _databaseHelper.updateBus(bus.id!, bus.toMap());
      _buses = _buses.map((b) => b.id == bus.id ? bus : b).toList();
      notifyListeners();
      return bus;
    } catch (e) {
      debugPrint('Error updating bus: $e');
      rethrow;
    }
  }

  Future<void> deleteBus(int id) async {
    try {
      await _databaseHelper.deleteBus(id);
      _buses = _buses.where((b) => b.id != id).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting bus: $e');
      rethrow;
    }
  }

  Future<List<Bus>> searchBuses({
    required int routeId,
    required String date,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      debugPrint('Searching buses for routeId: $routeId and date: $date');

      final buses = _buses.where((bus) {
        if (bus.routeId != routeId || bus.status != 'active') return false;
        final busDate = DateFormat('yyyy-MM-dd').format(bus.travelDate);
        return busDate == date;
      }).toList();

      if (buses.isEmpty) {
        debugPrint('No buses found for route $routeId and date $date');
        return [];
      }

      // Get all bookings for the given date to check seat availability
      final bookings = await _databaseHelper.query(
        'bookings',
        where: 'journeyDate = ? AND status != ?',
        whereArgs: [date, 'cancelled'],
      );

      debugPrint('Found ${bookings.length} bookings for date $date');

      // Calculate available seats for each bus
      final busesWithAvailability = buses.map((bus) {
        final busBookings = bookings.where((booking) => booking['busId'] == bus.id);
        final bookedSeats = busBookings.fold<int>(0, (sum, booking) => sum + (booking['numberOfSeats'] as int));
        final availableSeats = bus.totalSeats - bookedSeats;
        return bus.copyWith(availableSeats: availableSeats);
      }).where((bus) => bus.availableSeats > 0).toList();

      debugPrint('Returning ${busesWithAvailability.length} available buses');
      return busesWithAvailability;
    } catch (e) {
      debugPrint('Error searching buses: $e');
      return [];
    }
  }

  List<Bus> get activeBuses => _buses.where((bus) => bus.status == 'active').toList();

  Future<void> updateBusAvailability(int busId, int availableSeats) async {
    try {
      final bus = _buses.firstWhere((b) => b.id == busId);
      final updatedBus = bus.copyWith(availableSeats: availableSeats);
      await updateBus(updatedBus);
    } catch (e) {
      debugPrint('Error updating bus availability: $e');
      rethrow;
    }
  }
}