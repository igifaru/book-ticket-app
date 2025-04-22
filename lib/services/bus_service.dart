import 'package:flutter/foundation.dart';
import '../models/bus.dart';
import '../utils/database_helper.dart';
import 'package:intl/intl.dart';

class BusService extends ChangeNotifier {
  final DatabaseHelper _databaseHelper;
  List<Bus> _buses = [];
  bool _loading = false;
  bool _isInitialized = false;

  BusService({
    required DatabaseHelper databaseHelper,
  }) : _databaseHelper = databaseHelper;

  List<Bus> get buses => _buses;
  bool get loading => _loading;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _loading = true;
    notifyListeners();
    
    try {
      debugPrint('BusService: Starting initialization...');
      await _databaseHelper.database;
      await getAllBuses();
      _isInitialized = true;
      debugPrint('BusService: Initialization complete');
    } catch (e, stackTrace) {
      debugPrint('BusService: Error during initialization: $e');
      debugPrint('BusService: Stack trace: $stackTrace');
      _isInitialized = false;
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<List<Bus>> getAllBuses() async {
    if (!_isInitialized && !_loading) {
      await initialize();
    }

    _loading = true;
    notifyListeners();
    
    try {
      debugPrint('BusService: Loading all buses...');
      final List<Map<String, dynamic>> maps = await _databaseHelper.getAllBuses();
      _buses = maps.map((map) => Bus.fromMap(map)).toList();
      debugPrint('BusService: Loaded ${_buses.length} buses');
      return _buses;
    } catch (e, stackTrace) {
      debugPrint('BusService: Error loading buses: $e');
      debugPrint('BusService: Stack trace: $stackTrace');
      _buses = [];
      return [];
    } finally {
      _loading = false;
      notifyListeners();
    }
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
      return bus.copyWith(id: id);
    } catch (e) {
      debugPrint('Error creating bus: $e');
      rethrow;
    }
  }

  Future<Bus> updateBus(Bus bus) async {
    try {
      if (bus.id == null) throw Exception('Bus ID is required for update');
      await _databaseHelper.updateBus(bus.id!, bus.toMap());
      return bus;
    } catch (e) {
      debugPrint('Error updating bus: $e');
      rethrow;
    }
  }

  Future<void> deleteBus(int id) async {
    try {
      await _databaseHelper.deleteBus(id);
    } catch (e) {
      debugPrint('Error deleting bus: $e');
      rethrow;
    }
  }

  Future<List<Bus>> searchBuses({
    required int routeId,
    required String date,
  }) async {
    try {
      _loading = true;
      notifyListeners();

      debugPrint('Searching buses for routeId: $routeId and date: $date');

      // Get all active buses for the route and date
      final List<Map<String, dynamic>> results = await _databaseHelper.query(
        'buses',
        where: 'routeId = ? AND isActive = ?',
        whereArgs: [routeId, 1],
      );

      debugPrint('Found ${results.length} buses for route $routeId');

      if (results.isEmpty) {
        debugPrint('No buses found for route $routeId');
        return [];
      }

      final buses = results.map((map) {
        debugPrint('Bus data: ${map.toString()}');
        final bus = Bus.fromMap(map);
        debugPrint('Bus travel date: ${bus.travelDate.toString()}');
        return bus;
      }).where((bus) {
        final busDate = DateFormat('yyyy-MM-dd').format(bus.travelDate);
        debugPrint('Comparing bus date: $busDate with search date: $date');
        return busDate == date && bus.status == 'active';
      }).toList();
      
      debugPrint('Found ${buses.length} buses for date $date');

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
        
        final bookedSeats = busBookings.fold<int>(
          0, 
          (sum, booking) => sum + (booking['numberOfSeats'] as int)
        );
        
        final availableSeats = bus.totalSeats - bookedSeats;
        debugPrint('Bus ${bus.id}: total seats: ${bus.totalSeats}, booked: $bookedSeats, available: $availableSeats');
        
        return bus.copyWith(
          availableSeats: availableSeats
        );
      }).toList();
      
      // Return only buses with available seats
      final availableBuses = busesWithAvailability.where((bus) => bus.availableSeats > 0).toList();
      debugPrint('Returning ${availableBuses.length} available buses');
      
      return availableBuses;
    } catch (e) {
      debugPrint('Error searching buses: $e');
      return [];
    } finally {
      _loading = false;
      notifyListeners();
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