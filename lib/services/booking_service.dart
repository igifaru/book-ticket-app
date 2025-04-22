import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:bus_ticket_booking/models/booking.dart';
import 'package:bus_ticket_booking/models/bus.dart';
import 'package:bus_ticket_booking/utils/database_helper.dart';
import 'bus_service.dart';

class BookingService extends ChangeNotifier {
  final DatabaseHelper _databaseHelper;
  final BusService _busService;
  List<Booking> _bookings = [];
  bool _loading = false;
  bool _isInitialized = false;

  BookingService({
    required DatabaseHelper databaseHelper,
    required BusService busService,
  })  : _databaseHelper = databaseHelper,
        _busService = busService;

  List<Booking> get bookings => _bookings;
  bool get loading => _loading;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _loading = true;
    notifyListeners();

    try {
      debugPrint('BookingService: Starting initialization...');
      if (!_busService.isInitialized) {
        debugPrint('BookingService: Initializing BusService first...');
        await _busService.initialize();
      }
      await _databaseHelper.database;
      await getAllBookings();
      _isInitialized = true;
      debugPrint('BookingService: Initialization complete');
    } catch (e, stackTrace) {
      debugPrint('BookingService: Error during initialization: $e');
      debugPrint('BookingService: Stack trace: $stackTrace');
      _isInitialized = false;
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<List<Booking>> getAllBookings() async {
    if (!_isInitialized && !_loading) {
      await initialize();
    }

    _loading = true;
    notifyListeners();

    try {
      debugPrint('BookingService: Loading all bookings...');
      final List<Map<String, dynamic>> maps = await _databaseHelper.getAllBookings();
      _bookings = maps.map((map) => Booking.fromMap(map)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      debugPrint('BookingService: Loaded ${_bookings.length} bookings');
      return _bookings;
    } catch (e, stackTrace) {
      debugPrint('BookingService: Error loading bookings: $e');
      debugPrint('BookingService: Stack trace: $stackTrace');
      _bookings = [];
      return [];
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
    try {
      final bus = await _busService.getBusById(booking.busId);
      if (bus == null) throw Exception('Bus not found');

      if (bus.availableSeats < booking.numberOfSeats) {
        throw Exception('Not enough seats available');
      }

      final bookingId = await _databaseHelper.insertBooking(booking.toMap());

      // Update bus available seats
      await _busService.updateBusAvailability(
        booking.busId,
        (bus.availableSeats! - booking.numberOfSeats).toInt(),
      );

      await getAllBookings();
      return booking.copyWith(id: bookingId);
    } catch (e) {
      debugPrint('Error creating booking: $e');
      rethrow;
    }
  }

  Future<Booking> updateBooking(Booking booking) async {
    try {
      if (booking.id == null)
        throw Exception('Booking ID is required for update');
      await _databaseHelper.updateBooking(booking.id!, booking.toMap());
      return booking;
    } catch (e) {
      debugPrint('Error updating booking: $e');
      rethrow;
    }
  }

  Future<void> deleteBooking(int id) async {
    try {
      await _databaseHelper.deleteBooking(id);
    } catch (e) {
      debugPrint('Error deleting booking: $e');
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
    try {
      final List<Map<String, dynamic>> maps = await _databaseHelper
          .getBookingsByUserId(userId);
      return maps.map((map) => Booking.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error getting bookings by user id: $e');
      return [];
    }
  }

  Future<List<Booking>> getBookingsByBusId(int busId) async {
    try {
      final List<Map<String, dynamic>> maps = await _databaseHelper
          .getBookingsByBusId(busId);
      return maps.map((map) => Booking.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error getting bookings by bus id: $e');
      return [];
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

  Future<bool> cancelBooking(int id) async {
    try {
      final booking = await getBookingById(id);
      if (booking == null) return false;

      final bus = await _busService.getBusById(booking.busId);
      if (bus == null) return false;

      final updatedBooking = booking.copyWith(status: 'cancelled');
      await updateBooking(updatedBooking);

      await _busService.updateBusAvailability(
        bus.id!,
        (bus.availableSeats! + booking.numberOfSeats).toInt(),
      );

      // Force refresh and notify listeners
      _bookings = await getAllBookings();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error cancelling booking: $e');
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
