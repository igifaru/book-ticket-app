import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:bus_ticket_booking/models/booking.dart';
import 'package:bus_ticket_booking/models/bus.dart';
import 'package:bus_ticket_booking/utils/database_helper.dart';
import 'bus_service.dart';

class BookingService extends ChangeNotifier {
  final DatabaseHelper _databaseHelper;
  BusService? _busService;
  List<Booking> _bookings = [];
  bool _loading = false;
  bool _isInitialized = false;
  bool _isInitializing = false;
  String? _error;

  BookingService({
    required DatabaseHelper databaseHelper,
    BusService? busService,
  }) : _databaseHelper = databaseHelper {
    _busService = busService;
  }

  List<Booking> get bookings => List.unmodifiable(_bookings);
  bool get loading => _loading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  void setBusService(BusService busService) {
    _busService = busService;
    if (!_isInitialized && !_isInitializing) {
      Future.microtask(() => initialize());
    }
  }

  Future<void> initialize() async {
    if (_isInitialized || _isInitializing) return;
    if (_busService == null) {
      debugPrint('BookingService: Waiting for BusService to be set');
      return;
    }

    _isInitializing = true;
    _error = null;
    
    // Use microtask to avoid calling setState during build
    Future.microtask(() {
      _loading = true;
      notifyListeners();
    });

    try {
      debugPrint('BookingService: Starting initialization...');
      
      // Wait for bus service to be initialized
      if (!_busService!.isInitialized) {
        debugPrint('BookingService: Waiting for BusService to initialize...');
        await _busService!.initialize();
      }

      // Load all bookings
      final bookingsData = await _databaseHelper.getAllBookings();
      _bookings = bookingsData.map((data) => Booking.fromMap(data)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _isInitialized = true;
      debugPrint('BookingService: Initialization complete with ${_bookings.length} bookings');
    } catch (e) {
      debugPrint('BookingService: Error during initialization: $e');
      _error = e.toString();
      _bookings = [];
    } finally {
      _isInitializing = false;
      _loading = false;
      // Use microtask to avoid calling setState during build
      Future.microtask(() {
        notifyListeners();
      });
    }
  }

  Future<List<Booking>> getAllBookings() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_loading) {
      // Return current bookings if we're already loading
      return _bookings;
    }

    _loading = true;
    notifyListeners();

