import 'package:flutter/foundation.dart';
import 'package:bus_ticket_booking/models/payment.dart';
import 'package:bus_ticket_booking/models/booking.dart';
import 'package:bus_ticket_booking/utils/database_helper.dart';
import 'package:bus_ticket_booking/services/booking_service.dart';

class PaymentService extends ChangeNotifier {
  final DatabaseHelper _databaseHelper;
  final BookingService _bookingService;
  bool _isInitialized = false;
  List<Payment> _payments = [];
  bool _isLoading = false;

  PaymentService(this._databaseHelper, this._bookingService);

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  List<Payment> get payments => List.unmodifiable(_payments);

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isLoading = true;
      notifyListeners();
      
      // Wait for BookingService to be initialized first
      if (!_bookingService.isInitialized) {
        await _bookingService.initialize();
      }
      
      final paymentMaps = await _databaseHelper.getAllPayments();
      _payments = paymentMaps.map((map) => Payment.fromMap(map)).toList();
      _isInitialized = true;
    } catch (e, stackTrace) {
      debugPrint('Error initializing PaymentService: $e');
      debugPrint('Stack trace: $stackTrace');
      _isInitialized = false;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Payment>> getPaymentsByDateRange(DateTime start, DateTime end) async {
    if (!_isInitialized) {
      throw StateError('PaymentService must be initialized before use');
    }

    try {
      _isLoading = true;
      notifyListeners();

      final paymentMaps = await _databaseHelper.getPaymentsByDateRange(
        start.toIso8601String(),
        end.toIso8601String(),
      );
      final payments = paymentMaps.map((map) => Payment.fromMap(map)).toList();
      _payments = payments;
      return payments;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Payment>> getAllPayments() async {
    if (!_isInitialized) {
      await initialize();
    }

    _isLoading = true;
    notifyListeners();
    
    try {
      final List<Map<String, dynamic>> maps = await _databaseHelper.getAllPayments();
      _payments = maps.map((map) => Payment.fromMap(map)).toList();
      return _payments;
    } catch (e, stackTrace) {
      debugPrint('Error loading payments: $e');
      debugPrint('Stack trace: $stackTrace');
      _payments = [];
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Payment?> getPaymentById(int id) async {
    try {
      final map = await _databaseHelper.getPaymentById(id);
      return map != null ? Payment.fromMap(map) : null;
    } catch (e) {
      debugPrint('Error getting payment by id: $e');
      return null;
    }
  }

  Future<Payment> createPayment(Payment payment) async {
    try {
      final id = await _databaseHelper.insertPayment(payment.toMap());
      return payment.copyWith(id: id);
    } catch (e) {
      debugPrint('Error creating payment: $e');
      rethrow;
    }
  }

  Future<Payment> updatePayment(Payment payment) async {
    try {
      if (payment.id == null) {
        throw Exception('Payment ID is required for update');
      }
      await _databaseHelper.updatePayment(payment.id!, payment.toMap());
      return payment;
    } catch (e) {
      debugPrint('Error updating payment: $e');
      rethrow;
    }
  }

  Future<void> deletePayment(int id) async {
    try {
      await _databaseHelper.deletePayment(id);
    } catch (e) {
      debugPrint('Error deleting payment: $e');
      rethrow;
    }
  }

  Future<List<Payment>> getPaymentsByBookingId(int bookingId) async {
    try {
      final List<Map<String, dynamic>> maps =
          await _databaseHelper.getAllPayments();
      return maps
          .map((map) => Payment.fromMap(map))
          .where((payment) => payment.bookingId == bookingId)
          .toList();
    } catch (e) {
      debugPrint('Error getting payments by booking id: $e');
      return [];
    }
  }

  Future<List<Payment>> getPaymentsByStatus(String status) async {
    try {
      final List<Map<String, dynamic>> maps =
          await _databaseHelper.getAllPayments();
      return maps
          .map((map) => Payment.fromMap(map))
          .where((payment) => payment.status == status)
          .toList();
    } catch (e) {
      debugPrint('Error getting payments by status: $e');
      return [];
    }
  }

  Future<void> updatePaymentStatus(int id, String status) async {
    try {
      final payment = await getPaymentById(id);
      if (payment == null) throw Exception('Payment not found');

      final updatedPayment = payment.copyWith(status: status);
      await updatePayment(updatedPayment);

      // Update booking payment status
      await _bookingService.updatePaymentStatus(payment.bookingId, status);
    } catch (e) {
      debugPrint('Error updating payment status: $e');
      rethrow;
    }
  }

  Future<Payment?> processPayment({
    required int bookingId,
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      // Get booking details
      final booking = await _bookingService.getBookingById(bookingId);
      if (booking == null) {
        throw Exception('Booking not found');
      }

      // Validate payment amount
      if (amount != booking.totalAmount) {
        throw Exception('Invalid payment amount');
      }

      // Generate a unique transaction ID
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final transactionId = 'TXN${timestamp.toString().substring(timestamp.toString().length - 6)}';

      // Create payment record
      final payment = Payment(
        bookingId: bookingId,
        amount: amount,
        paymentMethod: paymentMethod,
        status: 'completed',
        transactionId: transactionId,
        paymentDate: DateTime.now(),
      );

      final createdPayment = await createPayment(payment);

      // Update booking payment status
      await _bookingService.updatePaymentStatus(bookingId, 'completed');
      await _bookingService.updateBookingStatus(bookingId, 'confirmed');

      return createdPayment;
    } catch (e) {
      debugPrint('Error processing payment: $e');
      rethrow;
    }
  }

  Future<List<Payment>> getBookingPayments(int bookingId) async {
    try {
      return await getPaymentsByBookingId(bookingId);
    } catch (e) {
      debugPrint('Error getting booking payments: $e');
      rethrow;
    }
  }

  Future<double> getTotalRevenue({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      final List<Map<String, dynamic>> maps =
          await _databaseHelper.getAllPayments();
      final payments =
          maps
              .map((map) => Payment.fromMap(map))
              .where(
                (payment) =>
                    payment.status == 'completed' &&
                    (startDate == null ||
                        payment.paymentDate.isAfter(startDate)) &&
                    (endDate == null || payment.paymentDate.isBefore(endDate)),
              )
              .toList();
      double total = 0.0;
      for (var payment in payments) {
        total += payment.amount;
      }
      return total;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
