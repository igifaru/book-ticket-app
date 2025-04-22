import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/route.dart' as route_model;
import '../models/bus.dart';
import '../models/booking.dart';
import '../models/payment.dart';
import '../services/booking_service.dart';
import '../services/payment_service.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import 'payment_screen.dart';

class BookingScreen extends StatefulWidget {
  final Bus bus;
  final route_model.Route route;

  const BookingScreen({
    super.key,
    required this.bus,
    required this.route,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _selectedSeats = 1;
  DateTime? _selectedDate;
  bool _isLoading = false;
  double _totalAmount = 0;

  @override
  void initState() {
    super.initState();
    _calculateTotal();
  }

  void _calculateTotal() {
    setState(() {
      _totalAmount = widget.bus.price * _selectedSeats;
    });
  }

  Future<void> _createBooking() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a travel date')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      final bookingService = context.read<BookingService>();
      final user = authService.currentUser;

      if (user == null) {
        throw Exception('User not logged in');
      }

      // Create the booking
      final booking = Booking(
        userId: user.id!,
        busId: widget.bus.id!,
        fromLocation: widget.bus.fromLocation,
        toLocation: widget.bus.toLocation,
        travelDate: _selectedDate!,
        numberOfSeats: _selectedSeats,
        totalAmount: _totalAmount,
      );

      final createdBooking = await bookingService.createBooking(booking);

      if (!mounted) return;

      // Navigate to payment screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            booking: createdBooking,
            amount: _totalAmount,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating booking: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Ticket'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bus Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Bus: ${widget.bus.busName}'),
                    Text(
                      'Route: ${widget.route.startLocation} to ${widget.route.endLocation}',
                    ),
                    Text('Departure: ${widget.bus.departureTime}'),
                    Text('Available Seats: ${widget.bus.availableSeats}'),
                    Text('Price per seat: ${widget.bus.formattedPrice}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Number of Seats:'),
                        const SizedBox(width: 16),
                        DropdownButton<int>(
                          value: _selectedSeats,
                          items: List.generate(
                            widget.bus.availableSeats,
                            (index) => DropdownMenuItem(
                              value: index + 1,
                              child: Text('${index + 1}'),
                            ),
                          ),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedSeats = value;
                                _calculateTotal();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Travel Date:'),
                        const SizedBox(width: 16),
                        TextButton(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 30)),
                            );
                            if (date != null) {
                              setState(() {
                                _selectedDate = date;
                              });
                            }
                          },
                          child: Text(
                            _selectedDate == null
                                ? 'Select Date'
                                : '${_selectedDate!.year}-${_selectedDate!.month}-${_selectedDate!.day}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Total Amount: RWF ${_totalAmount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _createBooking,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Proceed to Payment'),
            ),
          ],
        ),
      ),
    );
  }
}