    try {
      debugPrint('BookingService: Loading all bookings...');
      final List<Map<String, dynamic>> maps = await _databaseHelper.getAllBookings();
      _bookings = maps.map((map) => Booking.fromMap(map)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      debugPrint('BookingService: Loaded ${_bookings.length} bookings');
      return List.unmodifiable(_bookings);
    } catch (e, stackTrace) {
      debugPrint('BookingService: Error loading bookings: $e');
      debugPrint('BookingService: Stack trace: $stackTrace');
      return _bookings; // Return current bookings on error
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Booking?> getBookingById(int id) async {
    try {
      final map = await _databaseHelper.getBookingById(id);
      return map != null ? Booking.fromMap(map) : null;
    } catch (e) {
      debugPrint('Error getting booking by id: $e');
      return null;
    }
  }

  Future<Booking> createBooking(Booking booking) async {
    if (!_isInitialized) await initialize();
    
    try {
      if (_busService == null) {
        throw Exception('BusService not available');
      }

      final bus = await _busService!.getBusById(booking.busId);
      if (bus == null) {
        throw Exception('Bus not found');
      }

      if (bus.availableSeats < booking.numberOfSeats) {
        throw Exception('Not enough seats available');
      }

      final id = await _databaseHelper.insertBooking(booking.toMap());
      final newBooking = booking.copyWith(id: id);
      
      // Update bus available seats
      await _busService!.updateBusAvailability(
        booking.busId,
        bus.availableSeats - booking.numberOfSeats,
      );

      _bookings.insert(0, newBooking);
      notifyListeners();
      return newBooking;
    } catch (e) {
      debugPrint('BookingService: Error creating booking: $e');
      rethrow;
    }
  }

  Future<void> updateBooking(Booking booking) async {
    if (!_isInitialized) await initialize();
    
    try {
      await _databaseHelper.updateBooking(booking.id!, booking.toMap());
      final index = _bookings.indexWhere((b) => b.id == booking.id);
      if (index != -1) {
        _bookings[index] = booking;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('BookingService: Error updating booking: $e');
      rethrow;
    }
  }

  Future<void> deleteBooking(int id) async {
    if (!_isInitialized) await initialize();
    
    try {
      await _databaseHelper.deleteBooking(id);
      _bookings.removeWhere((booking) => booking.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('BookingService: Error deleting booking: $e');
      rethrow;
    }
  }

  Future<bool> updateBookingStatus(int id, String status, {int? adminId}) async {
    try {
      final booking = await getBookingById(id);
      if (booking == null) return false;

      Map<String, dynamic> updateData = {
        'status': status,
        'confirmedBy': null,
        'confirmedAt': null,
      };

      if (status == 'confirmed') {
        updateData['confirmedBy'] = adminId;
        updateData['confirmedAt'] = DateTime.now().toIso8601String();
      }

      await _databaseHelper.update(
        'bookings',
        updateData,
        where: 'id = ?',
        whereArgs: [id],
      );

      // Force refresh and notify listeners
      _bookings = await getAllBookings();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating booking status: $e');
      return false;
    }
  }

  Future<List<Booking>> getBookingsByUserId(int userId) async {
    if (!_isInitialized) await initialize();
    
    try {
      final bookingsData = await _databaseHelper.getBookingsByUserId(userId);
      return bookingsData.map((data) => Booking.fromMap(data)).toList();
    } catch (e) {
      debugPrint('BookingService: Error getting bookings for user $userId: $e');
      rethrow;
    }
  }

  Future<List<Booking>> getBookingsByBusId(int busId) async {
    if (!_isInitialized) await initialize();
    
    try {
      final bookingsData = await _databaseHelper.getBookingsByBusId(busId);
      return bookingsData.map((data) => Booking.fromMap(data)).toList();
    } catch (e) {
      debugPrint('BookingService: Error getting bookings for bus $busId: $e');
      rethrow;
    }
  }

  Future<bool> updatePaymentStatus(int id, String paymentStatus) async {
    try {
      final booking = await getBookingById(id);
      if (booking == null) return false;

      final updatedBooking = booking.copyWith(paymentStatus: paymentStatus);
      await updateBooking(updatedBooking);
      return true;
    } catch (e) {
      debugPrint('Error updating payment status: $e');
      return false;
    }
  }

  Future<bool> confirmBooking(int bookingId) async {
    try {
      final booking = _bookings.firstWhere((b) => b.id == bookingId);
      final updatedBooking = booking.copyWith(status: 'confirmed');
      await updateBooking(updatedBooking);
      return true;
    } catch (e) {
      debugPrint('BookingService: Error confirming booking: $e');
      return false;
    }
  }

  Future<bool> cancelBooking(int bookingId) async {
    try {
      final booking = _bookings.firstWhere((b) => b.id == bookingId);
      if (_busService == null) {
        throw Exception('BusService not available');
      }

      final bus = await _busService!.getBusById(booking.busId);
      if (bus == null) {
        throw Exception('Bus not found');
      }

      final updatedBooking = booking.copyWith(status: 'cancelled');
      await updateBooking(updatedBooking);

      // Return seats to bus
      await _busService!.updateBusAvailability(
        bus.id!,
        bus.availableSeats + booking.numberOfSeats,
      );

      return true;
    } catch (e) {
      debugPrint('BookingService: Error cancelling booking: $e');
      return false;
    }
  }

  Future<List<Booking>> getUserBookings(int userId) async {
    try {
      final List<Map<String, dynamic>> maps = await _databaseHelper
          .getUserBookings(userId);
      return maps.map((map) => Booking.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get user bookings: $e');
    }
  }

  Future<List<Booking>> getBusBookings(int busId) async {
    try {
      final List<Map<String, dynamic>> maps = await _databaseHelper
          .getBusBookings(busId);
      return maps.map((map) => Booking.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get bus bookings: $e');
    }
  }

  Future<List<Booking>> searchBookings({
    int? userId,
    int? busId,
    String? status,
    String? fromLocation,
    String? toLocation,
  }) async {
    final List<String> whereParts = [];
    final List<dynamic> whereArgs = [];

    if (userId != null) {
      whereParts.add('userId = ?');
      whereArgs.add(userId);
    }
    if (busId != null) {
      whereParts.add('busId = ?');
      whereArgs.add(busId);
    }
    if (status != null) {
      whereParts.add('status = ?');
      whereArgs.add(status);
    }
    if (fromLocation != null) {
      whereParts.add('fromLocation = ?');
      whereArgs.add(fromLocation);
    }
    if (toLocation != null) {
      whereParts.add('toLocation = ?');
      whereArgs.add(toLocation);
    }

    final String where = whereParts.isNotEmpty ? whereParts.join(' AND ') : '1';
    final List<Map<String, dynamic>> maps = await _databaseHelper
        .searchBookings(where: where, whereArgs: whereArgs);

    return maps.map((map) => Booking.fromMap(map)).toList();
  }
}
